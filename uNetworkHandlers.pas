unit uNetworkHandlers;

interface

uses
  uNetworkTypes;

type
   TuNetworkHandler = class
     public
        class procedure Setup(Dispatcher: TObject);

        class procedure NoneVEWLFHandler  (const aP: TuPacket);
        class procedure HubVEWLFHandler   (const aP: TuPacket);

        class procedure HTBHandler    (const aP: TuPacket);
        class procedure ClientHTBHandler  (const aP: TuPacket);
        class procedure ServerHTBHandler  (const aP: TuPacket);
        class procedure HubHTBHandler     (const aP: TuPacket);

        class procedure CHATHandler       (const aP: TuPacket);
        class procedure ClientCHATHandler (const aP: TuPacket);
        class procedure ServerCHATHandler (const aP: TuPacket);
        class procedure HubCHATHandler    (const aP: TuPacket);

//        class procedure SESHandler        (const aP: TuPacket); //Not sure if needed
        class procedure ClientSESHandler  (const aP: TuPacket);
        class procedure ServerSESHandler  (const aP: TuPacket);
        class procedure HubSESHandler     (const aP: TuPacket);

        class procedure ClientJOINHandler (const aP: TuPacket);
        class procedure ServerJOINHandler (const aP: TuPacket);

        class procedure ClientUPDHandler  (const aP: TuPacket);
        class procedure ServerUPDHandler  (const aP: TuPacket);

        class procedure NoneCLSHandler    (const aP: TuPacket);
        class procedure ClientCLSHandler  (const aP: TuPacket);
        class procedure ServerCLSHandler  (const aP: TuPacket);
        class procedure HubCLSHandler     (const aP: TuPacket);

        class procedure NoneKILHandler    (const aP: TuPacket);
        class procedure ClientKILHandler  (const aP: TuPacket);
        class procedure ServerKILHandler  (const aP: TuPacket);

        class procedure ClientSHFTHandler (const aP: TuPacket);
        class procedure ServerSHFTHandler (const aP: TuPacket);
        class procedure HubSHFTHandler    (const aP: TuPacket);
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

