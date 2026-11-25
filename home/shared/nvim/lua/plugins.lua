vim.pack.add({
		'https://github.com/rebelot/kanagawa.nvim',
		'https://github.com/nvim-mini/mini.nvim',
		'https://github.com/m4xshen/autoclose.nvim',
		'https://github.com/MeanderingProgrammer/render-markdown.nvim',
		'https://github.com/neovim/nvim-lspconfig',
})

-- Set color scheme to Kanagawa
vim.cmd.colorscheme('kanagawa')

-- Activate remaining plugins
require('autoclose').setup()
require('render-markdown').setup()
