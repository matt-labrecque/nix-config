{ ... }:
{
  # Docs: https://ghostty.org/docs/config
  programs.ghostty = {
    enable = true;
    # Ghostty itself is installed as a Homebrew cask
    package = null;
    settings = {
      font-family = "CaskaydiaCove NF";
      font-size = 16;
      background-opacity = 0.9;
    };
  };
}
