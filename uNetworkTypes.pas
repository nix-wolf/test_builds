unit uNetworkTypes;

interface

uses
   System.Rtti,
   Winapi.Winsock2,
   System.SysUtils;

type
   TuNetworkRole = (nrNone, nrClient, nrServer, nrHub);
   TuPacketFlag  = (pfCHAT, pfVEWLF, pfSES, pfJOIN, pfUPD, pfHTB, pfCLS, pfKIL, pfSHFT);
   TuNetProtocol = (npUDP, npTCP);

   TuGameSession = record
      FHostIP      : String;
      FHostName    : String;
      FGameType    : String;
      FPlayerCount : Integer;
      FMaxPlayers  : Integer;
      FLastSeen    : TDateTime;

      function  ToNetworkString: String;
      procedure FromNetworkString(aData: String);
   end;

   TuPacket = record
      FCommand : String;
      FIP      : String;
      FData    : String;

      function       Parse: string;
      procedure      FromString(const aMsg: String);
      class function Create(aPF: TuPacketFlag; const aMsg: String): TuPacket; static;
   end;

   TuDispatchKey = record
      FFlag     : TuPacketFlag;
      FProtocol : TuNetProtocol;

      class function Create(aFlag: TuPacketFlag; aProtocol: TuNetProtocol): TuDispatchKey; static;
   end;

   TuPacketRoutine = reference to procedure(const P: TuPacket);

   TuMultiRoleHandler = record
      Roles: array[TuNetworkRole] of TuPacketRoutine;

      procedure AddToRole(aRole: TuNetworkRole; aRoutine: TuPacketRoutine);
      procedure Execute(const P: TuPacket; aCurrentRole: TuNetworkRole);
   end;

   TuPacketHandler     = reference to procedure(const P: TuPacket);
   TClientConnectEvent = procedure(aSocket: TSocket; aAddr: SockAddr_In) of Object;
   TOnDataReceived     = procedure(const aIP, aData: String) of Object;
   TUIEvent            = procedure(const aData: String) of Object;


implementation

{ TuGameSession }

procedure TuGameSession.FromNetworkString(aData: String);
var
   aNetworkObject: TArray<String>;
begin
   aNetworkObject := aData.Split([',']);
   if Length(aNetworkObject) >= 5 then begin
      FHostIP      := aNetworkObject[0];
      FHostName    := aNetworkObject[1];
      FGameType    := aNetworkObject[2];
      FPlayerCount := StrToIntDef(aNetworkObject[3], 0);
      FMaxPlayers  := StrToIntDef(aNetworkObject[4], 0);
   end; {IF}
   //session data isnt returned yet.
end;

function TuGameSession.ToNetworkString: String;
begin
   Result := Format('%s,%s,%s,%d,%d', [FHostIP, FHostName, FGameType , FPlayerCount, FMaxPlayers]);
end;

{ TuPacket }

class function TuPacket.Create(aPF: TuPacketFlag; const aMsg: String): TuPacket;
begin
   Result.FCommand := TRttiEnumerationType.GetName<TuPacketFlag>(aPF);
   Result.FData := aMsg;
end;

procedure TuPacket.FromString(const aMsg: String);
var
   aData: TArray<string>;
begin
   // packet format: COMMAND|DATA
   aData := aMsg.Split(['|'], 2);
   if Length(aData) > 0 then
      FCommand := aData[0];
   if Length(aData) > 1 then
      FData := aData[1];
end;

function TuPacket.Parse: string;
begin
  Result := FCommand + '|' + FData;
end;

{ TDispatchKey }

class function TuDispatchKey.Create(aFlag: TuPacketFlag;
   aProtocol: TuNetProtocol): TuDispatchKey;
begin
   Result.FFlag     := aFlag;
   Result.FProtocol := aProtocol;
end;

{ TuMultiRoleHandler }

procedure TuMultiRoleHandler.AddToRole(aRole: TuNetworkRole;
   aRoutine: TuPacketRoutine);
begin
   Roles[aRole] := aRoutine;
end;

procedure TuMultiRoleHandler.Execute(const P      : TuPacket;
                                     aCurrentRole : TuNetworkRole);
begin
   if Assigned(Roles[aCurrentRole]) then
      Roles[aCurrentRole](P);
end;

end.
