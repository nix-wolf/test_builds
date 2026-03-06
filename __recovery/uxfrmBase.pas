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
         procedure FormKeyDown(aSender: Tobject; var aKey: Word; var aKeyChar: Char; aShift: TShiftState);
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
end;

procedure TxfrmBase.FormCreate(aSender: TObject);
begin
   Self.BorderStyle := TFmxFormBorderStyle.Single;
   Self.BorderIcons := [TBorderIcon.biSystemMenu, TBorderIcon.biMinimize];
   Self.ClientWidth  := 1024;
   Self.ClientHeight := 768;
   Self.Constraints.MinWidth  := 1024;
   Self.Constraints.MaxWidth  := 1024;
   Self.Constraints.MinHeight := 768;
   Self.Constraints.MaxHeight := 768;

   lytContainer.Align := TAlignLayout.Client;
   FLoader := TxFrmLoader.Create(lytContainer);

   FLoader.LoadFrame(TxfraMainMenu, True);
end;

procedure TxfrmBase.FormDelete(aSender: TObject);
begin
   FLoader.Free;
end;

procedure TxfrmBase.FormKeyDown(aSender: Tobject; var aKey: Word;
  var aKeyChar: Char; aShift: TShiftState);
begin
   if aKey = vkEscape then begin
      FLoader.PopFrame;
      aKey := 0;
   end; {IF}
end;

destructor TxfrmBase.Destroy;
begin
   //Kill NetMgr, but not sure how because it doesnt get constructed
   inherited;
end;

end.
