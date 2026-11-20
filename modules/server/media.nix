# Shared media library for Jellyfin, the *arr apps, and qBittorrent.
# Directories are setgid so new files stay in the media group.
{ config, ... }:
let
  root = "${config.homelab.dataRoot}/media";
  dir = {
    user = "root";
    group = "media";
    mode = "2775";
  };
in
{
  users.groups.media = { };

  systemd.tmpfiles.settings."10-media" = {
    ${root}.d = dir;
    "${root}/downloads".d = dir;
    "${root}/movies".d = dir;
    "${root}/tv".d = dir;
  };
}
