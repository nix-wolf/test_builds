unit uSocket;

interface

uses
   uNetworkTypes,
   System.SysUtils,
   System.Rtti,
   Winapi.Winsock2;

type
   TuSocket = class
      private
         FSocket : Winapi.Winsock2.TSocket;
      public
         constructor Create(aProtocol: TuNetProtocol);
         destructor Destroy; override;

         procedure Start;
   end;


implementation

{ TuSocket }

///////////////////////////////////////////////////////////////////////////////
//// Construction/Initalization
///////////////////////////////////////////////////////////////////////////////

constructor TuSocket.Create(aProtocol: TuNetProtocol);
begin
   with Winapi.Winsock2 do begin
      case aProtocol of
         npTCP : begin
            FSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
         end; {npTCP}
         npUDP : begin
            FSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);


         end; {npUDP}
      end; {CASE}
   end; {WITH}
end;

///////////////////////////////////////////////////////////////////////////////
//// Deconstruction
///////////////////////////////////////////////////////////////////////////////

destructor TuSocket.Destroy;
begin

  inherited;
end;

end.
