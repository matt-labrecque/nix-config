# Entry point for the homelab: module imports and the Home Manager modules the
# homelab user gets.
{ inputs, username, ... }:
{
  imports = [
    inputs.home-manager-stable.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    ./nix/settings.nix
    ./nixos/user.nix
  ];

  home-manager.users.${username}.imports = [
    ./home-manager/home.nix
    ./home-manager/shell.nix
    ./home-manager/neovim.nix
  ];
}
