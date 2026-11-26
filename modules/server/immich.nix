# NOT IMPORTED: nixos-26.05 marks Immich 2.7.5 insecure (no further 2.x
# updates); 3.x ships with NixOS 26.11. Add it back to machines/homelab.nix
# once the homelab is on 26.11.
{ config, ... }:
{
  services.immich = {
    enable = true;
    mediaLocation = "${config.homelab.dataRoot}/photos";
  };

  homelab.services.immich = config.services.immich.port;
}
