unit uxfrmNetFrame;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  uNetworkManager,
  uNetworkTypes,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.Forms,
  FMX.Dialogs,
  FMX.StdCtrls,
  FMX.Memo.Types,
  FMX.ScrollBox,
  FMX.Memo,
  FMX.Layouts,
  FMX.ListBox,
  FMX.Edit,
  FMX.Controls.Presentation;

type
  TNetFrame = class(TFrame)
    pnlHeader: TPanel;
    edtHubIP: TEdit;
    edtServerName: TEdit;
    btnStartHub: TButton;
    btnHost: TButton;
    btnRefresh: TButton;
    lbxGames: TListBox;
    memLog: TMemo;
    procedure btnStartHubClick(Sender: TObject);
    procedure btnHostClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);

  private
    FNetManager: TNetworkManager;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

{$R *.fmx}

procedure TNetFrame.btnHostClick(Sender: TObject);
begin
  FNetManager.HubIP := edtHubIP.Text;
  FNetManager.GameName := edtServerName.Text;

  if FNetManager.ConnectToHub then begin
    FNetManager.StartHosting(6001);
    memLog.Lines.Add('Hosting: ' + FNetManager.GameName);
  end; {IF}
end;

procedure TNetFrame.btnRefreshClick(Sender: TObject);
  var
    aGames: TArray<TGameSession>;
    aGame: TGameSession;
begin
  FNetManager.HubIP := edtHubIP.Text;
  if FNetManager.ConnectToHub then begin
    aGames := FNetManager.FetchRemoteConnections;
    lbxGames.Items.Clear;
    for aGame in aGames do
      lbxGames.Items.Add(aGame.HostName + '@' + aGame.HostIP);

//    memLog.Lines.Add('Found ' + IntToStr(Le) + ' sessions.');
  end; {IF}

end;

procedure TNetFrame.btnStartHubClick(Sender: TObject);
begin
  FNetManager.StartHosting(6000);
  memLog.Lines.Add('Hub is Active on port 6000');
  btnStartHub.Enabled := False;
end;

constructor TNetFrame.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  FNetManager := TNetworkManager.Create;
  memLog.Lines.Add('Network Frame Initialized');
end;

destructor TNetFrame.Destroy;
begin
  FNetManager.Free;
  inherited Destroy;
end;

end.
