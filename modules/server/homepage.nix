# Dashboard at https://<domain>, linking every tailnet service
{ config, ... }:
let
  inherit (config.homelab) domain;
  port = 8082;
  link = name: sub: { ${name}.href = "https://${sub}.${domain}"; };
in
{
  services.homepage-dashboard = {
    enable = true;
    listenPort = port;
    allowedHosts = domain;
    services = [
      {
        Media = [
          (link "Jellyfin" "jellyfin")
        ];
      }
      {
        Downloads = [
          (link "Sonarr" "sonarr")
          (link "Radarr" "radarr")
          (link "Prowlarr" "prowlarr")
          (link "Bazarr" "bazarr")
          (link "qBittorrent" "qbittorrent")
        ];
      }
      {
        Apps = [
          (link "Nextcloud" "nextcloud")
          (link "Vaultwarden" "vault")
          (link "Paperless" "paperless")
          (link "Forgejo" "git")
          (link "FreshRSS" "rss")
          (link "Syncthing" "sync")
        ];
      }
      {
        Infrastructure = [
          (link "AdGuard Home" "adguard")
          (link "Grafana" "grafana")
          (link "Prometheus" "prometheus")
        ];
      }
    ];
  };

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    import tailnet
    reverse_proxy 127.0.0.1:${toString port}
  '';
}
