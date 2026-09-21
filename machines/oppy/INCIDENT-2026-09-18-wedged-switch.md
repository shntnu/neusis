# Incident — 2026-09-18: wrong-host rebuild wedges oppy for 2 days

**Status:** open; still degraded at the 2026-09-21 follow-up inspection (no recovery performed by this PR)
**Detected:** 2026-09-20 20:12 UTC, via `502 Bad Gateway` from Cloudflare on the Overleaf hostname
**Started:** 2026-09-18 19:25:52 EDT
**Blast radius:** all of oppy's declarative services — not just Overleaf

## Summary

A `nixos-rebuild switch` for a **different machine** (`#moby`, hostname `gpa85-cad`)
was run locally on `oppy`. Activation reached the stop phase, tore down every
service whose store path differed between the two closures, then **deadlocked
inside `libvirt-guests.service` and never reached the start phase.**

`switch-to-configuration` has been sleeping for ~2 days. Nothing was ever
restarted. The Cloudflare 502 is the most visible symptom, not the fault.

## Timeline (EDT)

| Time | Event |
|---|---|
| Sep 18 19:25:52 | `sudo nixos-rebuild switch --flake ~/.local/share/src/nixos-config#moby` run on oppy; system profile flips to generation 75 = `nixos-system-gpa85-cad-26.11.20260719.241313f` |
| Sep 18 19:26:04 | Stop phase: Overleaf stack, `grafana`, `dex`, `marimohub`, `ollama`, `nftables`, `nfs-server`, `rpcbind`, `NetworkManager`, `systemd-networkd`, `prometheus*`, `loki` all stopped |
| Sep 18 19:26:04 | `libvirt-guests.service` enters `deactivating (stop)` — never leaves it |
| Sep 18 19:26:14 | `mongodb`, `redis-overleaf`, `promtail` stopped |
| Sep 18 19:26:15 | Last activity. Activation blocked; start phase never runs |
| Sep 20 20:12 | Cloudflare 502 reported |

## Root cause

Two independent faults, in sequence.

### 1. Trigger — a host's config applied to the wrong host

```
sudo nixos-rebuild switch --flake /home/amunoz/.local/share/src/nixos-config#moby \
  --option warn-dirty false --option substituters ...
```

Run on `oppy`, without `--target-host`. `#moby` evaluates to hostname `gpa85-cad`.
Because the two closures ship the same units at *different store paths*,
`switch-to-configuration` classified them all as **restart** → stop, then start.

### 2. Why it never recovered — `libvirt-guests` stop deadlock

Ordering cycle, with no timeout to break it:

1. `switch-to-configuration` requests **stop** of `libvirt-guests.service`
2. `libvirt-guests.sh stop` runs `virsh connect`
3. `virsh` hits the still-active `libvirtd.socket`, which requests **start** of `libvirtd.service`
4. that start job cannot run — it is ordered behind the `libvirt-guests` stop job that is waiting on it
5. `libvirt-guests.service` carries `TimeoutStopUSec=infinity` → **no escape**

Observed state, 2 days in:

```
$ systemctl list-jobs
415901 libvirt-guests.service     stop  running     # ← wedged since 19:26:04
416040 libvirtd.service           start waiting
416323 virt-guest-shutdown.target stop  waiting
416165 libvirtd.socket            stop  waiting

$ ps -o pid,etime,args -p 2661370
   PID     ELAPSED COMMAND
2661370 1-20:53:09 virsh connect                    # ← blocked ~45 h
```

**There were zero running VMs.** `ps` shows no `qemu-system*` processes. The
deadlock protected nothing.

`TimeoutStopUSec=infinity` comes from `virtualisation.libvirtd` in
`machines/common/virtualization.nix`, imported by oppy, karkinos and spirit — so
this is a shared Linux fleet trap, not an oppy quirk. `shutdownTimeout = 300`
already limits individual guest shutdowns, but does not bound `virsh connect`.

## State at initial report — half-switched

| | points at |
|---|---|
| `/nix/var/nix/profiles/system` (gen 75) | `…-nixos-system-gpa85-cad-26.11…` ← **wrong host** |
| `/run/current-system` | `…-nixos-system-oppy-25.11.20260404.36a6011` ← correct |
| `/etc/static` | still the oppy generation's `etc` |

