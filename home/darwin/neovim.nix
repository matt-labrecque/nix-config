# Mac-only additions to home/shared/neovim.nix
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
    source = config.lib.file.mkOutOfStoreSymlink "${configDir}/home/shared/nvim";
    recursive = false;
  };

  programs.neovim.extraPackages = with pkgs; [
    # Used by typst-preview instead of its own downloads
    tinymist
    websocat
    # `ob`, the CLI obsidian.nvim's sync backend runs (not the desktop
    # app's `obsidian` CLI); unstable-only, hence not in the shared module
    obsidian-headless
  ];
}
