unit uxfraHostMenu;

interface

uses
   uNetWorkTypes,
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
   FMX.StdCtrls,
   FMX.ListBox,
   FMX.Controls.Presentation,
   FMX.Edit, FMX.Objects;

type
   TxFraHostMenu = class(TFrame)
      edtGameName : TEdit;
      lblName     : TLabel;
      lblGType    : TLabel;
      btnCancel   : TButton;
      cbGameType  : TComboBox;
      btnCreate   : TButton;
      lbiPong     : TListBoxItem;
      Rectangle1  : TRectangle;

      procedure btnCreateClick(Sender: TObject);
      procedure btnCancelClick(Sender: TObject);
      procedure OnAction;
  end;

var
   xFraHostMenu: TxFraHostMenu;

implementation

{$R *.fmx}

uses
     uxfrmBase,
     uxfrmLoader,
     uNetManager;

procedure TxFraHostMenu.btnCancelClick(Sender: TObject);
begin
   OnAction;
end;

procedure TxFraHostMenu.btnCreateClick(Sender: TObject);
   var
      aSe   : TuGameSession;
      aP    : TuPacket;
      aForm : TForm;
begin


   FillChar(aP, SizeOf(aP), 0);
   FillChar(aSe, SizeOf(aSe), 0);

   if edtGameName.Text = '' then begin
      aSe.FHostName   := 'Why no name?';
   end {IF}
   else aSe.FHostName := edtGameName.Text;
   aSe.FGameType      := cbGameType.Text;
   aSe.FHostIP        := NetMgr.IP;
   aSe.FPlayerCount   := 0;
   aSe.FMaxPlayers    := 2;
   aSe.FLastSeen      := Now;
   aP                 := TuPacket.Create(pfSES, aSe.ToNetworkString);

   if NetMgr.Role = nrHub then begin
      //your going to have to have a callback
   end;

   NetMgr.Send(aP);

   OnAction;
end;

procedure TxFraHostMenu.OnAction;
   var
      aForm: TForm;
begin
   aForm := TForm(Self.Root.GetObject);
   TxFrmBase(aForm).Loader.PopFrame;
end;

end.
