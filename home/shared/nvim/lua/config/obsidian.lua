vim.pack.add({'https://github.com/obsidian-nvim/obsidian.nvim'})

local function zk_root()
  if vim.env.ZETTK_DIR and vim.env.ZETTK_DIR ~= '' then
    return vim.fs.normalize(vim.env.ZETTK_DIR)
  end
  local config_home = vim.env.XDG_CONFIG_HOME or vim.fs.joinpath(vim.env.HOME, '.config')
  local file = vim.fs.joinpath(config_home, 'zettk', 'config.json')
  if vim.uv.fs_stat(file) then
    local ok, cfg = pcall(vim.json.decode, table.concat(vim.fn.readfile(file), '\n'))
    if ok and type(cfg) == 'table' and type(cfg.dir) == 'string' and cfg.dir ~= '' then
      return vim.fs.normalize(cfg.dir)
    end
  end
  return vim.fs.normalize('~/Documents/zettelkasten')
end

-- setup() errors when no workspace exists, e.g. on machines without the vault
local vault = zk_root()
if vim.fn.isdirectory(vault) == 0 then
  return
end

require('obsidian').setup({
  legacy_commands = false,
  picker = { name = 'mini.pick' },
  workspaces = {
    { name = 'zettelkasten', path = vault },
  },
  -- Vault convention: Inbox/YYYYMMDDHHMM-kebab-case-title.md (zk new uses the
  -- same slug rules as title_to_slug)
  notes_subdir = 'Inbox',
  new_notes_location = 'notes_subdir',
  note_id_func = function(title)
    local id = os.date('%Y%m%d%H%M')
    if title ~= nil and vim.trim(title) ~= '' then
      id = id .. '-' .. require('obsidian.builtin').title_to_slug(title)
    end
    return id
  end,
  -- New notes use the vault's note template (as zk and the app's zk-prefixer
  -- do) instead of the plugin's id/aliases default.
  note = { template = 'note.md' },
  -- Templates own the frontmatter; don't inject id/aliases or re-sort keys
  frontmatter = { enabled = false },
  templates = {
    folder = '_Metadata/templates',
    -- `zk new -t input` puts reference notes in Input/
    customizations = { input = { notes_subdir = 'Input' } },
  },
  daily_notes = {
    folder = 'Output/daily-notes',
    template = 'daily.md',
  },
  unique_note = { format = 'YYYYMMDDHHmm', folder = 'Inbox' },
  -- Same folder as the Obsidian app's attachmentFolderPath
  attachments = { folder = '_Metadata/attachments' },
  -- Sync needs the `ob` CLI (obsidian-headless; on the Mac via
  -- home/darwin/neovim.nix); without it the plugin prompts an npm install
  sync = { enabled = vim.fn.executable('ob') == 1 },
})
