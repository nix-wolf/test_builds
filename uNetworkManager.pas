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
  TNetworkRole = (nrNone, nrClient, nrServer, nrHub);

  TLogEvent = procedure(const aMsg: String) of Object;

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
    FOnLog: TLogEvent;
    FDiscoveryAttempts: Integer;

    procedure OnBroadcastTimer(Sender: TObject);
    procedure OnUDPRead(aThread: TIdUDPListenerThread; const aData: TIdBytes; aBinding: TIdSocketHandle);
    procedure OnHubExecute(aContext: TIdContext);
    procedure RegisterWithHub(const aSession: TGameSession);
    procedure HandleRegistration(const aData: String; aContext: TIdContext);
    procedure OnCleanupTimer(Sender: TObject);
    procedure LogToUI(const aMsg: String);
  public
    constructor Create;
    destructor Destroy; override;

    function ConnectToHub: Boolean;
    function FetchRemoteConnections: TArray<TGameSession>;
    function DiscoverAndJoin(APort: Integer): Boolean;
    procedure StartHostingHub(APort: Integer);

    property Role: TNetworkRole read FRole;
    property HubIP: String Read FHubIP write FHubIP;
    property GameName: String Read FGameName write FGameName;
    property OnLog: TLogEvent read FOnLog write FOnLog;

  end;
implementation

{ TNetworkManager }

function TNetworkManager.ConnectToHub: Boolean;
begin
  Result := False;
  if FHubIP = '' then Exit;

  FTCPClient.Host := FHubIP;
  FTCPClient.Port := FServerPort;

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
  FServerPort := 6000;
  FUDPListener := TIdUDPServer.Create(nil);
  FUDPListener.OnUDPRead := OnUDPRead;
  FUDPListener.ThreadedEvent := True;

  FTCPClient := TIdTCPClient.Create(nil);
  FTCPServer := TIdTCPServer.Create(nil);

  FUDPClient := TIdUDPClient.Create(nil);

  FBroadcastTimer := TTimer.Create(nil);
  FBroadcastTimer.Interval := 2000;
  FBroadcastTimer.OnTimer := OnBroadcastTimer;

  FTCPServer.OnExecute := OnHubExecute;
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
    LogToUI('Hub Found... Connecting');
    FTCPClient.Port := aPort;
    try
      FTCPClient.Connect;
      Result := True;
    except
      FRole := nrNone;
    end; {TRY}
  end; {IF}

  if FRole = nrNone then begin
    LogToUI('No Hub Found Starting a Hub...');
    FUDPListener.Active := False;
//    StartHosting(APort);
    Result := True;
  end; {IF}
end;

function TNetworkManager.FetchRemoteConnections: TArray<TGameSession>;
  var
    aData: String;
    aGamesData: TArray<String>;
    i: Integer;
begin
  LogToUI('Fetching Games');
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
  LogToUI('Handling Registration');
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

procedure TNetworkManager.LogToUI(const aMsg: String);
begin
  if Assigned(FOnLog) then begin
    TThread.Queue(nil, procedure begin
      FOnLog(aMsg);
    end);{PROCEDURE}
  end; {IF}
end;

procedure TNetworkManager.OnBroadcastTimer(Sender: TObject);
begin
  if (FRole = nrClient) or (FRole = nrServer) then begin
    if FHubIP <> '' then begin
      LogToUI('UDP HEARTBEAT...');
      FUDPClient.Send(FHubIP, FServerPort, 'HEARTBEAT,' + FGameName);
    end; {IF}
  end; {IF}

  if FRole = nrNone then begin
    if FDiscoveryAttempts >= 3 then begin
      FRole := nrHub;
      StartHostingHub(FServerPort);
      FBroadcastTimer.Enabled := False;
    end {IF}
    else begin
      FUDPClient.BroadcastEnabled := True;
      LogToUI('Checking for Active Hub');
      FUDPClient.Send('255.255.255.255', FServerPort, 'VE_PROJ_WOLF');
      Inc(FDiscoveryAttempts);
    end; {ELSE}
  end; {IF}

end;

procedure TNetworkManager.OnCleanupTimer(Sender: TObject);
  var
    i: Integer;
begin
  LogToUI('Cleaning Up Sessions.');
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
    LogToUI('Request for Games List.');
    aResponse := '';
    for aSession in FActiveSessions do
      aResponse := aResponse + aSession.ToNetworkString + ';';

    AContext.Connection.IOHandler.WriteLn(aResponse);
  end {IF}
  else if aRequest.StartsWith('REGISTER,') then begin
    LogToUI('Register Request.');
    HandleRegistration(aRequest, aContext);
  end; {ELSE}

end;

procedure TNetworkManager.OnUDPRead(aThread: TIdUDPListenerThread;
  const aData: TIdBytes; aBinding: TIdSocketHandle);
  var
    aMsg: String;
    i: Integer;
begin
  aMsg := BytesToString(aData);

  case FRole of
    nrNone: begin
      if aMsg = 'VE_PROJ_WOLF' then begin
        LogToUI('Received Response From Hub, Connecting to TCP Lobby');
        FHubIP := aBinding.PeerIP;
        FTCPClient.Host := FHubIP;
        FTCPClient.Port := FServerPort;
        FRole := nrClient;

        FTCPClient.Connect;
      end; {IF}
    end; {CASE: nrNone}
    nrClient: ; //todo not so sure here, heart beats are sent to hub
    nrServer: ; //todo not so sure here, heart beats are sent to hub
    nrHub: begin
      if aMsg = 'VE_PROJ_WOLF' then begin
        LogToUI('Client@' + aBinding.PeerIP + 'Looking for Hub, Responding...');
        FUDPClient.Send(aBinding.PeerIP, FServerPort, 'VE_PROJ_WOLF');
      end {IF}
      else if aMsg.StartsWith('HEARTBEAT,') then begin
        LogToUI('UDP_HEARTBEAT... updating sessions');
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
      end;{ELSE IF}
    end; {CASE: nrHub}
  end;

end;

procedure TNetworkManager.RegisterWithHub(const aSession: TGameSession);
begin
  if FTCPClient.Connected then begin
    LogToUI('Registering with Hub');
    FTCPClient.IOHandler.WriteLn('REGISTER,' + aSession.ToNetworkString);
  end; {IF}
end;

procedure TNetworkManager.StartHostingHub(aPort: Integer);
begin
  try
    LogToUI('Starting  TCP Server, Broadcasting...');
    FTCPServer.DefaultPort := aPort;
    FTCPServer.Active := True;
    FRole := nrHub;

    FBroadcastTimer.Enabled := True;
  except
    on E: Exception do
      raise Exception.Create('Failed To Start Host: ' + E.Message);
  end;
end;

end.
