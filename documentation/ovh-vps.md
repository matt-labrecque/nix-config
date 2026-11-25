# OVH VPS (`ovh-vps`)

NixOS server for the public Matrix homeserver (Tuwunel), Tailscale, and an
incompletely wired FreshRSS service. For the repo layout, see
[monorepo-structure.md](monorepo-structure.md).

## Identity

| Item | Value | Source |
| --- | --- | --- |
| Flake output | `nixosConfigurations.ovh-vps` | `flake.nix` |
| Machine file | `machines/vps.nix` (selected by `mkNixos "vps"`) | `flake.nix` |
| Hardware | `machines/hardware/ovh-vps.nix`, `machines/hardware/ovh-vps-disk.nix` | `machines/vps.nix` |
| Platform | `x86_64-linux` | `machines/hardware/ovh-vps.nix` |
| Hostname | `ovh-vps` | `machines/vps.nix` |
| nixpkgs | `nixos-26.05` (`nixpkgs-stable`) | `flake.nix` |
| `system.stateVersion` | `"26.05"`, marked `DO NOT BUMP` | `machines/vps.nix` |
| Login user | `mlabrecque` (wheel, zsh, no password) | `modules/linux/default.nix` |
| Public domain | `mlabrecque.dev` | `modules/server/tuwunel.nix` |

The flake output name (`ovh-vps`) differs from the machine file name (`vps`).
Use `.#ovh-vps` for every rebuild command.

## Disk layout

`machines/hardware/ovh-vps-disk.nix` (disko) partitions `/dev/sda` as GPT:

| Partition | Size | Type | Mount |
| --- | --- | --- | --- |
| `boot` | 1 MiB | `EF02` (BIOS boot) | none |
| `ESP` | 512 MiB | `EF00`, vfat, `umask=0077` | `/boot` |
| `root` | rest of disk | ext4 | `/` |

Boot loader: GRUB with `efiSupport = true` and `efiInstallAsRemovable = true`
(`machines/vps.nix`).

`machines/hardware/ovh-vps.nix` is hardware-config output (`nixos-generate-config`
style). It imports `qemu-guest.nix` and sets the initrd and kernel modules.

## Networking

- **IPv4:** DHCP (`networking.useDHCP = true`).
- **IPv6:** static address `2604:2dc0:101:200::2a4/128` on `ens3`, default
  gateway `2604:2dc0:101:200::1` on `ens3`. The values come from OVH's
  OpenStack metadata service, per the comment in `machines/vps.nix`. The gateway
  is outside the `/128`, so `interface` is required to add the on-link route.
- **Firewall (`allowedTCPPorts`):** `22`, `80`, `443`, all public. The UDP port
  for Tailscale is opened by `services.tailscale.openFirewall`.

## SSH

- `services.openssh`: enabled, `PasswordAuthentication = false`.
- Root authorized key is set in `machines/vps.nix`. The file has a `TODO` to
  move this to an agenix secret.
- Login user `mlabrecque` has the same key, defined in `modules/linux/default.nix`
  (also a `TODO` for agenix).
- Passwordless sudo for `wheel` (`security.sudo.wheelNeedsPassword = false`).

## Services

### Matrix homeserver (Tuwunel)

`modules/server/tuwunel.nix`:

- `services.matrix-tuwunel` listens on `127.0.0.1` and `::1`, port `6167`.
- `server_name = mlabrecque.dev`, federation enabled.
- Well-known: client `https://matrix.mlabrecque.dev`, server
  `matrix.mlabrecque.dev:443`.
- Caddy vhosts:
  - `matrix.mlabrecque.dev`: `reverse_proxy /_matrix/*` → `127.0.0.1:6167`.
  - `mlabrecque.dev`: `reverse_proxy /.well-known/matrix/*` → `127.0.0.1:6167`.

Caddy is enabled by this module. HTTPS certificates come from Caddy's default
behavior for public hostnames; the repo sets no explicit TLS options.

### FreshRSS

`machines/vps.nix` imports `modules/server/freshrss.nix`, which enables FreshRSS
through PHP-FPM and Caddy at `rss.${homelab.domain}`. It applies the
tailnet-only Caddy snippet and reads its admin password from
`/run/agenix/freshrss-admin`.

The VPS does not provide the module's dependencies, so this currently prevents
evaluation; see [Known issues and open items](#known-issues-and-open-items).

### Tailscale

`modules/server/tailscale.nix`: `services.tailscale.enable = true`. Join the
tailnet once after the first switch with `sudo tailscale up`.

The Matrix vhosts are public and do not use the `import tailnet` snippet.
FreshRSS tries to use that snippet, but the VPS imports neither
`modules/server/caddy.nix` nor `modules/server/options.nix`.

## Setup

The repo contains the disko layout and NixOS config but no install command
(see open items).

After the system is running:

1. `sudo tailscale up`
2. Confirm SSH key login works before changing `PasswordAuthentication`
   (already `false` in config).

## Maintenance

### Apply changes

On the VPS, from its checkout (path not defined in the repo):

    git pull && sudo nixos-rebuild switch --flake .#ovh-vps

From the MacBook Air, in its checkout (`vps-sync` alias, defined in
`home/darwin/shell.nix`):

    nix run nixpkgs#nixos-rebuild -- switch --flake .#ovh-vps --target-host mlabrecque@ovh-vps --build-host root@ovh-vps

### Update inputs

    nix flake update nixpkgs-stable home-manager-stable disko agenix

`agenix` follows the unstable `nixpkgs` input even though the VPS uses stable
NixOS. Commit `flake.lock` after a successful deploy.

### State version

Do not change `system.stateVersion` (`"26.05"`). Moving the release branch
does not change it. The comment in `machines/vps.nix` says so explicitly.

### Cleanup

- Store GC runs automatically (30 days) and store optimisation runs
  automatically (`modules/shared/default.nix`).

### Format and check

    nix fmt
    nix eval --raw .#nixosConfigurations.ovh-vps.config.system.build.toplevel.drvPath

`checks.x86_64-linux.ovh-vps` builds the system toplevel when `nix flake check`
runs on x86_64-linux. On the Mac, use the evaluation command above instead.

### Checking the Matrix stack

    systemctl status tuwunel caddy tailscaled
    journalctl -u tuwunel -e

## Known issues and open items

- The VPS configuration cannot evaluate FreshRSS as imported: `freshrss.nix` reads
  `config.homelab.domain` and applies `import tailnet`, but the VPS imports
  neither `options.nix` nor `caddy.nix` and sets no `homelab.domain`. Remove the
  import or provide those dependencies before deploying. FreshRSS also needs
  the `freshrss-admin` secret, which is not provisioned.
- The homelab config also imports `modules/server/tuwunel.nix` with the same
  `server_name`. Planned migration (owner decision, not encoded in the repo):
  the homelab replaces this VPS, and the VPS is retired after cutover.
  `machines/homelab.nix` carries the matching comment.
- Root and login-user SSH keys are hard-coded (`TODO` for agenix).
- No backup configuration exists in the repo. Matrix data is stored on the VPS
  disk.
- No install procedure is documented in the repo.
