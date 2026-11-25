# Monorepo Structure

One flake builds the system configuration for every machine and the Home
Manager profile that runs on it. This document covers the layout and the
conventions behind it. Per-machine details:

- [macbook-air.md](macbook-air.md)
- [ovh-vps.md](ovh-vps.md)
- [homelab.md](homelab.md)

## Flake outputs

| Output | Target | Entry point |
| --- | --- | --- |
| `darwinConfigurations.macbook-air` | `aarch64-darwin`, nix-darwin | `machines/macbook-air.nix` |
| `nixosConfigurations.ovh-vps` | `x86_64-linux`, NixOS | `machines/vps.nix` |
| `nixosConfigurations.homelab` | `x86_64-linux`, NixOS | `machines/homelab.nix` |
| `formatter.aarch64-darwin`, `formatter.x86_64-linux` | `nixfmt-tree` (`nix fmt`) | `flake.nix` |
| `checks.aarch64-darwin.macbook-air` | system toplevel | `flake.nix` |
| `checks.x86_64-linux.ovh-vps` | system toplevel | `flake.nix` |
| `templates.{rust,python,node,go,julia}` | project flakes | `templates/<lang>/` |

Output names are the keys passed to `mkDarwin` / `mkNixos`. The machine file
is chosen by the argument, not the output name. Example: `ovh-vps = mkNixos
"vps"` uses `machines/vps.nix`. The comment in `flake.nix` says the output name
selects the file; that is only true for `macbook-air` and `homelab`.

`homelab` is not in `checks`.

## Inputs

| Input | Source | Follows | Used for |
| --- | --- | --- | --- |
| `nixpkgs` | `nixpkgs-unstable` | — | Macs, templates, default for other inputs |
| `nix-darwin` | `nix-darwin/master` | `nixpkgs` | macOS system |
| `home-manager` | `nix-community/home-manager` `master` | `nixpkgs` | Mac user profile |
| `omp` | `can1357/oh-my-pi` | `nixpkgs` | `home/darwin/omp.nix` |
| `nixpkgs-stable` | `nixos-26.05` | — | Servers |
| `home-manager-stable` | `release-26.05` | `nixpkgs-stable` | Server user profile |
| `disko` | `nix-community/disko` | `nixpkgs-stable` | VPS disk layout |
| `agenix` | `ryantm/agenix` | `nixpkgs` | Secrets (all machines) |

Two channels:

- **Macs** track unstable.
- **Servers** track the stable `nixos-26.05` branch.

`agenix` follows unstable nixpkgs but is also used on the stable NixOS
systems. `flake.lock` pins all of it.

## How a system is assembled

`flake.nix` defines two builders.

**`mkDarwin <machine>`** builds `darwinConfigurations.<output>` with, in order:

1. `modules/shared`
2. `modules/darwin`
3. `machines/<machine>.nix`
4. agenix darwin module
5. home-manager darwin module, running `home/darwin` for the user

**`mkNixos <machine>`** builds `nixosConfigurations.<output>` with, in order:

1. `modules/shared`
2. `modules/linux`
3. `machines/<machine>.nix`
4. agenix NixOS module
5. home-manager NixOS module, running `home/shared` for the user

Both pass the same `specialArgs` to every module:

| Arg | Darwin | NixOS |
| --- | --- | --- |
| `self`, `inputs` | yes | yes |
| `machine` | machine name | machine name |
| `username` | `mlabrecqu` | `mlabrecque` |
| `homeDirectory` | `/Users/mlabrecque` | `/home/mlabrecque` |
| `configDir` | `/Users/mlabrecque/Development/nix-config` | — |

`username` is the macOS short name on Darwin and the login name on NixOS.
`homeDirectory` is set explicitly on Darwin because it is not derived from the
short name.

### Home Manager wiring

`homeManagerConfig` is the same for both OSes:

- `useGlobalPkgs = true`: Home Manager uses the system `pkgs`.
- `useUserPackages = true`: user packages go into the user profile.
- `backupFileExtension = "before-nix"`: an existing file (for example
  `~/.zshrc`) is renamed to `<name>.before-nix` instead of failing activation.
