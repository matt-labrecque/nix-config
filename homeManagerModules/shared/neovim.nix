# Neovim binary and the tools its config needs. nvim/ is plain Lua that
# installs its own plugins with vim.pack, so it works unchanged outside Nix.
# homeManagerModules/darwin/neovim.nix links it from the checkout instead of the store.
{ lib, pkgs, ... }:
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
    ++ lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.gcc;
  };

  # Store copy for machines without a checkout. Recursive, so ~/.config/nvim
  # is a real directory where vim.pack can write its lockfile; the repo's copy
  # is left out because a store symlink is read-only (servers install the
  # latest plugin revisions instead of the pinned ones)
  xdg.configFile."nvim" = {
    source = lib.mkDefault (
      builtins.path {
        name = "nvim-config";
        path = ./nvim;
        filter = path: _: baseNameOf path != "nvim-pack-lock.json";
      }
    );
    recursive = lib.mkDefault true;
  };
}
