# Mac-only additions to the shared neovim wrapper (home/shared/neovim.nix)
{
  wrappers.neovim =
    { pkgs, ... }:
    {
      specs.typst-preview = {
        data = pkgs.vimPlugins.typst-preview-nvim;
        # tinymist and websocat are on nvim's PATH, so skip the plugin's download
        config = ''
          require('typst-preview').setup({
            dependencies_bin = { tinymist = 'tinymist', websocat = 'websocat' },
            -- Absolute imports ("/_Metadata/lib/lecture.typ") resolve against
            -- the root; the vault has no typst.toml or .git, so the default
            -- would pick the file's own folder. Fall back to the vault root.
            get_root = function(main_file)
              local path = vim.fn.fnamemodify(main_file, ':p')
              return os.getenv('TYPST_ROOT')
                or vim.fs.root(path, { 'typst.toml', '.git', '.obsidian' })
                or vim.fs.dirname(path)
            end,
          })
        '';
      };


      runtimePkgs = with pkgs; [
        tinymist
        websocat
        # `ob`, the CLI obsidian.nvim's sync backend runs (not the desktop
        # app's `obsidian` CLI); unstable-only, hence not in the shared spec
        obsidian-headless
      ];
    };
}
