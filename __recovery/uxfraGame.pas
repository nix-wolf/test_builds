unit uxfraGame;

interface

uses
   uNetworkTypes,
   FMX.Forms;

type
   TuxfraGame = class(TFrame)
      private
         FIsMultiplayer: Boolean;

      public
         procedure HandleGamePacket(const aP: TuPacket); virtual; abstract;
         property IsMultiplayer: Boolean read FIsMultiplayer write FIsMultiplayer;
   end;

implementation

{ TuxfraGame }

end.
