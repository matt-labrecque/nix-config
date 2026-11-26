{
  imports = [ ./media.nix ];

  services.jellyfin.enable = true;
  users.users.jellyfin.extraGroups = [ "media" ];

  homelab.services.jellyfin = 8096;
}
