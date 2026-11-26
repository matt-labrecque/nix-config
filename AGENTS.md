# AGENTS.md

Guidance for LLM agents editing this repo: a single Nix flake that builds every
machine's system config plus its Home Manager profile.

Reference docs (read the relevant one before non-trivial changes):

- `documentation/monorepo-structure.md`: layout, builders, specialArgs, layers,
  conventions, "adding things" recipes
- `documentation/macbook-air.md`, `documentation/ovh-vps.md`: per-machine
  details, deploy steps, open items
- `documentation/homelab/`: homelab docs split by topic (start at `README.md`;
  `architecture.md`, `network.md`, `services.md`, `storage.md`, `secrets.md`,
  `setup.md`, `operations.md`, `open-items.md`, `RECOVERY.md`)

## Map

| Output | Builder call | Machine file | nixpkgs | Home profile |
| --- | --- | --- | --- | --- |
| `darwinConfigurations.macbook-air` | `mkDarwin "macbook-air"` | `machines/macbook-air.nix` | unstable | `home/darwin` (imports `home/shared`) |
| `nixosConfigurations.ovh-vps` | `mkNixos "vps"` | `machines/vps.nix` | `nixos-26.05` | `home/shared` |
| `nixosConfigurations.homelab` | `mkNixos "homelab"` | `machines/homelab.nix` | `nixos-26.05` | `home/shared` |

- The builder argument picks the machine file, not the output name
  (`ovh-vps` → `machines/vps.nix`).
- Layers, general → specific: `modules/shared` → `modules/darwin` or
  `modules/linux` → `modules/server/*` (opt-in per machine) → `machines/<name>.nix`
  → `home/shared` / `home/darwin`. Put a setting in the most general layer that
  is true for every machine receiving it. Machine files hold only per-host values
  and imports.

## Hard rules

- **Never activate or deploy.** Do not run `rebuild`, `darwin-rebuild switch`,
  `nixos-rebuild switch`, `vps-sync`, or anything with `--target-host` unless the
  user explicitly asks. Evaluate/build only.
- **Never change a `stateVersion`** (`system.stateVersion` on NixOS or
  nix-darwin, `home.stateVersion`). The VPS one is marked `DO NOT BUMP`.
- **Never run `nix flake update`** (or `flake lock --update-input`) unless asked.
  Lock changes affect every machine.
- **Secrets:** never decrypt, print, or hand-edit `secrets/*.age`, and never put
  secret values in `.nix` files. Encryption is the user's step
  (`cd secrets && agenix -e <name>.age`); you may edit recipients in
  `secrets/secrets.nix` and the `age.secrets.*` declarations.
- **Homebrew uses `cleanup = "zap"`.** Removing or renaming a cask in
  `modules/darwin/homebrew.nix` uninstalls that app and its data on the next
  switch. Flag it to the user.
- Keep VPS SSH access intact: changes to `services.openssh`, firewall, network
  addresses, or `authorizedKeys` can lock the user out of a remote host.

## Nix gotchas specific to this repo

- **Flakes only see git-tracked files.** A new file is invisible to evaluation
  ("Path ... does not exist in Git repository") until staged. Run
  `git add -N <file>` (intent-to-add) after creating files, before evaluating.
- **Two channels.** Anything reachable from `home/shared`, `modules/shared`,
  `modules/linux`, or `modules/server` must evaluate on stable `nixos-26.05` *and*
  (for the shared parts) unstable. Do not use options or packages that exist only
  in unstable there. Check option names against the right Home Manager branch
  (`release-26.05` vs `master`).
- **specialArgs** (`self`, `inputs`, `machine`, `username`, `homeDirectory`)
  reach every system and Home Manager module. `configDir` exists **only on
  Darwin**; do not reference it from shared or Linux modules.
