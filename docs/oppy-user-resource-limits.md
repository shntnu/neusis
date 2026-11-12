# Oppy: per-user process and memory containment

Incident history and live rollout/verification records belong in the
[maintenance log, added by maintenance PR15](https://github.com/broadinstitute/imaging-server-maintenance/pull/15).
This document describes configuration and deployment mechanics only.

## Configuration and scope

The `jrietdij` user slice on Oppy has these aggregate limits:

| Slice property | Limit | Effect |
|---|---|---|
| `MemoryHigh` | 512 GiB | Throttle allocations and apply reclaim pressure |
| `MemoryMax` | 768 GiB | Hard limit; cgroup-local OOM killing if reclaim fails |
| `TasksMax` | 4,096 | Refuse additional processes/threads |

`TasksMax` counts threads too and does not retroactively kill existing tasks.
Whole-user OOM group killing is not configured. These are aggregate limits,
not limits per shell or per Python process, and cannot prevent every possible
multi-user overload.

Normal PAM login sessions and user services descend from `user-1008.slice`.
Root/system services and VM/container workloads outside that slice are not
covered. This is accident containment, not a security boundary. This module
does not change group membership, ACLs, CPU quotas or other users' limits.

- `users/cslab.nix` selects `uids.oppy = 1008` for this account.
- The regular-user builder supports optional per-machine `uids`, falling back
  to an explicit `uid`, then automatic allocation. Other accounts and machines
  keep their existing behavior.
- `machines/oppy/user-resource-limits.nix` derives the slice from the UID,
  asserts the expected mapping, and sets the three limits.

Before deployment to an existing installation, verify `id -u jrietdij` is 1008
and `getent passwd 1008` resolves to that account. Do not deploy a mismatched
UID pin: investigate ownership and mapping rather than renumbering an existing
user to make the assertion pass.

## Transition from imperative overrides

Persistent `systemctl set-property` overrides take precedence over generated
Nix units. Check for these before deploying changes to the limit values:

```text
/etc/systemd/system.control/user-1008.slice.d/50-MemoryHigh.conf
/etc/systemd/system.control/user-1008.slice.d/50-MemoryMax.conf
/etc/systemd/system.control/user-1008.slice.d/50-TasksMax.conf
```

After reviewed activation, verify that the generated slice fragment contains
the intended limits before retiring those **three specific** override files.
Do not use `systemctl revert` or delete the whole directory: unrelated
properties must survive. Reload systemd and recheck effective properties and
active kernel cgroup values; retain/restore the overrides if checks fail.
Until this transition is complete, account for both configuration sources.

## Validation

```bash
bash tests/user-resource-limits.sh
systemctl show user-1008.slice -p MemoryHigh -p MemoryMax -p TasksMax -p DropInPaths
systemctl status user-1008.slice
```

The automated tests check UID fallback/override behavior, the UID assertion,
Oppy's generated slice unit, and absence of these limits on Spirit/Karkinos.
When the slice is active, inspect `memory.events`, `pids.events`, `memory.high`,
`memory.max` and `pids.max` in `/sys/fs/cgroup/user.slice/user-1008.slice/`.
An inactive slice may have no kernel directory. Any destructive enforcement
test should use a separately bounded disposable child cgroup, not exhaust
the production 768 GiB limit. Record operational results in the maintenance log.
