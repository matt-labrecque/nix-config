# PLACEHOLDER so `nix flake check` can evaluate nixosConfigurations.homelab.
# Not a real machine description: do not deploy with it. Replace this file
# with the output of `nixos-generate-config` on the homelab, then set a real
# boot loader in machines/homelab.nix (generated files don't include one).
{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  boot.loader.grub.devices = [ "nodev" ];
}
