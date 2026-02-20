program network_test;

uses
  System.StartUpCopy,
  FMX.Forms,
  uNetworkManager in 'uNetworkManager.pas',
  uNetworkTypes in 'uNetworkTypes.pas',
  uxfrmNetFrame in 'uxfrmNetFrame.pas' {NetFrame: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.Run;
end.
