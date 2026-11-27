{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../shared
    ./shell.nix
    ./git.nix
    ./ghostty.nix
    ./neovim.nix
    ./nix-init.nix
    ./omp.nix
  ];

  home.packages = with pkgs; [
    fastfetch
    ffmpeg
    typst
    tinymist
  ];

  home.sessionPath = [
    "$HOME/go/bin"
    "$HOME/.local/bin" # pipx
    "$HOME/.lmstudio/bin"
    "$HOME/.cargo/bin" # rustup shims
  ];

  home.sessionVariables.OBSIDIAN_VAULT = "${config.home.homeDirectory}/Documents/zettelkasten";

  home.activation.createDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/Development"
  '';

}
