# Operations

Day-to-day work on the homelab: changing config, deploying, updating, checking
health, and fixing common problems.

## Change → verify → deploy

1. Edit on the Mac.
2. Verify (seconds, no build):

       nix fmt
       nix eval --raw .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath

   The homelab is not in `checks`, so `nix flake check` skips it, and the Mac
   cannot build `x86_64-linux` locally. Until the machine is installed,
   evaluation warns that `system.stateVersion` is unset; that is expected.
3. Commit and push.
4. Deploy, either way:

   On the homelab, from its checkout:

       git pull && sudo nixos-rebuild switch --flake .#homelab

   From the Mac over the tailnet, building on the homelab (same shape as the
   VPS's `vps-sync` alias; no homelab alias exists):

       nix run nixpkgs#nixos-rebuild -- switch --flake .#homelab \
         --target-host mlabrecque@<homelab> --build-host mlabrecque@<homelab> --sudo

   `--build-host` is required because the Mac is `aarch64-darwin`.
   `mlabrecque` is a Nix trusted user (`modules/shared`), so it can receive
   store paths.

Changes to `modules/shared`, `modules/linux`, `home/shared`, or a server module
the VPS also imports (`tailscale.nix`, `tuwunel.nix`, `freshrss.nix`) affect the
VPS too; evaluate `ovh-vps` as well.

## Rolling back

    sudo nixos-rebuild switch --rollback

Older generations are also in the boot menu. Rollback restores the system, not
service data: a migration a new package ran on its database stays.

## Updating

Only when intended; the stable inputs are shared with the VPS:

    nix flake update nixpkgs-stable home-manager-stable disko agenix

Commit `flake.lock` with the update, deploy, and check `systemctl --failed`.

Moving to a new NixOS release means changing the `nixpkgs-stable` and
`home-manager-stable` URLs in `flake.nix`; read the release notes first
(Nextcloud is pinned to `nextcloud35` and must be stepped one major version at
a time). Never change `system.stateVersion` as part of this.

Housekeeping is automatic (`modules/shared/default.nix`): store GC daily at
03:15 (NixOS default schedule) deleting generations older than 30 days, and
store optimisation daily at 03:45.

## Health checks

    systemctl --failed
    systemctl status caddy tailscaled adguardhome
    journalctl -u <unit> -e
    journalctl -u caddy -f              # live proxy and TLS errors

Units per service are listed in [services.md](services.md#catalog). Useful
groups:

    systemctl status sonarr radarr prowlarr bazarr qbittorrent jellyfin
    systemctl status phpfpm-nextcloud nginx postgresql redis-nextcloud
    systemctl status paperless-web paperless-consumer paperless-task-queue
    systemctl status prometheus prometheus-node-exporter grafana

Grafana (`https://grafana.lab.mlabrecque.dev`) shows host metrics from the node
exporter; there is no alerting.

## Adding a service

1. Create `modules/server/<name>.nix` (one service per file):

   ```nix
   { config, ... }:
   let
     host = "<name>.${config.homelab.domain}";
     port = 1234;
   in
   {
     services.<name> = {
       enable = true;
       # bind to 127.0.0.1 and set the port; option names vary per module
     };

     services.caddy.virtualHosts.${host}.extraConfig = ''
       import tailnet
       reverse_proxy 127.0.0.1:${toString port}
     '';
   }
   ```

   Data that belongs to the user goes under `${config.homelab.dataRoot}`.
   Non-HTTP ports go in `networking.firewall.interfaces.tailscale0` only.
2. `git add -N modules/server/<name>.nix` (flakes ignore untracked files).
3. Import it in `machines/homelab.nix`.
4. Add a `link` entry to the right group in `modules/server/homepage.nix`.
5. If it needs a secret, follow [secrets.md](secrets.md).
6. Update [services.md](services.md) and, if relevant, [storage.md](storage.md).
7. Verify and deploy as above. AdGuard's wildcard rewrite already covers the
   new subdomain; no DNS change is needed.

## Removing a service

Drop the import (and the Homepage link). NixOS stops the unit on the next
switch, but data in `/var/lib/<name>` and `/srv` stays until deleted by hand.

## Troubleshooting

| Symptom | Likely cause | Check / fix |
| --- | --- | --- |
| Browser warns about the certificate | Caddy root not trusted on this device | [setup.md](setup.md#9-client-onboarding) |
| Connection reset / empty reply on a lab URL | Request did not come from a Tailscale address (`abort @outside`) | `tailscale status` on the client; is the client connected? |
| Lab name does not resolve | Split DNS missing, `homelab.tailscaleIPv4` unset, or client has Tailscale DNS off | `dig @<tailscale-ip> x.lab.mlabrecque.dev`; admin console DNS page |
| 502 from Caddy | Backend down or wrong port | `systemctl status <unit>`; compare the vhost port with the service's |
| Service fails mentioning `/run/agenix/...` | Secret not provisioned or block still commented out | [secrets.md](secrets.md) |
| Syncthing GUI: "Host check error" | `Host` header rewrite missing | `header_up Host {upstream_hostport}` in `syncthing.nix` |
| Nextcloud "untrusted domain" | Accessed by a name other than `nextcloud.lab.mlabrecque.dev` | use the configured hostname |
| qBittorrent login unknown | Temporary password on first start | `journalctl -u qbittorrent` |
| Sonarr/Radarr cannot import or delete downloads | File permissions: group is `media` but umask leaves no group write | inspect modes under `/srv/media/downloads`; set `UMask = "0002"` on the units if needed |
| Torrents slow, no incoming peers | qBittorrent's listening port is not opened in the firewall | open it on purpose (and forward it) if wanted |
| Can't SSH to the homelab | SSH is tailnet-only | use the Tailscale address; on the LAN it is refused by design |
| Caddy ACME errors for `mlabrecque.dev` | Public DNS still points at the VPS | expected before the Matrix cutover |
