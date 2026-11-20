# Join the tailnet once after the first switch: `sudo tailscale up`
{
  services.tailscale = {
    enable = true;
    # Opens Tailscale's UDP port so peers can connect directly
    openFirewall = true;
  };
}
