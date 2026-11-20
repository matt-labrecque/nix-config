{ ... }:
{
  # nix-darwin drives `brew bundle`, but Homebrew itself must already be
  # installed (see mac_bootstrap.sh). GUI apps stay as casks so they land in
  # /Applications and can self-update.
  homebrew = {
    enable = true;

    onActivation = {
      # Rebuilds only install or remove what is declared below; they don't
      # move versions. Run `brew update && brew upgrade` to upgrade.
      autoUpdate = false;
      upgrade = false;
      # Full takeover: remove formulae/casks/taps that are not declared below.
      # Homebrew keeps recursive dependencies of declared formulae (and cask
      # formula dependencies), so only top-level packages need listing.
      cleanup = "zap";
    };

    taps = [
    ];

    # Formulae that are missing or poorly supported in nixpkgs on darwin
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
      "nordvpn"
      "prismlauncher"
      "qbittorrent"
      "rectangle"
      "rstudio"
      "steam"
      "vesktop"
    ];
  };
}