The profile symlink flipped before activation; activation never finished, so
`/run/current-system` and `/etc` were never updated. Generation 74 (the real
oppy config, from Sep 14) is intact on disk.

## Impact

**Down since Sep 18 19:26, ~48 h:**

- **Overleaf** — entire stack (`web`, `clsi`, `real-time`, `docstore`, `filestore`,
  `chat`, `contacts`, `notifications`, `project-history`, `references`,
  `history-v1`, `git-bridge`, `migrations`), plus `mongodb` and `redis-overleaf`.
  `overleaf-private-origin.socket` (`100.79.40.39:18080`) is dead, so karkinos'
  cloudflared tunnel gets connection-refused at the origin → **502**.
- **`nftables`** — ExecStop ran `deletions.nft` + `nftables-cleanup-deletions`
  successfully. The host has had **no nftables ruleset for ~2 days**, including
  the tailscale-scoped accept/drop pair that fences port 18080 in `overleaf.nix`.
- **`nfs-server` + `rpcbind`** — 0 `nfsd` kernel threads, 0 clients. Any host
  mounting oppy's exports has been broken since Sep 18.
- **Monitoring** — `prometheus`, `grafana`, `loki`, `promtail`, plus all
  `prometheus-*-exporter` units. The stack that should have paged on this is
  itself part of the outage; `promtail` and `dex` are in `failed`, not merely
  stopped. **No log ingestion for 2 days.**
- Also down: `marimohub`, `ollama`, `nvidia-persistenced`,
  `nvidia-container-toolkit-cdi-generator`, `libvirtd`.

**Not affected:** `sshd`, `tailscaled`, `nginx`, ZFS, all user processes and data.
No data loss observed anywhere. Oneshots that were "stopped"
(`suid-sgid-wrappers`, `linger-users`, `home-manager-*`, …) had already applied
their effects; `/run/wrappers` and `sudo` are intact.

## Follow-up inspection — 2026-09-21

Read-only checks on oppy confirmed:

- The original wrong-host activation (PID 2660298) and four libvirt jobs are
  still present; `libvirt-guests` still has `TimeoutStopUSec=infinity`.
- The system profile now points to **generation 76, an oppy configuration**;
  `/run/current-system` still points to generation 74. Changing the profile
  alone did **not** stop the original wrong-host activation or restore services.
- Overleaf's private origin still refuses connections. `nftables`, NFS,
  Grafana, Prometheus, Loki, marimohub and ollama remain inactive.
- Privileged inspection of `/boot/loader/entries` found only generations 73
  and 74, with generation 74 the default. No wrong-host entry was present.
  Generation 75 remains in the system profile history: a future bootloader
  refresh must not turn it into a boot entry.

These observations are not a recovery claim. No service or profile changes were
made during this inspection.

## Recovery plan

Run in an approved maintenance window. Re-inspect live state first: generation
numbers, processes and VM activity may have changed since the incident.
Do not run a second rebuild while the original switch is still alive.
The ordering below prevents resuming activation of the wrong config.

