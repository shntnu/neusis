# Neusis

> In geometry, the neusis (νεῦσις; from Ancient Greek νεύειν (neuein) 'incline towards'; plural: νεύσεις, neuseis) is a geometric construction method that was used in antiquity by Greek mathematicians.
> -- Wikipedia

Neusis provides nixos configs.

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
