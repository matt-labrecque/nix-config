# Neovim via nix-wrapper-modules. Plugins come from pkgs.vimPlugins (pinned by
# flake.lock); nvim/init.lua holds options, keymaps, and autocmds and runs
# before the spec configs below. Every Lua edit needs a rebuild.
# home/darwin/neovim.nix extends this with Mac-only specs.
{ inputs, ... }:
{
  imports = [ inputs.wrappers.homeModules.neovim ];

  wrappers.neovim =
    { pkgs, ... }:
    {
      enable = true;
      settings.config_directory = ./nvim;

      # No plugin uses remote providers; the hosts would add node, python3,
      # and ruby (plus clang and the Apple SDK on darwin) to the closure
      hosts.node.nvim-host.enable = false;
      hosts.python3.nvim-host.enable = false;
      hosts.ruby.nvim-host.enable = false;

      specs = {
        kanagawa = {
          data = pkgs.vimPlugins.kanagawa-nvim;
          config = "vim.cmd.colorscheme('kanagawa')";
        };

        # lualine's automatic theme follows the active colorscheme
        lualine = {
          data = pkgs.vimPlugins.lualine-nvim;
          after = [ "kanagawa" ];
          config = "require('lualine').setup()";
        };

        mini = {
          data = pkgs.vimPlugins.mini-nvim;
          config = "require('mini.starter').setup()";
        };

        oil = {
          data = pkgs.vimPlugins.oil-nvim;
          config = "require('oil').setup()";
        };

        autoclose = {
          data = pkgs.vimPlugins.autoclose-nvim;
          config = "require('autoclose').setup()";
        };

        # Splitview (edit left, preview right): <leader>s, mapped in nvim/init.lua
        markview = {
          data = pkgs.vimPlugins.markview-nvim;
          config = "require('markview').setup()";
        };

        # markview on the runtimepath makes obsidian.nvim skip its own UI
        obsidian = {
          data = pkgs.vimPlugins.obsidian-nvim;
          config = ''
            require('obsidian').setup({
              legacy_commands = false,
              picker = { name = 'telescope.nvim' },
              workspaces = {
                { name = 'zettelkasten', path = '~/Documents/zettelkasten' },
              },
              -- Vault convention: Inbox/YYYYMMDDHHMM-kebab-case-title.md
              notes_subdir = 'Inbox',
              new_notes_location = 'notes_subdir',
              note_id_func = function(title)
                local id = os.date('%Y%m%d%H%M')
                if title ~= nil and vim.trim(title) ~= ''' then
                  id = id .. '-' .. require('obsidian.builtin').title_to_slug(title)
                end
                return id
              end,
              -- Templates own the frontmatter; don't inject id/aliases or re-sort keys
              frontmatter = { enabled = false },
              templates = { folder = '_Metadata/templates' },
              daily_notes = {
                folder = 'Output/daily-notes',
                template = 'daily.md',
              },
              unique_note = { format = 'YYYYMMDDHHmm' },
              -- `ob` is only on PATH on the Mac (home/darwin/neovim.nix);
              -- without it the plugin prompts an npm install into the store
              sync = { enabled = vim.fn.executable('ob') == 1 },
            })
          '';
        };

        telescope = [
          pkgs.vimPlugins.plenary-nvim
          pkgs.vimPlugins.telescope-nvim
        ];

        nvim-web-devicons = pkgs.vimPlugins.nvim-web-devicons;

        # Language servers are enabled only inside Nix shells that provide them
        lspconfig = {
          data = pkgs.vimPlugins.nvim-lspconfig;
          config = ''
            if vim.env.IN_NIX_SHELL ~= nil then
              if vim.fn.executable('gopls') == 1 then
                vim.lsp.enable('gopls')
              end
              if vim.fn.executable('pyright-langserver') == 1 then
                vim.lsp.enable('pyright')
              end
            end
          '';
        };

        # Grammars are prebuilt, so no compiler is needed at runtime, and the
        # queries always match the parser versions
        treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (
          p: with p; [
            bash
            c
            css
            diff
            gitcommit
            go
            gomod
            gosum
            html
            javascript
            json
            julia
            lua
            markdown
            markdown_inline
            nix
            python
            query
            r
            regex
            rust
            toml
            tsx
            typescript
            typst
            vim
            vimdoc
            yaml
          ]
        );
      };
    };
}
