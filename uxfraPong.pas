unit uxfraPong;

interface

uses
   System.IOUtils,
   System.SysUtils,
   System.Types,
   System.UITypes,
   System.Classes,
   System.Variants,
   System.Math,
   System.DateUtils,
   FMX.Media,
   FMX.Types,
   FMX.Controls,
   FMX.Forms,
   FMX.Graphics,
   FMX.Dialogs,
   FMX.Objects;

type
   TxfrmPong = class(TFrame)
      recPlayer2      : TRectangle;
      recPlayer1      : TRectangle;
      recBorder       : TRectangle;
      txtPlayer1Text  : TText;
      txtPlayer2Text  : TText;
      cirBall         : TCircle;
      tmrTimer        : TTimer;
      txtPlayer1Score : TText;
      txtPlayer2Score : TText;
      txtMessageBox   : TText;
      recBackground   : TRectangle;

      procedure TimerStart(Sender: TObject);
      procedure FrameMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
      procedure FrameKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
      procedure FrameKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
      procedure SetupBorder;
      procedure SetupBall;
      procedure SetupPlayers;
      procedure SetupGame;
      procedure SetupTimer;
   private
      FObjColor        : TAlphaColor;
      FBallVY          : Single;
      FBallVX          : Single;
      FPlayer1ScoreInt : Single;
      FPlayer2ScoreInt : Single;
      FGameTime        : TDateTime;
      FKeyUpPressed    : Boolean;
      FKeyDownPressed  : Boolean;
      FBallBounce      : TMediaPlayer;



      procedure PlayBounce;
   const
      cPlayerWidth  = 10.0;
      cEdgeOffset   = 50.0;
      cBallSpeed    = 10.0;
      cPlayerSpeed  = 8.5;
      cPlayerHeight = 75.0;

   protected
      procedure Resize; override;
   public
      constructor Create(aOwner: TComponent); override;

   end;

var
   xfrmPong: TxfrmPong;

implementation

{$R *.fmx}

{ TxfrmPong }

constructor TxfrmPong.Create(aOwner: TComponent);
begin
   inherited Create(aOwner);

   Randomize;
   FObjColor                := TAlphaColorRec.Chartreuse;

   recBackground.Fill.Kind  := TBrushKind.Solid;
   recBackground.Fill.Color := TAlphaColorRec.Black;
   recBackground.HitTest    := false;

   FBallBounce := TMediaPlayer.Create(Self);
   var aSoundPath := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetDirectoryName(ParamStr(0)), 'bounce.mp3');
   if TFile.Exists(aSoundPath) then
      FBallBounce.FileName := aSoundPath;
end;

procedure TxfrmPong.Resize;
begin
   inherited;
   if recBackground = nil then Exit;

   SetupBorder;
   SetupBall;
   SetupPlayers;
   SetupGame;
   SetupTimer;
end;

procedure TxfrmPong.FrameKeyDown(Sender      : TObject;
                                 var Key     : Word;
                                 var KeyChar : Char;
                                 Shift       : TShiftState);
begin
   if(UpCase(KeyChar) = 'S') then FKeyDownPressed := True;
   if(UpCase(KeyChar) = 'W') then FKeyUpPressed   := True;
end;

procedure TxfrmPong.FrameKeyUp(Sender      : TObject;
                               var Key     : Word;
                               var KeyChar : Char;
                               Shift       : TShiftState);
begin
   if(UpCase(KeyChar) = 'S') then FKeyDownPressed := False;
   if(UpCase(KeyChar) = 'W') then FKeyUpPressed   := False;
end;

procedure TxfrmPong.FrameMouseDown(Sender : TObject;
                                   Button : TMouseButton;
                                   Shift  : TShiftState;
                                   X, Y   : Single);
begin
   tmrTimer.Enabled   := True;
   txtMessageBox.Text := '';
   FGameTime          := Now();
end;

procedure TxfrmPong.PlayBounce;
begin
   if (FBallBounce <> nil) and (FBallBounce.Media <> nil) then
   begin
      FBallBounce.CurrentTime := 0;
      FBallBounce.Play;
   end;
end;

procedure TxfrmPong.SetupBall;
   var
      aYDirection: Integer;
      aXDirection: Integer;
