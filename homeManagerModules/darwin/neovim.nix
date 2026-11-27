# Mac-only additions to homeManagerModules/shared/neovim.nix
{
  config,
  configDir,
  pkgs,
  ...
}:
{
  # Linked from the checkout so vim.pack writes nvim-pack-lock.json back into
  # the repo and Lua edits apply without a rebuild
  xdg.configFile."nvim" = {
    source = config.lib.file.mkOutOfStoreSymlink "${configDir}/homeManagerModules/shared/nvim";
    recursive = false;
  };

  programs.neovim.extraPackages = with pkgs; [
    websocat
  ];
}
