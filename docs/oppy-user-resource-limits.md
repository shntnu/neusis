# Oppy: per-user process and memory containment

## Incident and scope

On 2026-11-12, Oppy suffered global memory exhaustion. The first accumulated
OOM dump contained repeated PID rows; deduplication identified 17,585 distinct
Python processes belonging to `jrietdij` (UID 1008). The kernel reported about
1.4 TiB of anonymous memory and no swap. Monitoring, T3 and backfill controllers
were among the OOM victims. The precise launching program and reboot mechanism
were not established. This is evidence of runaway concurrency, not evidence of
an OAuth failure or intentional misuse.

The operator authorized containment for this account on Oppy only:

| Slice property | Limit | Effect |
|---|---|---|
| `MemoryHigh` | 512 GiB | Throttle allocations and apply reclaim pressure |
| `MemoryMax` | 768 GiB | Hard limit; cgroup-local OOM killing if reclaim fails |
| `TasksMax` | 4,096 | Refuse additional processes/threads |

`TasksMax` counts threads too and does not kill existing tasks merely because
there are too many. Memory-limit kills are confined to the affected cgroup;
whole-user OOM group killing is not configured. These are aggregate limits,
not limits per shell or per Python process. They cannot prevent every possible
multi-user overload.

Normal PAM login sessions and user services descend from `user-1008.slice`.
Root/system services and VM/container workloads outside that slice are not
covered. The account has virtualization/container group access; this is accident
containment, not a security boundary. This change does not alter group membership,
ACLs, CPU quotas, scientific workflows or other users' limits.

## Declarative configuration

- `users/cslab.nix` records the existing UID as `uids.oppy = 1008`.
- The regular-user builder supports optional per-machine `uids`, falling back
  to an explicit `uid`, then automatic allocation. Other accounts and machines
  keep their existing behavior.
- `machines/oppy/user-resource-limits.nix` derives the slice from that UID,
  asserts the verified identity mapping, and sets the three limits.

Pinning the existing UID avoids assigning the slice to an unrelated account
on a fresh installation. Before any deployment to an existing installation,
verify `id -u jrietdij` is 1008 and `getent passwd 1008` resolves to that account.
Do not deploy a mismatched UID pin: investigate ownership and account mapping
rather than renumbering an existing user to make the assertion pass.

## Live rollout and transition

The limits were applied on 2026-11-12 with persistent `systemctl set-property`
settings, without rebuilding or rebooting. They survived `daemon-reload`.
A transient service running as UID1008 verified its placement under the user
slice and the actual parent kernel values:

```text
memory.high=549755813888
memory.max=824633720832
pids.max=4096
```

The probe was itself bounded to 32 MiB, eight tasks and 20 seconds and was
collected after exit. No large-memory/OOM stress test was performed. Tailscale,
T3 and both backfill controllers remained active. Reboot persistence of these
new resource limits has not yet been exercised.

Live overrides currently take precedence over generated Nix units:

```text
/etc/systemd/system.control/user-1008.slice.d/50-MemoryHigh.conf
/etc/systemd/system.control/user-1008.slice.d/50-MemoryMax.conf
/etc/systemd/system.control/user-1008.slice.d/50-TasksMax.conf
```

Root-only before/after receipts are in
`/var/lib/neusis-user-guardrails/20261112-jrietdij/`. Private incident and probe
evidence is in `/work/users/amunoz/artifacts/oppy-recovery-20261112/`.

After a reviewed full activation, verify the generated slice fragment has the
same limits before retiring those **three specific** override files. Do not
use `systemctl revert` or delete the whole directory: unrelated properties
must survive. Reload systemd and recheck both effective properties and active
kernel cgroup values; retain/restore the overrides if those checks fail.
Changing limits later must account for both sources until this transition is
complete. No override was removed by this PR.

## Validation

```bash
bash tests/user-resource-limits.sh
```

This checks UID fallback/override behavior, the UID assertion, Oppy's generated
slice unit, and absence of these limits on Spirit/Karkinos. Runtime checks:

```bash
systemctl show user-1008.slice -p MemoryHigh -p MemoryMax -p TasksMax -p DropInPaths
systemctl status user-1008.slice
```

When the slice is active, inspect `memory.events`, `pids.events` and the three
limit files in `/sys/fs/cgroup/user.slice/user-1008.slice/`. An inactive slice
may have no kernel directory. Any future destructive enforcement test should
use a separately bounded disposable child cgroup, not exhaust the production
768 GiB limit.
