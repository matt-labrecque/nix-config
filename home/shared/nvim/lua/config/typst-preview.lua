vim.pack.add({'https://github.com/chomosuke/typst-preview.nvim'})

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
