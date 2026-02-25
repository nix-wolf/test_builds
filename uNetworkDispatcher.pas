unit uNetworkDispatcher;

interface

uses
   System.Generics.Collections,
   System.SysUtils,
   System.Rtti,
   uNetworkTypes;

type
   TuNetworkDispatcher = class
      private
         FHandlers: TDictionary<TuDispatchKey, TuMultiRoleHandler>;
      public
         constructor Create;
         destructor  Destroy; override;

         procedure HandlePacket(const aPacket  : TuPacket;
                                aProtocol      : TuNetProtocol;
                                aCurrentRole   : TuNetworkRole);
         procedure RegisterHandlers(aFlag      : TuPacketFlag;
                                    aProtocols : TArray<TuNetProtocol>;
                                    aRoles     : TArray<TuNetworkRole>;
                                    aRoutines  : TArray<TuPacketRoutine>);
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
   FHandlers := TDictionary<TuDispatchKey, TuMultiRoleHandler>.Create;
   TuNetworkHandler.Setup(Self);
end;

///////////////////////////////////////////////////////////////////////////////
//// Other
///////////////////////////////////////////////////////////////////////////////

procedure TuNetworkDispatcher.HandlePacket(const aPacket      : TuPacket;
                                                 aProtocol    : TuNetProtocol;
                                                 aCurrentRole : TuNetworkRole);
var
   aFlag    : TuPacketFlag;
   aKey     : TuDispatchKey;
   aHandler : TuMultiRoleHandler;
   aFlagStr : String;
begin
   try
      aFlagStr := 'pf' + aPacket.FCommand;
      aFlag := TRttiEnumerationType.GetValue<TuPacketFlag>(aFlagStr);
      aKey  := TuDispatchKey.Create(aFlag, aProtocol);

      if FHandlers.TryGetValue(aKey, aHandler) then
         aHandler.Execute(aPacket, aCurrentRole);
   except
      on E: Exception do
        //probably want to log this, but need a way to push it back to the ui?
   end;
end;

procedure TuNetworkDispatcher.RegisterHandlers(aFlag      : TuPacketFlag;
                                               aProtocols : TArray<TuNetProtocol>;
                                               aRoles     : TArray<TuNetworkRole>;
                                               aRoutines  : TArray<TuPacketRoutine>);
var
   aHandler  : TuMultiRoleHandler;
   aProtocol : TuNetProtocol;
   i         : Integer;
begin
   if Length(aRoles) <> Length(aRoutines) then
      raise Exception.CreateFmt(
         'Engine Wiring Error: Flag %s has %d roles but %d routines.',
         [TRttiEnumerationType.GetName<TuPacketFlag>(aFlag),
         Length(aRoles), Length(aRoutines)]);

   aHandler := Default(TuMultiRoleHandler);

   for i := 0 to High(aRoles) do
      aHandler.AddToRole(aRoles[i], aRoutines[i]);

   for aProtocol in aProtocols do
      FHandlers.AddOrSetValue(TuDispatchKey.Create(aFlag, aProtocol), aHandler);
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
