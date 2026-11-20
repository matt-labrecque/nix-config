# Prometheus scraping the node exporter, Grafana with Prometheus provisioned
{ config, ... }:
let
  inherit (config.homelab) domain;
  prometheus = config.services.prometheus;
  grafanaPort = 3002;
in
{
  # Grafana admin password and secret key
  # (`agenix -e grafana-admin.age`, `agenix -e grafana-secret-key.age`)
  # age.secrets.grafana-admin = {
  #   file = ../../secrets/grafana-admin.age;
  #   owner = "grafana";
  # };
  # age.secrets.grafana-secret-key = {
  #   file = ../../secrets/grafana-secret-key.age;
  #   owner = "grafana";
  # };

  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";
    };
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [ { targets = [ "127.0.0.1:${toString prometheus.exporters.node.port}" ]; } ];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = grafanaPort;
        domain = "grafana.${domain}";
        root_url = "https://grafana.${domain}/";
      };
      security = {
        admin_password = "$__file{/run/agenix/grafana-admin}";
        secret_key = "$__file{/run/agenix/grafana-secret-key}";
      };
    };
    provision.datasources.settings.datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        url = "http://127.0.0.1:${toString prometheus.port}";
        isDefault = true;
      }
    ];
  };

  services.caddy.virtualHosts = {
    "grafana.${domain}".extraConfig = ''
      import tailnet
      reverse_proxy 127.0.0.1:${toString grafanaPort}
    '';
    "prometheus.${domain}".extraConfig = ''
      import tailnet
      reverse_proxy 127.0.0.1:${toString prometheus.port}
    '';
  };
}
