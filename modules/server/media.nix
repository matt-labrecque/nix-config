# Shared media library for Jellyfin and Audiobookshelf.
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
    "${root}/movies".d = dir;
    "${root}/tv".d = dir;
    "${root}/audiobooks".d = dir;
  };
}
