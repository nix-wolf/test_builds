unit uxfraSessionItem;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Objects;

type
  TTuxfraSessionItem = class(TFrame)
    recBackground: TRectangle;
    lblGameName: TLabel;
    lblGameType: TLabel;
    lblPlayers: TLabel;

  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

end.
