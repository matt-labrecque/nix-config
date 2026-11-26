# AGENTS.md

Flake-based Nix configuration for one nix-darwin Mac (`macbook-air`) and one
NixOS homelab (`homelab`), with Home Manager running as a system module on both.
`README.md` covers usage and install; this file covers working on the repo.

## Where things go

| Change | File |
| --- | --- |
| Nix daemon settings, anything both OSes need at system level | `modules/shared/default.nix` |
| macOS system settings, fonts, system packages | `modules/darwin/default.nix` |
| GUI apps on the Mac (Homebrew casks) | `modules/darwin/homebrew.nix` |
| NixOS user account, sudo, SSH keys | `modules/linux/default.nix` |
| A homelab service | new file in `modules/server/`, imported from `machines/homelab.nix` |
| Host-specific values (hostname, enabled services, `homelab.*` options) | `machines/<name>.nix` |
| User packages, shell, CLI tools on every machine | `home/shared/` |
| User config only on the Mac (git, ghostty, aliases) | `home/darwin/` |
| Neovim behaviour and plugins | `home/shared/nvim/` (Lua) |
| Tools Neovim shells out to | `programs.neovim.extraPackages` in `home/shared/neovim.nix` or `home/darwin/neovim.nix` |
| A project dev-shell template | `templates/<lang>/` and the `templates` attrset in `flake.nix` |

Each machine is defined inline in `flake.nix` (`darwinConfigurations.macbook-air`,
`nixosConfigurations.homelab`) and imports `machines/<name>.nix`. Every module
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
| `modules/shared`, `home/shared` | both of the above |
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
- Do not edit `home/shared/nvim/nvim-pack-lock.json` by hand; `vim.pack`
  writes it.
- `machines/hardware/homelab.nix` is a placeholder that only exists so the
  flake evaluates. Do not add real hardware settings to it; it gets replaced by
  `nixos-generate-config` output.
- Homebrew runs with `cleanup = "zap"`: anything not listed in
  `modules/darwin/homebrew.nix` is uninstalled on switch. Prefer nixpkgs for
  CLI tools; use casks for GUI apps.
- Keep comments explaining why, in the existing style: a short header comment
  per module for anything non-obvious (manual steps, ports, upstream quirks).
- Keep `README.md` in sync when adding machines, services, templates, or
  aliases.

## Homelab services

Every tailnet service module follows the same shape; copy an existing one such
as `modules/server/audiobookshelf.nix`:

1. Bind the service to `127.0.0.1` on a port no other module uses (grep
   `modules/server/` for the number first).
2. Set `homelab.services.<subdomain> = <port>;`. `caddy.nix` turns it into a
   tailnet-only vhost proxying to `127.0.0.1:<port>`. A service that needs a
   custom vhost writes it itself and starts it with `import tailnet` (see
   `freshrss.nix`).
3. Store data under `config.homelab.dataRoot` when it is user data (media,
   photos, Nextcloud files).
4. Import the module from `machines/homelab.nix`.
5. Media apps join the `media` group and import `media.nix`.

Only `website.nix`, `tuwunel.nix` (80/443) and `minecraft-server.nix` (25565)
are public; nothing else opens firewall ports outside `tailscale0`.
`website.nix` owns the `mlabrecque.dev` vhost and `tuwunel.nix` adds only its
`/.well-known/matrix/*` handler to it.

`immich.nix` is intentionally not imported (see its header).

## Secrets

Secrets are agenix files in `secrets/`. They cannot be decrypted or created
without the user's SSH key, so never write or modify `.age` files. To add one:

1. Add the recipients to `secrets/secrets.nix`.
2. Ask the user to run `cd secrets && agenix -e <name>.age`.
3. Reference it with `age.secrets.<name>.file = ../secrets/<name>.age;`
   (system level) or under Home Manager (user level, see `home/darwin/git.nix`).

Several homelab modules carry commented-out `age.secrets` blocks waiting for
the homelab's host key; leave them commented until that key is in
`secrets/secrets.nix` and the file exists.

## Neovim

`home/shared/nvim/` is plain Lua and must keep working without Nix. Plugins are
added with `vim.pack.add` in `lua/config/plugins.lua`, never through Home
Manager. On the Mac `~/.config/nvim` is an out-of-store symlink to the checkout,
so Lua edits need no rebuild. Language servers come from project dev shells,
not the system profile.

## Templates

A template needs `flake.nix` (same `forAllSystems` shape as the others,
`nixpkgs-unstable`), an `.envrc` containing `use flake`, and a `.gitignore`
with at least `.direnv/`. Register it in the `templates` attrset in `flake.nix`,
add it to the usage string in `home/darwin/nix-init.nix`, and add a row to the
README table.
