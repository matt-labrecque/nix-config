# Values shared by the homelab service modules in this directory
{ lib, ... }:
{
  options.homelab = {
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Base domain. Tailnet services are served at <name>.<domain>.";
    };

    dataRoot = lib.mkOption {
      type = lib.types.str;
      default = "/srv";
      description = "Root directory for user data: media, photos, and Nextcloud files.";
    };

    services = lib.mkOption {
      type = lib.types.attrsOf lib.types.port;
      default = { };
      example = {
        jellyfin = 8096;
      };
      description = ''
        Tailnet services keyed by subdomain. caddy.nix gives each a
        tailnet-only vhost on <name>.<domain> proxying to 127.0.0.1:<port>.
      '';
    };
  };
}
