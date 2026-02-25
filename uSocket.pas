unit uSocket;

interface

uses
   uNetworkTypes,
   uReadThread,
   System.SysUtils,
   Winapi.Winsock2;

type
   TuSocket = class
      private
         FSocket : Winapi.Winsock2.TSocket;
         FReadThread: TuReadThread;
      public
         constructor Create(aProtocol: TuNetProtocol; aPort: Integer);
         destructor Destroy; override;

         procedure Start;
   end;


implementation

{ TuSocket }

///////////////////////////////////////////////////////////////////////////////
//// Construction/Initalization
///////////////////////////////////////////////////////////////////////////////

constructor TuSocket.Create(aProtocol: TuNetProtocol; aPort: Integer);
   var
      aV : Integer;
      aA : sockaddr_in;
begin
   aV := 1;
   case aProtocol of
      npTCP : begin
         FSocket := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
         if FSocket = INVALID_SOCKET then
            raise Exception.Create('Winsock socket creation failed: ' + IntToStr(WSAGetLastError));

         setsockopt(FSocket, SOL_SOCKET, SO_REUSEADDR, @aV, SizeOf(aV));
         aPort := aPort + 1;
      end; {npTCP}
      npUDP : begin
         FSocket := socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

         setsockopt(FSocket, SOL_SOCKET, SO_REUSEADDR, @aV, SizeOf(aV));
         setsockopt(FSocket, SOL_SOCKET, SO_BROADCAST, @aV, SizeOf(aV));
      end; {npUDP}
   end; {CASE}

   aA.sin_family      := AF_INET;
   aA.sin_port        := htons(aPort);
   aA.sin_addr.S_addr := INADDR_ANY;

   if bind(FSocket, sockaddr(aA), SizeOf(aA)) <> 0 then
      raise Exception.Create('Bind Failed: ' + IntToStr(WSAGetLastError));

   if (aProtocol = npTCP ) and (listen(FSocket, SOMAXCONN) <> 0) then
      raise Exception.Create('Listen Failed: ' + IntToStr(WSAGetLastError));

//   FReadThread := TuReadThread.Create(FSocket, OnDataRecieved, Disconnect);
//   FReadThread.Start;
end;

///////////////////////////////////////////////////////////////////////////////
//// Other
///////////////////////////////////////////////////////////////////////////////

procedure TuSocket.Start;
begin

end;

///////////////////////////////////////////////////////////////////////////////
//// Deconstruction
///////////////////////////////////////////////////////////////////////////////

destructor TuSocket.Destroy;
begin

  inherited;
end;

end.