- **Usernames differ:** `mlabrecqu` on macOS (home `/Users/mlabrecque`),
  `mlabrecque` on NixOS. Use `username` / `homeDirectory` / `config.home.*`, never
  hard-code.
- **`zettk-cli` is a `path:` input** pointing at
  `/Users/mlabrecque/Development/zettk-cli`. Evaluating the Darwin config needs
  that checkout present.
- **Server modules have dependencies:** a vhost using `import tailnet` needs
  `modules/server/caddy.nix` imported on that machine; any module reading
  `config.homelab.*` needs `modules/server/options.nix`. The homelab imports
  both; the VPS imports neither.
- Neovim config (`home/shared/nvim/`) must stay plain Lua that works outside
  Nix: plugins go in the `vim.pack.add` list in `lua/config/plugins.lua`, not in
  `pkgs.vimPlugins`. Nix only supplies the binary and tools on its PATH. The Mac
  links the directory from the checkout; `vim.pack` rewrites
  `nvim-pack-lock.json` there, so commit it with plugin changes.

## Verification

Run from the repo root. Evaluation is the minimum bar for every change; it takes
seconds.

```sh
nix fmt                                   # nixfmt-tree over the whole repo
nix eval --raw .#darwinConfigurations.macbook-air.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.ovh-vps.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath
```

- Evaluate every output your change can reach: shared modules affect all
  three; `home/shared` affects all three; `modules/server/*` affects whichever
  machines import the file.
- `nix flake check` builds the checks for the current system only (on the Mac:
  `macbook-air`). Linux outputs cannot be built locally on aarch64-darwin;
  evaluate them instead. `homelab` is not in `checks`, so evaluate it explicitly.
- Expected on homelab: a `system.stateVersion is not set` warning (the machine is
  not installed yet; `machines/hardware/homelab.nix` is a placeholder). Do not
  "fix" it by setting a stateVersion.
- Add `--show-trace` when an error's origin is unclear.

## Recipes

Full versions in `documentation/monorepo-structure.md#adding-things`.

- **Homelab service:** new `modules/server/<name>.nix` (one service per file):
  enable the service bound to `127.0.0.1`, add a Caddy vhost
  `<name>.${config.homelab.domain}` starting with `import tailnet`, open ports
  only via `networking.firewall.interfaces.tailscale0`. Import it in
  `machines/homelab.nix`; add it to the dashboard in
  `modules/server/homepage.nix`.
- **Secret:** add recipients in `secrets/secrets.nix` (user key + each host's
  `/etc/ssh/ssh_host_ed25519_key.pub`), ask the user to run `agenix -e`, then
  declare `age.secrets.<name>.file = ../../secrets/<name>.age;` (plus `owner`).
  On NixOS services read `/run/agenix/<name>`.
- **Mac GUI app:** cask in `modules/darwin/homebrew.nix`. **CLI package:**
  `home/darwin/default.nix` (Mac only) or `home/shared/default.nix` (all
  machines, so it must exist on 26.05 too).
- **Machine:** `machines/<name>.nix`, an `mkDarwin`/`mkNixos` entry in
  `flake.nix`, a hardware file for NixOS, and a `checks` entry.
- **Template:** `templates/<lang>/`, a `templates.<lang>` entry in `flake.nix`,
  and the language in the hand-written usage string in
  `home/darwin/nix-init.nix`.

## Style

- Format with `nix fmt`; 2-space indent, no tabs.
- Comments explain *why* (constraints, external facts, gotchas), one short line
  or block above the setting. Match the existing tone; no restating the option
  name.
- Prefer upstream NixOS / nix-darwin / Home Manager module options over raw
  config files or activation scripts.
- Use relative imports (`../modules/server/<name>.nix`) from machine files;
  there is no auto-import.

## Docs

When a change alters behavior described in `README.md` or `documentation/*.md`
(outputs, inputs, modules, aliases, casks, deploy steps, open items), update
those docs in the same change. Commit `flake.lock` together with any input
change.
