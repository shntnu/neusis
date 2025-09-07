{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.neusis.services.monitoring;

  grafanaDashboardSource = pkgs.fetchFromGitHub {
    owner = "rfrail3";
    repo = "grafana-dashboards";
    rev = "fb8ab3ec1444622f76ffc64162e193623e082062";
    sha256 = "sha256-33Fy5f3DhWqMQQzpHkdezLUrXiWku/HLH/DmuuZ293c=";
  };
in
{
  options = {
    neusis.services.monitoring = {
      enable = mkEnableOption "monitoring stack";

      prometheus = {
        enable = mkEnableOption "Prometheus monitoring" // {
          default = true;
        };
        port = mkOption {
          type = types.port;
          default = 9090;
          description = "Port for Prometheus web interface";
        };
        retention = mkOption {
          type = types.str;
          default = "30d";
          description = "Data retention period";
        };
      };

      grafana = {
        enable = mkEnableOption "Grafana dashboard" // {
          default = true;
        };
        port = mkOption {
          type = types.port;
          default = 3000;
          description = "Port for Grafana web interface";
        };
        domain = mkOption {
          type = types.nullOr types.str;
          default = "grafana.${toString config.networking.hostName}";
          description = "Domain for Grafana (optional)";
        };
      };

      nodeExporter = {
        enable = mkEnableOption "Node Exporter" // {
          default = true;
        };
        port = mkOption {
          type = types.port;
          default = 9100;
          description = "Port for Node Exporter";
        };
      };

      loki = {
        enable = mkEnableOption "Loki" // {
          default = true;
        };
        port = mkOption {
          type = types.port;
          default = 9194;
          description = "Port for Loki";
        };
        grpc_port = mkOption {
          type = types.port;
          default = 9195;
          description = "GRPC ort for Loki";
        };
      };

      promtail = {
        enable = mkEnableOption "Promtail" // {
          default = true;
        };
        port = mkOption {
          type = types.port;
          default = 9196;
          description = "Port for Promtail";
        };

        grpc_port = mkOption {
          type = types.port;
          default = 9197;
          description = "GRPC ort for Promatail";
        };
      };

      alerts = {
        enable = mkEnableOption "Alertmanager";
        port = mkOption {
          type = types.port;
          default = 9093;
          description = "Port for Alertmanager";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    services.prometheus = mkIf cfg.enable {
      enable = true;
      port = cfg.prometheus.port;
      retentionTime = cfg.prometheus.retention;

      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = [ "localhost:${toString cfg.nodeExporter.port}" ];
            }
          ];
        }
        {
          job_name = "prometheus";
          static_configs = [
            {
              targets = [ "localhost:${toString cfg.prometheus.port}" ];
            }
          ];
        }
      ];

      rules = [
        ''
          groups:
            - name: system
              rules:
                - alert: HighCPUUsage
                  expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
                  for: 5m
                  labels:
                    severity: warning
                  annotations:
                    summary: "High CPU usage detected"
                    description: "CPU usage is above 80% for more than 5 minutes"

                - alert: HighMemoryUsage
                  expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
                  for: 5m
                  labels:
                    severity: warning
                  annotations:
                    summary: "High memory usage detected"
                    description: "Memory usage is above 85% for more than 5 minutes"

                - alert: DiskSpaceLow
                  expr: (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"}) * 100 < 10
                  for: 5m
                  labels:
                    severity: critical
                  annotations:
                    summary: "Low disk space"
                    description: "Disk space is below 10% on {{ $labels.mountpoint }}"
        ''
      ];

      exporters.node = mkIf cfg.nodeExporter.enable {
        enable = true;
        port = cfg.nodeExporter.port;
        enabledCollectors = [
          "systemd"
          "processes"
          "network_route"
          "hwmon"
          "mountstats"
          "interrupts"
          "netdev"
          "filesystem"
          "diskstats"
          "cpu"
          "meminfo"
          "loadavg"
        ];
      };

      alertmanager = mkIf cfg.alerts.enable {
        enable = true;
        port = cfg.alerts.port;
        configuration = {
          global = {
            smtp_smarthost = "localhost:587";
            smtp_from = "alertmanager@localhost";
          };
          route = {
            group_by = [ "alertname" ];
            group_wait = "10s";
            group_interval = "10s";
            repeat_interval = "1h";
            receiver = "web.hook";
          };
          receivers = [
            {
              name = "web.hook";
              webhook_configs = [
                {
                  url = "http://localhost:5001/";
                }
              ];
            }
          ];
        };
      };
    };

    services.loki = mkIf cfg.loki.enable {
      enable = true;
      configuration = {
        server = {
          http_listen_port = cfg.loki.port;
          grpc_listen_port = cfg.loki.grpc_port;
        };
        auth_enabled = false;
        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore = {
                store = "inmemory";
              };
              replication_factor = 1;
            };
          };

        };

        schema_config = {
          configs = [
            {
              from = "2025-06-06";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };
        storage_config = {
          tsdb_shipper = {
            active_index_directory = "/var/lib/loki/tsdb-shipper-active";
            cache_location = "/var/lib/loki/tsdb-shipper-cache";
            cache_ttl = "24h";
          };
          filesystem = {
            directory = "/var/lib/loki/chunks";
          };
        };
        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
        };
        compactor = {
          working_directory = "/var/lib/loki";
          compactor_ring = {
            kvstore = {
              store = "inmemory";
            };
          };
        };
      };
    };

    services.promtail = mkIf cfg.promtail.enable {
      enable = true;
      configuration = {
        server = {
          http_listen_port = cfg.promtail.port;
          grpc_listen_port = cfg.promtail.grpc_port;
        };
        positions = {
          filename = "/tmp/positions.yaml";
        };
        clients = [
          {
            url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
          }
        ];
        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = config.networking.hostName;
              };
            };
            relabel_configs = [
              {
                source_labels = [ "__journal__systemd_unit" ];
                target_label = "unit";
              }
            ];
          }

        ];
      };

    };

    services.grafana = mkIf cfg.grafana.enable {
      enable = true;
      settings = {
        server = {
          http_port = cfg.grafana.port;
          domain = mkIf (cfg.grafana.domain != null) cfg.grafana.domain;
        };
        security = {
          admin_user = "admin";
          admin_password = "$__file{${pkgs.writeText "grafana-password" "admin"}}";
        };
      };

      provision = {
        enable = true;
        datasources.settings.datasources = mkIf cfg.prometheus.enable [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://localhost:${toString cfg.prometheus.port}";
            isDefault = true;
          }
          {
            name = "Loki";
            type = "loki";
            url = "http://localhost:${toString cfg.loki.port}";
          }
        ];

        dashboards.settings.providers = [
          {
            name = "default";
            orgId = 1;
            folder = "";
            type = "file";
            disableDeletion = false;
            updateIntervalSeconds = 10;
            allowUiUpdates = true;
            options.path = "/etc/grafana/dashboards";
          }
        ];
      };
    };

    # System dashboards

    environment.etc = mkIf cfg.grafana.enable {
      "grafana/dashboards/node-exporter.json".source =
        "${grafanaDashboardSource}/prometheus/node-exporter-full.json";
    };

    # Firewall configuration
    # networking.firewall.allowedTCPPorts = mkMerge [
    #   (mkIf cfg.prometheus.enable [ cfg.prometheus.port ])
    #   (mkIf cfg.grafana.enable [ cfg.grafana.port ])
    #   (mkIf cfg.nodeExporter.enable [ cfg.nodeExporter.port ])
    #   (mkIf cfg.alerts.enable [ cfg.alerts.port ])
    # ];

    # Systemd services for monitoring health
    systemd.services.monitoring-health = mkIf cfg.enable {
      description = "Monitoring Stack Health Check";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "monitoring-health" ''
          echo "Checking monitoring stack health..."
          ${optionalString cfg.prometheus.enable ''
            ${pkgs.curl}/bin/curl -f http://localhost:${toString cfg.prometheus.port}/-/healthy || exit 1
          ''}
          ${optionalString cfg.grafana.enable ''
            ${pkgs.curl}/bin/curl -f http://localhost:${toString cfg.grafana.port}/api/health || exit 1
          ''}
          echo "All monitoring services are healthy"
        '';
      };
    };

    systemd.timers.monitoring-health = mkIf cfg.enable {
      description = "Run monitoring health check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
      };
    };
  };
}

