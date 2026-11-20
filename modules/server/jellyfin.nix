{ config, ... }:
{
  imports = [ ./media.nix ];

  services.jellyfin.enable = true;
  users.users.jellyfin.extraGroups = [ "media" ];

  services.caddy.virtualHosts."jellyfin.${config.homelab.domain}".extraConfig = ''
    import tailnet
    reverse_proxy 127.0.0.1:8096
  '';
}
