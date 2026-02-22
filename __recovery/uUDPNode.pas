unit uUDPNode;

interface

uses
  System.Net.Socket,
  System.SysUtils,
  System.Classes,
  System.Threading,
  uReadThread;

type
  TOnUDPData = procedure(const aMsg: String) of Object;

  TuUDPNode = class
    private
      FSocket: TSocket;
      FReadThread: TuReadThread;
      FActive: Boolean;
      FOnData: TOnUDPData;
    public
      constructor Create;
      procedure Listen(const aPort: Integer);
      procedure Broadcast(const aMsg: String; const aPort: Integer);
      procedure Send(const aMsg, aIP: String; const aPort: Integer);

      procedure Stop;
      procedure Line(const aMsg: String);
      procedure Disconnect;
      destructor Destroy; override;

      property OnDataRecieved: TOnUDPData read FOnData write FOnData;

  end;

implementation

{ TuUDPNode }

///////////////////////////////////////////////////////////////////////////////
//// Construction/Initalization
///////////////////////////////////////////////////////////////////////////////

constructor TuUDPNode.Create;
begin
  inherited;
  FActive := False;
end;

procedure TuUDPNode.Listen(const aPort: Integer);
begin
  if FActive then Exit;
  FSocket := TSocket.Create(TSocketType.UDP);
  //binding to everything for the port being used?? maybe for now
  FSocket.Bind(TNetEndpoint.Create(TIPAddress.Create('0.0.0.0'), aPort));
  FActive := True;

  FReadThread := TuReadThread.Create(FSocket, OnDataRecieved, Disconnect);
  FReadThread.Start;
end;

///////////////////////////////////////////////////////////////////////////////
//// Other
///////////////////////////////////////////////////////////////////////////////

procedure TuUDPNode.Broadcast(const aMsg: String; const aPort: Integer);
begin
  Send(aMsg, '255.255.255.255', aPort);
end;

procedure TuUDPNode.Send(const aMsg, aIP: String; const aPort: Integer);
var
  aBytes: TBytes;
  aSock: TSocket;
  aEP: TNetEndpoint;
begin
  aBytes := TEncoding.UTF8.GetBytes(aMsg);
  aSock := TSocket.Create(TSocketType.UDP);
  try
    aEP := TNetEndpoint.Create(TIPAddress.Create(aIP), aPort);
    aSock.SendTo(aBytes, Length(aBytes), aEp);
  finally
    aSock.Free;
  end;
end;

procedure TuUDPNode.Line(const aMsg: String);
begin
 //todo
end;

///////////////////////////////////////////////////////////////////////////////
//// Deconstruction
///////////////////////////////////////////////////////////////////////////////

procedure TuUDPNode.Stop;
begin
  FActive := False;
  if Assigned(FSocket) then FSocket.Close;
end;

procedure TuUDPNode.Disconnect;
begin
  if Assigned(FSocket) then FSocket.Close;

end;

destructor TuUDPNode.Destroy;
begin
  Stop;
  inherited;
end;


end.
