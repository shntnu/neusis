# Neusis: Multi-machine Nix Configuration System

A reproducible, declarative infrastructure-as-code system for managing multiple machines and user environments.

## Conceptual Architecture

This repository implements a directed acyclic dependency graph where:

- **Nodes**: Configuration units (machines, users, modules)
- **Edges**: Import/dependency relationships
- **Entry Point**: flake.nix (root node)

The system follows pure functional composition principles where configurations are composed through explicit imports rather than global state.

## Dependency Structure

```ascii
flake.nix
├── nixosConfigurations/<machine>
│   ├── hardware-configuration.nix
│   ├── machines/common/* (shared modules)
│   └── homes/<users>/machines/<machine>.nix
├── darwinConfigurations/<machine>
│   └── (similar structure to nixosConfigurations)
└── homeConfigurations/<user>@<machine>
    ├── homes/<user>/home.nix (base config)
    ├── homes/<user>/machines/<machine>.nix
    └── homes/common/* (shared modules)
```

## Module System

Configurations are composed from smaller, parameterized functions:

```nix
# Example: Conditional module composition
{ config, pkgs, lib, ... }:
{
  imports = [
    (import ../common/dev/editors.nix { 
      enableNvim = true;
      enableAstro = false;
    })
  ];
}
```

## Using This Repository

1. **Machine setup**: `nixos-rebuild switch --flake .#<machine>`
2. **Adding users**: See `docs/add_users.md`
3. **Extending**: Create machine-specific configs in `machines/` or user-specific in `homes/`
4. **Common modules**: Reusable components in `homes/common/` and `machines/common/`

## Key Components

- **NixVim/Kalam/AstroNvim**: Terminal-centric development environment
- **Tailscale**: Secure networking fabric
- **GPU tools**: ML/AI acceleration (NVIDIA, vGPU)
- **Ollama**: Local LLM deployment

## Implementation Notes

- All configurations follow pure functional paradigms
- System state is derived entirely from declarative specs
- Version pinning ensures reproducibility across environments

## Specialized Subsystems

### Development Environment

The repository provides a sophisticated terminal-centric development environment:

```
homes/common/dev/
├── editors.nix (Neovim configurations)
├── git.nix (Version control)
├── terminals.nix (WezTerm, Kitty)
└── nixvim/ (Declarative Neovim)
```

### Machine Types

Machines are categorized by purpose:
- **Developer Workstations**: karkinos, darwin001
- **Compute Servers**: oppy, spirit
- **Specialized Systems**: chiral

### AI Infrastructure

The system integrates AI capabilities:
- Local LLM hosting via Ollama
- Neovim AI coding assistance (Avante, CodeCompanion)
- GPU acceleration for ML workloads

### Cross-Machine Synchronization

User environments follow users across machines:
- SSH keys synchronized via Git
- Tailscale for secure networking
- Consistent editor/terminal experience