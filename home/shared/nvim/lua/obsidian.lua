vim.pack.add('https://github.com/obsidian-nvim/obsidian.nvim')

local vault = vim.fs.normalize('~/Documents/zettelkasten')
if vim.fn.isdirectory(vault) == 0 then
  return
end

require('obsidian').setup({
  legacy_commands = false,
  picker = { name = 'mini.pick' },
  workspaces = {
    { name = 'zettelkasten', path = vault },
  },
  -- Vault convention: Inbox/YYYYMMDDHHMM-kebab-case-title.md
  notes_subdir = 'Inbox',
  new_notes_location = 'notes_subdir',
  note_id_func = function(title)
    local id = os.date('%Y%m%d%H%M')
    if title ~= nil and vim.trim(title) ~= '' then
      id = id .. '-' .. require('obsidian.builtin').title_to_slug(title)
    end
    return id
  end,
  -- Templates own the frontmatter; don't inject id/aliases or re-sort keys
  frontmatter = { enabled = false },
  templates = { folder = '_Metadata/templates' },
  daily_notes = {
    folder = 'Output/daily-notes',
    template = 'daily.md',
  },
  unique_note = { format = 'YYYYMMDDHHmm' },
  -- Sync needs the `ob` CLI (obsidian-headless; on the Mac via
  -- home/darwin/neovim.nix); without it the plugin prompts an npm install
  sync = { enabled = vim.fn.executable('ob') == 1 },
})
