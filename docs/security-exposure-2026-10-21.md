# Internal service exposure remediation — 2026-10-21

This records the completed security-only rollout on NixOS25.11. Both hosts were
subsequently upgraded to26.05; see [the upgrade record](nixos-upgrade-26.05.md)
for their current versions and operator instructions.

## Changes retained

- Prometheus, node/NVIDIA/ZFS exporters, Loki and the journal collector listen
  on loopback rather than exposing unauthenticated APIs to the network.
- Grafana's backend is loopback-only. Its nginx proxy permits the explicitly
  configured loopback/Tailscale client ranges and still requires Grafana login.
  The ACL uses the actual peer address, not caller-supplied forwarding headers.
- The Prometheus nginx proxy is also loopback-only; use SSH forwarding for its
  raw API/UI. Restricting only the backend listener would leave a proxy bypass.
- Oppy's patched history-v1 entrypoint honors `HISTORY_V1_HOST`, defaulting to
  `127.0.0.1`. An IPv4/IPv6 nftables rule also drops non-loopback TCP3100 traffic.
  Existing private Overleaf origin restrictions remain intact.
- Loki advertises loopback for its internal endpoints and uses an in-memory
  common ring. Explicit ring configuration avoids accidentally selecting Consul.
- The26.05 upgrade replaces Promtail with loopback-only Alloy without removing
  these restrictions.

## Completed security-only deployment

On2026-10-21, Spirit generation15 was persisted at20:04UTC and Oppy generation83
at20:13UTC, retaining generations14 and82 respectively. Both active systems
matched their profiles. Kernel, initrd, GPU/system packages and systemd were
unchanged in that security-only deployment; there was no reboot or compute-job
shutdown at that stage.

Local/cross-host verification then confirmed closed backend ports, proxy ACLs,
forwarded-header spoof rejection, working Loki queries and exact fresh journal
markers. Oppy passed30 backend/eight proxy checks; Spirit passed27/eight.
Promtail initially replayed old journal entries; fresh-marker verification passed
after catch-up. No unexpected workload-service restarts were observed.

Public Overleaf login returned200 and its Git bridge required authentication.
Local Overleaf/history and Marimohub origins remained available. Public
Marimohub Cloudflare530/error1033 and the IPMI scrape issue were preexisting,
not regressions claimed fixed here. Grafana health and authentication enforcement
were checked; a full authenticated dashboard interaction was not exercised.

Spirit's deployment deliberately preserved its deployed network and SSH-key
configuration rather than including unrelated pending changes. Karkinos was
excluded from deployment; shared source changes apply only on a future rebuild.
Unrelated main-checkout user/home changes were not included in this work.

Private deployment evidence remains under
`~/.local/state/neusis/exposure-20261021/`. Completed old deployment guards must
not be replayed. Earlier detailed preparation notes and process-specific tests
were archived outside the repository. Per operator request, those new tests and
the unused Grafana re-encryption rehearsal helpers were removed after the OS
upgrade; preexisting checks remain, plus one simple Overleaf availability test.

Direct Broad LAN dashboard access is a subsequent request, not a completed
change in this rollout. It remains pending client-network/transport clarification;
Grafana authentication and private raw monitoring endpoints must be preserved.
