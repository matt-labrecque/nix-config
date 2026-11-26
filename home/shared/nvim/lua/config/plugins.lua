vim.pack.add({
		'https://github.com/rebelot/kanagawa.nvim',
		'https://github.com/neovim/nvim-lspconfig',
		'https://github.com/folke/snacks.nvim',
})

-- Set color scheme to Kanagawa
vim.cmd.colorscheme('kanagawa')

-- Activate remaining plugins
require('snacks').setup ({ 
    image = {
				enabled = true,
				doc = {
								enabled = true, 
								inline = true, 
								float = true
				},
		},
})
