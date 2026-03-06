unit uxfraNetMenu;

interface

uses
   Winapi.Windows,
   System.SysUtils,
   System.Types,
   System.UITypes,
   System.Classes,
   System.Variants,
   uSocket,
   uxfraPong,
   uNetManager,
   uNetworkTypes,
   uxfraHostMenu,
   uxfraSessionItem,
   FMX.Types,
   FMX.Graphics,
   FMX.Controls,
   FMX.Forms,
   FMX.Dialogs,
   FMX.StdCtrls,
   FMX.Memo.Types,
   FMX.Edit,
   FMX.Controls.Presentation,
   FMX.ScrollBox,
   FMX.Memo,
   FMX.Header,
   FMX.Layouts,
   FMX.ListBox;

type
   TxfraNetMenu = class(TFrame)
      lstGames    : TListBox;
      lstMessages : TListBox;
      lLayout     : TLayout;
      btnJoinGame : TButton;
      btnHostGame : TButton;
      edtChat     : TEdit;
      lblStatus   : TLabel;

      procedure btnHostGameClick(Sender     : TObject);
      procedure btnJoinGameClick(Sender     : TObject);
      procedure edtChatKeyPress(Sender      : TObject;
                                var Key     : Word;
                                var KeyChar : WideChar;
                                Shift       : TShiftState);

      private
         FNetworkManager  : TNetManager;
         FSelectedSession : TTuxfraSessionItem;

         procedure HandleNetworkLogging(const aLogData: TuLogEventData);
         procedure HandleRoleChange(const aRole: TuNetworkRole);
         procedure HandleGameSession(const aGameSession: TuGameSession);
         procedure lstGameItemClick(const aSender: TCustomListBox; const aItem: TListBoxItem);
      public
         constructor Create(aOwner: TComponent); override;
         destructor Destroy; override;

         procedure DebounceGameJoin(aSender: TObject);
   end;

var
   xfraNetMenu: TxfraNetMenu;

implementation

{$R *.fmx}

uses
   uxfrmBase,
   uxfrmLoader;

procedure TxfraNetMenu.btnHostGameClick(Sender: TObject);
   var
      aForm: TForm;
begin
   if NetMgr.Role = nrNone then Exit;

   aForm := TForm(Self.Root.GetObject);

   TxFrmBase(aForm).Loader.LoadFrame(TxFraHostMenu, True, Self);
end;

procedure TxfraNetMenu.btnJoinGameClick(Sender: TObject);
   var
      aTimer : TTimer;
      aP     : TuPacket;
begin
   aTimer := TTimer.Create(Self);
   aTimer.Interval := 1000;
   aTimer.OnTimer := DebounceGameJoin;

   aP := TuPacket.Create(pfJOIN, FSelectedSession.GameSession.ToNetworkString);
   aP.FIP := NetMgr.IP;

   NetMgr.Send(aP);

   aTimer.Enabled := True;
   lstGames.Enabled := False;
end;


procedure TxfraNetMenu.DebounceGameJoin(aSender: TObject);
   var
      aSession     : TuGameSession;
      aIsConnected : Boolean;
      aForm        : TForm;
begin
   aSession                := FSelectedSession.GameSession;
   TTimer(aSender).Enabled := False;

   NetMgr.GameClient := TuSocket.Create(npTCP, 24001);
   aIsConnected := NetMgr.GameClient.Connect(aSession.FHostIP, 24001);

   if aIsConnected then begin
      aForm := TForm(Self.Root.GetObject);
      TxFrmBase(aForm).Loader.LoadFrame(TxfrmPong);
   end {IF}
   else begin
      HandleNetworkLogging(TuLogEventData.Create('Failed to Connect to Game Server, Try Again...', mtError));
      lstGames.Enabled := False;

      NetMgr.GameClient.Free;
   end; {ELSE}
end;

constructor TxfraNetMenu.Create(aOwner: TComponent);
   var
      aLogMsg: TuLogEventData;
