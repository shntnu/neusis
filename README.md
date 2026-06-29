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

## External Home Manager profiles

User accounts and SSH authorization stay in `neusis`, but a user may keep
their actual Home Manager profile in a personal flake. For those users, set a
machine entry in `homeModules` to `null`. `neusis` will still create the Unix
account and authorized keys, but it will not create a `home-manager.users.<name>`
profile or standalone `homeConfigurations.<name>@<machine>` output for that
machine.

`shsingh` uses this pattern on `oppy` and `karkinos`; the real profiles are
built and applied from `shntnu/nixos-config`:

```bash
nix build 'github:shntnu/nixos-config#homeConfigurations."shsingh@oppy".activationPackage'
home-manager switch --flake 'github:shntnu/nixos-config#shsingh@oppy'
```

Other users' `homeModules` remain local to `neusis` unless they choose to
extract their own configs.
