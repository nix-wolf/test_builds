unit uxfraNetMenu;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  uNetworkManager,
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
    lstGames: TListBox;
    lLayout: TLayout;
    memInfo: TMemo;
    btnJoinGame: TButton;
    btnHostGame: TButton;
    edtChat: TEdit;
    lblStatus: TLabel;
    procedure btnHostGameClick(Sender: TObject);
    procedure btnJoinGameClick(Sender: TObject);
    procedure edtChatKeyPress(Sender: TObject; var aKey: Char);

  private
    FNetworkManager: TNetworkManager;
    FDelaytimer: TTimer;
    procedure HandleNetworkLogging(const aMsg: String);
    procedure UpdateRoleUI(aNewRole: TNetworkRole);
    procedure DiscoveryDebounce(Sender: TObject);
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;

    procedure StartDiscovery;
  end;

var
  xfraNetMenu: TxfraNetMenu;

implementation

{$R *.fmx}

procedure TxfraNetMenu.btnHostGameClick(Sender: TObject);
begin
  //
end;

procedure TxfraNetMenu.btnJoinGameClick(Sender: TObject);
begin
  //
end;

constructor TxfraNetMenu.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  FNetworkManager := TNetworkManager.Create;
  FNetworkManager.OnLog := HandleNetworkLogging;

  memInfo.Lines.Add('Network Frame Initalized...');
//  StartDiscovery;

//  FDelayTimer := TTimer.Create(nil);
end;

destructor TxfraNetMenu.Destroy;
begin
  FNetworkManager.Free;
  inherited Destroy;
end;

procedure TxfraNetMenu.DiscoveryDebounce(Sender: TObject);
begin
//
end;

procedure TxfraNetMenu.edtChatKeyPress(Sender: TObject; var aKey: Char);
begin
  if aKey = #13 then begin
    if edtChat.Text <> '' then begin
//      FNetworkManager.SendMessage(edtChat.Text);
      edtChat.Text := '';
      aKey := #0 //prevents beep?
    end; {IF}
  end; {IF}
end;

procedure TxfraNetMenu.HandleNetworkLogging(const aMsg: String);
begin
  var aString := FormatDateTime('hh:nn:ss', Now);
  memInfo.Lines.Add(Format('[%s]::> %s', [aString, aMsg]));
  memInfo.SelStart := Length(memInfo.Text);
end;

procedure TxfraNetMenu.StartDiscovery;
begin
  FNetworkManager.DiscoverAndJoin(6000);
end;

procedure TxfraNetMenu.UpdateRoleUI(aNewRole: TNetworkRole);
begin
  case aNewRole of
    nrNone: lblStatus.Text   := 'Mode: None';
    nrClient: lblStatus.Text := 'Mode: Client';
    nrServer: lblStatus.Text := 'Mode: Server';
  end;
end;

end.
