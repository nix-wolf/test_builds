unit uSocket;

interface

uses
   uNetworkTypes,
   System.Classes,
   System.Threading,
   System.SysUtils,
   Winapi.Winsock2;

type
   TuSocket = class(TObject)
      private
         FSocket         : TSocket;
         FReadThread     : TThread;
         FAddress        : SockAddr_In;
         FProtocol       : TuNetProtocol;

         FOnDataReceived : TOnDataReceived;
         FOnConnect      : TClientConnectEvent;

         FIsConnected    : Boolean;
      public
         constructor Create(aProtocol: TuNetProtocol; aPort: Integer); overload;
         constructor Create(aSocket: TSocket;
                            aIP: String;
                            aPort: Integer;
                            aOnData: TOnDataReceived); overload;

         procedure Start(aIsAccepting: Boolean = False);
         procedure Send(const aMsg, aIP: String; const aPort: Integer);
         procedure Broadcast(const aMsg: String; const aPort: Integer);

         destructor Destroy; override;
         procedure Disconnect;
         procedure Close;

         function Connect(const aIP: String; const aPort: Integer): Boolean;
         class function IPToAddr(const aIP: String; const aPort: Integer): SockAddr_In;
         class function IpFromASocket(aSocket: TSocket): String;
         class function PortFromASocket(aSocket: TSocket): U_Short;

         property IsConnected    : Boolean             read FIsConnected;
         property Address        : SockAddr_In         read FAddress;
         property Port           : U_Short             read FAddress.Sin_Port;
         property Get            : TSocket             read FSocket;
         property Protocol       : TuNetProtocol       read FProtocol;
         property OnDataReceived : TOnDataReceived     read FOnDataReceived write FOnDataReceived;
         property OnConnect      : TClientConnectEvent read FOnConnect write FOnConnect;
         //ondisconnect
   end;


implementation

{ TuSocket }

uses uReadThread,
     uTCPRemoteClient;

///////////////////////////////////////////////////////////////////////////////
//// Construction/Initalization
///////////////////////////////////////////////////////////////////////////////

constructor TuSocket.Create(aProtocol: TuNetProtocol; aPort: Integer);
   var
      aV : Integer;
      aA : SockAddr_In;
begin
   aV := 1;
   case aProtocol of
      npTCP : begin
         FSocket := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
         if FSocket = INVALID_SOCKET then
            raise Exception.Create(
               'Winsock socket creation failed: ' + IntToStr(WSAGetLastError));

         setsockopt(FSocket, SOL_SOCKET, SO_REUSEADDR, @aV, SizeOf(aV));
      end; {npTCP}
      npUDP : begin
         FSocket := socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

         setsockopt(FSocket, SOL_SOCKET, SO_REUSEADDR, @aV, SizeOf(aV));
         setsockopt(FSocket, SOL_SOCKET, SO_BROADCAST, @aV, SizeOf(aV));
      end; {npUDP}
   end; {CASE}

   aA.Sin_Family      := AF_INET;
   aA.Sin_Port        := htons(aPort);
   aA.Sin_Addr.S_Addr := INADDR_ANY;
   FAddress           := aA;
   FProtocol          := aProtocol;

   if aProtocol = npUDP then
      FisConnected := True;
end;

constructor TuSocket.Create(aSocket: TSocket;
                            aIP: String;
                            aPort: Integer;
                            aOnData: TOnDataReceived);
begin
   FAddress        := IPToAddr(aIP, aPort);
   FSocket         := aSocket;
   FProtocol       := npTCP;
   FOnDataReceived := aOnData;
   FIsConnected    := True;

   FReadThread     := TuReadThread.Create(Self, OnDataReceived);
   FReadThread.Start;
end;


///////////////////////////////////////////////////////////////////////////////
//// Other
///////////////////////////////////////////////////////////////////////////////

procedure TuSocket.Start(aIsAccepting: Boolean = False);
begin

   if Bind(FSocket, sockaddr(FAddress), SizeOf(sockaddr_in)) <> 0 then
      raise Exception.Create('Bind Failed: ' + IntToStr(WSAGetLastError));

   if (FProtocol = npTCP ) and (Listen(FSocket, SOMAXCONN) <> 0) then
      raise Exception.Create('Listen Failed: ' + IntToStr(WSAGetLastError));


   if aIsAccepting then begin
      FReadThread := TuReadThread.Create(Self, OnDataReceived, True);
      FReadThread.Start;
   end {IF}
   else begin
      FReadThread := TuReadThread.Create(Self, OnDataReceived);
      FReadThread.Start;
   end; {ELSE}
