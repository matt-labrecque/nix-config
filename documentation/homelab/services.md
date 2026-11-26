# Services

Module names are files under `modules/server/`. URLs are
`https://<subdomain>.lab.mlabrecque.dev` unless noted. Ports, units, users, and
paths below are evaluated from the config; "module default" means the repo does
not set the value.

## Catalog

| Service | Subdomain | Module | Port | Bind | Units | Runs as |
| --- | --- | --- | --- | --- | --- | --- |
| Homepage | apex (`lab.mlabrecque.dev`) | `homepage.nix` | `8082` | app default (all) | `homepage-dashboard` | dynamic user |
| Jellyfin | `jellyfin` | `jellyfin.nix` | `8096` (app default) | app default (all) | `jellyfin` | `jellyfin` (+ `media`) |
| Sonarr | `sonarr` | `arr.nix` | `8989` (app default) | app default (all) | `sonarr` | `sonarr:media` |
| Radarr | `radarr` | `arr.nix` | `7878` (app default) | app default (all) | `radarr` | `radarr:media` |
| Prowlarr | `prowlarr` | `arr.nix` | `9696` (app default) | app default (all) | `prowlarr` | dynamic user |
| Bazarr | `bazarr` | `arr.nix` | `6767` (module default) | app default (all) | `bazarr` | `bazarr:media` |
| qBittorrent | `qbittorrent` | `arr.nix` | `8080` (module default) | app default (all) | `qbittorrent` | `qbittorrent:media` |
| Nextcloud 35 | `nextcloud` | `nextcloud.nix` | `8081` (nginx) | `127.0.0.1` | `phpfpm-nextcloud`, `nginx`, `nextcloud-setup`, `postgresql`, `redis-nextcloud` | `nextcloud` |
| Vaultwarden | `vault` | `vaultwarden.nix` | `8222` | `127.0.0.1` | `vaultwarden` | `vaultwarden` |
| Paperless-ngx | `paperless` | `paperless.nix` | `28981` (module default) | `127.0.0.1` | `paperless-web`, `paperless-consumer`, `paperless-scheduler`, `paperless-task-queue`, `redis-paperless` | `paperless` |
| Forgejo | `git` | `forgejo.nix` | `3001` | `127.0.0.1` | `forgejo` | `forgejo` |
| FreshRSS | `rss` | `freshrss.nix` | PHP-FPM socket | socket | `phpfpm-freshrss` | `freshrss` |
| Syncthing | `sync` | `syncthing.nix` | GUI `8384`; sync `22000`, discovery `21027` | GUI `127.0.0.1`; sync all | `syncthing` | `syncthing` |
| AdGuard Home | `adguard` | `adguardhome.nix` | UI `3000`; DNS `53` | UI `127.0.0.1`; DNS `0.0.0.0` | `adguardhome` | dynamic user |
| Grafana | `grafana` | `monitoring.nix` | `3002` | `127.0.0.1` | `grafana` | `grafana` |
| Prometheus | `prometheus` | `monitoring.nix` | `9090` (module default); exporter `9100` | `127.0.0.1` | `prometheus`, `prometheus-node-exporter` | `prometheus` |
| Tuwunel (Matrix) | `matrix.mlabrecque.dev` (public) | `tuwunel.nix` | `6167` | `127.0.0.1`, `::1` | `tuwunel` | dynamic user |

