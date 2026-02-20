unit NetworkTest;

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
  IdGlobal,
  IdTCPClient,
  IdTCPServer,
  IdUDPClient,
  IdUDPServer,
  IdContext;

type
  TNetFrame = class(TFrame)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  NetFrame: TNetFrame;

implementation

{$R *.fmx}

end.
