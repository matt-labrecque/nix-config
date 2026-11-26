# Public Paper server on 25565 (TCP and UDP); forward it on the router.
# Not declarative: server.properties, the whitelist, and plugins live in
# /var/lib/minecraft and are managed there.
{ pkgs, ... }:
{
  services.minecraft-server = {
    enable = true;
    package = pkgs.papermc;
    # Accepts Mojang's EULA (https://www.minecraft.net/eula); required to start
    eula = true;
    openFirewall = true;
  };
}
