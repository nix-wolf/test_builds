program VE_ARC;

uses
  System.StartUpCopy,
  FMX.Forms,
  uxfraSnake in 'uxfraSnake.pas' {xfraSnake: T},
  uxfrmLoader in 'uxfrmLoader.pas' {xfrmLoader: TFrame},
  uxfraPong in 'uxfraPong.pas' {xfraPong: T},
  uxfraMainMenu in 'uxfraMainMenu.pas' {xfraMainMenu: TFrame},
  uxfraNetMenu in 'uxfraNetMenu.pas' {xfraNetMenu: TFrame},
  uNetManager in 'uNetManager.pas',
  uTCPServer in 'uTCPServer.pas',
  uNetworkManager in 'uNetworkManager.pas',
  uNetworkTypes in 'uNetworkTypes.pas',
  uReadThread in 'uReadThread.pas',
  uNetworkDispatcher in 'uNetworkDispatcher.pas',
  uNetworkHandlers in 'uNetworkHandlers.pas',
  uSocket in 'uSocket.pas',
  uTCPRemoteClient in 'uTCPRemoteClient.pas';

{}

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TxfrmLoader, xfrmLoader);
  Application.Run;
end.