"App default (all)" means the repo sets no bind address and the application
listens on every interface. Those ports are not opened in the firewall, so they
are unreachable from outside the host, but the loopback-only rule from the
[server module pattern](architecture.md#server-module-pattern) is not enforced
for them ([open-items.md](open-items.md#known-issues)). The ports Caddy proxies
to for Jellyfin, Sonarr, Radarr, and Prowlarr are hard-coded in the vhosts and
must match the app defaults.

Accepting outside connections by design: Caddy, sshd, AdGuard DNS, Syncthing
sync, Tailscale.

Infrastructure units: `caddy`, `tailscaled`, `sshd`.

## Credentials and first run

| Service | Initial admin | Source of credential |
| --- | --- | --- |
| Homepage | none (no auth) | — |
| Jellyfin | created in the setup wizard on first visit | web UI |
| Sonarr, Radarr, Prowlarr, Bazarr | set on first visit | web UI |
| qBittorrent | `admin`, temporary password | `journalctl -u qbittorrent` on first start |
| Nextcloud | `root` | `/run/agenix/nextcloud-admin` (read only at initial setup) |
| Vaultwarden | `/admin` page | `ADMIN_TOKEN` in `/run/agenix/vaultwarden-env` |
| Paperless | `admin` | `/run/agenix/paperless-admin` |
| Forgejo | created after install | web UI or `forgejo admin user create` |
| FreshRSS | `admin` | `/run/agenix/freshrss-admin` |
| Syncthing | none set by the repo | GUI settings |
| AdGuard Home | none set by the repo | web UI |
| Grafana | `admin` | `/run/agenix/grafana-admin` (applied when the admin is first created) |
| Tuwunel | registration not configured | — |

Services reading `/run/agenix/*` fail or start without a usable admin until
the secret exists ([secrets.md](secrets.md)).

## Dashboard

`homepage.nix` serves Homepage at the apex domain (`allowedHosts =
lab.mlabrecque.dev`) with four groups:

| Group | Links |
| --- | --- |
| Media | Jellyfin |
| Downloads | Sonarr, Radarr, Prowlarr, Bazarr, qBittorrent |
| Apps | Nextcloud, Vaultwarden, Paperless, Forgejo, FreshRSS, Syncthing |
| Infrastructure | AdGuard Home, Grafana, Prometheus |

Entries are built with `link "<Label>" "<subdomain>"`. Add one whenever a
service is added; nothing checks the list against the imports.

## Media and downloads

`jellyfin.nix` and `arr.nix` both import `media.nix`, which creates the `media`
group and the `/srv/media` tree ([storage.md](storage.md#media-library)).
Everything that writes to the library runs in that group; Jellyfin joins it via
`extraGroups`. Prowlarr only talks to the other apps and stays out of it.

qBittorrent's default save path is `/srv/media/downloads`
(`serverConfig.BitTorrent.Session.DefaultSavePath`). Keeping downloads inside
`/srv/media` puts them on the same filesystem as the library, so Sonarr and
Radarr can hardlink or move instead of copying, provided `/srv/media` is one
filesystem.

Wiring done in the web UIs (not in the repo):

| In | Add | Address |
| --- | --- | --- |
| Prowlarr → Apps | Sonarr, Radarr | `http://127.0.0.1:8989`, `http://127.0.0.1:7878` + their API keys |
| Sonarr, Radarr → Download clients | qBittorrent | `127.0.0.1:8080` |
| Sonarr → Root folders | | `/srv/media/tv` |
| Radarr → Root folders | | `/srv/media/movies` |
| Bazarr → Settings | Sonarr, Radarr | `127.0.0.1:8989`, `127.0.0.1:7878` |
| Jellyfin → Libraries | Shows, Movies | `/srv/media/tv`, `/srv/media/movies` |

## Nextcloud

- `pkgs.nextcloud35`; hostname `nextcloud.lab.mlabrecque.dev`.
- Data directory `/srv/nextcloud`; app home `/var/lib/nextcloud`.
- PostgreSQL 17 created locally (database `nextcloud`); Redis enabled by the
  module.
- `https = true` so Nextcloud generates `https://` URLs although TLS ends at
  Caddy; `trusted_proxies` = `127.0.0.1`, `::1`.
- The upstream module serves through nginx; the repo moves that vhost to
  `127.0.0.1:8081` and Caddy proxies to it.
- `autoUpdateApps` is off; apps update through the web UI or with the release.

## Vaultwarden

- `DOMAIN = https://vault.lab.mlabrecque.dev`, Rocket on `127.0.0.1:8222`.
- SQLite in `/var/lib/vaultwarden`; `backupDir` is not set.
- `environmentFile = /run/agenix/vaultwarden-env` (holds `ADMIN_TOKEN`).
- `SIGNUPS_ALLOWED` is not set, so Vaultwarden's default (open signups) applies;
  only tailnet devices can reach it.

## Paperless-ngx

- `PAPERLESS_URL = https://paperless.lab.mlabrecque.dev`.
- Documents in `/srv/documents` (`mediaDir`); app data and database in
  `/var/lib/paperless`. No `PAPERLESS_DBHOST`, so Paperless uses SQLite.
- Superuser `admin` with the password from `/run/agenix/paperless-admin`.

## Forgejo

- `DOMAIN`/`ROOT_URL` `git.lab.mlabrecque.dev`, HTTP on `127.0.0.1:3001`.
- SQLite, state in `/var/lib/forgejo`.
- Git over SSH uses the system sshd (port 22, tailnet only). No `SSH_USER` or
  custom `user` is set, so Forgejo advertises its run user:

      forgejo@git.lab.mlabrecque.dev:<owner>/<repo>.git

  The comment in `forgejo.nix` says `git@…`; that is inaccurate as configured
  ([open-items.md](open-items.md#known-issues)).
- Registration is not disabled in the repo.

## FreshRSS

- `baseUrl = https://rss.lab.mlabrecque.dev`, data in `/var/lib/freshrss`.
- `webserver = "caddy"`: the upstream module writes the Caddy vhost (PHP-FPM).
  The repo adds `import tailnet` in front with `lib.mkBefore`.
- Default user `admin`, password from `/run/agenix/freshrss-admin`.

## Syncthing

- Runs as `syncthing`; data in `/srv/syncthing`, config in
  `/srv/syncthing/.config/syncthing`.
- GUI on `127.0.0.1:8384`. Caddy rewrites `Host` to the upstream address
  because the GUI rejects other hosts.
- Sync (TCP/UDP 22000) and local discovery (UDP 21027) open only on
  `tailscale0`; peers should use the homelab's Tailscale address.
- Folders and devices are configured in the GUI; none are declared in Nix.

## Monitoring

- Prometheus on `127.0.0.1:9090`, scraping the node exporter at
  `127.0.0.1:9100` (job `node`, default collectors). State in
  `/var/lib/prometheus2`.
- Grafana on `127.0.0.1:3002`, `root_url https://grafana.lab.mlabrecque.dev/`,
  Prometheus provisioned as the default datasource. No dashboards are
  provisioned; import one (e.g. "Node Exporter Full") in the UI.
- Grafana's `admin_password` and `secret_key` use `$__file{/run/agenix/...}`.

No service-specific exporters or alerting are configured.

## AdGuard Home

See [network.md](network.md#dns). UI on `127.0.0.1:3000`, DNS on `0.0.0.0:53`
(tailnet-only by firewall), mutable settings, state in `/var/lib/AdGuardHome`
(dynamic user, so physically `/var/lib/private/AdGuardHome`).

## Tuwunel (Matrix)

`tuwunel.nix`, shared with the VPS:

- `server_name = mlabrecque.dev`, federation on, listening on `127.0.0.1` and
  `::1` port `6167`.
- Well-known: client `https://matrix.mlabrecque.dev`, server
  `matrix.mlabrecque.dev:443`, served on `mlabrecque.dev/.well-known/matrix/*`.
- Caddy proxies `matrix.mlabrecque.dev/_matrix/*` and
  `mlabrecque.dev/.well-known/matrix/*` to Tuwunel; both are public.
- Database at `/var/lib/tuwunel` (dynamic user, physically
  `/var/lib/private/tuwunel`).

Until the cutover, the homelab instance is a separate, empty server with the
same `server_name`; the VPS is the live one. See
[open-items.md](open-items.md#matrix-cutover-vps--homelab).

## Immich (not imported)

`immich.nix` would serve `immich.lab.mlabrecque.dev` (module default port
`2283`) with photos in `/srv/photos`. Not imported because nixos-26.05 marks
Immich 2.7.5 insecure. See [open-items.md](open-items.md#immich).