- `sharedModules`: the agenix Home Manager module.
- `users.<username>`: imports the profile for that OS.

## Directory map

```
flake.nix                 inputs, builders, outputs, templates
flake.lock                pinned inputs (commit after updating)
machines/
  macbook-air.nix         hostname
  vps.nix                 OVH VPS: networking, SSH, imports Tuwunel and Tailscale
  homelab.nix             homelab: imports every server module
  hardware/
    ovh-vps.nix           hardware config (nixos-generate-config style)
    ovh-vps-disk.nix      disko layout for /dev/sda
    homelab.nix           PLACEHOLDER until the homelab is installed
modules/
  shared/                 both OSes: nix settings, GC, zsh, unfree
  darwin/                 nix-darwin: fonts, defaults, agenix CLI
    homebrew.nix          casks (cleanup = "zap")
  linux/                  NixOS: user, sudo, SSH key
  server/                 one module per homelab/VPS service, plus shared pieces
    options.nix           homelab.* options (domain, dataRoot, tailscaleIPv4)
    caddy.nix             Caddy + the `tailnet` snippet
    tailscale.nix         Tailscale service
    media.nix             media group and directories
    tuwunel.nix           Matrix homeserver (VPS and homelab)
    ...                   one file per service
home/
  shared/                 Home Manager for every machine
    default.nix           packages, EDITOR, stateVersion
    shell.nix             zsh, starship, bat, fzf, direnv
    neovim.nix            Neovim binary and the tools its config needs
    nvim/                 plain Lua config, plugins via vim.pack
  darwin/                 Mac-only Home Manager; imports ../shared
    default.nix           imports, Mac packages, PATH, OBSIDIAN_VAULT
    shell.nix             Mac aliases (rebuild, vps-sync, cdnix, ...)
    git.nix               git identity and agenix-managed email
    ghostty.nix           terminal config (app from Homebrew)
    neovim.nix            links nvim/ from the checkout; typst/obsidian tools
    nix-init.nix          project scaffolding command
    omp.nix               omp module
  starship.toml           prompt config
templates/                per-language project flakes for nix-init
secrets/
  secrets.nix             agenix recipients (read by the agenix CLI, not imported)
  *.age                   encrypted secrets
```

## Layers

Configuration is layered from general to specific:

1. **`modules/shared`**: every machine, both OSes.
2. **`modules/darwin` or `modules/linux`**: OS-level defaults for one platform.
3. **`modules/server`**: service modules. Imported only by the machines that run
   them.
4. **`machines/<name>.nix`**: the machine's own choices. Hostname, IP and IPv6
   addresses, which modules to import, domain, and per-host settings.
5. **`home/shared`** and **`home/darwin`**: user environment, built the same way
   for every machine that uses that OS.

A setting belongs in the most general layer that is true for every machine that
receives it.

## Conventions

### Machine files

Keep them to per-host values and imports. Settings that apply to more than one
machine go in a module.

### Server modules

Each file in `modules/server/` covers one service. The usual pattern:

1. Enable the NixOS service.
2. Bind it to `127.0.0.1`.
3. Add a Caddy virtual host for `<name>.${homelab.domain}`, starting with
   `import tailnet`.
4. Open ports only on `tailscale0` in `networking.firewall.interfaces`.

`import tailnet` is defined in `caddy.nix`. Any module that uses it must be
imported alongside `caddy.nix`. The homelab does this. The VPS does not use
the snippet.

`options.nix` defines the `homelab.*` options shared by the server modules.

### Secrets

agenix throughout.

1. Add the recipient keys (user and host) to `secrets/secrets.nix`.
2. Encrypt: `cd secrets && agenix -e <name>.age`.
3. Declare on the machine:

       age.secrets.<name>.file = ../../secrets/<name>.age;
       age.secrets.<name>.owner = "<service user>";

4. On NixOS, the decrypted file is at `/run/agenix/<name>`. Services reference
   that path directly.

