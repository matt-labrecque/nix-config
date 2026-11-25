-- General customization shit
vim.o.number = true
vim.o.relativenumber = true
vim.o.swapfile = false
vim.o.tabstop = 4
vim.o.smoothscroll = true
vim.o.textwidth = 80
vim.o.colorcolumn = "80"
vim.o.showmode = false

-- Import plugin files. Namespaced under config/ so they don't shadow the
-- plugins' own modules (require('obsidian') would load this file instead).
require('config.plugins')
require('config.mini')
require('config.obsidian')
require('config.typst-preview')

-- Keymappings
vim.keymap.set('n', '<leader>ff', '<cmd>Pick files<cr>',     { desc = 'Find files' })
vim.keymap.set('n', '<leader>fg', '<cmd>Pick grep_live<cr>', { desc = 'Live grep' })
vim.keymap.set('n', '<leader>fb', '<cmd>Pick buffers<cr>',   { desc = 'Buffers' })
vim.keymap.set('n', '<leader>fh', '<cmd>Pick help<cr>',      { desc = 'Help tags' })
vim.keymap.set('n', '<leader>fr', '<cmd>Pick resume<cr>',    { desc = 'Resume last picker' })
vim.keymap.set('n', '<leader>e', function() MiniFiles.open(vim.api.nvim_buf_get_name(0)) end, { desc = 'Explorer (current file)' })
vim.keymap.set('n', '<leader>E', function() MiniFiles.open(vim.uv.cwd()) end, { desc = 'Explorer (cwd)' })

-- Nix Shell Specific for LSP activation
if vim.env.IN_NIX_SHELL ~= nil or vim.fn.executable('nix') == 0 then
  if vim.fn.executable('gopls') == 1 then
    vim.lsp.enable('gopls')
  end
  if vim.fn.executable('pyright-langserver') == 1 then
    vim.lsp.enable('pyright')
  end
  if vim.fn.executable('clangd') == 1 then
    vim.lsp.enable('clangd')
  end
end