end;

function TuSocket.Connect(const aIP: String; const aPort: Integer): Boolean;
   var
      aAddr: SockAddr_In;
begin
   Result := False;
   aAddr  := IPToAddr(aIP, aPort);

   if WinApi.Winsock2.Connect(FSocket, SockAddr(aAddr), SizeOf(aAddr)) = 0 then begin
      Result := True;
      FIsConnected := True;

      if Assigned(FReadThread) then begin
         FReadThread.Start;
      end {IF}
      else begin
         FReadThread := TuReadThread.Create(Self, OnDataReceived);
         FReadThread.Start;
      end; {ELSE}
   end {IF}
   else begin
      //error need output
   end;{ELSE}

end;

procedure TuSocket.Send(const aMsg, aIP: String; const aPort: Integer);
   var
      aBytes    : TBytes;
      aAddr     : sockaddr_in;
      BytesSent : Integer;
begin
   if aMsg.Trim = '' then Exit;

   BytesSent := 0;
   aBytes    := TEncoding.UTF8.GetBytes(aMsg + #10);

   try
      if FProtocol = npTCP then begin
         BytesSent := WinApi.Winsock2.Send(
            FSocket,
            aBytes[0],
            Length(aBytes),
            0
         );
      end {IF}
      else begin
         aAddr := IPToAddr(aIP, aPort);

         BytesSent := WinApi.Winsock2.SendTo(
            FSocket,
            aBytes[0],
            Length(aBytes),
            0,
            PSockAddr(@aAddr),
            SizeOf(sockaddr_in)
         );
      end; {ELSE}
   except
      on E: Exception do begin
         WriteLn('UDP Send Error: ' + E.Message);
      end; {ON}
   end; {EXCEPT}

   if BytesSent = SOCKET_ERROR then begin
   // Doesnt work because there is no console attached I/O Error 105
//         WriteLn('Socket Send Error: ', WSAGetLastError());
   end; {IF}
end;

procedure TuSocket.Broadcast(const aMsg: String; const aPort: Integer);
begin
   Send(aMsg, '255.255.255.255', aPort);
end;

class function TuSocket.IpFromASocket(aSocket: TSocket): String;
   var
      aAddr    : SockAddr_In;
      aAddrLen : Integer;
begin
   Result   := '0.0.0.0';
   aAddrLen := SizeOf(aAddr);
   FillChar(aAddr, aAddrLen, 0);

   if GetPeerName(aSocket, SockAddr(aAddr), aAddrLen) = 0 then begin
      Result := String(INet_NToA(aAddr.Sin_Addr));
   end; {IF}
end;



class function TuSocket.IPToAddr(const aIP: String; const aPort: Integer): SockAddr_In;
begin
   FillChar(Result, SizeOf(Result), 0);
   Result.Sin_Family      := AF_INET;
   Result.Sin_Port        := htons(aPort);
   Result.Sin_Addr.S_addr := inet_addr(PAnsiChar(AnsiString(aIP)));
end;

class function TuSocket.PortFromASocket(aSocket: TSocket): U_Short;
   var
      aAddr    : SockAddr_In;
      aAddrLen : Integer;
begin
   Result := 0;
   aAddrLen := SizeOf(aAddr);
   FillChar(aAddr, aAddrLen, 0);

   if GetPeerName(aSocket, SockAddr(aAddr), aAddrLen) = 0 then begin
      Result := Ntohs(aAddr.Sin_Port);
   end; {IF}
end;

///////////////////////////////////////////////////////////////////////////////
//// Deconstruction
///////////////////////////////////////////////////////////////////////////////

procedure TuSocket.Close;
begin
   if Assigned(FReadThread) then begin
      FReadThread.Terminate;
      FReadThread.WaitFor;
      FreeAndNil(FReadThread);
   end;


   if FSocket <> INVALID_SOCKET then begin
      ShutDown(FSocket, SD_BOTH);
      CloseSocket(FSocket);
      FSocket := INVALID_SOCKET;
   end;
end;

procedure TuSocket.Disconnect;
begin
      //called on a disconnect, ethier kill, or other
end;

destructor TuSocket.Destroy;
begin
  Close;
  inherited;
end;

end.
