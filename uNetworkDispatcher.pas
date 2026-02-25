unit uNetworkDispatcher;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  uNetworkTypes;

type
   TuNetworkDispatcher = class
      private
         FHandlers: TDictionary<TuDispatchKey, TuPacketHandler>;
      public
         constructor Create;
         destructor  Destroy; override;

         procedure SetupHandler(aFlag     : TuPacketFlag;
                                aProtocol : TuNetProtocol;
                                aHandler  : TuPacketHandler);

         procedure SetupUHandler(aFlag: TuPacketFlag; aHandler: TuPacketHandler);
         procedure HandlePacket(const aPacket: TuPacket; aProtocol: TuNetProtocol);

         //why is this blue?
         procedure Register(aFlag     : TuPacketFlag;
                            aProto    : TArray<TuNetProtocol>;
                            aRoles    : TArray<TuNetworkRole>;
                            aRoutines : TArray<TuPacketRoutine>);
   end;

implementation

uses
   uNetworkHandlers;
{ TuNetworkDispatcher }

///////////////////////////////////////////////////////////////////////////////
//// Construction/Initalization
///////////////////////////////////////////////////////////////////////////////

constructor TuNetworkDispatcher.Create;
begin
   FHandlers := TDictionary<TuDispatchKey, TuPacketHandler>.Create;
end;

///////////////////////////////////////////////////////////////////////////////
//// Other
///////////////////////////////////////////////////////////////////////////////

procedure TuNetworkDispatcher.HandlePacket(const aPacket   : TuPacket;
                                                 aProtocol : TuNetProtocol);
var
   aKey     : TuDispatchKey;
   aHandler : TuPacketHandler;
begin
  //get flag
  //get handler
  //call handler with arguments properly

end;

procedure TuNetworkDispatcher.Register(
   aFlag     : TuPacketFlag;
   aProto    : TArray<TuNetProtocol>;
   aRoles    : TArray<TuNetworkRole>;
   aRoutines : TArray<TuPacketRoutine>);
var
   aHandler  : TuMultiRoleHandler;
   i         : Integer;
begin
   // Initialize the handler
   for i := 0 to High(aRoles) do
      aHandler.AddRole(aRoles[i], aRoutines[i]);

//   FHandlers.AddOrSetValue(TuDispatchKey.Create(aFlag, aProto), Handler);
end;

procedure TuNetworkDispatcher.SetupHandler(
   aFlag     : TuPacketFlag;
   aProtocol : TuNetProtocol;
   aHandler  : TuPacketHandler);
begin
   FHandlers.AddOrSetValue(TuDispatchKey.Create(aFlag, aProtocol), aHandler);
end;

procedure TuNetworkDispatcher.SetupUHandler(
   aFlag    : TuPacketFlag;
   aHandler : TuPacketHandler);
begin
   SetupHandler(aFlag, npUDP, aHandler);
   SetupHandler(aFlag, npTCP, aHandler);
end;

///////////////////////////////////////////////////////////////////////////////
//// Deconstruction
///////////////////////////////////////////////////////////////////////////////

destructor TuNetworkDispatcher.Destroy;
begin
  FreeAndNil(FHandlers);
  inherited;
end;

end.
