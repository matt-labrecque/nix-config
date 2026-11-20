# Nix Configurations Monorepo

This repo serves as a single point of entry for my Nix configurations across
multiple systems:

| Machine | Flake output | OS | nixpkgs |
| --- | --- | --- | --- |
| MacBook Air (hostname `MattBook`) | `darwinConfigurations.macbook-air` | nix-darwin | `nixpkgs-unstable` |
| Mac mini | `darwinConfigurations.mac-mini` | nix-darwin | `nixpkgs-unstable` |
| VPS hosting Matrix through Tuwunel | `nixosConfigurations.ovh-vps` | NixOS | `nixos-26.05` |
| Homelab | `nixosConfigurations.homelab` | NixOS | `nixos-26.05` |

Home Manager runs as a nix-darwin/NixOS module on every machine, for user
`mlabrecqu` (home `/Users/mlabrecque`) on the Macs and `mlabrecque` on NixOS.

## Layout

```
flake.nix              inputs, mkDarwin/mkNixos, templates, formatter, checks
machines/
  macbook-air.nix      per-machine settings (hostname, ...)
  mac-mini.nix
  vps.nix              networking, SSH, disko, imports modules/server/tuwunel.nix
  homelab.nix
  hardware/            hardware-configuration and disko files per machine
modules/
  shared/              system settings for every machine (nix, gc, zsh)
  darwin/              nix-darwin settings and Homebrew casks
  linux/               settings for every NixOS machine (user, sudo)
  server/              service roles: tuwunel (VPS + homelab), homelab services
home/
  shared/              Home Manager for every machine (zsh, starship, neovim, CLI tools)
  shared/neovim.nix    Neovim via nix-wrapper-modules: plugins + their setup
  shared/nvim/         init.lua (options, keymaps, autocmds), copied into the store
  darwin/              Mac-only Home Manager (ghostty, typst-preview, nix-init, omp, git)
  starship.toml        prompt config
templates/             per-language project flakes used by nix-init
secrets/secrets.nix    agenix recipients
```

## Macs

The checkout must live at `~/Development/nix-config` (`configDir` in
`flake.nix`); the `rebuild` alias and `nix-init` use it.
Homebrew must be installed before the first switch: nix-darwin manages casks
but does not install Homebrew itself.

### Neovim

Neovim is built with the
[nix-wrapper-modules](https://github.com/nix-community/nix-wrapper-modules)
neovim module on every machine. Plugins come from `pkgs.vimPlugins`, pinned
by `flake.lock`, so the servers get `nixos-26.05` versions and the Macs get
unstable ones. Each plugin's setup lives in its spec in
`home/shared/neovim.nix` and runs after `home/shared/nvim/init.lua`. The
config is copied into the store, so every edit needs a rebuild.
`home/darwin/neovim.nix` adds typst-preview with tinymist and websocat on
nvim's PATH. The node, python3, and ruby provider hosts are disabled.

First run (before darwin-rebuild exists):

    sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#macbook-air

After that (or `rebuild`, which targets the current machine's output):

    sudo darwin-rebuild switch --flake .#macbook-air

Output names do not match hostnames, so always pass `#macbook-air` or
`#mac-mini` explicitly.

Homebrew uses `cleanup = "zap"`: a rebuild uninstalls any cask not declared in
`modules/darwin/homebrew.nix`, including its preferences and support files.

### Project shells

    mkdir my-project && cd my-project
    nix-init <go|julia|node|python|rust>

`nix-init` copies `templates/<lang>`, locks the project's nixpkgs to the
system's revision, and runs `direnv allow`.

## VPS/Homelab

Both run NixOS tracking the `nixos-26.05` stable branch.

On the VPS itself:

    git pull && sudo nixos-rebuild switch --flake .#ovh-vps

From a Mac, in this checkout (`vps-sync` alias):

    nix run nixpkgs#nixos-rebuild -- switch --flake .#ovh-vps --target-host USER@IP_ADDRESS --build-host USER@IP_ADDRESS

`machines/hardware/homelab.nix` is a placeholder (dummy root filesystem and
boot loader) so `nix flake check` can evaluate the homelab; do not deploy it.
Replace it with `nixos-generate-config` output from the machine, then set a
real boot loader and `system.stateVersion` in `machines/homelab.nix`.

### Homelab services

All services except Matrix are reachable only over Tailscale, at
`https://<name>.home.mlabrecque.dev`, with the dashboard (Homepage) at
`https://home.mlabrecque.dev`. Each `modules/server/<service>.nix` declares
its own Caddy vhost.

| Service | Host | Module |
| --- | --- | --- |
| Homepage | `home` | `homepage.nix` |
| Jellyfin | `jellyfin` | `jellyfin.nix` |
| Sonarr, Radarr, Prowlarr, Bazarr, qBittorrent | `sonarr`, `radarr`, `prowlarr`, `bazarr`, `qbittorrent` | `arr.nix` |
| Nextcloud 35 | `nextcloud` | `nextcloud.nix` |
| Vaultwarden | `vault` | `vaultwarden.nix` |
| Paperless-ngx | `paperless` | `paperless.nix` |
| Forgejo | `git` | `forgejo.nix` |
| FreshRSS | `rss` | `freshrss.nix` |
| Syncthing | `sync` | `syncthing.nix` |
| AdGuard Home | `adguard` | `adguardhome.nix` |
| Grafana, Prometheus | `grafana`, `prometheus` | `monitoring.nix` |
| Tuwunel (public) | `matrix.mlabrecque.dev` | `tuwunel.nix` |

- **Tailnet-only vhosts** start with `import tailnet` (`caddy.nix`): a
  certificate from Caddy's internal CA, and clients outside Tailscale's
  address ranges are dropped. Trust Caddy's root certificate
  (`/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt`) on
  your devices.
- **Firewall:** 80/443 public (Matrix, router forwarding needed) and
  Tailscale's UDP port. SSH, DNS, Syncthing, and HTTPS for the other
  services are open only on `tailscale0`.
- **DNS:** after `sudo tailscale up`, set `homelab.tailscaleIPv4` in
  `machines/homelab.nix` so AdGuard answers `home.mlabrecque.dev` and
  `*.home.mlabrecque.dev`, then add a Tailscale split DNS entry for
  `home.mlabrecque.dev` pointing at the homelab.
- **Storage:** media, documents, Nextcloud data, and Syncthing live under
  `homelab.dataRoot` (`/srv`). `/srv/media` is shared by the `media` group.
- **Secrets:** Nextcloud, Vaultwarden, Paperless, FreshRSS, and Grafana read
  `/run/agenix/<name>`. Each module has its `age.secrets` block commented
  out; those services fail at runtime until the secret exists. Add the
  homelab's host key to `secrets/secrets.nix`, encrypt the file, and
  uncomment the block.
- **Immich** (`immich.nix`) is not imported: nixos-26.05 marks Immich 2.x
  insecure, and 3.x arrives with 26.11.

## Secrets

agenix: recipients live in `secrets/secrets.nix`. Machines decrypt with their
SSH host key, so add each host's `/etc/ssh/ssh_host_ed25519_key.pub` there
before encrypting secrets for it.

## Updating

    nix flake update nixpkgs nix-darwin home-manager omp     # Macs
    nix flake update nixpkgs-stable home-manager-stable disko # VPS/Homelab

## Formatting and checks

    nix fmt
    nix flake check
