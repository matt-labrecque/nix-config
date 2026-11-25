# MacBook Air (`macbook-air`)

nix-darwin system plus Home Manager user profile for the MacBook Air. For the
repo layout and how the pieces fit together, see
[monorepo-structure.md](monorepo-structure.md).

## Identity

| Item | Value | Source |
| --- | --- | --- |
| Flake output | `darwinConfigurations.macbook-air` | `flake.nix` |
| Machine file | `machines/macbook-air.nix` | `mkDarwin "macbook-air"` |
| Platform | `aarch64-darwin` | `modules/darwin/default.nix` |
| Hostname | `MattBook` (`networking.hostName`, `localHostName`, `computerName`) | `machines/macbook-air.nix` |
| nixpkgs | `nixpkgs-unstable` | `flake.nix` |
| nix-darwin `system.stateVersion` | `7` | `modules/darwin/default.nix` |
| Home Manager `home.stateVersion` | `26.05` | `home/shared/default.nix` |
| macOS short user | `mlabrecqu` (`system.primaryUser`) | `flake.nix` |
| Home directory | `/Users/mlabrecque` | `flake.nix` |
| Checkout path (`configDir`) | `/Users/mlabrecque/Development/nix-config` | `flake.nix` |

The checkout must be at `configDir`. The `rebuild` and `vps-sync` aliases,
`cdnix`, and `nix-init` all use that absolute path.

Output names do not match hostnames. Always pass the output name explicitly:
`#macbook-air`.

## Modules

Imported by `mkDarwin` in this order:

| Module | Purpose |
| --- | --- |
| `modules/shared` | `allowUnfree`, flakes, `trusted-users`, `nix.optimise`, `nix.gc` (30 days), zsh |
| `modules/darwin` | Host platform, fonts, agenix CLI, `system.defaults`, Homebrew import |
| `modules/darwin/homebrew.nix` | Homebrew casks (see below) |
| `machines/macbook-air.nix` | Hostname only |
| agenix darwin module | `age.secrets` on the system level (not used directly on this Mac) |
| home-manager darwin module | Runs `home/darwin` as user `mlabrecqu` |

Home Manager for this user imports `home/darwin/default.nix`, which imports
`home/shared` and the Mac-only files below.

## System configuration

- **Nix:** flakes and `nix-command` enabled; `trusted-users` is the user; store
  optimisation runs automatically; garbage collection runs automatically and
  deletes generations older than 30 days.
- **Shell:** `programs.zsh.enable = true` (system).
- **Fonts:** `nerd-fonts.caskaydia-cove`.
- **Defaults:** Press and Hold disabled (`NSGlobalDomain.ApplePressAndHoldEnabled = false`).
- **agenix CLI:** installed system-wide for editing `secrets/`.
- **Revision:** `system.configurationRevision` is set to the flake's git revision.

## Homebrew

nix-darwin runs `brew bundle` but does not install Homebrew. Install Homebrew
before the first switch.

`onActivation`: `autoUpdate = false`, `upgrade = false`, `cleanup = "zap"`.

**`cleanup = "zap"` removes every cask not declared in
`modules/darwin/homebrew.nix` on each switch, including its preferences and
support files.** Install GUI apps through the file, not by hand.

Declared casks (15):

`anki`, `balenaetcher`, `claude`, `element`, `ghostty`, `gimp`,
`helium-browser`, `musicbrainz-picard`, `prismlauncher`, `qbittorrent`,
`rectangle`, `rstudio`, `steam`, `tailscale-app`, `vesktop`

Taps and brews lists are empty.

## Home Manager configuration

Shared (`home/shared`, applies to every Home Manager user in this repo):

- Packages: `btop`, `fd`, `ripgrep`, `tree`.
- `EDITOR=nvim`.
- zsh with completion, autosuggestions, and syntax highlighting. Aliases:
  `ll`, `vim`/`nv` → `nvim`, `cat` → `bat`, `grep` → `rg`.
- Starship prompt from `home/starship.toml`.
- `bat`, `fzf` (zsh integration), `direnv` with `nix-direnv`.
- Neovim (see below).

Mac-only (`home/darwin`):

- Packages: `fastfetch`, `ffmpeg`, `tmux`, and the `nix-init` script.
- `sessionPath`: `~/go/bin`, `~/.local/bin`, `~/.lmstudio/bin`, `~/.cargo/bin`.
- `OBSIDIAN_VAULT=~/Documents/zettelkasten`.
- Activation creates `~/Development`.
- Shell aliases: `nrd` (`npm run dev`), `cdzk`, `cdd` (`~/Development`),
  `cdh` (`~/Homework`), `cdnix` (checkout), `rebuild`, `vps-sync`.
