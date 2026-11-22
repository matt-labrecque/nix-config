# hardware/homelab.nix is a placeholder until the machine is installed; see
# the note in that file. Boot loader and system.stateVersion still go here.
{
  imports = [
    ./hardware/homelab.nix
    ../modules/server/options.nix
    ../modules/server/caddy.nix
    ../modules/server/tailscale.nix
    ../modules/server/adguardhome.nix
    ../modules/server/jellyfin.nix
    ../modules/server/arr.nix
    ../modules/server/nextcloud.nix
    ../modules/server/vaultwarden.nix
    ../modules/server/paperless.nix
    ../modules/server/forgejo.nix
    ../modules/server/freshrss.nix
    ../modules/server/syncthing.nix
    ../modules/server/homepage.nix
    ../modules/server/monitoring.nix
    # Public: opens 80/443 for matrix.mlabrecque.dev and the well-known on
    # mlabrecque.dev (forward both ports on the router). Replaces the VPS
    # instance at migration.
    ../modules/server/tuwunel.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  homelab.domain = "lab.mlabrecque.dev";
  # Set after `tailscale up` (`tailscale ip -4`) to enable AdGuard's rewrites
  # homelab.tailscaleIPv4 = "";

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings.PasswordAuthentication = false;
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
}
