unit uNetManager;

interface

uses
  System.SysUtils,
  System.Classes,
  uTCPClient,
  uTCPServer,
  uUDPNode;

type
  TNetManager = class
    private
      FUDP: TuUDPNode;
      FTCPClient: TuTCPClient;
      FTCPServer: TuTCPServer;

      procedure OnTCPMessage();
      procedure OnUDPMessage();
    public
      constructor Create;
      destructor Destroy; override;

      procedure InitUDP(const aPort: Integer);
      procedure StartHub(const aPort: Integer);
      procedure ConnectToHub(const aIP: String; const aPort: Integer);

      property UDP: TuUDPNode read FUDP;
      property TCPClient: TuTCPClient read FTCPClient;
      property TCPServer: TuTCPServer read FTCPServer;
  end;

var
  NetMgr: TNetManager;

implementation



initialization
  NetMgr := TNetManager.Create;

finalization
  NetMgr.Free;

end.
