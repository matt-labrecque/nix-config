-- Plain Lua config: drop this directory into ~/.config/nvim on any system with
-- Neovim 0.12+ and git. Plugins and their setup are in lua/config/, loaded at
-- the end.

-- Treesitter highlighting for every filetype with an installed parser;
-- the rest keep regex highlighting.
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

-- Format on save with any attached server that supports formatting.
-- Servers handling willSaveWaitUntil already edit the buffer on save.
local lsp_format = vim.api.nvim_create_augroup('lsp_format_on_save', {})
vim.api.nvim_create_autocmd('LspAttach', {
  group = lsp_format,
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    if client:supports_method('textDocument/willSaveWaitUntil')
        or not client:supports_method('textDocument/formatting') then
      return
    end
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = lsp_format,
      buffer = args.buf,
      callback = function()
        vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
      end,
    })
  end,
})

-- Custom Keybinds
vim.keymap.set('n', '<leader>ff', '<cmd>Pick files<cr>',     { desc = 'Find files' })
vim.keymap.set('n', '<leader>fg', '<cmd>Pick grep_live<cr>', { desc = 'Live grep' })
vim.keymap.set('n', '<leader>fb', '<cmd>Pick buffers<cr>',   { desc = 'Buffers' })
vim.keymap.set('n', '<leader>fh', '<cmd>Pick help<cr>',      { desc = 'Help tags' })
vim.keymap.set('n', '<leader>fr', '<cmd>Pick resume<cr>',    { desc = 'Resume last picker' })
vim.keymap.set('n', '<leader>e', function() MiniFiles.open(vim.api.nvim_buf_get_name(0)) end, { desc = 'Explorer (current file)' })
vim.keymap.set('n', '<leader>E', function() MiniFiles.open(vim.uv.cwd()) end, { desc = 'Explorer (cwd)' })

-- Additional customization
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.smartcase = true
vim.opt.tabstop = 4
vim.opt.smoothscroll = true
vim.opt.termguicolors = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.textwidth = 80
vim.opt.colorcolumn = "80"
vim.opt.showmode = false
vim.opt.cmdheight = 1

require('config.plugins')
require('config.obsidian')
