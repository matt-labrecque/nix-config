-- General customization shit
vim.o.number = true
vim.o.relativenumber = true
vim.o.swapfile = false
vim.o.smoothscroll = true
vim.o.showmode = false
vim.o.tabstop = 2
vim.o.textwidth = 80
vim.o.colorcolumn = "80"

-- Add plugins from Git
vim.pack.add({
		'https://github.com/rebelot/kanagawa.nvim',
		'https://github.com/neovim/nvim-lspconfig',
    'https://github.com/nvim-mini/mini.nvim',
		'https://github.com/chomosuke/typst-preview.nvim',
})

-- Set color scheme to Kanagawa
vim.cmd.colorscheme('kanagawa')

-- Enable plugins
require('mini.icons').setup()
require('mini.starter').setup()
require('mini.statusline').setup({
  content = {
    -- Section layout of mini's default bar: mode-coloured ends,
    -- Devinfo-coloured inner blocks, Filename-coloured fill
    active = function()
      local _, mode_hl = MiniStatusline.section_mode({})
      local icon = MiniIcons.get('filetype', vim.bo.filetype)
      local git = vim.b.minigit_summary
      local branch = (git and git.head_name) and (' ' .. git.head_name) or ''
      -- %p puts line 1 at 1%; this makes the first line 0%
      local line, last = vim.fn.line('.'), vim.fn.line('$')
      local percent = last > 1 and math.floor((line - 1) * 100 / (last - 1)) or 0
      return MiniStatusline.combine_groups({
        { hl = mode_hl, strings = { icon, '%t', vim.bo.modified and '●' or '' } },
        { hl = 'MiniStatuslineDevinfo', strings = { branch } },
        '%<',
        { hl = 'MiniStatuslineFilename', strings = {} },
        '%=',
        { hl = 'MiniStatuslineDevinfo', strings = { percent .. '%%' } },
        { hl = mode_hl, strings = { '%l:' .. vim.fn.charcol('.') } },
      })
    end,
  },
})
require('mini.files').setup()
require('mini.pick').setup()
require('mini.git').setup()
require('mini.diff').setup()
require('mini.completion').setup()
require('mini.pairs').setup()
require('typst-preview').setup({
  -- Binaries on PATH win over the plugin's own download (nil = download)
  dependencies_bin = {
    tinymist = vim.fn.executable('tinymist') == 1 and 'tinymist' or nil,
    websocat = vim.fn.executable('websocat') == 1 and 'websocat' or nil,
  },
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
