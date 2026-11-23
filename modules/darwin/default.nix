{
  self,
  pkgs,
  inputs,
  username,
  homeDirectory,
  configDir,
  ...
}:
let
  zettk-cli = pkgs.callPackage ../../home/darwin/zettk-cli.nix { src = inputs.zettk-cli; };
in
{
  imports = [ ./homebrew.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Required for user-scoped options such as system.defaults and homebrew
  system.primaryUser = username;
  # Home Manager takes home.username and home.homeDirectory from this user
  users.users.${username}.home = homeDirectory;

  fonts.packages = [ pkgs.nerd-fonts.caskaydia-cove ];

  environment.systemPackages = [
    # agenix CLI for editing secrets/ (see secrets/secrets.nix)
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    zettk-cli
  ];

  system.defaults = {
    # Disable Press and Hold so keyboard navigation works
    NSGlobalDomain.ApplePressAndHoldEnabled = false;
  };

  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Read the nix-darwin changelog before changing this value
  system.stateVersion = 7;
}
