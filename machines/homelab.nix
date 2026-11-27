# hardware/homelab.nix is a placeholder until the machine is installed; see
# the note in that file. Boot loader and system.stateVersion still go here.
{
  imports = [ ./hardware/homelab.nix ];

  nixpkgs.hostPlatform = "x86_64-linux";

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings.PasswordAuthentication = false;
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
}
