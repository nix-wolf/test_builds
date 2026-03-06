unit uxfraSessionItem;

interface

uses
   uNetworkTypes,
   System.SysUtils,
   System.Types,
   System.UITypes,
   System.Classes,
   System.Variants,
   FMX.Types,
   FMX.Graphics,
   FMX.Controls,
   FMX.Forms,
   FMX.Dialogs,
   FMX.StdCtrls,
   FMX.Controls.Presentation,
   FMX.Objects;

type
   TTuxfraSessionItem = class(TFrame)
         recBackground: TRectangle;
         lblGameName: TLabel;
         lblGameType: TLabel;
         lblPlayers: TLabel;
      private
         FGameSession: TuGameSession;

      public
         property GameSession: TuGameSession read FGameSession;
         procedure Update(aGameSession: TuGameSession);
  end;

implementation

{$R *.fmx}

{ TTuxfraSessionItem }

procedure TTuxfraSessionItem.Update(aGameSession: TuGameSession);
begin
   //i suppose this could acctually let people update the game type
   FGameSession := aGameSession;

   recBackground.HitTest := False;
   lblGameName.HitTest   := False;
   lblGameType.HitTest   := False;
   lblPlayers.HitTest    := False;

   lblGameName.Text := FGameSession.FHostName;
   lblGameType.Text := FGameSession.FGameType;
   lblPlayers.Text  := Format('%d/%d', [FGameSession.FPlayerCount, FGameSession.FMaxPlayers]);
end;

end.
