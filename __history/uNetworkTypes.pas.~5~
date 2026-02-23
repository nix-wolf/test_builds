unit uNetworkTypes;

interface

uses System.SysUtils;

type
  TuPacketFlag = (pfCHAT, pfVEWLF, pfSES, pfJOIN, pfUPD);

  TuGameSession = record
    HostIP: String;
    HostName: String;
    GameType: String;
    PlayerCount: Integer;
    MaxPlayers: Integer;
    LastSeen: TDateTime;

    function ToNetworkString: String;
    procedure FromNetworkString(AData: String);
  end;

  TuPacket = record
    FCommand: String;
    FIP: String;
    FData: String;

    function Parse: string;
    procedure FromString(const aMsg: String);
    class function Create(aPF: TuPacketFlag; const aMsg: String): TuPacket; static;
  end;
implementation

{ TuGameSession }

procedure TuGameSession.FromNetworkString(AData: String);
  var
    aNetworkObject: TArray<String>;
begin
  aNetworkObject := AData.Split([',']);
  if Length(aNetworkObject) >= 5 then begin
    HostIP := aNetworkObject[0];
    HostName := aNetworkObject[1];
    GameType := aNetworkObject[2];
    PlayerCount := StrToIntDef(aNetworkObject[3], 0);
    MaxPlayers := StrToIntDef(aNetworkObject[4], 0);
  end; {IF}
end;

function TuGameSession.ToNetworkString: String;
begin
  Result := Format('%s,%s,%s,%d,%d', [HostIP, HostName, GameType, PlayerCount, MaxPlayers]);
end;

{ TuPacket }

class function TuPacket.Create(aPF: TuPacketFlag; const aMsg: String): TuPacket;
begin

end;

procedure TuPacket.FromString(const aMsg: String);
begin

end;

function TuPacket.Parse: string;
begin

end;

end.
