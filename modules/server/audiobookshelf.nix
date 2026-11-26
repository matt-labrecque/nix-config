# Libraries are added in the web UI; point them at <dataRoot>/media/audiobooks
# (created by media.nix). The first account created becomes the admin.
{ config, ... }:
{
  imports = [ ./media.nix ];

  services.audiobookshelf = {
    enable = true;
    host = "127.0.0.1";
    port = 8000;
  };
  users.users.audiobookshelf.extraGroups = [ "media" ];

  homelab.services.audiobooks = config.services.audiobookshelf.port;
}
