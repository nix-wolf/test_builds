unit uNetManager;

interface

uses
   System.UITypes,
   Winapi.Winsock2,
   System.Generics.Collections,
   System.SysUtils,
   System.Classes,
   System.DateUtils,
   System.Rtti,
   Vcl.ExtCtrls,
   uTCPRemoteClient,
   uNetworkDispatcher,
   uNetworkTypes,
   uTCPServer,
   uSocket;

type
   TUIEvent<T> = procedure(const aT: T) of Object;

   TNetManager = class
      private
         class var FInstance : TNetManager;
         WSAData             : TWSAData;
         StartupResult       : Integer;

         FUDP                : TuSocket;
         FTCPClient          : TuSocket;
         FTCPServer          : TuTCPServer;
         FDispatcher         : TuNetworkDispatcher;
         FRole               : TuNetworkRole;
         //Should be in server
         FActiveSessions     : TList<TuGameSession>;
         FBroadCastTimer     : TTimer;
         FGameUpdateTimer    : TTimer;
         FCleanUpTimer       : TTimer;
         //should be pulled for ini file?
         FServerPort         : Integer;
         //can this be moved into discovery of just doing the discovery in a loop
         FDiscoveryAttempts  : Integer;
         FHubIP              : String;
         FGameName           : String; //probably should be moved to session
         FName               : String; //is the user name
         FIP                 : String;

         FOnLog              : TUIEvent<String>;
         FOnRoleChange       : TUIEvent<TuNetworkRole>;

         //timer functions
         procedure OnBroadcastTimer    (aSender: TObject);
         procedure OnCleanUpTimer      (aSender: TObject);

         //primary message handlers
         procedure OnTCPMessage        (const aIP, aMsg: String);
         procedure OnUDPMessage        (const aIP, aMsg: String);

         //client functions
         procedure OnConnect           (aSender: TObject);
//         procedure OnDisconnect     (aSender: TObject);
         //server functions
         procedure OnConnected         (aSocket: TSocket; aAddr: SockAddr_In);
         procedure OnDisconnected      (aSocket: TSocket; aAddr: SockAddr_In);
         //Wrapper for UI events to return data to the ui
         procedure UIEventCallback<T>  (aEvent: TUIEvent<T>; aT: T);

         function GetLocalIP: string;
      public
         constructor Create;
         destructor Destroy; override;

         procedure Start;
         procedure StartHub(const aPort: Integer);
         procedure Connect(const aIP: String; const aPort: Integer);
         procedure Send(aP: TuPacket);
         //call backs for returning data to parent frame
         procedure LogToUI             (const aMsg: String);
         procedure UpdateRoleToUI;


         class property IP                : String                  read FIP;
         class property UDP               : TuSocket                read FUDP;
         class property TCPClient         : TuSocket                read FTCPClient;
         class property TCPServer         : TuTCPServer             read FTCPServer;
         class property ServerPort        : Integer                 read FServerPort;
         class property Role              : TuNetworkRole           read FRole              write FRole;
         class property BroadcastTimer    : TTimer                  read FBroadcastTimer    write FBroadcastTimer;
         class property OnLog             : TUIEvent<String>        read FOnLog             write FOnLog;
         class property OnRoleChange      : TUIEvent<TuNetworkRole> read FOnRoleChange      write FOnRoleChange;
         class property DiscoveryAttempts : Integer                 read FDiscoveryAttempts write FDiscoveryAttempts;

         class function Get               : TNetManager;
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
   StartupResult := WSAStartup($0202, WSAData);

   if StartupResult <> 0 then begin
      raise Exception.Create('Critical: WSAStartup failed with error: ' + IntToStr(StartupResult));
   end; {IF}
   //Should be read from .ini
   FServerPort              := 6000;
   FDispatcher              := TuNEtworkDispatcher.Create;
   FUDP                     := TuSocket.Create(npUDP, FServerPort);
   FTCPClient               := TuSocket.Create(npTCP, FServerPort + 1);
   FTCPServer               := TuTCPServer.Create;

   FActiveSessions          := TList<TuGameSession>.Create;

   FBroadcastTimer          := TTimer.Create(nil);
   FBroadcastTimer.Enabled  := False;
   FBroadcastTimer.Interval := 2000;
   FBroadcastTimer.OnTimer  := OnBroadcastTimer;

   //Setup GameTimer variables
   //Setup CleanUpTimer variables (Doesnt start till first session received, and shuts off when none are left)
