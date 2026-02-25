unit uTCPServer;

interface

uses
   Winapi.Winsock2,
   System.Net.Socket,
   System.SysUtils,
   System.Classes,
   System.Generics.Collections,
   uNetworkTypes,
   uReadThread;

type
   TuTCPServer     = class;

   TuTCPServer = class(TObject)
      private
         FListener     : TSocket;
         FClients      : TObjectList<TuTCPRemoteClient>;
         FActive       : Boolean;

         FOnMsg        : TOnTCPMessage;
         FOnConnect    : TClientEvent;
         FOnDisconnect : TClientEvent;
         FOnLog        : TUIEvent;

         procedure LogToUI(const aMsg: String);
         procedure Listen;
      public
         constructor Create;
         destructor Destroy; override;

         procedure OnClientMessage(aClient: TuTCPRemoteClient; const aMsg: String);
         procedure OnClientDisconnect(aClient: TuTCPRemoteClient);

         procedure Start(aPort: Integer);
         procedure Stop;
         procedure Broadcast(const aMsg: String);

         property OnMessage      : TOnTCPMessage    read FOnMsg        write FOnMsg;
         property OnConnected    : TClientEvent     read FOnConnect    write FOnConnect;
         property OnDisconnected : TClientEvent     read FOnDisconnect write FOnDisconnect;
         property OnLog          : TUIEvent         read FOnLog        write FOnLog;

   end;
implementation

{ TuTCPServer }

///////////////////////////////////////////////////////////////////////////////
//// Construction/Initalization
///////////////////////////////////////////////////////////////////////////////

constructor TuTCPServer.Create;
begin
   FClients := TObjectList<TuTCPRemoteClient>.Create;
   FActive  := False;
end;

procedure TuTCPServer.Start(aPort: Integer);
var
  aAddr: sockaddr_in;
  aV: Integer;
  aListener: Winapi.Winsock2.TSocket;
begin

  aListener := Winapi.Winsock2.socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if aListener = INVALID_SOCKET then
    raise Exception.Create('Winsock socket creation failed: ' + IntToStr(WSAGetLastError));

   //listener will become my own socket class

  aV := 1;
  setsockopt(aListener, SOL_SOCKET, SO_REUSEADDR, @aV, SizeOf(aV));

  aAddr.sin_family := AF_INET;
  aAddr.sin_port := htons(aPort + 1);
  aAddr.sin_addr.S_addr := INADDR_ANY;

  if Winapi.Winsock2.bind(aListener, sockaddr(aAddr), SizeOf(aAddr)) <> 0 then
    raise Exception.Create('Bind Failed: ' + IntToStr(WSAGetLastError));

  if Winapi.Winsock2.listen(aListener, SOMAXCONN) <> 0 then
    raise Exception.Create('Listen Failed: ' + IntToStr(WSAGetLastError));

  LogToUI('TCP Hub (Hybrid) Listening on ' + IntToStr(aPort + 1));


  FActive := True;
//  TThread.CreateAnonymousThread(Listen).Start;
end;

///////////////////////////////////////////////////////////////////////////////
//// Other
///////////////////////////////////////////////////////////////////////////////

procedure TuTCPServer.Listen;
begin
  while FActive do begin
    var aSocket := FListener.Accept(500);

    if Assigned(aSocket) then begin
      var aClient := TuTCPRemoteClient.Create(Self, aSocket);

      TMonitor.Enter(FClients);
      try
        FClients.Add(aClient);
      finally
        TMonitor.Exit(FClients);
      end;

      if Assigned(FOnConnect) then
        TThread.Queue(nil, procedure begin FOnConnect(aClient); end);
    end; {IF}
  end; {WHILE}
end;

procedure TuTCPServer.LogToUI(const aMsg: String);
begin
  OnLog(aMsg);
end;

procedure TuTCPServer.OnClientDisconnect(aClient: TuTCPRemoteClient);
begin
  if Assigned(FOnDisconnect) then
    FOnDisconnect(aClient);

  TMonitor.Enter(FClients);
  try
    FClients.Remove(aClient);
  finally
    TMonitor.Exit(FClients);
  end;
end;

procedure TuTCPServer.OnClientMessage(aClient: TuTCPRemoteClient;
  const aMsg: String);
begin
  if Assigned(FOnMsg) then
    FOnMsg(aClient, aMsg);
end;

procedure TuTCPServer.Broadcast(const aMsg: String);
var
  aClient: TuTCPRemoteClient;
begin
  TMonitor.Enter(FClients);
  try
    for aClient in FClients do begin
      if TSocketState.Connected in aClient.Socket.State then
        aClient.Send(aMsg);
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
end;

end.
