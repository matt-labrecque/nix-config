# Sonarr, Radarr, Prowlarr, Bazarr, and qBittorrent. Everything that writes
# to the library runs in the media group (media.nix).
# qBittorrent prints a temporary WebUI password to its journal on first start.
{ config, lib, ... }:
let
  inherit (config.homelab) domain dataRoot;
  vhost = name: port: {
    "${name}.${domain}".extraConfig = ''
      import tailnet
      reverse_proxy 127.0.0.1:${toString port}
    '';
  };
in
{
  imports = [ ./media.nix ];

  services.sonarr = {
    enable = true;
    group = "media";
  };

  services.radarr = {
    enable = true;
    group = "media";
  };

  services.bazarr = {
    enable = true;
    group = "media";
  };

  services.prowlarr.enable = true;

  services.qbittorrent = {
    enable = true;
    group = "media";
    serverConfig.BitTorrent.Session.DefaultSavePath = "${dataRoot}/media/downloads";
  };

  services.caddy.virtualHosts = lib.mkMerge [
    (vhost "sonarr" 8989)
    (vhost "radarr" 7878)
    (vhost "prowlarr" 9696)
    (vhost "bazarr" config.services.bazarr.listenPort)
    (vhost "qbittorrent" config.services.qbittorrent.webuiPort)
  ];
}
