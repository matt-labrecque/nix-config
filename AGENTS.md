# AGENTS.md

Flake-based Nix configuration for one nix-darwin Mac (`macbook-air`,
nixpkgs-unstable) and one NixOS homelab (`homelab`, nixpkgs-stable / NixOS
26.05), with Home Manager running as a system module on both. `README.md` is
the public overview; this file covers working on the repo.

## Where things go

| Change | File |
| --- | --- |
| Nix daemon settings, anything both OSes need at system level | `modules/nix/settings.nix` |
| macOS system settings, fonts, system packages, Homebrew casks | `modules/darwin.nix` |
| NixOS user account, sudo, SSH keys | `modules/nixos/user.nix` |
| Homelab Tailscale and firewall | `modules/nixos/networking.nix` |
| A homelab service | new file in `modules/nixos/`, imported from `modules/server.nix` |
| Host-specific values (hostname, SSH/firewall, boot loader) | `machines/<name>.nix` |
| User packages, shell, CLI tools on every machine | `modules/home-manager/`, listed in both `modules/darwin.nix` and `modules/server.nix` |
| Mac-only user config (git, ghostty, nix-init, omp, aliases) | additions to a shared file go in its `lib.mkIf isDarwin` block; Mac-only files are listed only in `modules/darwin.nix` |
| Neovim behaviour and plugins | `modules/home-manager/nvim/init.lua` (Lua) |
| Tools Neovim shells out to | `programs.neovim.extraPackages` in `modules/home-manager/neovim.nix` (shared list, or the `isDarwin` block for Mac-only tools) |
| A project dev-shell template | `templates/<lang>/`, the `templates` attrset in `flake.nix`, and the usage string in `modules/home-manager/nix-init.nix` |

`flake.nix` defines `darwinConfigurations.macbook-air` on nixpkgs-unstable and
`nixosConfigurations.homelab` on nixpkgs-stable. Each imports its entry module
(`modules/darwin.nix` or `modules/server.nix`) plus `machines/<name>.nix`. The
entry module imports the system modules and lists the Home Manager modules
under `home-manager.users.<username>.imports`. `modules/` holds three kinds of
module: `nix/` (system-level, both OSes), `nixos/` (NixOS only), and
`home-manager/` (user-level).

System modules receive `self`, `inputs`, `machine`, `username`, and
`homeDirectory` through `specialArgs`. The Mac also passes `configDir`, the
absolute path of the checkout, through both `specialArgs` and
`home-manager.extraSpecialArgs`; the homelab passes no `configDir`. Use these instead
of hardcoding users or paths, and note that a Home Manager module imported on
both machines does not get `configDir` on the homelab. Home Manager gets the
other values from `modules/nix/settings.nix`.

## Verifying changes

Flakes only see files tracked by git. After creating a file, run
`git add -N <file>` or evaluation fails with a missing-path error.

| Changed | Check |
| --- | --- |
| Anything on the Mac side | `nix build .#darwinConfigurations.macbook-air.system --no-link` |
| Anything on the homelab side | `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath` |
| `modules/nix/`, Home Manager modules listed in both entry modules | both of the above |
| A template | `nix flake init -t <repo>#<lang>` in a temp dir, then `nix develop -c true` |
| Any `.nix` file | `nix fmt` (nixfmt-tree) |

The homelab is `x86_64-linux`; from the Mac it can be evaluated but not built
without a Linux builder. `nix flake check` only builds the current system's
checks.

Do not run `rebuild`, `darwin-rebuild switch`, or `nixos-rebuild switch`: they
need sudo and change the live system. Leave activation to the user.

## Rules

- Do not change `system.stateVersion` or `home.stateVersion`.
- Do not run `nix flake update` or edit `flake.lock` unless asked.
- Do not edit `modules/home-manager/nvim/nvim-pack-lock.json` by hand;
  `vim.pack` writes it.
- `machines/hardware/homelab.nix` is a placeholder that only exists so the
  flake evaluates. Do not add real hardware settings to it; it gets replaced by
  `nixos-generate-config` output.
- Homebrew runs with `cleanup = "zap"`: anything not listed in
  `modules/darwin.nix` is uninstalled on switch. Prefer nixpkgs for
  CLI tools; use casks for GUI apps.
- Keep comments explaining why, in the existing style: a short header comment
  per module for anything non-obvious (manual steps, ports, upstream quirks).
- Keep `README.md` in sync when adding machines, services, templates, or
  aliases.

## Secrets

Secrets are agenix files in `secrets/`. They cannot be decrypted or created
without the user's SSH key, so never write or modify `.age` files. To add one:

1. Add the recipients to `secrets/secrets.nix`.
2. Ask the user to run `cd secrets && agenix -e <name>.age`.
3. Reference it with `age.secrets.<name>.file = ../secrets/<name>.age;` from a
   file in `modules/`, or `../../secrets/<name>.age` from `modules/nixos/` and
   `modules/home-manager/` (user-level example: `modules/home-manager/git.nix`).

Machines decrypt with their SSH host key, so add each host's
`/etc/ssh/ssh_host_ed25519_key.pub` to `secrets/secrets.nix` and to the
secret's `publicKeys`.

## Neovim

`modules/home-manager/nvim/` is plain Lua and must keep working without Nix.
Plugins are added with `vim.pack.add` in `init.lua`, never through Home
Manager. On the Mac `~/.config/nvim` is an out-of-store symlink to the
checkout, so Lua edits apply without a rebuild and `vim.pack` writes the
lockfile back into the repo. On the homelab it is a store copy with
`nvim-pack-lock.json` filtered out, so `vim.pack` writes a fresh one. Language
servers (`gopls`, `pyright`, `clangd`) are enabled when their binary is on
`PATH`, i.e. from project dev shells, not the system profile.

## Templates

A template has `flake.nix` (same `forAllSystems` shape as the others,
nixpkgs-unstable), an `.envrc` containing `use flake`, and a `.gitignore` with
at least `.direnv/`. Register it in the `templates` attrset in `flake.nix`,
add it to the usage string in `modules/home-manager/nix-init.nix`, and mention
it in `README.md`. `nix-init <lang>` copies the template, overrides its
nixpkgs input to the system's revision, and runs `direnv allow`.
