# Monitoring

## Access Grafana

### Via Tailscale (Recommended)

```bash
# One-time setup
tailscale up --auth-key=<get-key-from-admin>

# Access
open http://grafana.oppy
```

Login: admin/admin

### Direct Access (VPN Required)

```bash
open http://10.192.6.25
```

## Available Dashboards

- **Node Exporter**: CPU, memory, disk, network metrics
- **NVIDIA GPU**: GPU utilization, memory, temperature, power

## View Logs

In Grafana:

1. Navigate to Explore → Loki
2. Select job: `systemd-journal`
3. Filter by unit or search errors

## Alert Rules

Configured alerts:

- High CPU usage (>80% for 5min)
- High memory usage (>85% for 5min)  
- Low disk space (<10%)

### Configure Slack Alerts

Add Slack webhook to `modules/nixos/monitoring.nix`:

```nix
receivers = [{
  name = "slack";
  slack_configs = [{
    api_url = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL";
  }];
}];
```

Rebuild:

```bash
nixos-rebuild switch --flake .#oppy --target-host oppy
```

## Metrics Endpoints

| Service | Port | URL |
|---------|------|-----|
| Prometheus | 9090 | <http://oppy:9090> |
| Node Exporter | 9100 | <http://oppy:9100/metrics> |
| NVIDIA Exporter | 9835 | <http://oppy:9835/metrics> |
| Loki | 9194 | <http://oppy:9194> |
