# Incident — 2026-09-18: wrong-host rebuild wedges oppy for 2 days

**Status:** open, oppy still degraded at time of writing
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
`machines/common/virtualization.nix`, which every machine imports — so this is a
fleet-wide trap, not an oppy quirk.

## Current state — half-switched

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

## Recovery plan

Ordered to avoid resuming activation of the wrong config.

```bash
# 1. Kill the rebuild FIRST. Unblocking libvirt before this lets
#    switch-to-configuration resume and finish applying moby's config to oppy.
sudo systemctl stop nixos-rebuild-switch-to-configuration.service

# 2. Break the deadlock. 0 VMs running, so nothing to preserve.
sudo systemctl kill -s KILL libvirt-guests.service
sudo systemctl reset-failed libvirt-guests.service

# 3. Point the profile back at the real oppy generation.
sudo nix-env -p /nix/var/nix/profiles/system --switch-generation 74

# 4. Re-activate. Identical to /run/current-system, so the diff is ~empty;
#    its job is to start everything the stop phase killed.
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

Step 4 can re-enter the same deadlock, because `libvirtd.socket` is active again
and `libvirt-guests` is still `TimeoutStopSec=infinity`. Either land the
mitigation in this PR first, or mask the unit for the duration:

```bash
sudo systemctl mask libvirt-guests.service    # before step 4
sudo systemctl unmask libvirt-guests.service  # after
```

### Verify

```bash
systemctl list-jobs                                    # expect: No jobs running.
readlink -f /run/current-system                        # expect: …-oppy-25.11…
curl -sS -o /dev/null -w '%{http_code}\n' http://100.79.40.39:18080/
sudo nft list ruleset | grep 18080                     # firewall fence restored
systemctl --failed
```

Also check as root, which an unprivileged account cannot: **`/boot`**.
`NIXOS_INSTALL_BOOTLOADER` was set in the rebuild's environment. Activation
appears to have wedged before the bootloader step, but confirm no `gpa85-cad`
entries were written before anyone reboots oppy.

## Follow-ups

1. **Bound the libvirt-guests stop timeout** — proposed in this PR. A finite
   timeout turns a permanent fleet-wide wedge into a 5-minute delay.
2. **Guard against wrong-host activation.** A config for host *X* should refuse
   to activate on host *Y*. An assertion comparing `networking.hostName` against
   the live hostname at activation time would have made this a loud no-op.
   Related: #30 — same class of failure, different mechanism.
3. **Monitoring cannot live only on the host it monitors.** Prometheus, Grafana,
   Loki and Promtail all being on oppy meant a 48-hour outage was found by a
   human hitting a 502, not by an alert.
