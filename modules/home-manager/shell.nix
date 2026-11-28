# zsh and the CLI tools hooked into it. The Mac-only aliases use configDir,
# which only the Mac passes in, so it must stay inside the isDarwin block.
{
  lib,
  pkgs,
  configDir,
  machine,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  config = lib.mkMerge [
    {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        shellAliases = {
          ll = "ls -l";
          vim = "nvim";
          nv = "nvim";
          cat = "bat";
          grep = "rg";
        };
      };

      programs.starship = {
        enable = true;
        enableZshIntegration = true;
        settings = builtins.fromTOML (builtins.readFile ./starship.toml);
      };

      programs.bat.enable = true;

      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
      };

      # Loads a project's flake devShell on cd when it has `use flake` in .envrc.
      # nix-direnv caches the shell and registers a GC root for it.
      programs.direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };
    }

    (lib.mkIf isDarwin {
      programs.zsh.shellAliases = {
        nrd = "npm run dev";
        cdzk = "cd $HOME/Documents/zettelkasten";
        cdd = "cd $HOME/Development";
        cdh = "cd $HOME/Homework";
        cdnix = "cd ${configDir}";
        nixedit = "nvim ${configDir}";
        rebuild = "sudo darwin-rebuild switch --flake ${configDir}#${machine}";
      };
    })
  ];
}
