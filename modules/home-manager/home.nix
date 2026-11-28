# Home Manager settings for every machine; Mac-only settings are in the
# isDarwin block. home.username and home.homeDirectory come from
# users.users.<name> via the nix-darwin / NixOS Home Manager module.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  config = lib.mkMerge [
    {
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

    (lib.mkIf isDarwin {
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
    })
  ];
}