```bash
# 1. Stop the rebuild FIRST. Unblocking libvirt before this lets
#    switch-to-configuration resume and finish applying moby's config to oppy.
sudo systemctl stop nixos-rebuild-switch-to-configuration.service
systemctl show nixos-rebuild-switch-to-configuration.service -p MainPID -p ActiveState
pgrep -af '[/]bin/switch-to-configuration (switch|test|boot)'
# STOP if any activation process remains (pgrep should find none).

# 2. Recheck for VMs WITHOUT virsh (connecting is what deadlocked).
pgrep -af '[q]emu-system|[q]emu-kvm'
# STOP if guests are running; arrange their shutdown with their owners first.

# 3. Bound stops in the currently loaded configuration BEFORE reactivation.
#    Merely merging this PR cannot change a running unit's infinite timeout.
sudo install -d /run/systemd/system/libvirt-guests.service.d
printf '[Service]\nTimeoutStopSec=300\n' | sudo tee \
  /run/systemd/system/libvirt-guests.service.d/90-incident-timeout.conf
sudo systemctl daemon-reload
systemctl show libvirt-guests.service -p TimeoutStopUSec  # expect: 5min

# 4. Break the old stop job only after verifying the rebuild is gone.
sudo systemctl kill --kill-whom=all --signal=KILL libvirt-guests.service
sudo systemctl reset-failed libvirt-guests.service
systemctl list-jobs  # wait for the libvirt queue to clear before proceeding

# 5. Restore the known-good active closure, not whatever the profile now holds.
known_good=$(readlink -f /run/current-system)
case "$known_good" in
  /nix/store/*-nixos-system-oppy-*) ;;
  *) echo 'Unexpected active system; stop and investigate'; exit 1 ;;
esac
sudo nix-env -p /nix/var/nix/profiles/system --set "$known_good"

# 6. Restore the firewall before bringing application listeners back.
sudo systemctl start nftables.service
sudo nft list ruleset  # confirm the 18080 fence below before proceeding

# 7. Re-activate the same closure, consuming the pending /run/nixos/*-list
#    restart bookkeeping. Use test to leave /boot untouched for now.
sudo "$known_good/bin/switch-to-configuration" test
```

Do not clear `/run/nixos/start-list`, `restart-list` or `reload-list` manually:
the interrupted switch left the services that need recovery in those files.
The temporary timeout survives daemon reloads but not a reboot. After a correct
oppy configuration containing the declarative timeout is deployed, remove only
`/run/systemd/system/libvirt-guests.service.d/90-incident-timeout.conf`, reload
systemd, and verify the effective timeout is still 5 minutes.

Before any `switch`/`boot` action or reboot, inspect **all** system profile
generations as well as `/boot`. After confirming generation 75 is still the
wrong-host closure and is not selected, preserve an explicit GC root for forensic
inspection if needed, then remove that generation with
`sudo nix-env -p /nix/var/nix/profiles/system --delete-generations 75`.
Do not blindly delete that number on another host or after history changes.
Only then refresh the bootloader from the known-good oppy closure and verify its
entries/default again. This prevents a later bootloader refresh from exposing
the wrong-host generation that was absent from `/boot` during inspection.

### Verify

```bash
systemctl list-jobs                                    # expect: No jobs running.
readlink -f /run/current-system                        # expect: …-oppy-25.11…
curl -sS -o /dev/null -w '%{http_code}\n' http://100.79.40.39:18080/
sudo nft list ruleset                                 # inspect BOTH accept/drop rules for 18080
systemctl is-active nftables nfs-server grafana prometheus loki promtail \
  marimohub ollama overleaf-web overleaf-private-origin.socket
systemctl --failed
```

Also check the public Overleaf URL through Cloudflare (not just the private
origin), NFS exports, and monitoring ingestion. An HTTP response alone does not
prove every service or the firewall recovered.

Inspect **`/boot` as root**. `NIXOS_INSTALL_BOOTLOADER` was set in the rebuild's
environment; do not infer bootloader safety from the activation phase. Verify
the `init=` closure in every boot entry and the selected default before reboot.

## Follow-ups

1. **Bound the libvirt-guests stop timeout** — implemented as a 300-second
   default. This bounds the stuck stop job, not the entire rebuild, and a timed-out
   stop can still report a failed unit. It is a total stop budget, not per guest;
   hosts with many/slow guests can override it with a larger finite value.
2. **Guard against wrong-host activation** — enabled for oppy, karkinos and
   spirit using `system.preSwitchChecks`, before service stops and bootloader
   writes. An activation script would run too late. The reusable
   `nixosModules.safe-switch` module must also be enabled in external flakes
   such as the personal `#moby` configuration: a guard in neusis cannot stop an
   unguarded incoming closure. Older generations are unguarded too. See the
   [deployment safeguards](../../README.md#deployment-safeguards) for intentional
   renames and profile rollback caveats. Related: #30.
3. **Monitoring cannot live only on the host it monitors.** Prometheus, Grafana,
   Loki and Promtail all being on oppy meant a 48-hour outage was found by a
   human hitting a 502, not by an alert.