begin
   inherited Create(aOwner);
   FNetworkManager               := TNetManager.Get;
   FNetworkManager.OnLog         := HandleNetworkLogging;
   FNetworkManager.OnRoleChange  := HandleRoleChange;
   FNetworkManager.OnGameSession := HandleGameSession;

   edtChat.OnKeyDown             := edtChatKeyPress;
   lstGames.OnItemClick          := lstGameItemClick;

   btnHostGame.Enabled := False;
   btnJoinGame.Enabled := False;

   FNetworkManager.Start;
   aLogMsg := TuLogEventData.Create('Network Mananger Initalized...', mtSystem);
   HandleNetworkLogging(aLogMsg);
end;

procedure TxfraNetMenu.edtChatKeyPress(Sender      : TObject;
                                       var Key     : Word;
                                       var KeyChar : WideChar;
                                       Shift       : TShiftState);
begin
   if Key = VK_RETURN then begin
      if Trim(edtChat.Text) <> '' then begin
         var aP := TuPacket.Create(pfCHAT, edtChat.Text.Trim);
         aP.FIP := NetMgr.IP;
         FNetworkManager.Send(aP);
         edtChat.Text := '';
         Key := 0;
      end; {IF}
   end; {IF}
end;

procedure TxfraNetMenu.HandleGameSession(const aGameSession: TuGameSession);
   var
      aItem: TListBoxItem;
      aFrame: TTuxfraSessionItem;
begin
      aItem             := TListBoxItem.Create(lstGames);
      aItem.Parent      := lstGames;
      aItem.StyleLookup := '';
      aItem.Text        := '';
      aItem.Height      := 20;

      aFrame         := TTuxfraSessionItem.Create(aItem);
      aFrame.Parent  := aItem;
      aFrame.Align   := TAlignLayout.Contents;
      aFrame.HitTest := False;
      aFrame.Update(aGameSession);

      aFrame.RecalcSize;

      if NetMgr.IP = aGameSession.FHostIP then
         btnHostGame.Enabled := False;
end;

procedure TxfraNetMenu.HandleNetworkLogging(const aLogData: TuLogEventData);
begin
   var aString     := FormatDateTime('hh:nn:ss', aLogData.FTimestamp);
   var aItem       := TListBoxItem.Create(lstMessages);

   aItem.StyledSettings := aItem.StyledSettings - [TStyledSetting.FontColor];
   aItem.Text           := Format('[%s]::> %s', [aString, aLogData.FMsg]);
   aItem.FontColor      := aLogData.FColor;

   lstMessages.AddObject(aItem);
end;

procedure TxfraNetMenu.HandleRoleChange(const aRole: TuNetworkRole);
begin
   if aRole <> nrNone then begin
      btnHostGame.Enabled := True;
   end; {IF}

   case aRole of
      nrNone   : lblStatus.Text := 'Mode: None';
      nrClient : lblStatus.Text := 'Mode: Client';
      nrServer : lblStatus.Text := 'Mode: Server';
      nrHub    : lblStatus.Text := 'Mode: Hub';
   end; {CASE}
end;

procedure TxfraNetMenu.lstGameItemClick(const aSender : TCustomListBox;
                                        const aItem   : TListBoxItem);
   var
      i, k       : Integer;
      aFrame     : TTuxfraSessionItem;
      aOtherItem : TListBoxItem;
begin


   for i := 0 to lstGames.Count - 1 do begin
      aOtherItem := lstGames.ItemByIndex(i);


      for k := 0 to aOtherItem.ControlsCount -1  do begin
         if aOtherItem.Controls[k] is TTuxfraSessionItem then begin
            aFrame := TTuxfraSessionItem(aOtherItem.Controls[k]);

            aFrame.recBackground.Stroke.Kind  := TBrushKind.Solid;

            if aOtherItem.IsSelected then begin
               aFrame.recBackground.Stroke.Color     := TAlphaColorRec.Blue;
               aFrame.recBackground.Stroke.Thickness := 3;

               FSelectedSession    := aFrame;
               btnJoinGame.Enabled := True;
            end {IF}
            else begin
               aFrame.recBackground.Stroke.Color     := TAlphaColorRec.Black;
               aFrame.recBackground.Stroke.Thickness := 1;
            end; {ELSE}
         end; {IF}
      end; {FOR}
   end; {FOR}
end;

destructor TxfraNetMenu.Destroy;
begin

   inherited Destroy;
end;

end.
