# Settings common to every NixOS machine (homelab)
{
  pkgs,
  inputs,
  username,
  ...
}:
{
  imports = [
    inputs.home-manager-stable.nixosModules.home-manager
    inputs.agenix.nixosModules.default
  ];

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIeEZKXAJ0We9NYwQmC4fENGXcwio4B++M7iWWwkn2qD mheenan@Matts-MacBook-Air.local"
    ];
  };

  # The user has no password; SSH key auth is the only way in
  security.sudo.wheelNeedsPassword = false;

  home-manager.users.${username} = ../../homeManagerModules/shared;
}
