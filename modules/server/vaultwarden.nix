{ config, ... }:
let
  host = "vault.${config.homelab.domain}";
  port = 8222;
in
{
  # Environment file with ADMIN_TOKEN=<token> (`agenix -e vaultwarden-env.age`)
  # age.secrets.vaultwarden-env = {
  #   file = ../../secrets/vaultwarden-env.age;
  #   owner = "vaultwarden";
  # };

  services.vaultwarden = {
    enable = true;
    config = {
      DOMAIN = "https://${host}";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = port;
    };
    environmentFile = "/run/agenix/vaultwarden-env";
  };

  services.caddy.virtualHosts.${host}.extraConfig = ''
    import tailnet
    reverse_proxy 127.0.0.1:${toString port}
  '';
}
