unit uNetworkTypes;

interface

uses
   System.Net.Socket,
   uReadThread,
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



   TuPacketHandler = reference to procedure(const P: TuPacket);

   TOnDataReceived = procedure(const aIP, aData: String) of Object;
   TOnMessage      = procedure(const aPacket: TuPacket; aMsg: String);

   TuTCPRemoteClient = class
      private
         FOwner      : TObject;
         FSocket     : TSocket;
         FReadThread : TuReadThread;
         FIP         : String;

         FOnData     : TOnDataReceived;
         FOnMessage  : TOnMessage;

      public
         constructor Create(aOwner: TObject; aSocket: TSocket);
         destructor Destroy; override;

         procedure Send(const aMsg: String);
         procedure OnLine(const aIP, aMsg: String);
         procedure Disconnect;

         property IP             : String          read FIP;
         property Socket         : TSocket         read FSocket;
         property OnDataReceived : TOnDataReceived read FOnData    write FOnData;
         property OnMessage      : TOnMessage      read FOnMessage write FOnMessage;
   end;


   TOnTCPMessage = procedure(aClient: TuTCPRemoteClient; const aMsg: String) of Object;
   TOnUDPMessage = procedure(const aIP, aMsg: String) of Object;
   TClientEvent  = procedure(aClient: TuTCPRemoteClient) of Object;
   TUIEvent      = procedure(const aMsg: String) of Object;

implementation

{ TuGameSession }

uses uTCPServer;

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
//  Result.FCommand := TRttiEnumerationType.GetName<TuPacketFlag>(aPF);
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


{ TuTCPRemoteClient }

///////////////////////////////////////////////////////////////////////////////
//// Construction/Initalization
///////////////////////////////////////////////////////////////////////////////

constructor TuTCPRemoteClient.Create(aOwner: TObject; aSocket: TSocket);
begin
  FOwner := aOwner;
  FSocket := aSocket;

  //not sure about this
  try
    FIP := FSocket.Endpoint.Address.Address;
  except
    FIP := '0.0.0.0';
  end;

  FReadThread := TuReadThread.Create(FSocket, OnLine, Disconnect);
  FReadThread.Start;
end;

///////////////////////////////////////////////////////////////////////////////
//// Other
///////////////////////////////////////////////////////////////////////////////

procedure TuTCPRemoteClient.Send(const aMsg: String);
var
  aBytes: TBytes;
begin
  if TSocketState.Connected in FSocket.State then begin
    aBytes := TEncoding.UTF8.GetBytes(aMsg + #10);
    FSocket.Send(aBytes, 0, Length(aBytes));
  end; {IF}
end;

procedure TuTCPRemoteClient.OnLine(const aIP, aMsg: String);
begin
  if Assigned(FOwner) then
    (FOwner as TuTCPServer).OnClientMessage(Self, aMsg);
end;

///////////////////////////////////////////////////////////////////////////////
//// Deconstruction
///////////////////////////////////////////////////////////////////////////////

procedure TuTCPRemoteClient.Disconnect;
begin
  if Assigned(FOwner) then
    TuTCPServer(FOwner).OnClientDisconnect(Self);
end;

destructor TuTCPRemoteClient.Destroy;
begin
  if Assigned(FSocket) then FSocket.Close;
  inherited;
end;

end.
