unit uNetworkHandlers;

interface

uses
  uNetworkTypes;

implementation

{ TuMultiRoleHandler }

//procedure TuNetworkHandlers.Setup(Dispatcher: TuNetworkDispatcher);
//begin
//   CHAT: Both Client and Server have a routine, Hub might just relay
//  Dispatcher.Register(pfCHAT, npTCP,
//    [nrClient, nrServer],
//    [
//      procedure(const P: TuPacket) begin ClientChatLogic(P); end,
//      procedure(const P: TuPacket) begin ServerChatLogic(P); end
//    ]
//  );

  // VEWLF (Hub Check): Only the Client asks, only the Hub answers
//  Dispatcher.Register(pfVEWLF, npUDP,
//    [nrClient, nrHub],
//    [
//      procedure(const P: TuPacket) begin ClientReceiveHubBeacon(P); end,
//      procedure(const P: TuPacket) begin HubHandleIncomingSearch(P); end
//    ]
//  );
//end;

end.
