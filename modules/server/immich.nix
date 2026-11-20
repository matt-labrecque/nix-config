# NOT IMPORTED: nixos-26.05 marks Immich 2.7.5 insecure (no further 2.x
# updates); 3.x ships with NixOS 26.11. Add it back to machines/homelab.nix
# (and the Media group in homepage.nix) once the homelab is on 26.11.
{ config, ... }:
{
  services.immich = {
    enable = true;
    mediaLocation = "${config.homelab.dataRoot}/photos";
  };

  services.caddy.virtualHosts."immich.${config.homelab.domain}".extraConfig = ''
    import tailnet
    reverse_proxy 127.0.0.1:${toString config.services.immich.port}
  '';
}
