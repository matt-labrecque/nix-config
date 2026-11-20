{ config, ... }:
let
  host = "paperless.${config.homelab.domain}";
in
{
  # Admin password (`agenix -e paperless-admin.age`)
  # age.secrets.paperless-admin = {
  #   file = ../../secrets/paperless-admin.age;
  #   owner = "paperless";
  # };

  services.paperless = {
    enable = true;
    address = "127.0.0.1";
    mediaDir = "${config.homelab.dataRoot}/documents";
    passwordFile = "/run/agenix/paperless-admin";
    settings.PAPERLESS_URL = "https://${host}";
  };

  services.caddy.virtualHosts.${host}.extraConfig = ''
    import tailnet
    reverse_proxy 127.0.0.1:${toString config.services.paperless.port}
  '';
}
