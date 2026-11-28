# Neovim binary and the tools its config needs. nvim/ is plain Lua that
# installs its own plugins with vim.pack, so it works unchanged outside Nix.
# The Mac links it from the checkout (configDir, Mac only) instead of the store.
{
  config,
  configDir,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
in
{
  config = lib.mkMerge [
    {
      programs.neovim = {
        enable = true;
        # Pass HM's provider settings with --cmd; nvim/ owns init.lua
        sideloadInitLua = true;
        # vim.pack clones with git; nvim-treesitter builds parsers with tree-sitter
        # and a C compiler (Xcode's on the Mac; curl and tar come with both OSes)
        extraPackages = [
          pkgs.git
          pkgs.tree-sitter
        ]
        ++ lib.optional isLinux pkgs.gcc;
      };

      # Mac: linked from the checkout so vim.pack writes nvim-pack-lock.json
      # back into the repo and Lua edits apply without a rebuild.
      # Elsewhere: store copy for machines without a checkout. Recursive, so
      # ~/.config/nvim is a real directory where vim.pack can write its
      # lockfile; the repo's copy is left out because a store symlink is
      # read-only (servers install the latest plugin revisions instead of the
      # pinned ones)
      xdg.configFile."nvim" =
        if isDarwin then
          {
            source = config.lib.file.mkOutOfStoreSymlink "${configDir}/modules/home-manager/nvim";
            recursive = false;
          }
        else
          {
            source = builtins.path {
              name = "nvim-config";
              path = ./nvim;
              filter = path: _: baseNameOf path != "nvim-pack-lock.json";
            };
            recursive = true;
          };
    }

    (lib.mkIf isDarwin {
      programs.neovim.extraPackages = with pkgs; [
        websocat
      ];
    })
  ];
}
