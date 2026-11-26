# hardware/homelab.nix is a placeholder until the machine is installed; see
# the note in that file. Boot loader and system.stateVersion still go here.
{
  imports = [
    ./hardware/homelab.nix
    ../modules/server/options.nix
    ../modules/server/caddy.nix
    ../modules/server/tailscale.nix
    ../modules/server/jellyfin.nix
    ../modules/server/audiobookshelf.nix
    ../modules/server/nextcloud.nix
    ../modules/server/freshrss.nix
    # Public: open 80/443 (website, Matrix) and 25565 (Minecraft); forward
    # them on the router.
    ../modules/server/website.nix
    ../modules/server/tuwunel.nix
    ../modules/server/minecraft-server.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  homelab.domain = "lab.mlabrecque.dev";

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings.PasswordAuthentication = false;
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
}
