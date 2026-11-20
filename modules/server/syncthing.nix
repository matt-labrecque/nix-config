{ config, ... }:
{
  services.syncthing = {
    enable = true;
    dataDir = "${config.homelab.dataRoot}/syncthing";
    guiAddress = "127.0.0.1:8384";
  };

  # Sync and local discovery, tailnet only
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [
      22000
      21027
    ];
  };

  # The GUI rejects requests whose Host header isn't localhost
  services.caddy.virtualHosts."sync.${config.homelab.domain}".extraConfig = ''
    import tailnet
    reverse_proxy 127.0.0.1:8384 {
      header_up Host {upstream_hostport}
    }
  '';
}
