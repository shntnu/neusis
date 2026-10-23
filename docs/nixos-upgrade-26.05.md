# NixOS 26.05 upgrade — completed 2026-10-22

Oppy was upgraded and rebooted first. Fresh authenticated SSH to Oppy's
Tailscale address through Spirit succeeded before Spirit was changed.
Spirit was then upgraded and rebooted. Both active systems match their system
profiles and both are reachable through Tailscale.

| Host | Generation | Running system |
| --- | --- | --- |
| Oppy | 84 | `/nix/store/9n6g2n4k6qcsn2j201w3yk30dfm8i8a4-nixos-system-oppy-26.05.20261020.cd4ea8d` |
| Spirit | 16 | `/nix/store/iww1svbi5pk092449h2yjpnj3bgwhm6c-nixos-system-spirit-26.05.20261020.cd4ea8d` |

Both run Linux **6.18.57**, stock closed NVIDIA **580.159.03** (`dc_580`)
and ZFS **2.4.4**. All four H100 NVL GPUs on each host report the new driver.
There are no failed system services. Grafana health returns HTTP 200 on both;
Oppy's Overleaf login returns HTTP 200. Alloy, Loki and Prometheus are active.
No extended post-upgrade test suite was run, as requested by the operator.

## Scope and preservation

- Nixpkgs, Home Manager, Nixvim, Stylix, nix-darwin and NixOS-WSL follow26.05.
- Removed Node package references and obsolete Ollama acceleration settings
  were updated; the separate Ollama and personal Home Manager pins were retained.
- The compatible Overleaf/MongoDB/Redis runtime pin was retained.
- No `system.stateVersion` values or ZFS pool feature flags were changed.
- NVIDIA uses the native headless module with matching driver/GSP/persistenced.
  No custom driver patch, firmware override or kernel downgrade is used.
- The earlier monitoring/history-v1 hardening remains in place.
- Spirit's build retained its deployed `machines/spirit/network.nix` and
  `users/cslab_spirit.nix`: the unrelated NetworkManager unmanaged-interface
  change and additional kshimofu MacBook SSH key were not deployed. Those
  preexisting source changes were not reverted in this branch.
- Karkinos was not contacted or deployed. Shared version/GPU changes affect
  it only when it is subsequently rebuilt; this is not runtime acceptance
  for Karkinos or a claim of NVIDIA platform certification.

## Boot and rollback

The realized system closure was copied to Spirit using `nix copy --to ssh://spirit`.
Each target was selected with `nix-env --profile /nix/var/nix/profiles/system
--set <target>`, then staged with `NIXOS_INSTALL_BOOTLOADER=1
<target>/bin/switch-to-configuration boot`, followed by a normal reboot.
There was no live switch mixing new NVIDIA userspace with old loaded modules.

Oppy's first `bootctl update` failed because its fallback EFI executable had
GRUB/shim metadata rather than systemd version information. The old profile
and primary bootloader were restored before retrying. The final standard
bootloader reinstall installed systemd-boot260.5 normally; the original fallback
was privately backed up. Spirit's EFI files were also backed up before its
standard reinstall. No custom bootloader override was added.

Retained rollback systems are Oppy83 (also previously booted82) and Spirit15
(also14). Application rollback after a Grafana schema upgrade must use its
matching pre-upgrade database/key backup, not merely an older OS generation.
Do not prune those generations or upgrade ZFS pool features as part of this work.

## Monitoring data

Both Grafana instances kept their existing encryption keys, provisioned as
root-only `/var/lib/grafana-secrets/secret-key` and loaded through systemd
credentials. Consistent SQLite/config/key backups were taken before reboot.
No key rotation or database re-encryption was performed.

Promtail's journal positions were copied through its live PrivateTmp namespace.
`scripts/upgrade/alloy-journal-position.py` converted each preserved copy into
Alloy's corrected checkpoint format, installed inside its actual
DynamicUser/StateDirectory context. The defective Alloy1.16 legacy import was
not used. The journal boundary/checkpoint lag can replay already-collected logs.

Private operational evidence/backups are retained outside Git. On Oppy the
handoff and receipts are under
`~/.local/state/neusis/upgrade-2605-20261021/`; Spirit's receipts are under
`~/.local/state/neusis/spirit-upgrade-NAf0YZ31/`. Root-private backups on both
hosts are under `/var/lib/neusis-upgrade-backups/20261022/`.

## Operator choices and remaining work

- Process restarts are **manual**. Existing enabled systemd jobs may start
  normally, but no claim is made that arbitrary process memory or computation
  state survived. The custom job-restoration task was removed without running.
- The one-time Pi continuation resumed this session after Oppy's reboot; its
  startup enablement was then removed. No permanent recovery framework remains.
- Process-specific security/migration tests and Grafana rehearsal helpers were
  removed after deployment. Preexisting checks remain. The only new runtime
  test retained is `bash tests/overleaf-running.sh`, run on Oppy.
- Direct Broad LAN dashboard access remains pending confirmation of client/VPN
  CIDRs and the desired HTTP/HTTPS setup. Grafana authentication and private raw
  monitoring backends remain intact. LAN SSH forwarding is already an encrypted
  alternative to Tailscale; the OS upgrade was not held for additional networking.
- The previously observed public Marimohub Cloudflare1033 and IPMI scrape issue
  were not investigated or claimed fixed by this upgrade. Email remains paused.
