let
  domain = "mlabrecque.dev";
  port = 6167;
  upstream = "127.0.0.1:${toString port}";
in
{
  services.matrix-tuwunel = {
    enable = true;
    settings.global = {
      server_name = domain;
      address = [
        "127.0.0.1"
        "::1"
      ];
      port = [ port ];
      allow_federation = true;

      well_known = {
        client = "https://matrix.${domain}";
        server = "matrix.${domain}:443";
      };
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."matrix.${domain}".extraConfig = ''
      reverse_proxy /_matrix/* ${upstream}
    '';
    virtualHosts.${domain}.extraConfig = ''
      reverse_proxy /.well-known/matrix/* ${upstream}
    '';
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

}
