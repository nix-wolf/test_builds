unit uNetworkHandlers;

interface

uses
  uNetworkTypes;

type
   TuNetworkHandler = class
     public
        procedure Setup(Dispatcher: TObject);

        procedure NoneVEWLFHandler  (const aP: TuPacket);
        procedure HubVEWLFHandler   (const aP: TuPacket);

        procedure HTBHandler    (const aP: TuPacket);
        procedure ClientHTBHandler  (const aP: TuPacket);
        procedure ServerHTBHandler  (const aP: TuPacket);
        procedure HubHTBHandler     (const aP: TuPacket);

        procedure CHATHandler       (const aP: TuPacket);
        procedure ClientCHATHandler (const aP: TuPacket);
        procedure ServerCHATHandler (const aP: TuPacket);
        procedure HubCHATHandler    (const aP: TuPacket);

//        procedure SESHandler        (const aP: TuPacket); //Not sure if needed
        procedure ClientSESHandler  (const aP: TuPacket);
        procedure ServerSESHandler  (const aP: TuPacket);
        procedure HubSESHandler     (const aP: TuPacket);

        procedure ClientJOINHandler (const aP: TuPacket);
        procedure ServerJOINHandler  (const aP: TuPacket);

        procedure ClientUPDHandler  (const aP: TuPacket);
        procedure ServerUPDHandler  (const aP: TuPacket);

        procedure NoneCLSHandler    (const aP: TuPacket);
        procedure ClientCLSHandler  (const aP: TuPacket);
        procedure ServerCLSHandler  (const aP: TuPacket);
        procedure HubCLSHandler     (const aP: TuPacket);

        procedure NoneKILHandler    (const aP: TuPacket);
        procedure ClientKILHandler  (const aP: TuPacket);
        procedure ServerKILHandler  (const aP: TuPacket);

        procedure ClientSHFTHandler (const aP: TuPacket);
        procedure ServerSHFTHandler (const aP: TuPacket);
        procedure HubSHFTHandler    (const aP: TuPacket);
   end;

implementation

uses
   uNetManager,
   uNetworkDispatcher;

{ TuMultiRoleHandler }

{*
   Dispatcher.Register(pfFLAG, PROTO,
      [nrNone, nrClient, nrServer, nrHub],
      [
         procedure(const P: TuPacket) begin nrNoneFLAGHandler(P); end,
         procedure(const P: TuPacket) begin nrClientFLAGHandler(P); end,
         procedure(const P: TuPacket) begin nrServerFLAGHandler(P); end,
         procedure(const P: TuPacket) begin nrHubFLAGHandler(P); end
      ]
   );

pfVEWLF : Hub Check      ; udp      :: A Flat UDP Broadcast check to find the hub
pfHTB   : Heart Beat     ; udp      :: A Check-in message, for hub to track dead connections
pfCHAT  : Chat Message   ; tcp      :: Is a Chat Message, displayed to UI
pfSES   : Session Data   ; tcp      :: Is the Lobby Session data for a game server
pfJOIN  : Join Request   ; tcp      :: Specifcally for Session JOIN
pfUPD   : Update Request ; tcp      :: To send Updates FOR the rendered frame
pfCLS   : Close Signal   ; tcp, udp :: Client to Server notification closed
pfKIL   : Kill Signal    ; tcp, udp :: Server to Client to drop connection
pfSHFT  : Hub Shift      ; tcp, udp :: For Shifting WHOisHUB when Hub Entity exits

*}

///////////////////////////////////////////////////////////////////////////////
//// Setup Function: Main definition linking everything together
///////////////////////////////////////////////////////////////////////////////

