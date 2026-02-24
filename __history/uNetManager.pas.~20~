unit uNetManager;

interface

uses
  Winapi.Winsock2,
  System.Generics.Collections,
  System.SysUtils,
  System.Classes,
  System.DateUtils,
  Vcl.ExtCtrls,
  uNetworkTypes,
  uTCPClient,
  uTCPServer,
  uUDPNode;

type
  TUIEvent<T> = procedure(const aT: T) of Object;

  TNetManager = class
    private
      class var FInstance: TNetManager;
      FUDP: TuUDPNode;
      FTCPClient: TuTCPClient;
      FTCPServer: TuTCPServer;
      FBroadCastTimer: TTimer;
      FDispatcher: TDictionary<TuDispatchKey, TuPacketHandler>;
      FActiveSessions: TList<TuGameSession>;
      FRole: TuNetworkRole;
      FIP: String;
      //should be pulled for ini file?
      FServerPort: Integer;
      //can this be moved into discovery of just doing the discovery in a loop
      FDiscoveryAttempts: Integer;
      FHubIP: String;
      FGameName: String;

      FOnLog: TUIEvent<String>;
      FOnRoleChange: TUIEvent<TuNetworkRole>;

      //timer functions
      procedure OnBroadcastTimer(Sender: TObject);
      procedure OnCleanUpTimer(Sender: TObject);

      //client functions
      procedure CreateSession(const aSession: TuGameSession);
      procedure OnConnect(Sender: TObject);
      procedure OnDisconnect(Sender: TObject);
      procedure OnTCPMessage(aSender: TuTCPClient; const aMsg: String);
      procedure OnUDPMessage(const aIP, aMsg: String);
      //server functions
      procedure HandleCreateSession(const aMsg: String; aClient: TuTCPRemoteClient);
      procedure OnConnected(aClient: TuTCPRemoteClient);
      procedure OnDisconnected(aClient: TuTCPRemoteClient);
      procedure OnServerTCPMessage(aClient: TuTCPRemoteClient; const aMsg: String);
      procedure OnServerUDPMessage(const aIP, aMsg: String);



      procedure LogToUI(const aMsg: String);
      procedure UpdateRoleToUI;
      procedure UIEventCallback<T>(aEvent: TUIEvent<T>; aT: T);

      function GetLocalIP: string;
    public
      constructor Create;
      destructor Destroy; override;

      procedure StartHub(const aPort: Integer);
      procedure Connect(const aIP: String; const aPort: Integer);

      class property UDP: TuUDPNode read FUDP;
      class property TCPClient: TuTCPClient read FTCPClient;
      class property TCPServer: TuTCPServer read FTCPServer;
      class property OnLog: TUIEvent<String> read FOnLog write FOnLog;
      class property OnRoleChange: TUIEvent<TuNetworkRole> read FOnRoleChange write FOnRoleChange;

      class function Get: TNetManager;
      procedure Start;
  end;

var
  NetMgr: TNetManager;

implementation

{ TNetManager }

///////////////////////////////////////////////////////////////////////////////
//// Construction/Initalization
///////////////////////////////////////////////////////////////////////////////

constructor TNetManager.Create;
begin
  FServerPort := 6000;

  FUDP := TuUDPNode.Create;
  FTCPClient := TuTCPClient.Create;
  FTCPServer := TuTCPServer.Create;
  FActiveSessions := TList<TuGameSession>.Create;

  FBroadcastTimer := TTimer.Create(nil);
  FBroadcastTimer.Enabled := False;
  FBroadcastTimer.Interval := 2000;
  FBroadcastTimer.OnTimer := OnBroadcastTimer;
end;

procedure TNetManager.Start;
begin
  FUDP := TuUDPNode.Create;
  FUDP.OnDataRecieved := OnUDPMessage;
  FUDP.Start(6000);

  FBroadcastTimer.Enabled := True;

  FIP := GetLocalIP;
end;

///////////////////////////////////////////////////////////////////////////////
//// Other
///////////////////////////////////////////////////////////////////////////////

class function TNetManager.Get: TNetManager;
begin
  if FInstance = nil then
    FInstance := TNetManager.Create;
  Result := FInstance;
end;

function TNetManager.GetLocalIP: string;
var
  aHostName: array[0..255] of AnsiChar;
  aHostEnt: PHostEnt;
  aAddr: PInAddr;
begin
  Result := '127.0.0.1';

  if GetHostname(aHostName, SizeOf(aHostName)) = 0 then
  begin
    aHostEnt := GetHostByName(aHostName);
    if aHostEnt <> nil then
    begin
      aAddr := PInAddr(aHostEnt^.h_addr_list^);
      if aAddr <> nil then
        Result := string(inet_ntoa(aAddr^));
    end;
  end;
end;

procedure TNetManager.OnBroadcastTimer(Sender: TObject);
begin
 if (FRole = nrClient) or (FRole = nrServer) then begin
    if FHubIP <> '' then begin
