# Neusis

> In geometry, the neusis (νεῦσις; from Ancient Greek νεύειν (neuein) 'incline towards'; plural: νεύσεις, neuseis) is a geometric construction method that was used in antiquity by Greek mathematicians.
> -- Wikipedia

Neusis provides nixos configs.

## Documentation

Operational documentation for the lab fleet (Oppy, Spirit, Karkinos) lives
in [broadinstitute/imaging-server-maintenance][ism] (Broad-internal):

- [`RUNBOOK_NIX.md`][runbook-nix] — NixOS procedures, including how to add a
  user to neusis.
- [`policies/user-access.md`][policy-access] and
  [`policies/user-lifecycle.md`][policy-lifecycle] — account states (active /
  locked / removed), onboarding/offboarding policy, group memberships,
  Tailscale ACL.
- [`MAINTENANCE_LOG.md`][log] — chronological incident record.

[ism]: https://github.com/broadinstitute/imaging-server-maintenance
[runbook-nix]: https://github.com/broadinstitute/imaging-server-maintenance/blob/main/RUNBOOK_NIX.md
[policy-access]: https://github.com/broadinstitute/imaging-server-maintenance/blob/main/policies/user-access.md
[policy-lifecycle]: https://github.com/broadinstitute/imaging-server-maintenance/blob/main/policies/user-lifecycle.md
[log]: https://github.com/broadinstitute/imaging-server-maintenance/blob/main/MAINTENANCE_LOG.md

## Getting started

linux machines

```bash
nixos-rebuild switch --flake .#karkinos
```

macos machines

```bash
darwin-rebuild switch --flake .#darwin001
```

## Deployment safeguards

Oppy, Karkinos and Spirit reject an incoming configuration whose hostname differs
from the live kernel hostname. This uses `system.preSwitchChecks`, **before**
services stop or the bootloader is updated; ordinary activation scripts are too
late. Use the correct flake output and `--target-host` for remote deployments.

For a deliberate rename or first activation on an installer, set
`NEUSIS_ALLOW_HOSTNAME_CHANGE=1` in the **target's** activation environment, e.g.
`sudo env NEUSIS_ALLOW_HOSTNAME_CHANGE=1 /path/to/new-system/bin/switch-to-configuration test`.
Do not set this globally. `NIXOS_NO_CHECK=1` bypasses all NixOS pre-switch checks,
including this guard.

The check belongs to the **incoming closure**. It does not protect against older
unguarded generations or other flakes. External configurations (including
personal machine flakes) can opt in with:

```nix
imports = [ inputs.neusis.nixosModules.safe-switch ];
neusis.safeSwitch.enable = true;
```

A rejected rebuild may already have changed `/nix/var/nix/profiles/system`.
Inspect it and restore the known-good generation before rebooting; this guard
does not undo profile changes or remove bad generations from history.

The shared libvirt configuration also bounds guest-service stops to 300 seconds
instead of infinity. This is a total budget; machines with many/slow guests can
set a larger finite `systemd.services.libvirt-guests.serviceConfig.TimeoutStopSec`.
See the [Oppy incident and recovery runbook](machines/oppy/INCIDENT-2026-09-18-wedged-switch.md).

Run the focused regression checks without activating a system:

```bash
nix build .#checks.x86_64-linux.switch-safety --no-link
```

## Updating your own home-manager profile

You can rebuild your home-manager profile without waiting for a full
`nixos-rebuild` — from any fleet machine:

```bash
home-manager switch --flake github:shntnu/neusis#<username>@<machine>
```

Reads your `homes/<username>/machines/<machine>.nix` entry from the
latest neusis `main`, rebuilds the profile, and swaps it in. Useful when
you add a package to your home config and want it live in seconds
without a system rebuild.

`shsingh` runs the same command against his personal flake instead:

```bash
home-manager switch --flake github:shntnu/nixos-config#shsingh@oppy
```
