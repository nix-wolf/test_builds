unit uReadThread;

interface

uses
   uNetworkTypes,
   uTCPRemoteClient,
   Winapi.Winsock2,
   System.SysUtils,
   System.Classes,
   System.Generics.Collections,
   System.Threading;

type
   TuReadThread = class(TThread)
      private
         FSocket         : TObject;
         FBufferSize     : Integer;
         FIsAccepting    : Boolean;

         FOnDataReceived : TOnDataReceived;
         FOnConnect      : TClientEvent;

         procedure ListenExecute;
         procedure AcceptExecute;
      protected
         procedure Execute; override;
      public
         constructor Create(
            aSocket      : TObject;
            aOnData      : TOnDataReceived;
            aIsAccepting : Boolean = False
         );

         property BufferSize: Integer read FBufferSize write FBufferSize;
  end;

implementation

uses uSocket;

constructor TuReadThread.Create(aSocket      : TObject;
                                aOnData      : TOnDataReceived;
                                aIsAccepting : Boolean = False);
begin
   inherited Create(True);
   FSocket         := aSocket;
   FOnDataReceived := aOnData;
   FBufferSize     := 4096;
   FreeOnTerminate := True;
   FIsAccepting    := aIsAccepting;
end;

procedure TuReadThread.AcceptExecute;
var
   ClientSocket: TSocket;
   RemoteAddr: sockaddr_in;
   AddrLen: Integer;
begin
   while not Terminated do
   begin
      AddrLen := SizeOf(RemoteAddr);
      ClientSocket := accept(TuSocket(FSocket).Get, @RemoteAddr, @AddrLen);

      if (ClientSocket <> INVALID_SOCKET) and (not Terminated) then
      begin
         TThread.Queue(nil, procedure begin
//            FOnConnect(ClientSocket, inet_ntoa(RemoteAddr.sin_addr));
         end);
      end;
  end;
end;

procedure TuReadThread.ListenExecute;
var
   aBuffer    : TBytes;
   aLen       : Integer;
   RemoteAddr : sockaddr_in;
   AddrLen    : Integer;
   aIP, aData : string;
begin
   SetLength(aBuffer, FBufferSize);

   while not Terminated do begin
      AddrLen := SizeOf(RemoteAddr);
      FillChar(RemoteAddr, AddrLen, 0);

      aLen := RecVFrom(
         TuSocket(FSocket).Get,
         aBuffer[0],
         Length(aBuffer),
         0,
         sockaddr(RemoteAddr),
         AddrLen
      );

      if aLen > 0 then begin
         aIP := string(inet_ntoa(RemoteAddr.sin_addr));
         aData := TEncoding.UTF8.GetString(aBuffer, 0, aLen);

         if Assigned(FOnDataReceived) then begin
            TThread.Queue(nil, procedure begin FOnDataReceived(aIP, aData.Trim); end);
         end; {IF}

      end {IF}
      else if aLen = SOCKET_ERROR then begin
         if not Terminated then Break;
      end;{ IF}
   end; {WHILE}
end;

procedure TuReadThread.Execute;
begin
   if not FIsAccepting then begin ListenExecute; end
   else AcceptExecute;
end;

end.
