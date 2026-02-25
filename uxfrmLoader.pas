unit uxfrmLoader;

interface

uses
   System.SysUtils,
   System.Types,
   System.UITypes,
   System.Classes,
   System.Variants,
   System.Generics.Collections,
   uxfraPong,
   uxfraSnake,
   uxfraMainMenu,
   Vcl.Forms,
   Vcl.ExtCtrls,
   Vcl.StdCtrls,
   Vcl.Controls,
   FMX.Types,
   FMX.Graphics,
   FMX.Controls,
   FMX.Forms,
   FMX.Dialogs,
   FMX.StdCtrls,
   FMX.Controls.Presentation,
   FMX.Layouts;

type
   TFrameClass = class of TFrame;

   TxfrmLoader = class(TForm)
      sldLayout   : TScaledLayout;
      btnExit     : TButton;
      panViewPort : TPanel;

      procedure FormShow(Sender: TObject);
      procedure btnExitClick(Sender: TObject);

      private
         FFrames : TStack<TFrameClass>;
         FFrame  : TFrame;
      public
         procedure SwitchFrame(aFrameClass: TFrameClass);
         procedure PopFrame();
         procedure PushFrame(aFrameClass: TFrameClass);
         procedure UpdateBackButton;
   end;

var
   xfrmLoader: TxfrmLoader;

implementation

{$R *.fmx}

procedure TxfrmLoader.btnExitClick(Sender: TObject);
begin
   PopFrame();
end;

procedure TxfrmLoader.FormShow(Sender: TObject);
begin
   FFrames := TStack<TFrameClass>.Create;
   PushFrame(TxfraMainMenu);
end;

procedure TxfrmLoader.PopFrame;
begin
   if FFrames.Count > 1 then begin
      FFrames.Pop;
      PushFrame(FFrames.Pop);
   end; {IF}
end;

procedure TxfrmLoader.PushFrame(aFrameClass: TFrameClass);
begin
   FFrames.Push(aFrameClass);
   SwitchFrame(aFrameClass);
   UpdateBackButton;
end;

procedure TxfrmLoader.SwitchFrame(aFrameClass: TFrameClass);
begin
   if Assigned(FFrame) then
      FreeAndNil(FFrame);

   FFrame            := aFrameClass.Create(Self);
   FFrame.Parent     := Self;
   FFrame.Position.X := 0;
   FFrame.Position.Y := 0;
   FFrame.Align      := TAlignLayout.Client;
   Self.Realign;
   FFrame.CanFocus   := True;
   FFrame.SetFocus;
end;

procedure TxfrmLoader.UpdateBackButton;
begin
   btnExit.Visible := FFrames.Count > 1;
   btnExit.Parent  := Self;
   btnExit.BringToFront;
end;

end.
