# Storage

User data lives under `homelab.dataRoot` (`/srv`); application state lives in
each service's default directory under `/var/lib`. The disk layout is not
decided: the hardware file is a placeholder, so nothing in the repo mounts a
separate filesystem at `/srv`.

## `/srv`

| Path | Owner / mode | Created by | Used by |
| --- | --- | --- | --- |
| `/srv/media` | `root:media`, `2775` | `media.nix` (tmpfiles) | media library root |
| `/srv/media/downloads` | `root:media`, `2775` | `media.nix` | qBittorrent default save path |
| `/srv/media/movies` | `root:media`, `2775` | `media.nix` | Radarr, Jellyfin |
| `/srv/media/tv` | `root:media`, `2775` | `media.nix` | Sonarr, Jellyfin |
| `/srv/nextcloud` | `nextcloud` | Nextcloud module | Nextcloud data directory (`datadir`) |
| `/srv/documents` | `paperless` | Paperless module | Paperless documents (`mediaDir`) |
| `/srv/syncthing` | `syncthing` | Syncthing module | Syncthing data and config (`dataDir`) |
| `/srv/photos` | — | — | Immich `mediaLocation` once imported |

### Media library

`media.nix` creates the `media` group and the directories above through
`systemd.tmpfiles.settings."10-media"`. Mode `2775` gives the group write
access, and the setgid bit makes new files and directories inherit the `media`
group.

Members: `sonarr`, `radarr`, `bazarr`, and `qbittorrent` run with
`group = "media"`; `jellyfin` has it in `extraGroups`.

The setgid bit fixes the group, not the permission bits: files are created
with each service's umask. If Sonarr or Radarr cannot move or delete files
qBittorrent wrote, the services' umask is the first thing to check
([operations.md](operations.md#troubleshooting)).

## Service state

Evaluated from each module. Dynamic-user services keep their state in
`/var/lib/private/<name>`, with `/var/lib/<name>` as a symlink.

| Service | State | Database |
| --- | --- | --- |
| Caddy | `/var/lib/caddy` (includes the internal CA) | — |
| Tailscale | `/var/lib/tailscale` (node identity) | — |
| AdGuard Home | `/var/lib/private/AdGuardHome` | — |
| Homepage | `/var/lib/private/homepage-dashboard` | — |
| Jellyfin | `/var/lib/jellyfin` | SQLite |
| Sonarr | `/var/lib/sonarr/.config/NzbDrone` | SQLite |
| Radarr | `/var/lib/radarr/.config/Radarr` | SQLite |
| Prowlarr | `/var/lib/private/prowlarr` | SQLite |
| Bazarr | `/var/lib/bazarr` | SQLite |
| qBittorrent | `/var/lib/qBittorrent` | — |
| Nextcloud | `/var/lib/nextcloud` (config, apps) | PostgreSQL 17, `/var/lib/postgresql/17` |
| Vaultwarden | `/var/lib/vaultwarden` | SQLite |
| Paperless | `/var/lib/paperless` | SQLite |
| Forgejo | `/var/lib/forgejo` (repositories, LFS) | SQLite |
| FreshRSS | `/var/lib/freshrss` | SQLite |
| Grafana | `/var/lib/grafana` | SQLite |
| Prometheus | `/var/lib/prometheus2` | TSDB |
| Tuwunel | `/var/lib/private/tuwunel` | RocksDB (includes the server signing key) |

## Backup inventory

**No backup is configured in the repo.** Until one exists, this is what a
restore would need, most critical first:

| What | Why it matters |
| --- | --- |
| `/etc/ssh/ssh_host_ed25519_key` | agenix decrypts every secret with it; losing it means re-encrypting all secrets for a new key |
| `/var/lib/vaultwarden` | Password vault |
| `/var/lib/private/tuwunel` | Matrix history and the server signing key (federation identity) |
| PostgreSQL `nextcloud` database + `/srv/nextcloud` + `/var/lib/nextcloud/config` | Nextcloud needs all three consistent; dump the DB (`pg_dump`) rather than copying files of a running server |
| `/srv/documents` + `/var/lib/paperless` | Documents and their metadata/index |
| `/var/lib/forgejo` | Repositories and issues |
| `/srv/syncthing` | Synced files (other devices may hold copies) |
| `/var/lib/caddy` | Internal CA; losing it means trusting a new root on every client |
| `/var/lib/tailscale` | Node identity; restoring it keeps the same tailnet IP, so DNS and peers need no changes |
| `/var/lib/{sonarr,radarr,bazarr,jellyfin,freshrss,grafana}`, `/var/lib/private/{prowlarr,AdGuardHome}`, `/var/lib/qBittorrent` | App configuration done in web UIs |
| `/srv/media` | Large; re-obtainable, so often excluded |
| `/var/lib/prometheus2` | Metrics history; usually excluded |

Everything else is reproducible from the flake. The restore procedure is in
[RECOVERY.md](RECOVERY.md#6-restore-service-data).
