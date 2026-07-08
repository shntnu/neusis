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
