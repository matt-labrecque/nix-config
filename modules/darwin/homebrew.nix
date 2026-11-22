{ ... }:
{
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
