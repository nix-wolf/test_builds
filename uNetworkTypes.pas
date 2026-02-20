unit uNetworkTypes;

interface

uses System.SysUtils;

type
  TGameSession = record
    HostIP: String;
    HostName: String;
    GameType: String;
    PlayerCount: Integer;
    MaxPlayers: Integer;
    LastSeen: TDateTime;

    function ToNetworkString: String;
    procedure FromNetworkString(AData: String);
  end;

implementation


{ TGameSession }

procedure TGameSession.FromNetworkString(AData: String);
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

function TGameSession.ToNetworkString: String;
begin
  Result := Format('%s,%s,%s,%d,%d', [HostIP, HostName, GameType, PlayerCount, MaxPlayers]);
end;

end.