//      LogToUI('UDP HEARTBEAT...');
      FUDP.Send('HEARTBEAT,' + FGameName, FHubIP, FServerPort);
    end; {IF}
  end; {IF}

  if FRole = nrNone then begin
    if FDiscoveryAttempts >= 3 then begin
      FRole := nrHub;
      UpdateRoleToUI;
      StartHub(FServerPort);
      FBroadcastTimer.Enabled := False;
    end {IF}
    else begin
      UpdateRoleToUI;
      LogToUI('Checking for Active Hub');
      FUDP.Broadcast('VEWLF', FServerPort);
      Inc(FDiscoveryAttempts);
    end; {ELSE}
  end; {IF}
end;

procedure TNetManager.OnCleanUpTimer(Sender: TObject);
  var
    i: Integer;
begin
  LogToUI('Cleaning Up Sessions.');
  TMonitor.Enter(FActiveSessions);
  try
    for i := FActiveSessions.Count - 1 downto 0 do begin
      if SecondsBetween(Now, FActiveSessions[i].FLastSeen) > 10 then begin
        FActiveSessions.Delete(i);
      end; {IF}
    end; {FOR}
  finally
    TMonitor.Exit(FActiveSessions);
  end;
end;


procedure TNetManager.UIEventCallback<T>(aEvent: TUiEvent<T>; aT: T);
begin
  if Assigned(aEvent) then begin
    TThread.Queue(nil, procedure begin
      aEvent(aT);
    end);{PROCEDURE}
  end; {IF}
end;

procedure TNetManager.LogToUI(const aMsg: String);
begin
  UIEventCallback<String>(FOnLog, aMsg);
end;

procedure TNetManager.UpdateRoleToUI;
begin
  UIEventCallback<TuNetworkRole>(FOnRoleChange, FRole);
end;

///////////////////////////////////////////////////////////////////////////////
//// Client Functions
///////////////////////////////////////////////////////////////////////////////

procedure TNetManager.Connect(const aIP: String; const aPort: Integer);
begin
  if not Assigned(FTCPClient) then
    FTCPClient := TuTCPClient.Create;
  FTCPClient.Connect(aIP, aPort);
end;

procedure TNetManager.OnConnect(Sender: TObject);
begin

end;


procedure TNetManager.OnDisconnect(Sender: TObject);
begin

end;

procedure TNetManager.OnTCPMessage(aSender: TuTCPClient; const aMsg: String);
begin

end;

procedure TNetManager.OnUDPMessage(const aIP, aMsg: String);
begin
  if aIP = FIP then Exit;

  case FRole of
    nrNone: begin
        LogToUI('OnNone::' + aIP + '@: ' + aMsg);

    end;
    nrClient: begin
      LogToUI('OnClient::' + aIP + '@: ' + aMsg);
    end;
    nrServer: begin
      LogToUI('OnServer::' + aIP + '@: ' + aMsg);
    end;
    nrHub: begin
      LogToUI('OnHub::' + aIP + '@: ' + aMsg);
      if aMsg = 'VE_PROJ_WOLF' then
        FUDP.Send(aMsg, aIP, FServerPort);

    end;
  end;

end;

procedure TNetManager.CreateSession(const aSession: TuGameSession);
begin

end;

///////////////////////////////////////////////////////////////////////////////
//// Server Functions
///////////////////////////////////////////////////////////////////////////////


procedure TNetManager.StartHub(const aPort: Integer);
begin
  LogToUI('Starting Lobby Server...');
  FTCPServer := TuTCPServer.Create;

  FTCPServer.OnConnected := OnConnected;
  FTCPServer.OnDisconnected := OnDisconnected;
  FTCPServer.OnMessage := OnServerTCPMessage;
  FTCPServer.OnLog := LogToUI;
  FTCPServer.Start(aPort);
end;

procedure TNetManager.OnConnected(aClient: TuTCPRemoteClient);
begin

end;

procedure TNetManager.OnDisconnected(aClient: TuTCPRemoteClient);
begin

end;

procedure TNetManager.OnServerTCPMessage(aClient: TuTCPRemoteClient;
  const aMsg: String);
begin

end;

procedure TNetManager.OnServerUDPMessage(const aIP, aMsg: String);
begin

end;

procedure TNetManager.HandleCreateSession(const aMsg: String;
  aClient: TuTCPRemoteClient);
begin

end;


///////////////////////////////////////////////////////////////////////////////
//// Deconstruction
///////////////////////////////////////////////////////////////////////////////

destructor TNetManager.Destroy;
begin
  //todo freeandnil() all of these on an if
  if Assigned(FBroadcastTimer) then begin
    FBroadcastTimer.Enabled := False;
    FreeAndNil(FBroadcastTimer);
  end;
  if Assigned(FUDP) then FreeAndNil(FUDP);
  if Assigned(FTCPClient) then FreeAndNil(FTCPClient);
  if Assigned(FTCPServer) then FreeAndNil(FTCPServer);

  inherited;
end;

initialization

finalization
  if TNetManager.FInstance <> nil then begin
    var aInst := TNetManager.FInstance;
    TNetManager.FInstance := nil;
    aInst.Free;
  end; {IF}
end.
