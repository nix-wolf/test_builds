unit uxfrmBase;

interface

uses
   System.SysUtils,
   System.Types,
   System.UITypes,
   System.Classes,
   System.Variants,
   FMX.Layouts,
   FMX.StdCtrls,
   FMX.Types,
   FMX.Controls,
   FMX.Forms,
   FMX.Graphics,
   FMX.Dialogs,
   uxFraMainMenu,
   uxfrmLoader,
   uNetManager;

type
   TxfrmBase = class(TForm)
         lytContainer: TLayout;
         procedure FormCreate(aSender: TObject);
         procedure FormDelete(aSender: TObject);
      private
         FLoader: TxfrmLoader;
         FNetMgr: TNetManager;
      public
         constructor Create(aOwner: TComponent); override;
         destructor Destroy; override;


         property Loader: TxFrmLoader read FLoader;
         property NetMgr: TNetManager read FNetMgr;
   end;

var
   xfrmBase: TxfrmBase;

implementation

{$R *.fmx}

{ TxfrmBase }

constructor TxfrmBase.Create(aOwner: TComponent);
begin
   inherited Create(AOwner);

   FLoader := TxFrmLoader.Create(lytContainer);
end;

procedure TxfrmBase.FormCreate(aSender: TObject);
begin
   FLoader.LoadFrame(TxfraMainMenu, True);
end;

procedure TxfrmBase.FormDelete(aSender: TObject);
begin
   FLoader.Free;
end;

destructor TxfrmBase.Destroy;
begin
   //Kill NetMgr, but not sure how because it doesnt get constructed
   inherited;
end;

end.
