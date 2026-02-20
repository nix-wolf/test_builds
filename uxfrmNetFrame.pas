unit uxfrmNetFrame;

interface

uses
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
  FMX.StdCtrls, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Layouts,
  FMX.ListBox, FMX.Edit, FMX.Controls.Presentation;

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
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

end.
