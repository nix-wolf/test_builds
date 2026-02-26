unit uTCPRemoteClient;

interface

uses
   uSocket,
   uNetworkTypes,
   System.SysUtils;

type

   TuTCPRemoteClient = class
      private
         FOwner  : TObject;
         FSocket : TuSocket;
         FIP     : String;
         FName   : String;

         FOnData : TOnDataReceived;

      public
         constructor Create(aOwner: TObject; aSocket: TuSocket);
         destructor Destroy; override;

         procedure Send(const aMsg: String);
         procedure OnMessage(const aIP, aMsg: String);
         procedure Disconnect;

         property IP             : String          read FIP;
         property Socket         : TuSocket        read FSocket;
         property OnDataReceived : TOnDataReceived read FOnData    write FOnData;
   end;

implementation

{ TuTCPRemoteClient }

uses uTCPServer;

///////////////////////////////////////////////////////////////////////////////
//// Construction/Initalization
///////////////////////////////////////////////////////////////////////////////

constructor TuTCPRemoteClient.Create(aOwner: TObject; aSocket: TuSocket);
begin
   FOwner := aOwner;
   FSocket := aSocket;
end;

///////////////////////////////////////////////////////////////////////////////
//// Other
///////////////////////////////////////////////////////////////////////////////

procedure TuTCPRemoteClient.Send(const aMsg: String);
   var
      aBytes: TBytes;
begin

end;
///nope this does work
procedure TuTCPRemoteClient.OnMessage(const aIP, aMsg: String);
begin
   if Assigned(FOwner) then
      (FOwner as TuTCPServer).OnClientMessage(Self, aMsg);
end;

///////////////////////////////////////////////////////////////////////////////
//// Deconstruction
///////////////////////////////////////////////////////////////////////////////

procedure TuTCPRemoteClient.Disconnect;
begin
   if Assigned(FOwner) then
      TuTCPServer(FOwner).OnClientDisconnect(Self);
end;

destructor TuTCPRemoteClient.Destroy;
begin
   if Assigned(FSocket) then FSocket.Close;
   inherited;
end;

end.


///////////////////////////////////////////////////////////////////////////////
//// FOOTNOTE:::
/// I suppose that uTCPRemoteClient, should have always been TCPClient
///   since you logically just need a socket as your "TCP connection" on a
///   client. but I dont want to shift everything over now... to much reworking
///   ... getting painful... but its added to the kanban
///////////////////////////////////////////////////////////////////////////////