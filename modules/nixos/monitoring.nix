{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.neusis.services.monitoring;

  journalConfig = import ../../lib/alloy-journal.nix {
    inherit lib;
    hostName = config.networking.hostName;
    lokiPort = cfg.loki.port;
  };
  grafanaDashboardSource = pkgs.fetchFromGitHub {
    owner = "rfrail3";
    repo = "grafana-dashboards";
    rev = "fb8ab3ec1444622f76ffc64162e193623e082062";
    sha256 = "sha256-33Fy5f3DhWqMQQzpHkdezLUrXiWku/HLH/DmuuZ293c=";
  };

  nvidiaDashboardSource = pkgs.fetchFromGitHub {
    owner = "utkuozdemir";
    repo = "nvidia_gpu_exporter";
    rev = "ca6b809235a8b4ed8e92380733104c90be9e8240";
    sha256 = "sha256-Yh0iTQjV1oSwVmCIAdt7svG9MrKEewEIBBAPqUzsD88=";
  };

  ipmiExporterYAMLConfig = pkgs.writeText "ipmi_local.yml" ''
    modules:
      default:
        # Available collectors are bmc, bmc-watchdog, ipmi, chassis, dcmi, sel, sel-events and sm-lan-mode
        collectors:
          - ipmi
          # - sel
          # - sel-events
          # - sm-lan-mode
          # - bmc
          # - bmc-watchdog
          # - chassis
          # - dcmi
        collector_cmd:
          ipmi: /run/wrappers/bin/sudo
        #   sel: ${pkgs.sudo}/bin/sudo
        #   sel-events: ${pkgs.sudo}/bin/sudo
        #   sm-lan-mode: ${pkgs.sudo}/bin/sudo
        #   bmc: ${pkgs.sudo}/bin/sudo
        #   bmc-watchdog: ${pkgs.sudo}/bin/sudo
        #   chassis: ${pkgs.sudo}/bin/sudo
        #   dcmi: ${pkgs.sudo}/bin/sudo
        custom_args:
          ipmi:
            - ${pkgs.freeipmi}/bin/ipmimonitoring
  '';
in
{
  imports = [
    (mkRenamedOptionModule
      [ "neusis" "services" "monitoring" "promtail" "enable" ]
      [ "neusis" "services" "monitoring" "journal" "enable" ])
    (mkRenamedOptionModule
      [ "neusis" "services" "monitoring" "promtail" "port" ]
      [ "neusis" "services" "monitoring" "journal" "port" ])
    (mkRemovedOptionModule [ "neusis" "services" "monitoring" "promtail" "grpc_port" ]
      "Journal collection now uses Alloy, which has no gRPC listener.")
    (mkRenamedOptionModule
      [ "neusis" "services" "monitoring" "alloy" "port" ]
      [ "neusis" "services" "monitoring" "journal" "port" ])
  ];

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
          default = "3600d";
          description = "Data retention period";
        };
        domain = mkOption {
          type = types.nullOr types.str;
          default = "prometheus.${toString config.networking.hostName}";
          description = "Domain for Prometheus (optional)";
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
        secretKeyFile = mkOption {
          type = types.str;
          default = "/var/lib/grafana-secrets/secret-key";
          description = ''
            Root-owned runtime encryption key, passed through systemd credentials.
            Existing installations MUST back up and migrate encrypted database
            contents before changing this key. Never generate it on each start.
          '';
        };
      };

      # Historical option name: this controls Prometheus's existing remote write,
      # independently of the local Alloy journal collector.
      alloy.enable = mkEnableOption "Grafana Cloud metrics remote write" // {
        default = true;
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

      nvidiaExporter = {
        enable = mkEnableOption "Nvidia Exporter" // {
          default = true;
        };
        port = mkOption {
          type = types.port;
          default = 9835;
          description = "Port for Nvidia Exporter";
        };
      };

      zfsExporter = {
        enable = mkEnableOption "ZFS Exporter" // {
          default = true;
        };
        port = mkOption {
          type = types.port;
          default = 9134;
          description = "Port for ZFS Exporter";
        };
      };

      ipmiExporter = {
        enable = mkEnableOption "IPMI Exporter" // {
          default = false;
        };
        port = mkOption {
          type = types.port;
          default = 9290;
          description = "Port for IPMI Exporter";
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

      nginx = {
        grafanaAllowedAddresses = mkOption {
          type = types.listOf types.str;
          default = [
            "127.0.0.1"
            "::1"
          ];
          description = ''
            Client addresses/CIDRs allowed to reach Grafana through nginx.
            This supplements Grafana authentication. Prometheus's nginx proxy
            is always loopback-only; use SSH forwarding for its raw API/UI.
          '';
        };
        enable = mkEnableOption "nginx reverse proxy for Grafana" // {
          default = true;
        };
        serverName = mkOption {
          type = types.str;
          default = "grafana.${config.networking.hostName}";
          description = "Server name for nginx virtual host";
        };
        ssl = {
          enable = mkEnableOption "SSL/TLS for nginx";
          certificatePath = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Path to SSL certificate";
          };
          keyPath = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Path to SSL private key";
          };
        };
      };

      journal = {
        enable = mkEnableOption "systemd journal collection through Alloy" // {
          default = true;
        };
        port = mkOption {
          type = types.port;
          default = 9196;
          description = "Loopback-only Alloy diagnostic HTTP port";
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

    age.secrets.alloy_key = mkIf cfg.alloy.enable {
      file = ../../secrets/oppy/alloy_key.age;
      # Required for alloy to read it dynamically
      mode = "770";
      owner = "prometheus";
      group = "prometheus";
    };

    services.prometheus = mkIf cfg.enable {
      enable = true;
      # These APIs have no application authentication. The general host
      # firewall is disabled on this fleet, so bind them explicitly.
      listenAddress = "127.0.0.1";
      port = cfg.prometheus.port;
      retentionTime = cfg.prometheus.retention;
      remoteWrite = mkIf cfg.alloy.enable [
        {
          url = "https://prometheus-prod-56-prod-us-east-2.grafana.net/api/prom/push";
          basic_auth = {
            username = "2660759";
            password_file = config.age.secrets.alloy_key.path;
          };
        }

      ];
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
          job_name = "nvidia";
          static_configs = [
            {
              targets = [ "localhost:${toString cfg.nvidiaExporter.port}" ];
            }
          ];
        }
        {
          job_name = "zfs";
          static_configs = [
            {
              targets = [ "localhost:${toString cfg.zfsExporter.port}" ];
            }
          ];
        }
        {
          job_name = "ipmi";
          static_configs = [
            {
              targets = [ "localhost:${toString cfg.ipmiExporter.port}" ];
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
        listenAddress = "127.0.0.1";
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

      exporters.nvidia-gpu = mkIf cfg.nvidiaExporter.enable {
        enable = true;
        port = cfg.nvidiaExporter.port;
        listenAddress = "127.0.0.1";
      };

      exporters.zfs = mkIf cfg.zfsExporter.enable {
        enable = true;
        port = cfg.zfsExporter.port;
        listenAddress = "127.0.0.1";
      };

      exporters.ipmi = mkIf cfg.ipmiExporter.enable {
        enable = true;
        port = cfg.ipmiExporter.port;
        listenAddress = "127.0.0.1";
        extraFlags = [ "--native-ipmi" ];
        #configFile = ipmiExporterYAMLConfig;
      };

      alertmanager = mkIf cfg.alerts.enable {
        enable = true;
        port = cfg.alerts.port;
        listenAddress = "127.0.0.1";
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

    # NixOS supplies a dedicated DynamicUser, systemd-journal membership and a
    # persistent StateDirectory. Do not run the collector as a personal user.
    services.alloy = mkIf cfg.journal.enable {
      enable = true;
      extraFlags = [
        "--server.http.listen-addr=127.0.0.1:${toString cfg.journal.port}"
        "--storage.path=/var/lib/alloy"
        "--disable-reporting"
      ];
    };

    services.loki = mkIf cfg.loki.enable {
      enable = true;
      configuration = {
        server = {
          http_listen_address = "127.0.0.1";
          http_listen_port = cfg.loki.port;
          grpc_listen_address = "127.0.0.1";
          grpc_listen_port = cfg.loki.grpc_port;
        };
        auth_enabled = false;
        # Single-process Loki still uses internal gRPC callbacks. Advertising
        # a LAN address while listening only on loopback breaks log queries.
        common = {
          instance_addr = "127.0.0.1";
          # Setting instance_addr enables common-ring inheritance in Loki.
          # Keep every ring in-process rather than inheriting the Consul default.
          ring.kvstore.store = "inmemory";
        };
        frontend.address = "127.0.0.1";
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
            instance_addr = "127.0.0.1";
            kvstore = {
              store = "inmemory";
            };
          };
        };
      };
    };

    # Require an explicit runtime key; preserve the existing key for OS upgrades.
    # Rotate it separately. Systemd reads it outside the world-readable store.
    systemd.services.grafana.serviceConfig.LoadCredential = mkIf cfg.grafana.enable [
      "secret-key:${cfg.grafana.secretKeyFile}"
    ];

    services.grafana = mkIf cfg.grafana.enable {
      enable = true;
      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = cfg.grafana.port;
          domain = mkIf (cfg.grafana.domain != null) cfg.grafana.domain;
        };
        security = {
          admin_user = "admin";
          secret_key = "$__file{/run/credentials/grafana.service/secret-key}";
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

    # nginx configuration for Grafana
    services.nginx = mkIf cfg.nginx.enable {
      enable = true;
      virtualHosts."${cfg.nginx.serverName}" = {
        # nginx checks the actual peer address, not X-Forwarded-For. Keep
        # dashboard access on the explicitly allowed private network only.
        extraConfig =
          concatMapStringsSep "\n" (address: "allow ${address};") cfg.nginx.grafanaAllowedAddresses
          + "\ndeny all;";
        serverAliases = [
          "${cfg.grafana.domain}"
          "grafana.localhost"
        ];
        listen = [
          {
            addr = "0.0.0.0";
            port = 80;
          }
        ]
        ++ (optionals cfg.nginx.ssl.enable [
          {
            addr = "0.0.0.0";
            port = 443;
            ssl = true;
          }
        ]);

        forceSSL = cfg.nginx.ssl.enable;
        sslCertificate = mkIf cfg.nginx.ssl.enable cfg.nginx.ssl.certificatePath;
        sslCertificateKey = mkIf cfg.nginx.ssl.enable cfg.nginx.ssl.keyPath;

        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.grafana.port}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };

      virtualHosts."${cfg.prometheus.domain}" = {
        # Binding Prometheus itself is insufficient: this proxy would otherwise
        # re-expose the unauthenticated API on port 80 (and optional TLS).
        extraConfig = ''
          allow 127.0.0.1;
          allow ::1;
          deny all;
        '';
        serverAliases = [
          "prometheus.localhost"
        ];
        listen = [
          {
            addr = "0.0.0.0";
            port = 80;
          }
        ]
        ++ (optionals cfg.nginx.ssl.enable [
          {
            addr = "0.0.0.0";
            port = 443;
            ssl = true;
          }
        ]);

        forceSSL = cfg.nginx.ssl.enable;
        sslCertificate = mkIf cfg.nginx.ssl.enable cfg.nginx.ssl.certificatePath;
        sslCertificateKey = mkIf cfg.nginx.ssl.enable cfg.nginx.ssl.keyPath;

        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.prometheus.port}";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
    };

    # System dashboards

    environment.etc = mkMerge [
      (mkIf cfg.journal.enable {
        "alloy/config.alloy".text = journalConfig;
      })
      (mkIf cfg.grafana.enable {
        "grafana/dashboards/node-exporter.json".source =
          "${grafanaDashboardSource}/prometheus/node-exporter-full.json";
        "grafana/dashboards/nvidia-exporter.json".source =
          "${nvidiaDashboardSource}/grafana/dashboard.json";
      })
    ];

    # Firewall configuration
    # networking.firewall.allowedTCPPorts = mkMerge [
    #   (mkIf cfg.prometheus.enable [ cfg.prometheus.port ])
    #   (mkIf cfg.grafana.enable [ cfg.grafana.port ])
    #   (mkIf cfg.nodeExporter.enable [ cfg.nodeExporter.port ])
    #   (mkIf cfg.alerts.enable [ cfg.alerts.port ])
    # ];

    # Systemd services for monitoring health
    # systemd.services.monitoring-health = mkIf cfg.enable {
    #   description = "Monitoring Stack Health Check";
    #   after = [ "network.target" ];
    #   wantedBy = [ "multi-user.target" ];
    #   serviceConfig = {
    #     Type = "oneshot";
    #     ExecStart = pkgs.writeShellScript "monitoring-health" ''
    #       echo "Checking monitoring stack health..."
    #       ${optionalString cfg.prometheus.enable ''
    #         ${pkgs.curl}/bin/curl -f http://localhost:${toString cfg.prometheus.port}/-/healthy || exit 1
    #       ''}
    #       ${optionalString cfg.grafana.enable ''
    #         ${pkgs.curl}/bin/curl -f http://localhost:${toString cfg.grafana.port}/api/health || exit 1
    #       ''}
    #       echo "All monitoring services are healthy"
    #     '';
    #   };
    # };

    # systemd.timers.monitoring-health = mkIf cfg.enable {
    #   description = "Run monitoring health check";
    #   wantedBy = [ "timers.target" ];
    #   timerConfig = {
    #     OnCalendar = "hourly";
    #     Persistent = true;
    #   };
    # };
  };
}
