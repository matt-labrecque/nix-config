{ config, lib, ... }:
let
  host = "rss.${config.homelab.domain}";
in
{
  # Admin password (`agenix -e freshrss-admin.age`)
  # age.secrets.freshrss-admin = {
  #   file = ../../secrets/freshrss-admin.age;
  #   owner = "freshrss";
  # };

  services.freshrss = {
    enable = true;
    baseUrl = "https://${host}";
    # The module writes the Caddy vhost (php-fpm) itself
    webserver = "caddy";
    virtualHost = host;
    passwordFile = "/run/agenix/freshrss-admin";
  };

  services.caddy.virtualHosts.${host}.extraConfig = lib.mkBefore "import tailnet";
}