On macOS, Home Manager declares secrets with `path = ...`. See the known issue
in [macbook-air.md](macbook-air.md#known-issue-the-secret-path-overwrites-the-repo-file).

### State versions

Do not change these without reading the release notes:

- `system.stateVersion`: VPS `"26.05"` (marked `DO NOT BUMP`). The homelab does
  not set one yet.
- nix-darwin `system.stateVersion`: `7`.
- Home Manager `home.stateVersion`: `26.05`.

### Neovim

`home/shared/nvim` is a standalone Lua config: plugins install with `vim.pack`
at the revisions in `nvim-pack-lock.json`, so the directory works as
`~/.config/nvim` on any distro with Neovim 0.12+ and git. nvim-treesitter
builds parsers when `tree-sitter` and `cc` are on PATH.

`home/shared/neovim.nix` (`programs.neovim`) installs the binary with `git`,
`tree-sitter`, and (Linux) `gcc` on its PATH, and copies the config into the
store without the lockfile, since `vim.pack` must write it: the servers get
the latest plugin revisions on first start. The Mac links the checkout instead
(`home/darwin/neovim.nix`), so it uses and updates the pinned lockfile.

Language servers are enabled when installed; on machines with Nix only inside
a Nix shell.

### Templates and `nix-init`

`templates/<lang>/` are flakes for project dev shells. `nix-init <lang>` runs
`nix flake init -t <checkout>#<lang>`, locks the project's `nixpkgs` to the
system's revision, and runs `direnv allow`.

| Template | Shell contents |
| --- | --- |
| `rust` | Toolchain from `rust-toolchain.toml` via `rust-overlay` |
| `python` | `python3`, `uv` (uses the pinned interpreter), `ruff`, `pyright` |
| `node` | `nodejs_24`, `bun` |
| `go` | `go`, `gopls`, `gotools`, `delve`; `GOBIN` is `./.bin` |
| `julia` | Official `julia-bin` |

The `nix-init` usage string lists `go|julia|node|python|rust` by hand. Update it
when a template is added.

## Commands

    nix fmt                 format all Nix files (nixfmt-tree)
    nix flake check         evaluate and build the checks listed above
    nix flake update <input>...

Machine-specific rebuild commands are in each machine document.

## Adding things

These steps follow from the layout above.

- **Machine:** add `machines/<name>.nix`, a `darwinConfigurations` or
  `nixosConfigurations` entry in `flake.nix` using `mkDarwin` or `mkNixos`, and
  for NixOS a hardware file. Add its host key as an agenix recipient if it uses
  secrets.
- **Homelab service:** add `modules/server/<name>.nix` following the server
  pattern. Import it in `machines/homelab.nix`. Add it to the dashboard list in
  `modules/server/homepage.nix`.
- **Mac cask:** add it to `modules/darwin/homebrew.nix`. Undeclared casks are
  removed on the next switch.
- **Mac package:** add it to `home/darwin/default.nix`. For a package every
  machine needs, use `home/shared/default.nix`.
- **Template:** add `templates/<lang>/`, a `templates.<lang>` entry in
  `flake.nix`, and the language name in the `nix-init` usage string
  (`home/darwin/nix-init.nix`).

## Current state

These are facts about the repo as it stands. Each one is covered in more detail
in the machine documents.

- The working tree has uncommitted changes, including the deletion of
  `machines/mac-mini.nix` and a staged `secrets/github-email.age` whose
  working-tree copy is a symlink. `mac-mini` is not in `flake.nix`, so it is not
  documented here.
- The root `README.md` still describes the Mac mini and uses the domain
  `home.mlabrecque.dev`. The code uses `lab.mlabrecque.dev`. The README was left
  unchanged as requested.
- `home/darwin/omp.nix` does not match the code (see
  [macbook-air.md](macbook-air.md#open-items)).
- `modules/darwin/homebrew.nix` refers to `mac_bootstrap.sh`, which is not in
  the repo or its history.
- `secrets/secrets.nix` defines a `users` list that is not used.
- No backup configuration exists anywhere in the repo.