procedure TuNetworkHandler.Setup(Dispatcher: TObject);
begin
   TuNetworkDispatcher(Dispatcher).Register(pfVEWLF,
      [npUDP],
      [nrNone, nrHub],
      [
         procedure(const aP: TuPacket) begin NoneVEWLFHandler(aP); end,
         procedure(const aP: TuPacket) begin HubVEWLFHandler (aP); end
      ]
   );

   TuNetworkDispatcher(Dispatcher).Register(pfHTB,
      [npUDP],
      [nrNone, nrClient, nrServer, nrHub],
      [
         procedure(const aP: TuPacket) begin ClientHTBHandler(aP); end,
         procedure(const aP: TuPacket) begin ServerHTBHandler(aP); end,
         procedure(const aP: TuPacket) begin HubHTBHandler   (aP); end
      ]
   );

   TuNetworkDispatcher(Dispatcher).Register(pfCHAT,
      [npTCP],
      [nrNone, nrClient, nrServer, nrHub],
      [
         procedure(const aP: TuPacket) begin ClientCHATHandler(aP); end,
         procedure(const aP: TuPacket) begin ServerCHATHandler(aP); end,
         procedure(const aP: TuPacket) begin HubCHATHandler   (aP); end
      ]
   );

   TuNetworkDispatcher(Dispatcher).Register(pfSES,
      [npTCP],
      [nrNone, nrClient, nrServer, nrHub],
      [
         procedure(const aP: TuPacket) begin ClientSESHandler(aP); end,
         procedure(const aP: TuPacket) begin ServerSESHandler(aP); end,
         procedure(const aP: TuPacket) begin HubSESHandler   (aP); end
      ]
   );
   TuNetworkDispatcher(Dispatcher).Register(pfJOIN,
      [npTCP],
      [nrClient, nrServer],
      [
         procedure(const aP: TuPacket) begin ClientJOINHandler(aP); end,
         procedure(const aP: TuPacket) begin ServerJOINHandler(aP); end
      ]
   );

   TuNetworkDispatcher(Dispatcher).Register(pfUPD,
      [npTCP],
      [nrClient, nrServer],
      [
         procedure(const aP: TuPacket) begin ClientUPDHandler(aP); end,
         procedure(const aP: TuPacket) begin ServerUPDHandler(aP); end
      ]
   );

   TuNetworkDispatcher(Dispatcher).Register(pfCLS,
      [npUDP, npTCP],
      [nrNone, nrClient, nrServer, nrHub],
      [
         procedure(const aP: TuPacket) begin NoneCLSHandler  (aP); end,
         procedure(const aP: TuPacket) begin ClientCLSHandler(aP); end,
         procedure(const aP: TuPacket) begin ServerCLSHandler(aP); end,
         procedure(const aP: TuPacket) begin HubCLSHandler   (aP); end
      ]
   );

   TuNetworkDispatcher(Dispatcher).Register(pfKIL,
      [npUDP, npTCP],
      [nrNone, nrClient, nrServer, nrHub],
      [
         procedure(const aP: TuPacket) begin NoneKILHandler  (aP); end,
         procedure(const aP: TuPacket) begin ClientKILHandler(aP); end,
         procedure(const aP: TuPacket) begin ServerKILHandler(aP); end
      ]
   );

   TuNetworkDispatcher(Dispatcher).Register(pfSHFT,
      [npUDP, npTCP],
      [nrClient, nrServer, nrHub],
      [
         procedure(const aP: TuPacket) begin ClientSHFTHandler(aP); end,
         procedure(const aP: TuPacket) begin ServerSHFTHandler(aP); end,
         procedure(const aP: TuPacket) begin HubSHFTHandler   (aP); end
      ]
   );

end;

///////////////////////////////////////////////////////////////////////////////
//// Handler Implementations::
///////////////////////////////////////////////////////////////////////////////

{ TuNetworkHandler }

procedure TuNetworkHandler.CHATHandler(const aP: TuPacket);
begin
   //Should be the same for everybody, log the message to the ui
end;

procedure TuNetworkHandler.HTBHandler(const aP: TuPacket);
begin

end;

///////////////////////////////////////////////////////////////////////////////
//// pfVEWLF HANDLERS::
///////////////////////////////////////////////////////////////////////////////

procedure TuNetworkHandler.NoneVEWLFHandler(const aP: TuPacket);
begin
   with NetMgr do begin
      Role := nrClient;
      //Connect to server TCP is on 6001
      Connect(aP.FIP, ServerPort + 1);
   end;
