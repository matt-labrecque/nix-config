{ config, pkgs, ... }:
let
  hostName = "nextcloud.${config.homelab.domain}";
  port = 8081;
in
{
  # Uncomment once the homelab's host key is in secrets/secrets.nix and the
  # file is encrypted (`agenix -e nextcloud-admin.age`).
  # age.secrets.nextcloud-admin = {
  #   file = ../../secrets/nextcloud-admin.age;
  #   owner = "nextcloud";
  # };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud35;
    inherit hostName;
    # Generate https:// URLs; TLS terminates at Caddy
    https = true;
    datadir = "${config.homelab.dataRoot}/nextcloud";
    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      adminpassFile = "/run/agenix/nextcloud-admin";
    };
    settings.trusted_proxies = [
      "127.0.0.1"
      "::1"
    ];
  };

  # The module serves Nextcloud through nginx; keep nginx off Caddy's ports
  services.nginx.virtualHosts.${hostName}.listen = [
    {
      addr = "127.0.0.1";
      inherit port;
    }
  ];

  homelab.services.nextcloud = port;
}
