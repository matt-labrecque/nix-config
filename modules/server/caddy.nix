# Caddy for tailnet-only vhosts. A vhost that starts with `import tailnet`
# gets a certificate from Caddy's internal CA and drops clients outside
# Tailscale's address ranges, so it stays private even though port 443 is
# public for Matrix (tuwunel.nix). Trust Caddy's root certificate on your
# devices: /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt
{
  services.caddy = {
    enable = true;
    extraConfig = ''
      (tailnet) {
        tls internal
        @outside not remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
        abort @outside
      }
    '';
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 443 ];
}
