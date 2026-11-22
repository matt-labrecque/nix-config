{ ... }:
{
  # nix-darwin drives `brew bundle`, but Homebrew itself must already be
  # installed (see mac_bootstrap.sh).
  # GUI apps stay as casks so they land in /Applications and can self-update.
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
      "qbittorrent"
      "rectangle"
      "rstudio"
      "steam"
      "tailscale-app"
      "vesktop"
    ];
  };
}
