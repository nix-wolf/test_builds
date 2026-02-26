unit uNetManager;

interface

uses
   Winapi.Winsock2,
   System.Generics.Collections,
   System.SysUtils,
   System.Classes,
   System.DateUtils,
   Vcl.ExtCtrls,
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
         procedure OnBroadcastTimer (Sender: TObject);
         procedure OnCleanUpTimer   (Sender: TObject);
         //primary message handlers
         procedure OnTCPMessage     (const aIP, aMsg: String);
         procedure OnUDPMessage     (const aIP, aMsg: String);
         //client functions
         procedure OnConnect        (Sender: TObject);
         procedure OnDisconnect     (Sender: TObject);
         //server functions
//         procedure OnConnected         (aClient: TuTCPRemoteClient);
//         procedure OnDisconnected      (aClient: TuTCPRemoteClient);
         //Wrapper for UI events to return data to the ui
         procedure UIEventCallback<T>  (aEvent: TUIEvent<T>; aT: T);

         function GetLocalIP: string;
      public
         constructor Create;
         destructor Destroy; override;

         procedure Start;
         procedure StartHub(const aPort: Integer);
         procedure Connect(const aIP: String; const aPort: Integer);

         //call backs for returning data to parent frame
         procedure LogToUI             (const aMsg: String);
         procedure UpdateRoleToUI;

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

   if StartupResult <> 0 then
   begin
      raise Exception.Create('Critical: WSAStartup failed with error: ' + IntToStr(StartupResult));
   end;
   //Should be read from .ini
   FServerPort := 6000;

   FDispatcher := TuNEtworkDispatcher.Create;

   FUDP                     := TuSocket.Create(npUDP, FServerPort);
   FTCPClient               := TuSocket.Create(npTCP, FServerPort + 1);
   FTCPServer               := TuTCPServer.Create;

   FActiveSessions          := TList<TuGameSession>.Create;

   FBroadcastTimer          := TTimer.Create(nil);
   FBroadcastTimer.Enabled  := False;
   FBroadcastTimer.Interval := 2000;
   FBroadcastTimer.OnTimer  := OnBroadcastTimer;

   //Setup GameTimer variables
   //Setup CleanUpTimer variables
end;

procedure TNetManager.Start;
begin
   FUDP.OnDataReceived := OnUDPMessage;
   FUDP.Start;

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

procedure TNetManager.OnBroadcastTimer(Sender: TObject);
begin
   if (FRole = nrClient) or (FRole = nrServer) then begin
      if FHubIP <> '' then begin
//         LogToUI('UDP HEARTBEAT...');
//      FUDP.Send('HEARTBEAT,' + FGameName, FHubIP, FServerPort);
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
   begin UIEventCallback<String>(FOnLog, aMsg); end;

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
   LogToUI('Message Received TCP::');
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

   LogToUI('Message Received UDP::' + aIP + '@:: ' + aMsg);
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

      {
         Needs to be able to set the onconnect and ondisconnect in the client
         probably should do that also for the udp connection aswell not sure
         if there is any other life cycle methods that need to be set

         connect shouldnt need ip or port as they should already be in the socket
         well addr is
      }

   aConnection := FTCPClient.Connect(aIP, aPort);

   if aConnection then
      LogToUI('Connected to: ' + aIP + '@' + IntToStr(aPort));

end;

procedure TNetManager.OnConnect(Sender: TObject);
begin
   LogToUI('Connection Established');

end;

procedure TNetManager.OnDisconnect(Sender: TObject);
begin
   //notify server disconnect, kill connections, scrub data for graceful exit
end;

///////////////////////////////////////////////////////////////////////////////
//// Server Functions
///////////////////////////////////////////////////////////////////////////////


procedure TNetManager.StartHub(const aPort: Integer);
begin
   LogToUI('Starting Lobby Server...');
   FTCPServer := TuTCPServer.Create;

   {
      oh i have these set? i wonder why they never where called
      should have been called on the server when the client connected?
      i have a powershell netstat output that claimed is was ESTABLISHED
   }

//   FTCPServer.OnConnected := OnConnected;
//   FTCPServer.OnDisconnected := OnDisconnected;
   FTCPServer.OnMessage := OnTCPMessage;
   FTCPServer.OnLog := LogToUI;
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
