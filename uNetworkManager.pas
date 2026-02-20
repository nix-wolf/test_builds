unit uNetworkManager;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  System.Classes,
  System.DateUtils,
  IdGlobal,
  IdTCPClient,
  IdTCPServer,
  IdUDPClient,
  IdUDPServer,
  IdContext,
  IdSocketHandle,
  Vcl.ExtCtrls,
  uNetworkTypes;

type
  TNetworkRole = (nrNone, nrClient, nrServer);

  TNetworkManager = class(TObject)
  private
    FUDPListener: TIdUDPServer;
    FTCPClient: TIdTCPClient;
    FTCPServer: TIdTCPServer;
    FRole: TNetworkRole;
    FBroadcastTimer: TTimer;
    FUDPClient: TIdUDPClient;
    FServerPort: Integer;
    FActiveSessions: TList<TGameSession>;
    FHubIP: String;
    FGameName: String;

    procedure OnBroadcastTimer(Sender: TObject);
    procedure OnUDPRead(aThread: TIdUDPListenerThread; const aData: TIdBytes; aBinding: TIdSocketHandle);
    procedure OnHubExecute(aContext: TIdContext);
    procedure RegisterWithHub(const aSession: TGameSession);
    procedure HandleRegistration(const aData: String; aContext: TIdContext);
    procedure OnCleanupTimer(Sender: TObject);
    function ConnectToHub: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    function FetchRemoteConnections: TArray<TGameSession>;
    function DiscoverAndJoin(APort: Integer): Boolean;
    procedure StartHosting(APort: Integer);

    property Role: TNetworkRole read FRole;
    property HubIP: String Read FHubIP write FHubIP;
    property GameName: String Read FGameName write FGameName;

  end;
implementation

{ TNetworkManager }

function TNetworkManager.ConnectToHub: Boolean;
begin
  Result := False;
  if FHubIP = '' then Exit;

  FTCPClient.Host := FHubIP;
  FTCPClient.Port := 6000;

  try
    if not FTCPClient.Connected then
      FTCPClient.Connect;
    Result := True;
  except
    on E: Exception do
      //todo handle failure
  end; {TRY}
end;

constructor TNetworkManager.Create;
begin
  inherited Create;
  FRole := nrNone;

  FUDPListener := TIdUDPServer.Create(nil);
  FUDPListener.OnUDPRead := OnUDPRead;
  FUDPListener.ThreadedEvent := True;

  FTCPClient := TIdTCPClient.Create(nil);
  FTCPServer := TIdTCPServer.Create(nil);

  FUDPClient := TIdUDPClient.Create(nil);

  FBroadcastTimer := TTimer.Create(nil);
  FBroadcastTimer.Interval := 2000;
  FBroadcastTimer.OnTimer := OnBroadcastTimer;

end;

destructor TNetworkManager.Destroy;
begin
  FUDPListener.Free;
  FTCPClient.Free;
  FTCPServer.Free;
  FUDPClient.Free;
  FBroadcastTimer.Free;
  inherited Destroy;
end;

function TNetworkManager.DiscoverAndJoin(aPort: Integer): Boolean;
  var
    aTimeoutCounter: Integer;
begin
  Result := False;
  FRole := nrNone;

  FUDPListener.DefaultPort := aPort;
  FUDPListener.Active := True;

  aTimeoutCounter := 0;
  while (FRole = nrNone) and (aTimeoutCounter < 30) do begin
    Sleep(100);
    Inc(aTimeoutCounter);
    CheckSynchronize(10);
  end; {WHILE}

  if FRole = nrClient then begin
    FTCPClient.Port := aPort;
    try
      FTCPClient.Connect;
      Result := True;
    except
      FRole := nrNone;
    end; {TRY}
  end; {IF}

  if FRole = nrNone then begin
    FUDPListener.Active := False;
    StartHosting(APort);
    Result := True;
  end; {IF}
end;

function TNetworkManager.FetchRemoteConnections: TArray<TGameSession>;
  var
    aData: String;
    aGamesData: TArray<String>;
    i: Integer;
begin
  if not FTCPClient.Connected then Exit;

  FTCPClient.IOHandler.WriteLn('GET_GAMES');
  aData := FTCPClient.IOHandler.ReadLn;

  aGamesData := aData.Split([';'], TStringSplitOptions.ExcludeEmpty);
  SetLength(Result, Length(aGamesData));

  for i := 0 to High(aGamesData) do
    Result[i].FromNetworkString(aGamesData[i]);
