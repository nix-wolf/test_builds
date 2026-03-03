unit uxfraNetMenu;

interface

uses
   Winapi.Windows,
   System.SysUtils,
   System.Types,
   System.UITypes,
   System.Classes,
   System.Variants,
   uNetManager,
   uNetworkTypes,
   uxfraHostMenu,
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
         FNetworkManager: TNetManager;
         aSelectedSession: TuGameSession;

         procedure HandleNetworkLogging(const aLogData: TuLogEventData);
         procedure HandleRoleChange(const aRole: TuNetworkRole);
         procedure UpdateRoleUI(const aRole: TuNetworkRole);
      public
         constructor Create(aOwner: TComponent); override;
         destructor Destroy; override;
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
   aForm := TForm(Self.Root.GetObject);

   TxFrmBase(aForm).Loader.LoadFrame(TxFraHostMenu, True, Self);
end;

procedure TxfraNetMenu.btnJoinGameClick(Sender: TObject);
begin
  //
end;

constructor TxfraNetMenu.Create(aOwner: TComponent);
   var
      aLogMsg: TuLogEventData;
begin
   inherited Create(aOwner);
   FNetworkManager              := TNetManager.Get;
   FNetworkManager.OnLog        := HandleNetworkLogging;
   FNetworkManager.OnRoleChange := HandleRoleChange;
   edtChat.OnKeyDown            := edtChatKeyPress;

   FNetworkManager.Start;
   aLogMsg := TuLogEventData.Create('Network Mananger Initalized...', mtSystem);
   HandleNetworkLogging(aLogMsg);
end;

destructor TxfraNetMenu.Destroy;
begin

   inherited Destroy;
end;


procedure TxfraNetMenu.edtChatKeyPress(Sender      : TObject;
                                       var Key     : Word;
                                       var KeyChar : WideChar;
                                       Shift       : TShiftState);
begin
   if Key = VK_RETURN then begin
      if Trim(edtChat.Text) <> '' then begin
         FNetworkManager.Send(TuPacket.Create(pfCHAT, edtChat.Text.Trim));
         edtChat.Text := '';
         Key := 0;
      end; {IF}
   end; {IF}
end;

procedure TxfraNetMenu.HandleNetworkLogging(const aLogData: TuLogEventData);
begin
   var aString     := FormatDateTime('hh:nn:ss', aLogData.FTimestamp);
   var aItem       := TListBoxItem.Create(lstMessages);
   aItem.StyledSettings := aItem.StyledSettings - [TStyledSetting.FontColor];
   aItem.Text  := Format('[%s]::> %s', [aString, aLogData.FMsg]);
   aItem.FontColor := aLogData.FColor;

   lstMessages.AddObject(aItem);
end;

procedure TxfraNetMenu.HandleRoleChange(const aRole: TuNetworkRole);
begin
   UpdateRoleUI(aRole);
end;

procedure TxfraNetMenu.UpdateRoleUI(const aRole: TuNetworkRole);
begin
   case aRole of
      nrNone   : lblStatus.Text := 'Mode: None';
      nrClient : lblStatus.Text := 'Mode: Client';
      nrServer : lblStatus.Text := 'Mode: Server';
      nrHub    : lblStatus.Text := 'Mode: Hub';
   end; {CASE}
end;

end.
