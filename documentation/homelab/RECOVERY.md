# Recovery

Bringing the homelab back after a system failure: dead disk, replaced hardware,
or an install too broken to repair. For a first-ever install, use
[setup.md](setup.md); for a bad deploy, roll back instead (below).

**No backups are configured in the repo.** This runbook has two paths: with a
backup of the items in [storage.md](storage.md#backup-inventory), and without
one. Read [Prepare now](#prepare-now) while the homelab still works.

## Triage

| Situation | Path |
| --- | --- |
| Boots, but the last deploy broke something | `sudo nixos-rebuild switch --rollback`, or pick an older generation in the boot menu. Stop here. |
| Won't boot after a deploy | Boot an older generation from the boot menu, then roll back. Stop here. |
| System disk dead or wiped; `/srv` disk intact | This runbook; do not format the `/srv` disk |
| Everything lost (new hardware, all disks) | This runbook, restoring `/srv` from backup or starting empty |

## What survives a failure

| Where | What | Why it matters |
| --- | --- | --- |
| Git (the Mac checkout, the remote) | All configuration, `flake.lock`, encrypted `secrets/*.age` | `flake.lock` pins the exact package versions, so the rebuild matches the old system |
| The Mac's SSH key (`~/.ssh/id_ed25519`) | Recipient of every secret | The Mac can decrypt and re-encrypt all secrets for a new host key |
| Tailscale admin console | Old node entry, split DNS setting (points at the old IP) | Needs cleanup or reuse |
| Client devices | Trusted Caddy root, Syncthing copies, Bitwarden offline vault cache, Git clones | Possible partial data recovery without backups |
| Backup (if any) | The backup inventory | Everything stateful |

Lost without a backup: all service state, `/srv` (unless its disk survived),
the SSH host key, the Caddy internal CA, the Tailscale node identity, and
the Matrix signing key.

## Prepare now

Do these while the homelab works, or recovery becomes the "without backups"
path:

- [ ] Back up everything in the [backup inventory](storage.md#backup-inventory),
      off the homelab. Dump PostgreSQL (`pg_dump`) instead of copying its files.
- [ ] Keep a copy of `/etc/ssh/ssh_host_ed25519_key` and its `.pub` somewhere
      safe, off the homelab. With it, secrets decrypt unchanged on the new
      system.
- [ ] Back up the Mac's `~/.ssh/id_ed25519`. It is the only key besides the host
      key that can decrypt the secrets.
- [ ] Do not keep the only copy of recovery credentials (backup passphrase,
      Tailscale login, DNS registrar) in Vaultwarden: it runs on the homelab.
- [ ] Note the homelab's Tailscale IP and the disk layout (`lsblk -f`).

## Before you start

You need:

- The Mac with the checkout, up to date (`git pull`).
- A NixOS 26.05 installer USB.
- Access to the backup, the Tailscale admin console, and (after the Matrix
  cutover) the router and public DNS.

If Matrix is already served from the homelab, **disable the router's 80/443
forwards** until Tuwunel's data is restored. Otherwise the fresh install
generates a new Matrix signing key and announces it to other servers.

## 1. Partition and mount

Boot the installer and partition the new system disk. If the `/srv` disk
survived, leave it untouched and only mount it:

    # example; adapt devices and filesystems
    mount /dev/disk/by-label/nixos /mnt
    mkdir -p /mnt/boot /mnt/srv
    mount /dev/disk/by-label/boot /mnt/boot
    mount /dev/disk/by-label/srv /mnt/srv      # surviving or new data disk

## 2. Hardware configuration

Disk UUIDs change with new disks, so regenerate:

    nixos-generate-config --root /mnt --show-hardware-config > hardware.nix

Put it in `machines/hardware/homelab.nix` in the checkout (diff against the old
one; keep the `/srv` mount). Check that `machines/homelab.nix` still matches the
hardware: boot loader (UEFI vs BIOS) and `networking.hostName`. **Keep
`system.stateVersion` as it was**, even on a newer installer: it describes the
data on disk, not the installer.

Commit on the Mac and get the checkout onto the installer (clone it, or copy it
over the LAN after setting a password with `passwd` on the installer).

## 3. SSH host key

**With the old host key:** restore it before installing, so agenix can decrypt
during the first activation:

    mkdir -p /mnt/etc/ssh
    cp ssh_host_ed25519_key ssh_host_ed25519_key.pub /mnt/etc/ssh/
    chmod 600 /mnt/etc/ssh/ssh_host_ed25519_key
    chmod 644 /mnt/etc/ssh/ssh_host_ed25519_key.pub

**Without it:** install first (step 4) and let sshd generate a new key, then
re-encrypt on the Mac:

1. On the homelab: `cat /etc/ssh/ssh_host_ed25519_key.pub`.
2. Replace the homelab key in `secrets/secrets.nix`.
3. From `secrets/`: `agenix -r` (re-encrypts every file; the Mac key decrypts).
4. Commit, pull on the homelab, switch.

Until then, services reading `/run/agenix/*` fail.

## 4. Install

    nixos-install --flake /path/to/checkout#homelab

Set the root password when prompted. `mlabrecque` has no password: until
Tailscale is up, the console `root` login is the only way in, because SSH is
tailnet-only.

If evaluating on the installer fails while fetching an input the homelab does
not use (`zk` is a `path:` input to a Mac directory), install a minimal NixOS
instead, then deploy from the Mac, which evaluates locally and builds on the
homelab ([operations.md](operations.md#change--verify--deploy)).

Reboot into the new system.

## 5. Tailscale

The old node identity lives in `/var/lib/tailscale`. Run only one machine with
it: if the old hardware could come back, take the fresh path.

**Restore it** (from backup) to keep the same node and IP; nothing else
changes:

    sudo systemctl stop tailscaled
    # restore /var/lib/tailscale from backup
    sudo systemctl start tailscaled

**Or join fresh:**

1. Delete the old node in the admin console.
2. `sudo tailscale up`, then `tailscale ip -4`.
3. Either set the old IPv4 on the new node in the admin console (machine →
   Edit IP address), or update everything that points at the old one:
   `homelab.tailscaleIPv4` in `machines/homelab.nix` (commit, switch), the
   split DNS nameserver, and Syncthing peers that use the address.
4. Disable key expiry on the new node.

SSH from the Mac works again once this is done.

## 6. Restore service data

The first activation started every service with empty state (Nextcloud ran its
installer, Vaultwarden created an empty vault). Replace that state with the
backup: stop the service, restore its paths, fix ownership, start it.

Service UIDs can differ from the old system, so set ownership after restoring
rather than trusting the archive's numeric owners. Dynamic-user services
(`/var/lib/private/*`) are re-owned by systemd on start.

| Service | Stop | Restore | Then |
| --- | --- | --- | --- |
| Caddy | `caddy` | `/var/lib/caddy` | `chown -R caddy:caddy /var/lib/caddy`; clients keep trusting the old root |
| Vaultwarden | `vaultwarden` | `/var/lib/vaultwarden` | `chown -R vaultwarden:vaultwarden` |
| Tuwunel | `tuwunel` | `/var/lib/private/tuwunel` | re-owned on start; then re-enable router forwards |
| Nextcloud | `phpfpm-nextcloud nginx` | database, `/var/lib/nextcloud/config`, `/srv/nextcloud` | see below |
| Paperless | `paperless-web paperless-consumer paperless-scheduler paperless-task-queue` | `/var/lib/paperless`, `/srv/documents` | `chown -R paperless:paperless` both |
| Forgejo | `forgejo` | `/var/lib/forgejo` | `chown -R forgejo:forgejo` |
| FreshRSS | `phpfpm-freshrss` | `/var/lib/freshrss` | `chown -R freshrss:freshrss` |
| Syncthing | `syncthing` | `/srv/syncthing` (includes `.config/syncthing`, the device ID) | `chown -R syncthing:syncthing` |
| Jellyfin | `jellyfin` | `/var/lib/jellyfin` | `chown -R jellyfin:jellyfin` |
| Sonarr, Radarr, Bazarr | `sonarr radarr bazarr` | `/var/lib/{sonarr,radarr,bazarr}` | `chown -R <name>:media` |
| qBittorrent | `qbittorrent` | `/var/lib/qBittorrent` | `chown -R qbittorrent:media` |
| Prowlarr, AdGuard | `prowlarr adguardhome` | `/var/lib/private/{prowlarr,AdGuardHome}` | re-owned on start |
| Grafana | `grafana` | `/var/lib/grafana` | `chown -R grafana:grafana` |
| Media library | — | `/srv/media` (if backed up) | `chown -R root:media /srv/media`, `chmod -R g+rwX /srv/media`, `find /srv/media -type d -exec chmod g+s {} +` |

`systemd-tmpfiles` recreates the empty media directories and their modes on
boot; it does not fix ownership of restored files inside them.

### Nextcloud

The config (`config.php` holds the instance ID and salts), the database, and
the data directory must come from the same backup:

    sudo systemctl stop phpfpm-nextcloud nginx
    sudo -u postgres psql -c 'DROP DATABASE nextcloud;'
    sudo -u postgres psql -c 'CREATE DATABASE nextcloud OWNER nextcloud;'
    sudo -u postgres psql nextcloud < nextcloud.sql
    # restore /var/lib/nextcloud/config and /srv/nextcloud
    sudo chown -R nextcloud:nextcloud /var/lib/nextcloud /srv/nextcloud
    sudo systemctl start phpfpm-nextcloud nginx
    sudo nextcloud-occ maintenance:mode --off
    sudo nextcloud-occ maintenance:data-fingerprint

The last command tells sync clients the server was restored, so they
re-check files instead of assuming the server is current.

## 7. Verify

    systemctl --failed
    tailscale status
    dig @<tailscale-ip> vault.lab.mlabrecque.dev     # from a tailnet device

Then from a client: open `https://lab.mlabrecque.dev`, follow each link, log
into Vaultwarden, Nextcloud, and Paperless, and push to a Forgejo repo. After
the Matrix cutover, also run the checks in
[open-items.md](open-items.md#matrix-cutover-vps--homelab) (step 6).

## Without backups

The system comes back fully from the flake; the data does not. After steps
1–5, on top of the per-service first-run setup in
[services.md](services.md#credentials-and-first-run):

| Lost | Do |
| --- | --- |
| Caddy CA | Remove the old root from every client, trust the new one ([setup.md](setup.md#9-client-onboarding)) |
| Vaultwarden | **Before** any client syncs with the empty server, export the vault from a client that is still logged in (desktop app or browser extension keep an offline copy), then import it into a new account |
| Syncthing | New device ID: remove the old device on each peer, add the new one; the peers' copies re-seed `/srv/syncthing` |
| Forgejo | Re-create users and repositories; push from local clones; re-add SSH keys |
| Nextcloud | Fresh instance; desktop clients re-upload from their local copies after re-login |
| Paperless | Re-ingest documents from wherever originals exist |
| *arr, qBittorrent, Jellyfin, AdGuard, Grafana | Reconfigure in the web UIs ([services.md](services.md#media-and-downloads)) |
| Matrix (after cutover) | New signing key and empty database under the same `server_name`; accounts and history are gone, and other servers pick up the new key once their cached copy expires |

## Afterwards

- Commit the new hardware file and any changed values (`tailscaleIPv4`, host key
  in `secrets/secrets.nix`).
- Update these docs if the layout changed (disks, IPs).
- Set up the backups in [Prepare now](#prepare-now) if they were missing.