end;

procedure TuNetworkHandler.HubVEWLFHandler(const aP: TuPacket);
begin
   with NetMgr do begin
      //may not work?
      UDP.Send(aP.FData, aP.FIP, ServerPort);
   end;
end;

///////////////////////////////////////////////////////////////////////////////
//// pfHTB HANDLERS::
///////////////////////////////////////////////////////////////////////////////

procedure TuNetworkHandler.ClientHTBHandler(const aP: TuPacket);
   begin HTBHandler(aP); end;
procedure TuNetworkHandler.ServerHTBHandler(const aP: TuPacket);
   begin HTBHandler(aP); end;

procedure TuNetworkHandler.HubHTBHandler(const aP: TuPacket);
begin
   //Hub will reference its active sessions, and connections accordingly
end;

///////////////////////////////////////////////////////////////////////////////
//// pfCHAT HANDLERS::
///////////////////////////////////////////////////////////////////////////////

procedure TuNetworkHandler.ClientCHATHandler(const aP: TuPacket);
   begin ChatHandler(aP); end;
procedure TuNetworkHandler.ServerCHATHandler(const aP: TuPacket);
   begin ChatHandler(aP); end;
procedure TuNetworkHandler.HubCHATHandler   (const aP: TuPacket);
   begin ChatHandler(aP); end;

///////////////////////////////////////////////////////////////////////////////
//// pfSES HANDLERS::
///////////////////////////////////////////////////////////////////////////////

procedure TuNetworkHandler.ClientSESHandler(const aP: TuPacket);
begin

end;

procedure TuNetworkHandler.ServerSESHandler(const aP: TuPacket);
begin

end;

procedure TuNetworkHandler.HubSESHandler(const aP: TuPacket);
begin

end;

///////////////////////////////////////////////////////////////////////////////
//// pfJOIN HANDLERS::
///////////////////////////////////////////////////////////////////////////////

procedure TuNetworkHandler.ClientJOINHandler(const aP: TuPacket);
begin

end;

procedure TuNetworkHandler.ServerJOINHandler(const aP: TuPacket);
begin

end;

///////////////////////////////////////////////////////////////////////////////
//// pfUPD HANDLERS::
///////////////////////////////////////////////////////////////////////////////

procedure TuNetworkHandler.ClientUPDHandler(const aP: TuPacket);
begin

end;

procedure TuNetworkHandler.ServerUPDHandler(const aP: TuPacket);
begin

end;

///////////////////////////////////////////////////////////////////////////////
//// pfCLS HANDLERS::
///////////////////////////////////////////////////////////////////////////////

procedure TuNetworkHandler.NoneCLSHandler(const aP: TuPacket);
begin

end;

procedure TuNetworkHandler.ClientCLSHandler(const aP: TuPacket);
begin

end;

procedure TuNetworkHandler.ServerCLSHandler(const aP: TuPacket);
begin

end;

procedure TuNetworkHandler.HubCLSHandler(const aP: TuPacket);
begin

end;


///////////////////////////////////////////////////////////////////////////////
//// pfKIL HANDLERS::
///////////////////////////////////////////////////////////////////////////////


procedure TuNetworkHandler.NoneKILHandler(const aP: TuPacket);
begin

end;

procedure TuNetworkHandler.ClientKILHandler(const aP: TuPacket);
begin

end;

procedure TuNetworkHandler.ServerKILHandler(const aP: TuPacket);
begin

end;

///////////////////////////////////////////////////////////////////////////////
//// pfSHFT HANDLERS::
///////////////////////////////////////////////////////////////////////////////


procedure TuNetworkHandler.ClientSHFTHandler(const aP: TuPacket);
begin

end;

procedure TuNetworkHandler.ServerSHFTHandler(const aP: TuPacket);
begin

end;

procedure TuNetworkHandler.HubSHFTHandler(const aP: TuPacket);
begin

end;


end.


