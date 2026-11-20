{
  self,
  pkgs,
  inputs,
  username,
  homeDirectory,
  ...
}:
{
  imports = [ ./homebrew.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Required for user-scoped options such as system.defaults and homebrew
  system.primaryUser = username;
  # Home Manager takes home.username and home.homeDirectory from this user
  users.users.${username}.home = homeDirectory;

  fonts.packages = [ pkgs.nerd-fonts.caskaydia-cove ];

  # agenix CLI for editing secrets/ (see secrets/secrets.nix)
  environment.systemPackages = [ inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  system.defaults = {
    # Disable Press and Hold so keyboard navigation works
    NSGlobalDomain.ApplePressAndHoldEnabled = false;
  };

  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Read the nix-darwin changelog before changing this value
  system.stateVersion = 7;
}
