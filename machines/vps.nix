{ inputs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.disko.nixosModules.disko
    ./hardware/ovh-vps-disk.nix
    ./hardware/ovh-vps.nix
    ../modules/server/tuwunel.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking.hostName = "ovh-vps";
  networking.useDHCP = true; # OVH VPS IPv4 normally comes via DHCP

  # OVH provides IPv6 statically (no RA/DHCPv6); values from the OpenStack metadata
  # service (169.254.169.254/openstack/latest/network_data.json). The gateway sits
  # outside the /128, so `interface` makes NixOS add an on-link route to it first.
  networking.interfaces.ens3.ipv6.addresses = [
    {
      address = "2604:2dc0:101:200::2a4";
      prefixLength = 128;
    }
  ];
  networking.defaultGateway6 = {
    address = "2604:2dc0:101:200::1";
    interface = "ens3";
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIeEZKXAJ0We9NYwQmC4fENGXcwio4B++M7iWWwkn2qD mheenan@Matts-MacBook-Air.local"
  ];

  system.stateVersion = "26.05"; # DO NOT BUMP TO NEWER VERSION
}
