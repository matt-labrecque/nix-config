vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local spec, kind = ev.data.spec, ev.data.kind
    if spec.name == 'markdown-preview.nvim' and (kind == 'install' or kind == 'update') then
      if not ev.data.active then vim.cmd.packadd('markdown-preview.nvim') end
      vim.fn['mkdp#util#install']()
    end
  end,
})

vim.pack.add({
		'https://github.com/rebelot/kanagawa.nvim',
		'https://github.com/MeanderingProgrammer/render-markdown.nvim',
		'https://github.com/sammaji/markdown-preview.nvim',
		'https://github.com/neovim/nvim-lspconfig',
		'https://github.com/folke/snacks.nvim',
})

-- Set color scheme to Kanagawa
vim.cmd.colorscheme('kanagawa')

-- Activate remaining plugins
require('render-markdown').setup()
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
