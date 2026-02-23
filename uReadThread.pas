unit uReadThread;

interface

uses
  Winapi.Winsock2,
  System.Net.Socket,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Threading;

type
  TOnLine = procedure(const aIP, aLine: String) of Object;
  TOnDisconnect = procedure of Object;

  TuReadThread = class(TThread)
    private
      FSocket: TSocket;
      FOnLine: TOnLine;
      FOnDisconnect: TOnDisconnect;
      FBufferSize: Integer;
    protected
      procedure Execute; override;
    public
      constructor Create(aSocket: TSocket;
        aOnLine: TOnLine; aOnDisconnect: TOnDisconnect);
      property BufferSize: Integer read FBufferSize write FBufferSize;
  end;

implementation

constructor TuReadThread.Create(aSocket: TSocket;
        aOnLine: TOnLine; aOnDisconnect: TOnDisconnect);
begin
  inherited Create(True);
  FSocket := aSocket;
  FOnLine := aOnLine;
  FOnDisconnect := aOnDisconnect;
  FBufferSize := 4096;
  FreeOnTerminate := True;
end;

procedure TuReadThread.Execute;
var
  aBuffer: TBytes;
  aLen: Integer;
  RemoteAddr: sockaddr_in;
  AddrLen: Integer;
  aIP, aData: string;
begin
  SetLength(aBuffer, FBufferSize);

  while not Terminated do begin
    AddrLen := SizeOf(RemoteAddr);
    FillChar(RemoteAddr, AddrLen, 0);

    aLen := Winapi.Winsock2.recvfrom(
      FSocket.Handle,
      aBuffer[0],
      Length(aBuffer),
      0,
      sockaddr(RemoteAddr),
      AddrLen
    );

    if aLen > 0 then begin
      aIP := string(inet_ntoa(RemoteAddr.sin_addr));
      aData := TEncoding.UTF8.GetString(aBuffer, 0, aLen);

      if Assigned(FOnLine) then
        TThread.Queue(nil, procedure begin FOnLine(aIP, aData.Trim); end);
    end {IF}
    else if aLen = SOCKET_ERROR then begin
      if not Terminated then Break;
    end;{ELSE IF}
  end; {WHILE}
end;

end.