//todo this could use a test for it
class procedure TuNetworkHandler.Setup(Dispatcher: TObject);
begin
   TuNetworkDispatcher(Dispatcher).RegisterHandlers(pfVEWLF,
      [npUDP],
      [nrNone, nrHub],
      [
         procedure(const aP: TuPacket) begin NoneVEWLFHandler(aP); end,
         procedure(const aP: TuPacket) begin HubVEWLFHandler (aP); end
      ]
   );

   TuNetworkDispatcher(Dispatcher).RegisterHandlers(pfHTB,
      [npUDP],
      [nrClient, nrServer, nrHub],
      [
         procedure(const aP: TuPacket) begin ClientHTBHandler(aP); end,
         procedure(const aP: TuPacket) begin ServerHTBHandler(aP); end,
         procedure(const aP: TuPacket) begin HubHTBHandler   (aP); end
      ]
   );

   TuNetworkDispatcher(Dispatcher).RegisterHandlers(pfCHAT,
      [npTCP],
      [nrClient, nrServer, nrHub],
      [
         procedure(const aP: TuPacket) begin ClientCHATHandler(aP); end,
         procedure(const aP: TuPacket) begin ServerCHATHandler(aP); end,
         procedure(const aP: TuPacket) begin HubCHATHandler   (aP); end
      ]
   );

   TuNetworkDispatcher(Dispatcher).RegisterHandlers(pfSES,
      [npTCP],
      [nrClient, nrServer, nrHub],
      [
         procedure(const aP: TuPacket) begin ClientSESHandler(aP); end,
         procedure(const aP: TuPacket) begin ServerSESHandler(aP); end,
         procedure(const aP: TuPacket) begin HubSESHandler   (aP); end
      ]
   );
   TuNetworkDispatcher(Dispatcher).RegisterHandlers(pfJOIN,
      [npTCP],
      [nrClient, nrServer],
      [
         procedure(const aP: TuPacket) begin ClientJOINHandler(aP); end,
         procedure(const aP: TuPacket) begin ServerJOINHandler(aP); end
      ]
   );

   TuNetworkDispatcher(Dispatcher).RegisterHandlers(pfUPD,
      [npTCP],
      [nrClient, nrServer],
      [
         procedure(const aP: TuPacket) begin ClientUPDHandler(aP); end,
         procedure(const aP: TuPacket) begin ServerUPDHandler(aP); end
      ]
   );

   TuNetworkDispatcher(Dispatcher).RegisterHandlers(pfCLS,
      [npUDP, npTCP],
      [nrNone, nrClient, nrServer, nrHub],
      [
         procedure(const aP: TuPacket) begin NoneCLSHandler  (aP); end,
         procedure(const aP: TuPacket) begin ClientCLSHandler(aP); end,
         procedure(const aP: TuPacket) begin ServerCLSHandler(aP); end,
         procedure(const aP: TuPacket) begin HubCLSHandler   (aP); end
      ]
   );

   TuNetworkDispatcher(Dispatcher).RegisterHandlers(pfKIL,
      [npUDP, npTCP],
      [nrClient, nrServer, nrHub],
      [
         procedure(const aP: TuPacket) begin NoneKILHandler  (aP); end,
         procedure(const aP: TuPacket) begin ClientKILHandler(aP); end,
         procedure(const aP: TuPacket) begin ServerKILHandler(aP); end
      ]
   );

   TuNetworkDispatcher(Dispatcher).RegisterHandlers(pfSHFT,
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

class procedure TuNetworkHandler.CHATHandler(const aP: TuPacket);
begin
   //Should be the same for everybody, log the message to the ui
end;

class procedure TuNetworkHandler.HTBHandler(const aP: TuPacket);
begin

end;

///////////////////////////////////////////////////////////////////////////////
//// pfVEWLF HANDLERS::
///////////////////////////////////////////////////////////////////////////////

class procedure TuNetworkHandler.NoneVEWLFHandler(const aP: TuPacket);
begin
   with NetMgr do begin
      Role := nrClient;
      //Connect to server TCP is on 6001
      Connect(aP.FIP, ServerPort + 1);
   end;
end;

class procedure TuNetworkHandler.HubVEWLFHandler(const aP: TuPacket);
begin
   with NetMgr do begin
      //may not work?
      UDP.Send(aP.Parse, aP.FIP, ServerPort);
   end;
end;

///////////////////////////////////////////////////////////////////////////////
//// pfHTB HANDLERS::
///////////////////////////////////////////////////////////////////////////////

class procedure TuNetworkHandler.ClientHTBHandler(const aP: TuPacket);
   begin HTBHandler(aP); end;
class procedure TuNetworkHandler.ServerHTBHandler(const aP: TuPacket);
   begin HTBHandler(aP); end;

class procedure TuNetworkHandler.HubHTBHandler(const aP: TuPacket);
begin
   //Hub will reference its active sessions, and connections accordingly
end;

///////////////////////////////////////////////////////////////////////////////
//// pfCHAT HANDLERS::
///////////////////////////////////////////////////////////////////////////////

class procedure TuNetworkHandler.ClientCHATHandler(const aP: TuPacket);
   begin ChatHandler(aP); end;
class procedure TuNetworkHandler.ServerCHATHandler(const aP: TuPacket);
   begin ChatHandler(aP); end;
class procedure TuNetworkHandler.HubCHATHandler   (const aP: TuPacket);
   begin ChatHandler(aP); end;

///////////////////////////////////////////////////////////////////////////////
//// pfSES HANDLERS::
///////////////////////////////////////////////////////////////////////////////

class procedure TuNetworkHandler.ClientSESHandler(const aP: TuPacket);
begin

end;

class procedure TuNetworkHandler.ServerSESHandler(const aP: TuPacket);
begin

end;

class procedure TuNetworkHandler.HubSESHandler(const aP: TuPacket);
begin

end;

///////////////////////////////////////////////////////////////////////////////
//// pfJOIN HANDLERS::
///////////////////////////////////////////////////////////////////////////////

class procedure TuNetworkHandler.ClientJOINHandler(const aP: TuPacket);
begin

end;

class procedure TuNetworkHandler.ServerJOINHandler(const aP: TuPacket);
begin

end;

///////////////////////////////////////////////////////////////////////////////
//// pfUPD HANDLERS::
///////////////////////////////////////////////////////////////////////////////

class procedure TuNetworkHandler.ClientUPDHandler(const aP: TuPacket);
begin

end;

class procedure TuNetworkHandler.ServerUPDHandler(const aP: TuPacket);
begin

end;

///////////////////////////////////////////////////////////////////////////////
//// pfCLS HANDLERS::
///////////////////////////////////////////////////////////////////////////////

class procedure TuNetworkHandler.NoneCLSHandler(const aP: TuPacket);
begin

end;

class procedure TuNetworkHandler.ClientCLSHandler(const aP: TuPacket);
begin

end;

class procedure TuNetworkHandler.ServerCLSHandler(const aP: TuPacket);
begin

end;

class procedure TuNetworkHandler.HubCLSHandler(const aP: TuPacket);
begin

end;


///////////////////////////////////////////////////////////////////////////////
//// pfKIL HANDLERS::
///////////////////////////////////////////////////////////////////////////////


class procedure TuNetworkHandler.NoneKILHandler(const aP: TuPacket);
begin

end;

class procedure TuNetworkHandler.ClientKILHandler(const aP: TuPacket);
begin

end;

class procedure TuNetworkHandler.ServerKILHandler(const aP: TuPacket);
begin

end;

///////////////////////////////////////////////////////////////////////////////
//// pfSHFT HANDLERS::
///////////////////////////////////////////////////////////////////////////////

//If there is no one left just kill yourself and be done with it...

class procedure TuNetworkHandler.ClientSHFTHandler(const aP: TuPacket);
begin

end;

class procedure TuNetworkHandler.ServerSHFTHandler(const aP: TuPacket);
begin

end;

class procedure TuNetworkHandler.HubSHFTHandler(const aP: TuPacket);
begin

end;


end.


