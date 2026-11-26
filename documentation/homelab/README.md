# Homelab (`homelab`)

NixOS server for personal services: media, files, passwords, documents, Git,
RSS, sync, DNS, monitoring, and (after migration from the VPS) the public
Matrix homeserver. Everything except Matrix is reachable only over Tailscale.

For the repo as a whole, see
[../monorepo-structure.md](../monorepo-structure.md).

## Status

**Not deployable yet.** The repo evaluates the homelab, but the machine is not
installed and several values only exist after installation:

- `machines/hardware/homelab.nix` is a placeholder (dummy root filesystem,
  GRUB `nodev`).
- `system.stateVersion` and `networking.hostName` are unset (evaluation warns;
  hostname defaults to `nixos`).
- No secrets are provisioned; every `age.secrets` block is commented out.
- `homelab.tailscaleIPv4` is unset, so AdGuard has no DNS rewrites.

The full list is in [open-items.md](open-items.md); the install procedure is in
[setup.md](setup.md).

## At a glance

| Item | Value | Source |
| --- | --- | --- |
| Flake output | `nixosConfigurations.homelab` | `flake.nix` |
| Machine file | `machines/homelab.nix` (`mkNixos "homelab"`) | `flake.nix` |
| Hardware | `machines/hardware/homelab.nix` (placeholder) | `machines/homelab.nix` |
| Platform | `x86_64-linux` | `machines/homelab.nix` |
| nixpkgs | `nixos-26.05` (`nixpkgs-stable`) | `flake.nix` |
| Home Manager | `release-26.05`, profile `home/shared` | `flake.nix` |
| Base domain | `lab.mlabrecque.dev` (`homelab.domain`) | `machines/homelab.nix` |
| Data root | `/srv` (`homelab.dataRoot`) | `modules/server/options.nix` |
| Login user | `mlabrecque` (wheel, zsh, SSH key only, passwordless sudo) | `modules/linux/default.nix` |
| `checks` entry | none (evaluate explicitly) | `flake.nix` |

URLs follow `https://<name>.lab.mlabrecque.dev`; the dashboard is
`https://lab.mlabrecque.dev`. Matrix is public at `matrix.mlabrecque.dev`.

## Documents

| Document | Covers |
| --- | --- |
| [architecture.md](architecture.md) | How the flake, layers, and server modules compose; runtime topology; how services depend on each other |
| [network.md](network.md) | Tailscale, split DNS and AdGuard, Caddy and TLS, the `tailnet` guard, firewall, SSH, public exposure |
| [services.md](services.md) | Every service: URL, port, unit, user, state, credentials, first-run steps |
| [storage.md](storage.md) | `/srv` layout, the media group, service state under `/var/lib`, backup inventory |
| [secrets.md](secrets.md) | agenix on the homelab, every secret, enabling procedure |
| [setup.md](setup.md) | First install runbook and client onboarding |
| [operations.md](operations.md) | Deploying, updating, health checks, adding a service, troubleshooting |
| [open-items.md](open-items.md) | Known issues, Immich, the VPS → homelab Matrix cutover runbook |
| [RECOVERY.md](RECOVERY.md) | Rebuilding from scratch after a system failure, with or without backups |

## Quick reference

    # evaluate (on the Mac; seconds)
    nix eval --raw .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath

    # apply (on the homelab, from its checkout)
    sudo nixos-rebuild switch --flake .#homelab

    # what's failing
    systemctl --failed
