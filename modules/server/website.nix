# Public static Astro site on mlabrecque.dev (forward 80 and 443 on the router).
# Built outside Nix; deploy the build output with
#   rsync -a --delete dist/ homelab:/var/www/mlabrecque.dev/
# The site owns every path except /.well-known/matrix/*, which tuwunel.nix
# adds to the same vhost.
{ username, ... }:
let
  domain = "mlabrecque.dev";
  root = "/var/www/${domain}";
in
{
  systemd.tmpfiles.settings."10-website".${root}.d = {
    user = username;
    group = "users";
    mode = "0755";
  };

  services.caddy = {
    enable = true;
    virtualHosts.${domain}.extraConfig = ''
      handle {
        root * ${root}
        encode zstd gzip
        file_server
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
