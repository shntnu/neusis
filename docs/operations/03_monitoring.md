# Monitoring

## Access Grafana

### Via Tailscale (Recommended)

```bash
# One-time setup
tailscale up --auth-key=<get-key-from-admin>

# Access Grafana (Tailscale provides DNS)
open http://grafana.oppy
```

### Direct Network Access

If you have direct network access to the machine (VPN, same network, etc.):

```bash
# Access via nginx proxy (port 80)
open http://oppy

# Or directly to Grafana port
open http://oppy:3000
```

## Available Dashboards

- **Node Exporter**: CPU, memory, disk, network metrics (from `rfrail3/grafana-dashboards`)
- **NVIDIA GPU**: GPU utilization, memory, temperature, power (from `utkuozdemir/nvidia_gpu_exporter`)

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

The monitoring module supports alert configuration, but currently no alert receivers are configured.
To enable Slack alerts, you would need to add the webhook configuration to the Prometheus/Alertmanager setup in `modules/nixos/monitoring.nix`.

Rebuild:

```bash
nixos-rebuild switch --flake .#oppy --target-host oppy
```

## Metrics Endpoints

| Service | Port | URL |
|---------|------|-----|
| Prometheus | 9090 | <http://oppy:9090> |
| Grafana | 3000 | <http://grafana.oppy> or <http://oppy:80> |
| Node Exporter | 9100 | <http://oppy:9100/metrics> |
| NVIDIA Exporter | 9835 | <http://oppy:9835/metrics> |
| Loki | 3100 | <http://oppy:3100> |
| Promtail | 28183 | <http://oppy:28183> |
