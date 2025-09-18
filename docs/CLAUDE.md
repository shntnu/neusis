# CLAUDE.md - Documentation Guidelines

This file guides Claude Code when creating or modifying documentation in the `docs/` directory.

## Documentation Philosophy

### Writing Style

- **Prescriptive over descriptive**: Write "Do X" not "You might consider X"
- **Dense, executable content**: Every line should be actionable
- **No verbose explanations**: Assume technical competence

### Target Audience

- Experienced engineers operating NixOS servers
- Users familiar with Linux but new to Nix
- Admins managing multi-user compute infrastructure

## Content Principles

### Do

- Start with exact commands
- Use real values from actual deployments
- Document from transcripts and proven procedures
- Cross-reference with dual links: `[Local](../path) | [GitHub](https://github.com/...)`

### Don't

- Write theoretical explanations
- Document unimplemented features
- Duplicate imaging-server-maintenance content
- Add philosophical discussions about Nix

## Documentation Scope

### In Scope (neusis/docs)

- NixOS configuration and deployment
- Nix-specific operations (rebuilds, flakes)
- Secret management via Agenix
- Service configuration through Nix modules
- User management via Nix

### Out of Scope (→ imaging-server-maintenance)

- Hardware specifications
- Physical network topology
- BMC/IPMI procedures
- Datacenter access
- Incident logs for hardware failures

## File Organization

```text
docs/
├── operations/        # Day-to-day procedures
├── user/             # End-user documentation
└── reference/        # Quick lookup
```

Keep flat structure. Avoid deep nesting.

## Example Documentation

### Good

```markdown
## Deploy to Oppy

\```bash
nixos-rebuild switch --flake .#oppy --target-host oppy
\```

If fails with "Permission denied":
\```bash
ssh-add ~/.ssh/id_ed25519
\```
```

### Bad

```markdown
## Understanding NixOS Deployment

NixOS uses a declarative approach to system configuration...
There are several ways you might deploy...
Consider the following options...
```

## Cross-Repository References

Always provide dual links:

```markdown
Hardware specs: [Local](../../../../misc/imaging-server-maintenance/INVENTORY.md) | [GitHub](https://github.com/broadinstitute/imaging-server-maintenance/blob/main/INVENTORY.md)
```

## Maintenance

- Update from actual operations, not theory
- Remove outdated content immediately
- Test all commands before documenting
