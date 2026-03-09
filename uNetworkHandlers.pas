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

        class procedure HTBHandler        (const aP: TuPacket);
        class procedure ClientHTBHandler  (const aP: TuPacket);
        class procedure ServerHTBHandler  (const aP: TuPacket);
        class procedure HubHTBHandler     (const aP: TuPacket);

        class procedure ClientCHATHandler (const aP: TuPacket);
        class procedure HubCHATHandler    (const aP: TuPacket);

        class procedure ClientSESHandler  (const aP: TuPacket);
        class procedure HubSESHandler     (const aP: TuPacket);

        class procedure ServerJOINHandler (const aP: TuPacket);
        class procedure HubJOINHandler    (const aP: TuPacket);

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
   uTCPRemoteClient,
   uNetManager,
   uNetworkDispatcher;

{ TuMultiRoleHandler }

{*
   Dispatcher.Register(pfFLAG,
      [npPROTO],
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
      [nrClient, nrHub],
      [
         procedure(const aP: TuPacket) begin ClientCHATHandler(aP); end,
         procedure(const aP: TuPacket) begin HubCHATHandler   (aP); end
      ]
   );

   TuNetworkDispatcher(Dispatcher).RegisterHandlers(pfSES,
      [npTCP],
      [nrClient, nrHub],
      [
         procedure(const aP: TuPacket) begin ClientSESHandler(aP); end,
         procedure(const aP: TuPacket) begin HubSESHandler   (aP); end
      ]
   );
   TuNetworkDispatcher(Dispatcher).RegisterHandlers(pfJOIN,
      [npTCP],
      [nrServer, nrHub],
      [
         procedure(const aP: TuPacket) begin ServerJOINHandler(aP); end,
         procedure(const aP: TuPacket) begin HubJOINHandler(aP); end
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

{ TuNetworkHandler }

///////////////////////////////////////////////////////////////////////////////
//// Handler Implementations::
///////////////////////////////////////////////////////////////////////////////

class procedure TuNetworkHandler.HTBHandler(const aP: TuPacket);
begin
   //do nothing we dont handler heart beats on anyone but hub
end;

///////////////////////////////////////////////////////////////////////////////
//// pfVEWLF HANDLERS::
///////////////////////////////////////////////////////////////////////////////

class procedure TuNetworkHandler.NoneVEWLFHandler(const aP: TuPacket);
begin
   with NetMgr do begin
      TCPClient.Role := nrClient;
      UDP.Role       := nrClient;
      Role           := nrClient;
      UpdateRoleToUI;

      //Connect to server TCP is on 6001
      Connect(aP.FIP, ServerPort + 1);
   end;
end;

class procedure TuNetworkHandler.HubVEWLFHandler(const aP: TuPacket);
begin
   with NetMgr do begin
      UDP.Send(aP.Parse, aP.FIP, ServerPort);
   end;
end;

///////////////////////////////////////////////////////////////////////////////
//// pfHTB HANDLERS::
///////////////////////////////////////////////////////////////////////////////

//send dont receive only hub receives these
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
begin
   with NetMgr do begin
      if IP = aP.FIP then
         LogtoUI(aP.FData, mtLocal)
      else
         LogtoUI(aP.FData, mtIn);
   end; {WITH}
end;

class procedure TuNetworkHandler.HubCHATHandler(const aP: TuPacket);
begin
   with NetMgr do begin
      Send(aP);
   end; {WITH}
end;

///////////////////////////////////////////////////////////////////////////////
//// pfSES HANDLERS::
///////////////////////////////////////////////////////////////////////////////

class procedure TuNetworkHandler.ClientSESHandler(const aP: TuPacket);
   var
      aGameSession: TuGameSession;
begin
   FillChar(aGameSession, SizeOf(aGameSession), 0);
   aGameSession.FromNetworkString(aP.FData);

   With NetMgr do begin
      GameSessions.Add(aGameSession);
      GameSessionToUI(aGameSession);
   end;
end;

class procedure TuNetworkHandler.HubSESHandler(const aP: TuPacket);
   var
      aSession: TuGameSession;
begin
   FillChar(aSession, SizeOf(aSession), 0);
   aSession.FromNetworkString(aP.FData);

   with NetMgr do begin
      GameSessions.Add(aSession);
      GameSessionToUI(aSession);

      Send(aP);
   end; {WITH}
end;

///////////////////////////////////////////////////////////////////////////////
//// pfJOIN HANDLERS::
///////////////////////////////////////////////////////////////////////////////

class procedure TuNetworkHandler.ServerJOINHandler(const aP: TuPacket);
begin
   with NetMgr do begin
      GameServer.Joiners.Add(aP.FData);
      LogToUI('New Join Request Stored...', mtSystem);
   end; {WITH}
end;

class procedure TuNetworkHandler.HubJOINHandler(const aP: TuPacket);
   var
      aSession : TuGameSession;
      aP2      : TuPacket;
      aClient  : TuTCPRemoteClient;
begin
   FillChar(aSession, SizeOf(aSession), 0);
   aSession.FromNetworkString(aP.FData);

   aP2 := TuPacket.Create(pfJOIN, aP.FIP);

   with NetMgr do begin
      for aClient in TCPServer.Clients do begin
         if aClient.IP = aSession.FHostIP then
            aClient.Send(aP);
      end; {FOR}
   end; {WITH}
end;

///////////////////////////////////////////////////////////////////////////////
//// pfUPD HANDLERS::
///////////////////////////////////////////////////////////////////////////////

class procedure TuNetworkHandler.ClientUPDHandler(const aP: TuPacket);
begin
   with NetMgr do
      if Assigned(OnGameUpdate) then OnGameUpdate(aP)
end;

class procedure TuNetworkHandler.ServerUPDHandler(const aP: TuPacket);
begin
   ClientUPDHandler(aP);
end;

///////////////////////////////////////////////////////////////////////////////
//// pfCLS HANDLERS::
///////////////////////////////////////////////////////////////////////////////

class procedure TuNetworkHandler.NoneCLSHandler(const aP: TuPacket);
begin
   //can it even do this? its only on udp so probably not
end;

class procedure TuNetworkHandler.ClientCLSHandler(const aP: TuPacket);
begin
   //it sends one? it doesnt receive a close?
end;

class procedure TuNetworkHandler.ServerCLSHandler(const aP: TuPacket);
begin
   //hmmm not sure ethier what server would do here, probably same as the
   //hub
end;

class procedure TuNetworkHandler.HubCLSHandler(const aP: TuPacket);
begin
   //a on close message for the hub, removes the connection data(which maybe dead)
   //and then check sessions to ensure no items exist for the ip
end;


///////////////////////////////////////////////////////////////////////////////
//// pfKIL HANDLERS::
///////////////////////////////////////////////////////////////////////////////


class procedure TuNetworkHandler.NoneKILHandler(const aP: TuPacket);
begin
   //kill tcp connection to hub
end;

class procedure TuNetworkHandler.ClientKILHandler(const aP: TuPacket);
begin
   //kill tcp connection to hub
end;

class procedure TuNetworkHandler.ServerKILHandler(const aP: TuPacket);
begin
    //kill tcp connect to hub
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


