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

   TxfrmLoader = class
      sldLayout     : TScaledLayout;
      private
         FContainer : TControl;
         FFrames    : TObjectList<TFrame>;
      public
         constructor Create(aContainer: TControl);
         destructor Destroy; override;

         function LoadFrame(aFC: TFrameClass; aActive: Boolean = True; aFrame: TFrame = nil): TFrame;
         procedure PopFrame(aFrame: TFrame = nil);
   end;

var
   xfrmLoader: TxfrmLoader;

implementation

{$R *.fmx}

constructor TxfrmLoader.Create(aContainer: TControl);
begin
   inherited Create;
   FContainer := aContainer;

   FFrames := TObjectList<TFrame>.Create(True);
end;

function TxfrmLoader.LoadFrame(aFC: TFrameClass; aActive: Boolean = True; aFrame: TFrame = nil): TFrame;
begin
   Result         := aFC.Create(FContainer);
   Result.Parent  := FContainer;
   Result.Align   := TAlignLayout.Center;
   Result.Visible := aActive;

   if Assigned(FFrames) then begin
      for var i := 0 to FFrames.Count - 1 do begin
         if Assigned(aFrame) and (FFrames[i] = aFrame) then begin
            FFrames[i].Opacity := 0.5;
            break;
         end;

         FFrames[i].Visible := False;
      end;

      FFrames.Add(Result);
   end;
end;

procedure TxfrmLoader.PopFrame(aFrame: TFrame);
   var
      aTarget: TFrame;
begin
   if FFrames.Count = 0 then Exit;

   aTarget := aFrame;
   if aTarget = nil then aTarget := FFrames.Last;

   aTarget.AnimateFloat('Opacity', 0, 0.3);

   FFrames.Remove(aTarget);

   if FFrames.Count > 0 then
   begin
      FFrames.Last.Visible := True;
      FFrames.Last.Opacity := 1.0;
      FFrames.Last.BringToFront;
   end;
end;

//Will need to disable the back button in game but should exist every where
//else. Will also need ot handle inactivating all the network components
//when we close the multiplayer menu.

destructor TxfrmLoader.Destroy;
begin
   FFrames.Free;
   inherited Destroy;
end;


end.
