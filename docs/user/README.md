# User Documentation

Guide for users of Neusis-managed systems.

## Getting Started

1. [Initial Setup](01_getting_started.md) - Get your account working
2. [Architecture Overview](02_architecture.md) - Understand the system
3. [Development Environments](03_environment_setup.md) - Use templates for projects
4. [User Management](04_user_management.md) - For admins adding users

## Quick Commands

```bash
# Test your home configuration locally
home-manager switch --flake .#yourname@oppy

# Enter a development shell
nix develop

# Use a project template
nix flake init -t github:broadinstitute/neusis#python
```

## Available Machines

| Machine | Type | Access |
|---------|------|--------|
| oppy | Compute server (GPU) | SSH via VPN |
| spirit | Compute server (GPU) | SSH via VPN |
| karkinos | Workstation | Direct |
| darwin001 | macOS | Direct |

## Getting Help

- Check [Troubleshooting](../operations/troubleshooting.md)
- Ask in Slack channel
- Submit PR for config changes
