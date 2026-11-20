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
          })
        '';
      };

      runtimePkgs = with pkgs; [
        tinymist
        websocat
      ];
    };
}