begin
   cirBall.Width       := 9;
   cirBall.Height      := 9;
   cirBall.Fill.Color  := FObjColor;
   cirBall.Stroke.Kind := TBrushKind.None;
   cirBall.Position.X  := Self.Width/2 - cirBall.Width/2;
   cirBall.Position.Y  := Self.Height/2 - cirBall.Height/2;
   cirBall.HitTest     := False;

   aYDirection := RandomRange(1, 10);
   aXDirection := RandomRange(1,10);
   FBallVX     := cBallSpeed;
   FBallVY     := cBallSpeed;

   if aXDirection > 5 then FBallVX := -FBallVX;
   if aYDirection > 5 then FBallVY := -FBallVY;
end;

procedure TxfrmPong.SetupBorder;
begin
   recBorder.HitTest          := False;
   recBorder.Height           := Self.LocalRect.Height - 40;
   recBorder.Width            := Self.LocalRect.Width - 15;
   recBorder.Fill.Kind        := TBrushKind.None;
   recBorder.Stroke.Kind      := TBrushKind.Solid;
   recBorder.Stroke.Color     := FObjColor;
   recBorder.Stroke.Thickness := 5.0;
end;

procedure TxfrmPong.SetupGame;
begin
   txtPlayer1Text.Text   := 'Player 1:';
   txtPlayer1Text.Color  := FObjColor;
   txtPlayer1Text.Position.X := Self.Width/2 - 100;
   FPlayer1ScoreInt      := 0;
   txtPlayer1Score.Text  := FloatToStr(FPlayer1ScoreInt);
   txtPlayer1Score.Position.X := Self.Width/2 - 50;
   txtPlayer1Score.Color := FObjColor;

   txtPlayer2Text.Text   := 'Player 2:';
   txtPlayer2Text.Color  := FObjColor;
   txtPlayer2Text.Position.X := Self.Width/2 + 50;
   FPlayer2ScoreInt      := 0;
   txtPlayer2Score.Position.X := Self.Width/2 + 100;
   txtPlayer2Score.Text  := FloatToStr(FPlayer2ScoreInt);
   txtPlayer2Score.Color := FObjColor;

   txtMessageBox.Text    := 'Click Mouse To Start!';
   txtMessageBox.Color   := FObjColor;


end;

procedure TxfrmPong.SetupPlayers;
begin
   var Center_Y          := Self.Height/2 - cPlayerHeight/2;

   //Default Player 1 Settings
   recPlayer1.Fill.Kind  := TBrushKind.Solid;
   recPlayer1.Fill.Color := FObjColor;
   recPlayer1.Align      := TAlignLayout.None;
   recPlayer1.Width      := cPlayerWidth;
   recPlayer1.Height     := cPlayerHeight;
   recPlayer1.Position.X := recBorder.Stroke.Thickness + cEdgeOffset;
   recPlayer1.Position.Y := Center_Y;
   recPlayer1.HitTest    := False;

   //Default Player 2 Settings
   recPlayer2.Fill.Kind  := TBrushKind.Solid;
   recPlayer2.Fill.Color := FObjColor;
   recPlayer2.Align      := TAlignLayout.None;
   recPlayer2.Width      := cPlayerWidth;
   recPlayer2.Height     := cPlayerHeight;
   recPlayer2.Position.X := Self.Width - recBorder.Stroke.Thickness - cEdgeOffset - cPlayerWidth;
   recPlayer2.Position.Y := Center_Y;
   recPlayer2.HitTest    := False;
end;

procedure TxfrmPong.SetupTimer;
begin
   tmrTimer.Interval := 16;
   tmrTimer.Enabled  := False;
end;

procedure TxfrmPong.TimerStart(Sender: TObject);
   var
      aBThickness: Single;
      aPlayer2Center: Single;
      aBallCenter: Single;
      aTopCheck: Single;
      aBottomCheck: Single;
      aRightCheck: Single;
      aLeftCheck: Single;
      aDidScore: Boolean;

