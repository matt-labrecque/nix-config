# AGENTS.md

Flake-based Nix configuration for one nix-darwin Mac (`macbook-air`) and one
NixOS homelab (`homelab`), with Home Manager running as a system module on both.
`README.md` covers usage and install; this file covers working on the repo.

## Where things go

| Change | File |
| --- | --- |
| Nix daemon settings, anything both OSes need at system level | `modules/nix/settings.nix` |
| macOS system settings, fonts, system packages, Homebrew casks | `modules/darwin.nix` |
| NixOS user account, sudo, SSH keys | `modules/nixos/user.nix` |
| A homelab service | new file in `modules/nixos/`, imported from `modules/server.nix` |
| Host-specific values (hostname, enabled services) | `machines/<name>.nix` |
| User packages, shell, CLI tools on every machine | `modules/home-manager/`, listed in both `modules/darwin.nix` and `modules/server.nix` |
| User config only on the Mac (git, ghostty, aliases) | `modules/home-manager/` (Mac-only additions to a shared file go in `<name>-darwin.nix`), listed only in `modules/darwin.nix` |
| Neovim behaviour and plugins | `modules/home-manager/nvim/` (Lua) |
| Tools Neovim shells out to | `programs.neovim.extraPackages` in `modules/home-manager/neovim.nix` or `modules/home-manager/neovim-darwin.nix` |
| A project dev-shell template | `templates/<lang>/` and the `templates` attrset in `flake.nix` |

Each machine is defined inline in `flake.nix` (`darwinConfigurations.macbook-air`,
`nixosConfigurations.homelab`) and imports its entry module (`modules/darwin.nix`
or `modules/server.nix`) plus `machines/<name>.nix`. The entry module imports
the system modules and lists the Home Manager modules under
`home-manager.users.<username>.imports`. `modules/` holds three kinds of
module: `nix/` (system-level, both OSes), `nixos/` (NixOS only), and
`home-manager/` (user-level). Every module
receives `self`, `inputs`, `machine`, `username`, and `homeDirectory` through
`specialArgs`; Mac modules also receive `configDir`,
the absolute path of the checkout. Use these instead of hardcoding users or
paths.

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
3. Reference it with `age.secrets.<name>.file = ../../secrets/<name>.age;`
   (system level) or under Home Manager (user level, see `modules/home-manager/git.nix`).

## Neovim

`modules/home-manager/nvim/` is plain Lua and must keep working without Nix. Plugins are
added with `vim.pack.add` in `lua/config/plugins.lua`, never through Home
Manager. On the Mac `~/.config/nvim` is an out-of-store symlink to the checkout,
so Lua edits need no rebuild. Language servers come from project dev shells,
not the system profile.

## Templates

A template needs `flake.nix` (same `forAllSystems` shape as the others,
`nixpkgs-unstable`), an `.envrc` containing `use flake`, and a `.gitignore`
with at least `.direnv/`. Register it in the `templates` attrset in `flake.nix`,
add it to the usage string in `modules/home-manager/nix-init.nix`, and add a row to the
README table.
