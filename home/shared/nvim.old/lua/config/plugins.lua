-- Plugins are installed by vim.pack (needs git) on first start, at the
-- revisions in nvim-pack-lock.json. Update with :lua vim.pack.update()

-- nvim-treesitter's parsers must be rebuilt whenever the plugin changes.
-- Registered before vim.pack.add so it also runs for lockfile installs.
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.spec.name == 'nvim-treesitter' and ev.data.kind == 'update' then
      if not ev.data.active then
        vim.cmd.packadd('nvim-treesitter')
      end
      vim.cmd('TSUpdate')
    end
  end,
})

-- Parsers are built locally, which needs curl, tar, tree-sitter, and a C
-- compiler; without them Neovim's bundled parsers (lua, vim, vimdoc, c,
-- markdown, query) still work. The install is a no-op once done.
if vim.fn.executable('tree-sitter') == 1 and vim.fn.executable('cc') == 1 then
  require('nvim-treesitter').install({
    'bash', 'c', 'css', 'diff', 'gitcommit', 'go', 'gomod', 'gosum', 'html',
    'javascript', 'json', 'julia', 'lua', 'markdown', 'markdown_inline', 'nix',
    'python', 'query', 'r', 'regex', 'rust', 'toml', 'tsx', 'typescript',
    'typst', 'vim', 'vimdoc', 'yaml',
  })
end
