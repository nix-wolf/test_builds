unit uxfrmLoader;

interface

uses
   System.SysUtils,
   System.Types,
   System.UITypes,
   System.Classes,
   System.Variants,
   System.Generics.Collections,
   uNetworkTypes,
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
   TxfrmLoader = class
      sldLayout     : TScaledLayout;
      private
         FContainer : TControl;
         FFrames    : TObjectList<TFrame>;
      public
         constructor Create(aContainer: TControl);
         destructor Destroy; override;

         function LoadFrame(aFrame: TFrame): TFrame; overload;
         function LoadFrame(aFC: TFrameClass; aActive: Boolean = True; aFrame: TFrame = nil): TFrame; overload;
         procedure PopFrame(aFrame: TFrame = nil);

         property Container: TControl read FContainer;
   end;

var
   xfrmLoader: TxfrmLoader;

implementation

constructor TxfrmLoader.Create(aContainer: TControl);
begin
   inherited Create;
   FContainer := aContainer;
   FFrames := TObjectList<TFrame>.Create(True);
end;

function TxfrmLoader.LoadFrame(aFrame: TFrame): TFrame;
begin
   Result := aFrame;

   Result.Width       := FContainer.Width;
   Result.Height      := FContainer.Height;

   Result.Align       := TAlignLayout.Contents;
   Result.Visible     := True;

   Result.CanFocus    := True;
   Result.SetFocus;

   FFrames.Add(Result);
end;

function TxfrmLoader.LoadFrame(aFC: TFrameClass; aActive: Boolean = True; aFrame: TFrame = nil): TFrame;
begin
   if (FContainer.Root <> nil) then
      FContainer.Root.Focused := nil;

   Result             := aFC.Create(FContainer);
   Result.Parent      := FContainer;

   Result.Width       := FContainer.Width;
   Result.Height      := FContainer.Height;

   Result.Align       := TAlignLayout.Contents;
   Result.Visible     := aActive;
//   Result.ResetFocus;
   Result.CanFocus    := True;
//   Result.AutoCapture := True;

   if Assigned(FFrames) then begin
      for var i := 0 to FFrames.Count - 1 do begin
         if Assigned(aFrame) and (FFrames[i] = aFrame) then begin
            FFrames[i].Opacity := 0.5;
            Result.Align       := TAlignLayout.Center;
            Result.BringToFront;
            Break;
         end;

         FFrames[i].Visible := False;
      end;

      FFrames.Add(Result);
   end;

   Result.SetFocus;
end;

procedure TxfrmLoader.PopFrame(aFrame: TFrame);
   var
      aTarget: TFrame;
begin
   if FFrames.Count = 1 then Exit;

   aTarget := aFrame;
   if aTarget = nil then aTarget := FFrames.Last;

   if (aTarget.Root <> nil) and (aTarget.Root.Focused <> nil) then
      aTarget.Root.Focused := nil;

//   aTarget.AnimateFloat('Opacity', 0, 0.3);
   aTarget.Visible := False;
   aTarget.Enabled := False;
   aTarget.ResetFocus;
   FFrames.Remove(aTarget);

   if FFrames.Count > 0 then begin
      FFrames.Last.Visible     := True;
//      FFrames.Last.ResetFocus;
      FFrames.Last.CanFocus    := True;
      FFrames.Last.Opacity     := 1.0;
      FFrames.Last.BringToFront;
      FFrames.Last.SetFocus;
      FFrames.Last.HitTest := False;
   end; {IF}

end;

//Will need to disable the back button in game but should exist every where
//else. Will also need ot handle inactivating all the network components
//when we close the multiplayer menu.

destructor TxfrmLoader.Destroy;
begin
   FFrames.Free;
   inherited Destroy;
end;


function TxfrmLoader.LoadFrame(aFrame: TFrame): TFrame;
begin

end;

end.