end;

procedure TNetManager.Start;
begin
   FIP                 := GetLocalIP;
   FUDP.OnDataReceived := OnUDPMessage;
   FUDP.Start;

   FBroadcastTimer.Enabled := True;
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
   aHostName : array[0..255] of AnsiChar;
   aHostEnt  : PHostEnt;
   aAddr     : PInAddr;
begin
   Result := '127.0.0.1';

   if GetHostname(aHostName, SizeOf(aHostName)) = 0 then begin
      aHostEnt := GetHostByName(aHostName);
      if aHostEnt <> nil then begin
         aAddr := PInAddr(aHostEnt^.h_addr_list^);

         if aAddr <> nil then
            Result := string(inet_ntoa(aAddr^));
      end; {IF}
   end; {IF}
end;

procedure TNetManager.OnBroadcastTimer(aSender: TObject);
begin
   if (FRole = nrClient) or (FRole = nrServer) then begin
      if FHubIP <> '' then begin
//      FUDP.Send('HETB|' + FGameName, FHubIP, FServerPort);
      end; {IF}
   end; {IF}

   if FRole = nrNone then begin
      if FDiscoveryAttempts >= 3 then begin
         FRole := nrHub;

      UpdateRoleToUI;
      StartHub(FServerPort);
      FBroadcastTimer.Interval := 10000;
      end {IF}
      else begin
         UpdateRoleToUI;
         LogToUI('Checking for Active Hub');
         //should be making a proper packet here
         FUDP.Broadcast(TuPacket.Create(pfVEWLF, '').Parse, FServerPort);
         Inc(FDiscoveryAttempts);
      end; {ELSE}
   end; {IF}
end;

procedure TNetManager.OnCleanUpTimer(aSender: TObject);
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

procedure TNetManager.Send(aP: TuPacket);
   var
      aCmd: TuPacketFlag;
begin
   //Probably should have a way to ensure the connection is good... active in the socket
   aCmd := TRttiEnumerationType.GetValue<TuPacketFlag>(aP.FCommand);

   case FRole of
      nrNone: begin
         if Assigned(UDP) and UDP.IsConnected then begin
            UDP.Broadcast(aP.Parse, 6000);
            Exit;
         end;
      end;
      nrClient: begin
         if Assigned(FTCPClient) and FTCPClient.IsConnected then begin
            FTCPClient.Send(aP.Parse, '', 0);
            Exit;
         end;
      end;
      nrServer,
      nrHub: begin
         if Assigned(FTCPServer) then begin
            case aCmd of
               pfCHAT: LogToUI(aP.FData);
               pfVEWLF: LogToUI('Responding to a Hub Search Query');
               pfSES: {here now.};
               pfJOIN: {Handle info for join to respective parties};
               pfKIL: {causes connection to drop};
               pfSHFT: {sending a shift will dump data for other hub};
            end;

            FTCPServer.Broadcast(aP);
            Exit;
         end;{end}
      end;

   end;
   LogToUI('Not Connected');
end;

procedure TNetManager.UIEventCallback<T>(aEvent: TUiEvent<T>; aT: T);
begin
   if Assigned(aEvent) then begin
      TThread.Queue(nil, procedure begin
         aEvent(aT);
      end);{PROCEDURE}
   end; {IF}
end;

procedure TNetManager.LogToUI(const aMsg: String; aColor TAlphaColor);
begin


   UIEventCallback<>(FOnLog, aMsg);
end;

procedure TNetManager.UpdateRoleToUI;
   begin UIEventCallback<TuNetworkRole>(FOnRoleChange, FRole); end;

///////////////////////////////////////////////////////////////////////////////
//// Primary Message Handlers
///////////////////////////////////////////////////////////////////////////////

///COMPRESS TO A SINGLE CALL THEY ARE BOTH JUST DIFFERENTIATED BY PROTOCOL
procedure TNetManager.OnTCPMessage(const aIP, aMsg: String);
   var
      aPacket: TuPacket;
