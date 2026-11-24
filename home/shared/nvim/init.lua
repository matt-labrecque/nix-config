-- Plugins and their setup come from Nix (home/shared/neovim.nix and
-- home/darwin/neovim.nix). Their configuration runs after this file.

-- Treesitter highlighting; the plugin and grammars come from Nix.
-- Filetypes without a grammar keep regex highlighting.
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
vim.keymap.set('n', '<bs>', ':edit #<cr>', { silent = true })
vim.keymap.set('n', '<leader>t', '<cmd>Telescope fd<cr>', {desc = "Open Telescope"})
vim.keymap.set('n', '<leader>s', '<cmd>Markview splitToggle<cr>', { desc = 'Toggle markview splitview' })
vim.keymap.set('n', '<leader>f', '<cmd>lua MiniFiles.open()<cr>', {desc = "Open MiniFiles"})

-- Additional customization
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.smartcase = true
vim.opt.tabstop = 4
vim.opt.swapfile = false
vim.opt.smoothscroll = true
vim.opt.termguicolors = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.textwidth = 80
vim.opt.colorcolumn = "80"
vim.opt.showmode = false
vim.opt.showcmd = false