begin
   aBThickness := recBorder.Stroke.Thickness;
   cirBall.Position.X := cirBall.Position.X + FBallVX;
   cirBall.Position.Y := cirBall.Position.Y + FBallVY;
   aPlayer2Center := recPlayer2.Position.Y + (recPlayer2.Height/2);
   aBallCenter := cirBall.Position.Y + (cirBall.Height/2);
   aTopCheck := recBorder.BoundsRect.CenterPoint.Y + recBorder.Height/2 - aBThickness;
   aBottomCheck :=  recBorder.BoundsRect.CenterPoint.Y - recBorder.Height/2 + aBThickness;
   aRightCheck := recBorder.BoundsRect.CenterPoint.X + recBorder.Width/2 - aBThickness;
   aLeftCheck := recBorder.BoundsRect.CenterPoint.X - recBorder.Width/2 + aBThickness;
   aDidScore := False;

   if (SecondsBetween(Now(), FGameTime) > 3) and (txtMessageBox.Text <> '') then
      txtMessageBox.Text := '';

   //Handle Input
   if FKeyUpPressed then
      recPlayer1.Position.Y := recPlayer1.Position.Y - cPlayerSpeed;

   if FKeyDownPressed then
      recPlayer1.Position.Y := recPlayer1.Position.Y + cPlayerSpeed;

   //handle npc movement
   if aBallCenter > aPlayer2Center then
      recPlayer2.Position.Y := recPlayer2.Position.Y + cPlayerSpeed + 1.0;

   if aBallCenter < aPlayer2Center then
      recPlayer2.Position.Y := recPlayer2.Position.Y - cPlayerSpeed + 1.0;

   if recPlayer2.Position.Y < aBottomCheck then
      recPlayer2.Position.Y := aBottomCheck;

   if recPlayer2.Position.Y + recPlayer2.Height > aTopCheck then
      recPlayer2.Position.Y := aTopCheck - recPlayer2.Height;

   //Handle player collisions
   if recPlayer1.Position.Y < aBottomCheck then
      recPlayer1.Position.Y := aBottomCheck;
   if recPlayer1.Position.Y + recPlayer1.Height > aTopCheck then
      recPlayer1.Position.Y := aTopCheck - recPlayer1.Height;

   //cirBall Collisions
   if cirBall.Position.Y <= aBottomCheck then begin
      cirBall.Position.Y := aBottomCheck;
      FBallVY := -FBallVY;
      PlayBounce;
   end; {IF}

   if cirBall.Position.Y + cirBall.Height >= aTopCheck then begin
      cirBall.Position.Y := aTopCheck - cirBall.Height;
      FBallVY := -FBallVY;
      PlayBounce;
   end; {IF}

   if (cirBall.Position.X <= aLeftCheck) or
      (cirBall.Position.X + cirBall.Width >= aRightCheck) then begin
         FBallVX := -FBallVX;
         PlayBounce;
   end; {IF}

   if cirBall.BoundsRect.IntersectsWith(recPlayer1.BoundsRect) then begin
      FBallVX := Abs(FBallVX);
      cirBall.Position.X := recPlayer1.Position.X + recPlayer1.Width + 1;
      PlayBounce;
   end; {IF}

   if cirBall.BoundsRect.IntersectsWith(recPlayer2.BoundsRect) then begin
      FBallVX := -Abs(FBallVX);
      cirBall.Position.X := recPlayer2.Position.X - recPlayer2.Width - 1;
      PlayBounce;
   end; {IF}

   //check scoring
   if cirBall.Position.X <= aLeftCheck then begin
      txtMessageBox.Text   := 'Player 2 Scored!';
      FPlayer2ScoreInt     := FPlayer2ScoreInt + 1;
      txtPlayer2Score.Text := FloatToStr(FPlayer2ScoreInt);
      FGameTime            := Now();
      aDidScore            := True;
      SetupBall;
   end; {IF}

   if cirBall.Position.X + cirBall.Width >= aRightCheck then begin
      txtMessageBox.Text   := 'Player 1 Scored!';
      FPlayer1ScoreInt     := FPlayer1ScoreInt + 1;
      txtPlayer1Score.Text := FloatToStr(FPlayer1ScoreInt);
      FGameTime            := Now();
      aDidScore            := True;
      SetupBall;
   end; {IF}

   if aDidScore then begin
      SetupPlayers;
      tmrTimer.Enabled := False;
   end; {IF}
//  UpdateDifficulty; Todo
end;

end.
