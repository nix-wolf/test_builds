unit uNetworkTypes;

interface

uses
   FMX.Forms,
   FMX.ListBox,
   System.UITypes,
   System.Rtti,
   Winapi.Winsock2,
   System.SysUtils;

type
   TuNetworkRole = (nrNone, nrClient, nrServer, nrHub);
   TuMessageType = (mtSystem, mtError, mtIn, mtLocal);
   TuPacketFlag  = (pfCHAT, pfVEWLF, pfSES, pfJOIN, pfUPD, pfHTB, pfCLS, pfKIL, pfSHFT);
   TuNetProtocol = (npUDP, npTCP);
   TuGameType    = (gtNone, gtPong);

   TFrameClass = class of TFrame;

   TuLogEventData = record
      FMsg      : String;
      FType	: TuMessageType;
      FColor    : TAlphaColor;
      FTimeStamp : TDateTIme;

      class function Create(aMsg: String; aType: TuMessageType): TuLogEventData ; static;
      class function ColorFromType(aType: TuMessageType):        TAlphaColor    ; static;
   end;

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


   TuPacketRoutine      = reference to procedure(const P: TuPacket);
   TLogEvent            = procedure(aMsg: String; aType: TuMessageType);

   TuPacketHandler      = procedure(const P: TuPacket) of Object;
   TClientConnectEvent  = procedure(aSocket: TSocket; aAddr: SockAddr_In) of Object;
   TOnDataReceived      = procedure(const aIP, aData: String; aPort: U_SHORT) of Object;
   TSessionCreatedEvent = procedure(const ASessionName: string) of object;

   TUIEvent<T>          = procedure(aT: T) of Object;
   TUIEvent2<T, T2>     = procedure(aT: T; aT2: T2) of Object;

   TuMultiRoleHandler = record
      Roles: array[TuNetworkRole] of TuPacketRoutine;

      procedure AddToRole(aRole: TuNetworkRole; aRoutine: TuPacketRoutine);
      procedure Execute(const P: TuPacket; aCurrentRole: TuNetworkRole);
   end;

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

{ TuLogEventData }

class function TuLogEventData.Create(aMsg: String; aType: TuMessageType): TuLogEventData;
begin
   Result.FMsg       := aMsg;
   Result.FType      := aType;
   Result.FColor     := TuLogEventData.ColorFromType(aType);
   Result.FTimeStamp := Now;
end;

class function TuLogEventData.ColorFromType(aType: TuMessageType): TAlphaColor;
begin
   case aType of
      mtSystem : Result := TAlphaColorRec.Green ;
      mtIn     : Result := TAlphaColorRec.Blue  ;
      mtLocal  : Result := TAlphaColorRec.Black ;
      mtError  : Result := TAlphaColorRec.Red   ;
   end;
end;

end.