begin
//   LogToUI('Message Received TCP::');
   if aIP = FIP then Exit;
   aPacket.FromString(aMsg);
   aPacket.FIP := aIP;

   FDispatcher.HandlePacket(aPacket, npTCP, FRole);
end;

procedure TNetManager.OnUDPMessage(const aIP, aMsg: String);
   var
      aPacket: TuPacket;
begin
   if (aIP = FIP) or (aIP = '127.0.0.1') then Exit;

//   LogToUI('Message Received UDP::' + aIP + '@:: ' + aMsg);
   aPacket.FromString(aMsg);
   aPacket.FIP := aIP;

   FDispatcher.HandlePacket(aPacket, npUDP, FRole);
end;

///////////////////////////////////////////////////////////////////////////////
//// Client Functions
///////////////////////////////////////////////////////////////////////////////

procedure TNetManager.Connect(const aIP: String; const aPort: Integer);
   var
      aConnection: Boolean;
begin
   FTCPClient.OnDataReceived := OnTCPMessage;
   aConnection               := FTCPClient.Connect(aIP, aPort);

   if aConnection then OnConnect(Self);
end;

//does this even need a argument? IT NEED A PROTOCOL for where we call it
procedure TNetManager.OnConnect(aSender: TObject);
   var
      aIP, aPort: String;
begin
   aIP   := FTCPClient.IpFromASocket(FTCPClient.Get);
   aPort := IntToStr(FTCPClient.Port);

   LogToUI('Connected to: ' + aIP + '@' + aPort);
end;

///////////////////////////////////////////////////////////////////////////////
//// Server Functions
///////////////////////////////////////////////////////////////////////////////

procedure TNetManager.OnConnected(aSocket: TSocket; aAddr: SockAddr_In);
   var
      aRConn   : TuTCPRemoteClient;
      aUSocket : TuSocket;
      aP       : TuPacket;
begin

   aUSocket := TuSocket.Create(
      aSocket,
      TuSocket.IpFromASocket(aSocket),
      TuSocket.PortFromASocket(aSocket),
      OnTCPMessage
   );

   aRConn := TuTCPRemoteClient.Create(
      Self,
      aUsocket,
      aUSocket.IpFromASocket(aSocket)
   );

   FTCPServer.OnClientConnected(aRConn);

   aP     := TuPacket.Create(pfCHAT, 'Welcome to the lobby!!');
   aP.FIP := aRConn.IP;
   aRConn.Send(aP);

   LogToUI('Connection Established: ' + aRConn.IP + '@' + IntToStr(aRConn.Port) + ': Welcome Message Sent');
end;

procedure TNetManager.OnDisconnected(aSocket: TSocket; aAddr: SockAddr_In);
begin
//   notify server disconnect, kill connections, scrub data for graceful exit
end;

procedure TNetManager.StartHub(const aPort: Integer);
begin
   LogToUI('Starting Lobby Server...');
   FTCPServer                := TuTCPServer.Create;
   FTCPServer.OnMessage      := OnTCPMessage;
   FTCPServer.OnLog          := LogToUI;
   FTCPServer.OnConnected    := OnConnected;
   FTCPServer.OnDisconnected := OnDisconnected;
   //should be on 6001, will be 24000+ for actual game servers.
   FTCPServer.Start(aPort + 1);

end;


///////////////////////////////////////////////////////////////////////////////
//// Deconstruction
///////////////////////////////////////////////////////////////////////////////

destructor TNetManager.Destroy;
begin
   if Assigned(FBroadcastTimer) then begin
      FBroadcastTimer.Enabled := False;
      FreeAndNil(FBroadcastTimer);
   end; {IF}
   if Assigned(FUDP)        then FreeAndNil(FUDP);
   if Assigned(FTCPClient)  then FreeAndNil(FTCPClient);
   if Assigned(FTCPServer)  then FreeAndNil(FTCPServer);
   if Assigned(FDispatcher) then FreeAndNil(FDispatcher);

   FreeAndNil(FActiveSessions);

   WSACleanup();
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
