# Homelab (`homelab`)

NixOS server for the home services. Everything except Matrix is reachable only
over Tailscale. For the repo layout, see
[monorepo-structure.md](monorepo-structure.md).

## Status

**Not deployable yet.** The repo can evaluate the homelab, but the following
must be done on the machine before a real deploy:

- `machines/hardware/homelab.nix` is a placeholder (dummy root filesystem by
  label `nixos`, GRUB `nodev`). Replace it with `nixos-generate-config` output.
- `machines/homelab.nix` does not set `system.stateVersion`. Evaluation warns
  and defaults it to `26.05`. The file's comments say it must be set.
- `networking.hostName` is not set; it defaults to `nixos`.
- Secrets are not provisioned. Every service that needs one has its
  `age.secrets` block commented out.
- `homelab.tailscaleIPv4` is unset, so AdGuard has no DNS rewrites yet.
- `immich.nix` is not imported (see [Immich](#immich)).

`checks` in `flake.nix` only cover `macbook-air` and `ovh-vps`; the homelab
is not in that list.

## Identity

| Item | Value | Source |
| --- | --- | --- |
| Flake output | `nixosConfigurations.homelab` | `flake.nix` |
| Machine file | `machines/homelab.nix` | `mkNixos "homelab"` |
| Hardware | `machines/hardware/homelab.nix` (placeholder) | `machines/homelab.nix` |
| Platform | `x86_64-linux` | `machines/homelab.nix` |
| nixpkgs | `nixos-26.05` (`nixpkgs-stable`) | `flake.nix` |
| Base domain | `lab.mlabrecque.dev` (`homelab.domain`) | `machines/homelab.nix` |
| Data root | `/srv` (`homelab.dataRoot`) | `modules/server/options.nix` |
| Login user | `mlabrecque` (wheel, zsh, no password) | `modules/linux/default.nix` |

Service URLs use the pattern `https://<name>.lab.mlabrecque.dev`. The dashboard
is at `https://lab.mlabrecque.dev`.

The root `README.md` still says `home.mlabrecque.dev`. That does not match
`homelab.domain` in `machines/homelab.nix`, which is `lab.mlabrecque.dev`.
This document follows the code.

## Network and access

### Access model

- **Tailnet-only vhosts** start with `import tailnet` (defined in
  `modules/server/caddy.nix`). Caddy issues certificates from its internal CA
  (`tls internal`), and requests from outside Tailscale's ranges
  (`100.64.0.0/10`, `fd7a:115c:a1e0::/48`) are aborted.
- Trust Caddy's root certificate on each client device:
  `/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt`.
- Services bind to `127.0.0.1` and Caddy is the only entry point.

### Firewall

Computed from the NixOS config (`networking.firewall`):

| Interface | TCP | UDP | Source |
| --- | --- | --- | --- |
| all (public) | `80`, `443` | — | `tuwunel.nix` (Matrix; router must forward) |
| `tailscale0` | `22` | — | `machines/homelab.nix` (sshd, `openFirewall = false`) |
| `tailscale0` | `53`, `443`, `22000` | `53`, `21027`, `22000` | AdGuard, Caddy, Syncthing |

Tailscale's own UDP port is opened by `services.tailscale.openFirewall`.

### Tailscale

`modules/server/tailscale.nix` enables the service. Join the tailnet with
`sudo tailscale up`, then read the address with `tailscale ip -4`.

### DNS (AdGuard Home)

`modules/server/adguardhome.nix`:

- Web UI on `127.0.0.1:3000`, served at `https://adguard.lab.mlabrecque.dev`.
- DNS listens on `0.0.0.0`; the firewall opens 53 only on `tailscale0`.
- `mutableSettings = true`: changes made in the web UI persist.
- When `homelab.tailscaleIPv4` is set, AdGuard rewrites `lab.mlabrecque.dev`
  and `*.lab.mlabrecque.dev` to that address.

Manual steps (not in the repo):

1. `sudo tailscale up` on the homelab.
2. Set `homelab.tailscaleIPv4` in `machines/homelab.nix` to `tailscale ip -4`.
   Commit, switch.
3. In the Tailscale admin console, add a split DNS entry for
   `lab.mlabrecque.dev` pointing at the homelab's Tailscale IP.

## Services

| Service | URL | Module | Local port | Data / notes |
| --- | --- | --- | --- | --- |
| Homepage (dashboard) | `lab.mlabrecque.dev` | `homepage.nix` | 8082 | Links to the services below |
| Jellyfin | `jellyfin` | `jellyfin.nix` | 8096 | Media group |
| Sonarr | `sonarr` | `arr.nix` | 8989 | Media group |
| Radarr | `radarr` | `arr.nix` | 7878 | Media group |
| Prowlarr | `prowlarr` | `arr.nix` | 9696 | — |
| Bazarr | `bazarr` | `arr.nix` | 6767 (module default) | Media group |
| qBittorrent | `qbittorrent` | `arr.nix` | 8080 (module default) | Media group; default save path `/srv/media/downloads` |
| Nextcloud 35 | `nextcloud` | `nextcloud.nix` | 8081 (nginx) | `/srv/nextcloud`; PostgreSQL local |
| Vaultwarden | `vault` | `vaultwarden.nix` | 8222 | Needs `vaultwarden-env` secret |
| Paperless-ngx | `paperless` | `paperless.nix` | 28981 (module default) | `/srv/documents`; needs `paperless-admin` |
| Forgejo | `git` | `forgejo.nix` | 3001 | Git over SSH uses system sshd (`git@git.lab.mlabrecque.dev:owner/repo.git`) |
| FreshRSS | `rss` | `freshrss.nix` | via PHP-FPM (Caddy) | Needs `freshrss-admin` |
| Syncthing | `sync` | `syncthing.nix` | 8384 (GUI) | `/srv/syncthing`; sync on `tailscale0` 22000, discovery 21027 |
| AdGuard Home | `adguard` | `adguardhome.nix` | 3000 | See DNS above |
| Grafana | `grafana` | `monitoring.nix` | 3002 | Needs `grafana-admin`, `grafana-secret-key` |
| Prometheus | `prometheus` | `monitoring.nix` | 9090 (module default) | Node exporter on 127.0.0.1 |
| Tuwunel (Matrix) | `matrix.mlabrecque.dev` | `tuwunel.nix` | 6167 | **Public**; also serves `mlabrecque.dev` well-known |

Module names are the file names under `modules/server/`. `media.nix` is
imported by the Jellyfin and *arr modules and is not a service itself.

### Immich

`modules/server/immich.nix` is not imported. Its comment says the
nixos-26.05 package is marked insecure and 3.x ships with NixOS 26.11. When
re-enabling it, add the import to `machines/homelab.nix` and a Homepage entry.
The module defines a Caddy vhost and `/srv/photos` as media location.

### Dashboard

`modules/server/homepage.nix` lists the services above in four groups
(Media, Downloads, Apps, Infrastructure). Add a service to that list when it is
added to the homelab.

## Storage

Root: `homelab.dataRoot` (`/srv`).

| Path | Owner / group | Used by |
| --- | --- | --- |
| `/srv/media` | `root:media`, `2775` | Jellyfin, *arr apps, qBittorrent |
| `/srv/media/downloads` | `root:media`, `2775` | qBittorrent save path |
| `/srv/media/movies` | `root:media`, `2775` | Radarr, Jellyfin |
| `/srv/media/tv` | `root:media`, `2775` | Sonarr, Jellyfin |
| `/srv/nextcloud` | Nextcloud | Nextcloud data directory |
| `/srv/documents` | Paperless | Paperless media directory |
| `/srv/syncthing` | Syncthing | Syncthing data directory |

`modules/server/media.nix` creates the media directories through
`systemd.tmpfiles`. It does not create the other directories; each module
handles its own path or relies on the service to create it. The
group is `media`. The setgid bit keeps new files in that group.

qBittorrent prints a temporary WebUI password to the journal on first start
(comment in `arr.nix`). Read it with `journalctl -u qbittorrent`.

## Secrets

agenix. Each secret lives in `secrets/<name>.age`. Recipients are in
`secrets/secrets.nix`.

**Current state:** `secrets/secrets.nix` lists only the Mac user key.
The homelab's host key is not a recipient, and no homelab secret is encrypted.
Every block below is commented out.

| Secret (`/run/agenix/<name>`) | Consumer | Expected content |
| --- | --- | --- |
| `nextcloud-admin` | Nextcloud `adminpassFile` | Admin password (path only; no `age.secrets` block) |
| `vaultwarden-env` | Vaultwarden `environmentFile` | `ADMIN_TOKEN=<token>` |
| `paperless-admin` | Paperless `passwordFile` | Admin password |
| `freshrss-admin` | FreshRSS `passwordFile` | Admin password |
| `grafana-admin` | Grafana `admin_password` | Admin password |
| `grafana-secret-key` | Grafana `secret_key` | Secret key |

Services that reference a missing `/run/agenix/<name>` fail at runtime until the
secret exists. Nextcloud's `age.secrets` block is commented out, and its
`adminpassFile` path is set unconditionally.

To enable a secret:

1. Get the homelab's host key: `ssh-keyscan` or read
   `/etc/ssh/ssh_host_ed25519_key.pub` on the machine.
2. Add it to `secrets/secrets.nix` and to each secret's `publicKeys`.
3. From `secrets/`: `agenix -e <name>.age` (create or edit).
4. Uncomment the matching `age.secrets.<name>` block in its module.
5. Rebuild.

## Setup (first install)

Steps in the order the repo's comments require:

1. Install NixOS on the machine. The repo does not define the install procedure.
2. Run `nixos-generate-config` on the homelab. Replace
   `machines/hardware/homelab.nix` with the generated hardware configuration
   (the placeholder's comment says not to deploy it).
3. In `machines/homelab.nix`, set a real boot loader and
   `system.stateVersion`. The generated file does not include a boot loader.
4. Set `networking.hostName` if `nixos` is not wanted.
5. `sudo tailscale up`, then set `homelab.tailscaleIPv4` (see DNS above).
6. Add the host key and provision secrets (see Secrets above).
7. Rebuild on the homelab. The repo does not document the deploy command for
   this host. The VPS pattern is `sudo nixos-rebuild switch --flake .#homelab`
   [INFERENCE: not written down in the repo].

## Maintenance

### Apply changes

    sudo nixos-rebuild switch --flake .#homelab

[INFERENCE: same pattern as the VPS; not documented for this host.]

### Update inputs

    nix flake update nixpkgs-stable home-manager-stable disko

Same list as the root README. `agenix` and `wrappers` are not included.

### State version

Do not change `system.stateVersion` without checking the NixOS release notes.
It is not set yet (see Status).

### Cleanup

- Store GC runs automatically (30 days); store optimisation runs automatically.

### Health checks

    systemctl --failed
    journalctl -u <service> -e

Unit names follow the NixOS module defaults. Confirm on the host.

### Format and check

    nix fmt
    nix flake check

The homelab is not in `checks`, so `nix flake check` does not build its system
toplevel. Build it explicitly if needed:

    nix build .#nixosConfigurations.homelab.config.system.build.toplevel

## Known issues and open items

- Hardware file is a placeholder; system is not installed from this repo.
- `system.stateVersion` and `networking.hostName` are unset.
- No secrets are provisioned; several services fail until they are.
- The homelab and VPS both import `tuwunel.nix` with `server_name =
  mlabrecque.dev`. Planned migration (owner decision): the homelab replaces the
  VPS, which is retired after cutover.
- Immich is not imported.
- No backup configuration exists in the repo for `/srv` or any service state.
- The root `README.md` domain (`home.mlabrecque.dev`) and its Homelab services
  table are out of date.