end;

procedure TNetworkManager.HandleRegistration(const aData: String;
  aContext: TIdContext);
  var
    aNewSession: TGameSession;
    i: Integer;
    aFound: Boolean;
begin
  aNewSession.FromNetworkString(aData);

  if aNewSession.HostIP = '' then
    aNewSession.HostIP := aContext.Binding.PeerIP;

  aFound := False;

  TMonitor.Enter(FActiveSessions);
  try
    for I := 0 to FActiveSessions.Count - 1 do begin
      if FActiveSessions[i].HostIP = aNewSession.HostIP then begin
        FActiveSessions[i] := aNewSession;
        aFound := True;
        Break;
      end; {IF}
    end; {FOR}

    if not aFound then
        FActiveSessions.Add(aNewSession);
  finally
    TMonitor.Exit(FActiveSessions);
  end;
end;

procedure TNetworkManager.OnBroadcastTimer(Sender: TObject);
begin
  if FRole = nrServer then begin
    try
      FUDPClient.BroadcastEnabled := True;

      if FHubIP <> '' then
       FUDPClient.Send(FHubIP, FServerPort, 'HEARTBEAT,' + FGameName);

      FUDPClient.Send('255.255.255.255', FServerPort, 'VE_PROJ_WOLF');
    except
      on E: Exception do
        //handle exception
    end;

  end; {IF}
end;

procedure TNetworkManager.OnCleanupTimer(Sender: TObject);
  var
    i: Integer;
begin
  TMonitor.Enter(FActiveSessions);
  try
    for i := FActiveSessions.Count - 1 downto 0 do begin
      if SecondsBetween(Now, FActiveSessions[i].LastSeen) > 10 then begin
        FActiveSessions.Delete(i);
      end; {IF}
    end; {FOR}
  finally
    TMonitor.Exit(FActiveSessions);
  end;
end;

procedure TNetworkManager.OnHubExecute(aContext: TIdContext);
  var
    aRequest: String;
    aSession: TGameSession;
    aResponse: String;
begin
  aRequest := aContext.Connection.IOHandler.ReadLn;

  if aRequest = 'GET_GAMES' then begin
    aResponse := '';
    for aSession in FActiveSessions do
      aResponse := aResponse + aSession.ToNetworkString + ';';

    AContext.Connection.IOHandler.WriteLn(aResponse);
  end {IF}
  else if aRequest.StartsWith('REGISTER,') then begin
    //add new host game
  end; {ELSE}

end;

procedure TNetworkManager.OnUDPRead(aThread: TIdUDPListenerThread;
  const aData: TIdBytes; aBinding: TIdSocketHandle);
  var
    aMsg: String;
    i: Integer;
begin
  aMsg := BytesToString(aData);

  if aMsg = 'VE_PROJ_WOLF' then begin
    FRole := nrClient;
    FTCPClient.Host := aBinding.PeerIP;
  end; {IF}

  if aMsg.StartsWith('HEARTBEAT,') then begin
    TMonitor.Enter(FActiveSessions);
    try
      for i := 0 to FActiveSessions.Count - 1 do begin
        if FActiveSessions[i].HostIP = aBinding.PeerIP then begin
          var aTemp := FActiveSessions[I];
          aTemp.LastSeen := Now();
          FActiveSessions[i] := aTemp;
          Break;
        end; {IF}
      end; {FOR}
    finally
      TMonitor.Exit(FActiveSessions);
    end; {TRY}
  end; {IF}
end;

procedure TNetworkManager.RegisterWithHub(const aSession: TGameSession);
begin
  if FTCPClient.Connected then begin
    FTCPClient.IOHandler.WriteLn('REGISTER,' + aSession.ToNetworkString);
  end; {IF}
end;

procedure TNetworkManager.StartHosting(aPort: Integer);
begin
  try
    FTCPServer.DefaultPort := aPort;
    FTCPServer.Active := True;
    FRole := nrServer;

    FBroadcastTimer.Enabled := True;
  except
    on E: Exception do
      raise Exception.Create('Failed To Start Host: ' + E.Message);
  end;
end;

end.
