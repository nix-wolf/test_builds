unit uTCPRemoteClient;

interface

uses
   uSocket,
   uNetworkTypes,
   Winapi.Winsock2,
   System.SysUtils;

type

   TuTCPRemoteClient = class
      private
         FOwner  : TObject;
         FSocket : TuSocket;
         FJoined : TDateTime;
         FIP     : String;
         FName   : String;
         FPort   : U_SHORT;

      public
         constructor Create(aOwner: TObject; aSocket: TuSocket); overload;
         constructor Create(aOwner: TObject; aSocket: TuSocket; aIP: String); overload;
         destructor Destroy; override;

         procedure Send(const aP: TuPacket);

         property Socket         : TuSocket read FSocket;
         property IP             : String   read FIP;
         property Port           : U_SHORT   read FPort;
         property Name           : String   read FName     write FName;
   end;

implementation

{ TuTCPRemoteClient }

uses uTCPServer;

///////////////////////////////////////////////////////////////////////////////
//// Construction/Initalization
///////////////////////////////////////////////////////////////////////////////

constructor TuTCPRemoteClient.Create(aOwner: TObject; aSocket: TuSocket);
begin
   FOwner  := aOwner;
   FSocket := aSocket;
   FJoined := Now;
   FIP     := TuSocket.IpFromASocket(aSocket.Get);
   FPort   := TuSocket.PortFromASocket(aSocket.Get);
   FName   := 'aUser.... <change your name>';
end;

constructor TuTCPRemoteClient.Create(aOwner: TObject; aSocket: TuSocket; aIP: String);
begin
   FOwner  := aOwner;
   FSocket := aSocket;
   FJoined := Now;
   FIP     := aIP;
   FPort   := TuSocket.PortFromASocket(aSocket.Get);
   FName   := 'aUser.... <change your name>';
end;

///////////////////////////////////////////////////////////////////////////////
//// Other
///////////////////////////////////////////////////////////////////////////////

procedure TuTCPRemoteClient.Send(const aP: TuPacket);
begin
    FSocket.Send(aP.Parse, FIP, FPort);
end;

///////////////////////////////////////////////////////////////////////////////
//// Deconstruction
///////////////////////////////////////////////////////////////////////////////

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