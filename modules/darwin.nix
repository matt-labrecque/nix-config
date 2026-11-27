# Entry point for the Mac: module imports, macOS system settings, Homebrew,
# and the Home Manager modules the Mac user gets.
{
  self,
  pkgs,
  inputs,
  username,
  homeDirectory,
  configDir,
  ...
}:
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.agenix.darwinModules.default
    ./nix/settings.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Required for user-scoped options such as system.defaults and homebrew
  system.primaryUser = username;
  # Home Manager takes home.username and home.homeDirectory from this user
  users.users.${username}.home = homeDirectory;

  home-manager.extraSpecialArgs = { inherit configDir; };
  home-manager.users.${username}.imports = [
    ./home-manager/home.nix
    ./home-manager/shell.nix
    ./home-manager/neovim.nix
    # Mac only
    ./home-manager/home-darwin.nix
    ./home-manager/shell-darwin.nix
    ./home-manager/neovim-darwin.nix
    ./home-manager/git.nix
    ./home-manager/ghostty.nix
    ./home-manager/nix-init.nix
    ./home-manager/omp.nix
  ];

  fonts.packages = [ pkgs.nerd-fonts.caskaydia-cove ];

  environment.systemPackages = [
    # agenix CLI for editing secrets/ (see secrets/secrets.nix)
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  system.defaults = {
    # Disable Press and Hold so keyboard navigation works
    NSGlobalDomain.ApplePressAndHoldEnabled = false;
  };

  # cleanup = "zap" uninstalls anything not listed here on switch
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "zap";
    };

    taps = [
    ];

    brews = [
    ];

    casks = [
      "anki"
      "balenaetcher"
      "claude"
      "element"
      "ghostty"
      "gimp"
      "helium-browser"
      "musicbrainz-picard"
      "prismlauncher"
      "protonvpn"
      "proton-mail-bridge"
      "qbittorrent"
      "rectangle"
      "rstudio"
      "steam"
      "tailscale-app"
      "vesktop"
      "vlc"
    ];
  };

  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Read the nix-darwin changelog before changing this value
  system.stateVersion = 7;
}
