# Git over SSH uses the system sshd (tailnet-only, machines/homelab.nix):
# git@git.<domain>:<owner>/<repo>.git
{ config, ... }:
let
  host = "git.${config.homelab.domain}";
  port = 3001;
in
{
  services.forgejo = {
    enable = true;
    settings.server = {
      DOMAIN = host;
      ROOT_URL = "https://${host}/";
      HTTP_ADDR = "127.0.0.1";
      HTTP_PORT = port;
    };
  };

  services.caddy.virtualHosts.${host}.extraConfig = ''
    import tailnet
    reverse_proxy 127.0.0.1:${toString port}
  '';
}
