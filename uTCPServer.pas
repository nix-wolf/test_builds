unit uTCPServer;

interface

uses
   uNetworkTypes,
   uReadThread,
   uSocket,
   uTCPRemoteClient,
   Winapi.Winsock2,
   System.SysUtils,
   System.Classes,
   System.Generics.Collections;

type
   TuTCPServer     = class;

   TuTCPServer = class(TuSocket)
      private
         FListener     : TuSocket;
         FJoinThread   : TuReadThread;
         FClients      : TObjectList<TuTCPRemoteClient>;
         FJoiners      : TStringList;
         FActive       : Boolean;

         FOnMsg        : TOnDataReceived;
         FOnConnect    : TClientConnectEvent;
         FOnDisconnect : TClientConnectEvent;
         FOnLog        : TUIEvent2<String, TuMessageType>;

         procedure LogToUI(const aMsg: String);
      public
         constructor Create;
         destructor Destroy; override;

         procedure OnClientMessage(aClient: TuTCPRemoteClient; const aMsg: String);
         procedure OnClientConnected(aClient: TuTCPRemoteClient);
         procedure OnClientDisconnect(aClient: TuTCPRemoteClient);

         procedure Start(aPort: Integer);
         procedure Stop;
         procedure Broadcast(aP: TuPacket);

         property Clients        : TObjectList<TuTCPRemoteClient>   read FClients;
         property Joiners        : TStringList                      read FJoiners      write FJoiners;
         property OnMessage      : TOnDataReceived                  read FOnMsg        write FOnMsg;
         property OnConnected    : TClientConnectEvent              read FOnConnect    write FOnConnect;
         property OnDisconnected : TClientConnectEvent              read FOnDisconnect write FOnDisconnect;
         property OnLog          : TUIEvent2<String, TuMessageType> read FOnLog        write FOnLog;

   end;
implementation

{ TuTCPServer }

///////////////////////////////////////////////////////////////////////////////
//// Construction/Initalization
///////////////////////////////////////////////////////////////////////////////

constructor TuTCPServer.Create;
begin
   FClients := TObjectList<TuTCPRemoteClient>.Create;
   FJoiners := TStringList.Create;
   FActive  := False;
end;

procedure TuTCPServer.Start(aPort: Integer);
begin
   FListener                := TuSocket.Create(npTCP, aPort);
   FListener.OnDataReceived := OnMessage;
   FJoinThread              := TuReadThread.Create(FListener, OnMessage, True);

   if Assigned(FOnConnect) then
      FJoinThread.OnConnect := FOnConnect;

   FListener.Start;
   FJoinThread.Start;

   LogToUI('TCP Server Listening on ' + IntToStr(aPort));
   FActive := True;
end;

///////////////////////////////////////////////////////////////////////////////
//// Other
///////////////////////////////////////////////////////////////////////////////

procedure TuTCPServer.LogToUI(const aMsg: String);
begin
   OnLog(aMsg, mtSystem);
end;

procedure TuTCPServer.OnClientConnected(aClient: TuTCPRemoteClient);
begin
   FClients.Add(aClient);
end;

procedure TuTCPServer.OnClientDisconnect(aClient: TuTCPRemoteClient);
begin
//   if Assigned(FOnDisconnect) then
//      FOnDisconnect(aClient);

   TMonitor.Enter(FClients);
   try
      FClients.Remove(aClient);
   finally
      TMonitor.Exit(FClients);
   end;
end;

procedure TuTCPServer.OnClientMessage(aClient: TuTCPRemoteClient; const aMsg: String);
begin
   if Assigned(FOnMsg) then
//    FOnMsg(aClient, aMsg);
end;

procedure TuTCPServer.Broadcast(aP: TuPacket);
   var
      aClient : TuTCPRemoteClient;
begin
   TMonitor.Enter(FClients);
   try
      for aClient in FClients do begin
         if aClient.Socket.IsConnected then
            aClient.Send(aP);
      end;
   finally
      TMonitor.Exit(FClients);
   end;
end;


///////////////////////////////////////////////////////////////////////////////
//// Deconstruction
///////////////////////////////////////////////////////////////////////////////

//should be disconnect call i think no stop should logically make sense
procedure TuTCPServer.Stop;
begin
   FActive := False;
   if Assigned(FListener) then FListener.Close;
end;

destructor TuTCPServer.Destroy;
begin
   Stop;
   FClients.Free;
   FJoiners.Free;
   FListener.Free;
end;

end.
