# Home Manager settings for every machine.
# home.username and home.homeDirectory come from users.users.<name>
# via the nix-darwin / NixOS Home Manager module.
{ pkgs, ... }:
{
  imports = [
    ./shell.nix
    ./neovim.nix
  ];

  home.packages = with pkgs; [
    btop
    fd
    ripgrep
    tree
  ];

  home.sessionVariables.EDITOR = "nvim";

  # Read the Home Manager release notes before changing this value
  home.stateVersion = "26.05";
}
