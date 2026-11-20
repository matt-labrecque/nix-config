# DNS for the tailnet. In the Tailscale admin console, add a split DNS entry
# for homelab.domain pointing at the homelab's Tailscale IP, and set
# homelab.tailscaleIPv4 so the rewrites below exist.
{ config, lib, ... }:
let
  inherit (config.homelab) domain tailscaleIPv4;
in
{
  services.adguardhome = {
    enable = true;
    host = "127.0.0.1";
    port = 3000;
    # Web UI changes persist; these settings are merged in on every start
    mutableSettings = true;
    settings = {
      # Listens on every interface; the firewall only opens 53 on tailscale0
      dns.bind_hosts = [ "0.0.0.0" ];
      filtering.rewrites = lib.optionals (tailscaleIPv4 != null) [
        {
          inherit domain;
          answer = tailscaleIPv4;
          enabled = true;
        }
        {
          domain = "*.${domain}";
          answer = tailscaleIPv4;
          enabled = true;
        }
      ];
    };
  };

  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

  services.caddy.virtualHosts."adguard.${domain}".extraConfig = ''
    import tailnet
    reverse_proxy 127.0.0.1:${toString config.services.adguardhome.port}
  '';
}