- Ghostty config (`home/darwin/ghostty.nix`): font `CaskaydiaCove NF`, size 14,
  background opacity 0.9. The app itself comes from the `ghostty` cask
  (`package = null`).
- omp (`home/darwin/omp.nix`): enabled with `startup.quiet = true`.
- Git (`home/darwin/git.nix`): `user.name = "Matt Labrecque"`; the email is
  included from an agenix secret (see [Secrets](#secrets)).

### Neovim

`home/shared/nvim` is a plain Lua config (`init.lua`, `lua/config/plugins.lua`,
`lua/config/obsidian.lua`) that works dropped into `~/.config/nvim` on any
system with Neovim 0.12+ and git. Plugins install with `vim.pack` on first
start at the revisions in `nvim-pack-lock.json`; update them with
`:lua vim.pack.update()`.

`home/darwin/neovim.nix` links `~/.config/nvim` to the checkout
(`mkOutOfStoreSymlink`), so Lua edits apply without a switch and `vim.pack`
writes lockfile changes back into the repo; commit them. It also puts
`tinymist`, `websocat` (for typst-preview), and `ob` on nvim's PATH.

Home Manager supplies the binary with `git` and `tree-sitter` on its PATH
(parsers build with Xcode's `cc`). Node, Python, and Ruby providers are
disabled.

### Project shells

    mkdir my-project && cd my-project
    nix-init <go|julia|node|python|rust>

`nix-init` runs `nix flake init -t <checkout>#<lang>`, locks the project's
`nixpkgs` to this system's nixpkgs revision, and runs `direnv allow`. Templates
are described in [monorepo-structure.md](monorepo-structure.md#templates-and-nix-init).

## Secrets

Mac secrets use agenix through Home Manager.

- Identity: `~/.ssh/id_ed25519` (`age.identityPaths`). Its public key must be a
  recipient in `secrets/secrets.nix`. Checked during this write-up: the local
  `~/.ssh/id_ed25519.pub` matches the only recipient key in `secrets/secrets.nix`.
- Secret: `secrets/github-email.age` → `age.secrets.github-email`, decrypted
  into the per-user temp directory and exposed through git's `includes`.

## Setup from scratch

1. Install Homebrew (not automated by this repo; `homebrew.nix` refers to a
   `mac_bootstrap.sh` that does not exist in the repo or its git history).
2. Place `~/.ssh/id_ed25519` (must match a recipient in `secrets/secrets.nix`).
3. Clone the repo to `~/Development/nix-config`.
4. First switch (`darwin-rebuild` does not exist yet):

        sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#macbook-air

5. Afterwards use `rebuild` (or the command below).

Existing dotfiles such as `~/.zshrc` are moved aside to `<name>.before-nix`
rather than blocking activation (`backupFileExtension`).

## Maintenance

### Apply changes

    rebuild

or:

    sudo darwin-rebuild switch --flake ~/Development/nix-config#macbook-air

Shell and Ghostty config changes also need a switch; Neovim Lua edits do not.

### Roll back

`darwin-rebuild` supports `--list-generations` and `--rollback` (confirmed in
`darwin-rebuild --help` on this machine). Rollback is not wrapped by any alias
or script in the repo.

### Update inputs

    nix flake update nixpkgs nix-darwin home-manager omp

This is the list in the root `README.md`. `agenix` and `wrappers` are not in
the list; updating them requires a separate `nix flake update <input>` (or a
bare `nix flake update`, which updates all inputs).

Commit `flake.lock` after a successful switch.

### Cleanup

- Store GC runs automatically and removes generations older than 30 days.
- Homebrew casks not in `homebrew.nix` are removed on every switch (`zap`).

### Format and check

    nix fmt
    nix flake check

`checks.aarch64-darwin.macbook-air` builds the system toplevel.

### Adding things

- **Cask:** add the name to `modules/darwin/homebrew.nix`, then switch.
- **CLI package for this Mac only:** add to `home.packages` in
  `home/darwin/default.nix` (or a new file imported there).
- **CLI package for every machine:** add to `home/shared/default.nix`. Note that
  Home Manager on the servers also imports `home/shared`.
- **System setting:** `modules/darwin/default.nix`.

## Open items

- The working tree has uncommitted changes, including the staged
  `secrets/github-email.age` and the deletion of `machines/mac-mini.nix`.
- No backup configuration exists in the repo for this machine.
