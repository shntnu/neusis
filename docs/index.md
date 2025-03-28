# Neusis: Multi-machine Nix Configuration System

Welcome to the Neusis documentation. This repository contains a comprehensive Nix-based configuration system for managing multiple machines and user environments.

## What is Neusis?

Neusis is a declarative infrastructure-as-code system built on the Nix ecosystem that enables:

- **Reproducible Environments**: Identical development environments across machines
- **Multi-platform Support**: Configurations for both NixOS (Linux) and nix-darwin (macOS)
- **User Management**: Per-user, per-machine home-manager configurations

## Getting Started

- [Understanding the Architecture](architecture.md)
- [Creating a User](create_user.md)
- [Customizing Your Home](modify_home.md)
- [Creating Environments](create_env.md)
- [Machine Configurations](machines.md)

## Machines

The repository currently manages configurations for:

- **karkinos**: NixOS developer workstation
- **darwin001**: macOS developer machine
- **oppy, spirit**: Compute servers with GPU support
- **chiral**: Specialized system configurations

## Quick Commands

```bash
# Deploy NixOS configuration
nixos-rebuild switch --flake .#<machine>

# Deploy macOS configuration
darwin-rebuild switch --flake .#<machine>

# Update user environment
home-manager switch --flake .#<user>@<machine>
```
