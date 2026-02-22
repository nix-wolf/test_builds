unit uNetworkManager;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  System.Classes,
  System.DateUtils,
  IdGlobal,
  IdStack,
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

  TUIEvent = procedure(const aMsg: String) of Object;
  TRoleEvent = procedure(const aRole: TNetworkRole) of Object;

  TReadThread = class(TThread)
  private
    FManager: TObject;
  protected
    procedure Execute; override;
  public
    constructor Create(aManager: TObject);
  end;


  TNetworkManager = class(TObject)
  private
    FUDPClient: TIdUDPClient;
    FUDPListener: TIdUDPServer;
    FTCPClient: TIdTCPClient;
    FTCPServer: TIdTCPServer;
    FBroadcastTimer: TTimer;
    FReadThread: TReadThread;

    FActiveSessions: TList<TGameSession>;
    FRole: TNetworkRole;

    FServerPort: Integer;
    FDiscoveryAttempts: Integer;
    FHubIP: String;
    FGameName: String;

    FOnLog: TUIEvent;
    FOnRoleChange: TRoleEvent;

    procedure OnBroadcastTimer(Sender: TObject);
    procedure OnUDPRead(aThread: TIdUDPListenerThread; const aData: TIdBytes;
      aBinding: TIdSocketHandle);
    procedure OnHubExecute(aContext: TIdContext);
    procedure HandleRegistration(const aData: String; aContext: TIdContext);
    procedure LogToUI(const aMsg: String);
    procedure UpdateRoleToUI;

    procedure OnHubConnect(aContext: TidContext);
    procedure OnHubDisconnect(aContext: TidContext);
    procedure onClientConnected(Sender: TObject);
    procedure onClientDisconnected(Sender: TObject);

  public
    constructor Create;
    destructor Destroy; override;

    function ConnectToHub: Boolean;
    function FetchRemoteConnections: TArray<TGameSession>;

    procedure StartHostingHub(APort: Integer);
    procedure SendChatMessage(const  aUser, aMsg: String);
    procedure BroadcastToClients(const aMsg: String);
    procedure HandleIncomingTCP(const aMsg: String);

    property HubIP: String Read FHubIP write FHubIP;
    property GameName: String Read FGameName write FGameName;
    property OnLog: TUIEvent read FOnLog write FOnLog;
    property OnRoleChange: TRoleEvent read FOnRoleChange write FOnRoleChange;
  end;
implementation

{ TNetworkManager }

procedure TNetworkManager.BroadcastToClients(const aMsg: String);
  var
    aList: TList;
    i: Integer;
    aContext: TIdContext;
begin
  aList := FTCPServer.Contexts.LockList;
  try
    for i := 0 to aList.Count - 1 do begin
      aContext := TIdContext(aList[i]);
      try
        aContext.Connection.IOHandler.WriteLn(aMsg);
      except
        on E: Exception do ;
      end;
    end; {FOR}
  finally
    FTCPServer.Contexts.UnlockList;
  end;

end;

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
    on E: Exception do ;
      //todo handle failure
  end; {TRY}
end;

constructor TNetworkManager.Create;
begin
  inherited Create;
  FRole := nrNone;
  FActiveSessions := TList<TGameSession>.Create;
  FServerPort := 6000;
  FUDPListener := TIdUDPServer.Create(nil);
  FUDPListener.DefaultPort := FServerPort;
  FUDPListener.OnUDPRead := OnUDPRead;
  FUDPListener.ThreadedEvent := True;
  FUDPListener.Active := True;

  FUDPClient := TIdUDPClient.Create(nil);
  FTCPClient := TIdTCPClient.Create(nil);
  FTCPServer := TIdTCPServer.Create(nil);

  FBroadcastTimer := TTimer.Create(nil);
  FBroadcastTimer.Interval := 2000;
  FBroadcastTimer.OnTimer := OnBroadcastTimer;

  FTCPServer.OnExecute := OnHubExecute;

  FTCPServer.OnConnect := OnHubConnect;
  FTCPServer.OnDisconnect := OnHubDisconnect;
  FTCPClient.OnConnected := OnClientConnected;
  FTCPClient.OnDisconnected := OnClientDisconnected;
end;

destructor TNetworkManager.Destroy;
begin
  FUDPListener.Free;
  FTCPClient.Free;
  FTCPServer.Free;
  FUDPClient.Free;
  FBroadcastTimer.Free;

  FActiveSessions.Free;
  if Assigned(FReadThread) then FReadThread.Free;
  inherited Destroy;
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

procedure TNetworkManager.HandleIncomingTCP(const aMsg: String);
var
  aCommand, aFinalMsg: String;
  aCommaPos: Integer;
begin
  aCommaPos := Pos(',', aMsg);

  if aCommaPos > 0 then begin
    aCommand := Copy(aMsg, 1, aCommaPos - 2);
    aFinalMsg := Copy(aMsg, aCommaPos + 1, MaxInt);

    if aCommand = 'CHAT' then
      LogToUI(aFinalMsg);

  end{IF}
  else
    LogToUI('MalFormed Command:: ' + aMsg);
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
//      LogToUI('UDP HEARTBEAT...');
      FUDPClient.Send(FHubIP, FServerPort, 'HEARTBEAT,' + FGameName);
    end; {IF}
  end; {IF}

  if FRole = nrNone then begin
    if FDiscoveryAttempts >= 3 then begin
      FRole := nrHub;
      UpdateRoleToUI;
      StartHostingHub(FServerPort);
      FBroadcastTimer.Enabled := False;
    end {IF}
    else begin
      UpdateRoleToUI;
      FUDPClient.BroadcastEnabled := True;
      LogToUI('Checking for Active Hub');
      FUDPClient.Send('255.255.255.255', FServerPort, 'VE_PROJ_WOLF');
      Inc(FDiscoveryAttempts);
    end; {ELSE}
  end; {IF}

