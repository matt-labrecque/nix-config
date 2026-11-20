# Values shared by the homelab service modules in this directory
{ lib, ... }:
{
  options.homelab = {
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Base domain. Services are served on the tailnet at <name>.<domain>, the dashboard at <domain>.";
    };

    dataRoot = lib.mkOption {
      type = lib.types.str;
      default = "/srv";
      description = "Root directory for media, photos, documents, and synced files.";
    };

    tailscaleIPv4 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        The homelab's Tailscale IPv4 address (`tailscale ip -4`). When set,
        AdGuard Home answers <domain> and *.<domain> with it.
      '';
    };
  };
}
