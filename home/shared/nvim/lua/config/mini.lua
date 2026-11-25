vim.pack.add({'https://github.com/nvim-mini/mini.nvim'})

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