end;

procedure TNetworkManager.onClientConnected(Sender: TObject);
begin
  FRole := nrClient;

  TThread.Queue(nil, procedure
  begin
    LogToUI('Client: Successfully handshaked with Hub.');
    UpdateRoleToUI;
  end);

  if not Assigned(FReadThread) then
    FReadThread := TReadThread.Create(Self);
end;

procedure TNetworkManager.onClientDisconnected(Sender: TObject);
begin
  FRole := nrNone;
  TThread.Queue(nil, procedure begin
    LogToUI('Lost connection to Hub. Reverting to discovery mode...');
    FBroadcastTimer.Enabled := True;
  end); {PROCEDURE}
end;

procedure TNetworkManager.OnHubConnect(aContext: TidContext);
begin
  TThread.Queue(nil, procedure begin
    LogToUI('Hub: New TCP client connected from ' + AContext.Binding.PeerIP);
  end); {PROCEDURE}

  AContext.Connection.IOHandler.WriteLn('CHAT, Hub: Connection Established. Welcome to the Wolf Network.');
end;

procedure TNetworkManager.OnHubDisconnect(aContext: TidContext);
begin
//remove any associations to the ip and user?
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
  end {ELSE IF}
  else if aRequest.StartsWith('CHAT,') then begin

  end; {ELSE IF}


end;

procedure TNetworkManager.OnUDPRead(aThread: TIdUDPListenerThread;
  const aData: TIdBytes; aBinding: TIdSocketHandle);
  var
    aMsg: String;
    i: Integer;
    aLocalIP: String;
begin
  aLocalIP := GStack.LocalAddress;
  if(aBinding.PeerIP = '127.0.0.1') or (aBinding.PeerIP = aLocalIP) then
    Exit;

  aMsg := BytesToString(aData);
//  LogToUI('Recieved Message::: ' + aMsg);
  case FRole of
    nrNone: begin
      if aMsg = 'VE_PROJ_WOLF' then begin
        LogToUI('Received Response From Hub, Connecting to TCP Lobby');
        FHubIP := aBinding.PeerIP;
        FTCPClient.Host := FHubIP;
        FTCPClient.Port := FServerPort + 1;
        FTCPClient.ConnectTimeout := 1000;

        try
          LogToUI('Connecting...');
          FTCPClient.Connect;
        except
          on E:Exception do begin
            LogToUI('TCP Connection Failed:' + E.Message);
            FRole := nrNone;
            UpdateRoleToUI;
          end;{EXCEPTION}
        end;
      end; {IF}
    end; {CASE: nrNone}
    nrClient: ; //todo not so sure here, heart beats are sent to hub
    nrServer: ; //todo not so sure here, heart beats are sent to hub
    nrHub: begin
      if aMsg = 'VE_PROJ_WOLF' then begin
        LogToUI('Client@' + aBinding.PeerIP + ' Looking for Hub, Responding...');
        FUDPClient.Send('255.255.255.255', FServerPort, 'VE_PROJ_WOLF');
      end {IF}
      else if aMsg.StartsWith('HEARTBEAT,') then begin
//        LogToUI('UDP_HEARTBEAT... updating sessions');
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

procedure TNetworkManager.SendChatMessage(const  aUser, aMsg: String);
  var
    aFinalMsg: String;
begin
  aFinalMsg := 'CHAT, ' + aUser + ', ' + aMsg;

  if FRole = nrClient then begin
    if FTCPClient.Connected then
      LogToUI('Attemping to send a message');
      FTCPClient.IOHandler.WriteLn(aFinalMsg);
  end {IF}
  else if FRole = nrHub then begin
    LogToUI(aUser + ': ' + aMsg);
    BroadcastToClients(AFinalMsg);
  end; {ELSE}
end;

procedure TNetworkManager.StartHostingHub(aPort: Integer);
begin
  try
    LogToUI('Starting  TCP Server, Broadcasting...');
    FTCPServer.DefaultPort := aPort + 1;
    FTCPServer.Active := True;
    FRole := nrHub;
    UpdateRoleToUI;
  except
    on E: Exception do
      raise Exception.Create('Failed To Start Host: ' + E.Message);
  end;
end;

procedure TNetworkManager.UpdateRoleToUI;
begin
  if Assigned(FOnRoleChange) then begin
    TThread.Queue(nil, procedure begin
      FOnRoleChange(FRole);
    end);{PROCEDURE}
  end; {IF}
end;

{ TReadThread }

constructor TReadThread.Create(aManager: TObject);
begin
  inherited Create(False);
  FManager := aManager;
//  FreeOnTerminate := True;
end;

procedure TReadThread.Execute;
var
  aMsg: String;
  aNetMgr: TNetworkManager;
begin
  aNetMgr := TNetworkManager(FManager);

  TThread.Queue(nil, procedure begin
    aNetMgr.LogToUI('DEBUG: ReadingThread is now active and listening...');
  end); {PROCEDURE}
  while(not Terminated) and (aNetMgr.FTCPClient.Connected) do begin
    try
      aMsg := aNetMgr.FTCPClient.IOHandler.ReadLn;

      if aMsg <> '' then begin
        TThread.Queue(nil, procedure begin
          aNetMgr.HandleIncomingTCP(aMsg);
        end); {PROCEDURE}
      end; {IF}
    except
      on E: Exception do begin
        Terminate;
      end;
    end;
  end; {WHILE}
end;

end.
