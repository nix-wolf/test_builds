unit uxFrmMain;

interface

uses
   System.SysUtils,
   System.Types,
   System.UITypes,
   System.Classes,
   System.Variants,
   FMX.Types,
   FMX.Controls,
   FMX.Forms,
   FMX.Graphics,
   FMX.Dialogs,

   FMX.Layouts,
   FMX.StdCtrls,

   uxfrmLoader,
   uNetManager;

type
   TuxFrmMain = class(TForm)
      lytContainer: TLayout;
      procedure FormCreate(aSender  : TObject);
      procedure FormDestroy(aSender : TObject);

   private
      FFrameLoader: TxfrmLoader;
   end;

var
   xFrmMain: TuxFrmMain;

implementation

{$R *.res}

procedure TuxFrmMain.FormCreate(aSender: TObject);
begin

end;


procedure TuxFrmMain.FormDestroy(aSender: TObject);
begin

end;

end.

