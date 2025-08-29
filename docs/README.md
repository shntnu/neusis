# Neusis Documentation

This Nix configuration manages multiple Linux and macOS machines for a shared lab/team environment.

## Key Features

- **Multi-user setup**: Users defined in `users/` with different permission levels (admin/regular/guest)
- **Per-machine, per-user configs**: Each user can have different settings on different machines
- **Self-service workflow**: Users can test changes locally before submitting PRs
- **Development templates**: Quick-start templates for Python, Rust, etc.

## Directory Layout

```
neusis/
├── flake.nix           # Entry point
├── machines/           # Machine configurations
│   ├── karkinos/       # Linux workstation
│   ├── darwin001/      # macOS machine  
│   └── common/         # Shared modules
├── homes/              # User home configs
│   ├── <username>/     # Per-user directory
│   └── common/         # Shared user modules
├── users/              # User definitions
├── templates/          # Project templates
└── lib/                # Helper functions
```

## How It Works

1. Users are defined in `users/*.nix` with their SSH keys and shell preferences
2. The `lib.neusisOS` functions dynamically generate home configurations for each user@machine combination
3. Users can test changes locally with `home-manager switch` before submitting PRs
4. Admins control which machines users can access

## Differences from Typical Configs

Most personal Nix configs manage one user's dotfiles. This repo handles multiple users across multiple machines, useful for teams or shared computing environments. It's essentially a lightweight user management layer on top of NixOS/nix-darwin.

## Documentation

- [Getting Started](02_getting_started.md) - Set up your user account and environment
- [Architecture Overview](03_architecture.md) - Detailed technical overview
- [Environment Setup](04_environment_setup.md) - Create development environments  
- [User Management](05_user_management.md) - Admin guide for adding users