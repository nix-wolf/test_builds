unit uxfraMainMenu;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  uxfraNetMenu,
  uxfraPong,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.Forms,
  FMX.Dialogs,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.Header,
  FMX.Controls.Presentation;

type
  TxfraMainMenu = class(TFrame)
    btnMultiButton: TButton;
    btnSinglePlayer: TButton;
    lLayout: TLayout;
    procedure btnSinglePlayerClick(Sender: TObject);
    procedure btnMultiButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
    xfraMainMenu: TxfraMainMenu;

implementation

uses uxfrmLoader;

{$R *.fmx}

procedure TxfraMainMenu.btnMultiButtonClick(Sender: TObject);
begin
   TxfrmLoader(Parent).PushFrame(TxfraNetMenu);
end;

procedure TxfraMainMenu.btnSinglePlayerClick(Sender: TObject);
begin
//pong needs to be renamed to fra, its a frame not a form
   TxfrmLoader(Parent).PushFrame(TxfrmPong);
end;

end.
