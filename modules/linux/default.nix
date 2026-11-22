# Settings common to every NixOS machine (vps, homelab)
{ pkgs, username, ... }:
{
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    # TODO: This should be secret through agenix
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIeEZKXAJ0We9NYwQmC4fENGXcwio4B++M7iWWwkn2qD mheenan@Matts-MacBook-Air.local"
    ];
  };

  # The user has no password; SSH key auth is the only way in
  security.sudo.wheelNeedsPassword = false;
}
