# Oppy Implementation Progress

> [!NOTE]
> Chronological log of NixOS configuration development for Oppy.
> Tracks policy implementation, features added, and configuration changes.
> Never edit past entries - append new progress at the bottom.

<details>
  <summary>Maintainer's Guide: Adding Progress Entries</summary>

## Maintainer's Guide: Adding Progress Entries

**When to add entries:**
- After implementing a new feature or module
- When policy requirements are met
- After significant configuration changes
- When testing/validation completes

**Entry format:**

```text
## YYYY-MM-DD - [Brief Description]

**Goal**: [What you set out to accomplish]

**Implementation**: [What was added/changed - file paths, key config]

**Testing**: [How it was verified - commands run, results]

**Status**: [✅ Complete | ⚠️ Partial | 🔧 In Progress | ❌ Blocked]

**Notes**: [Lessons learned, future improvements, related issues]
```

**Keep it concise:**
- Focus on *what* changed and *why*
- Include file paths for traceability
- Document test commands for future validation
- Link to policies when implementing requirements

</details>

---

## 2025-10-04 - CSLab Infrastructure Planning

**Goal**: Plan NixOS implementation of lab policies (user management, directory structure, monitoring)

**Analysis**:
- Reviewed existing Ansible implementation on Spirit (users.yml, directory structure, monitoring scripts)
- Discovered neusis already has user management via `lib/neusisOS.nix` and `users/cslab.nix`
- Decided on machine-specific implementation in `machines/oppy/` (extract to modules when Spirit migrates)

**Decision**: Create oppy-specific modules first, extract to shared modules only when proven on 2+ machines

**Next Steps**:
- Create `cslab-infrastructure.nix` - imaging group, /work/* directories
- Create `cslab-monitoring.nix` - systemd timers for quota checks
- Update `default.nix` to import these modules

**Status**: 🔧 Planning Complete

**Notes**: Following CLAUDE.md principle - "Let patterns emerge from real incidents before optimizing structure"

---

## 2025-10-04 - CSLab Infrastructure Implementation

**Goal**: Implement lab policies for directory structure, group membership, and monitoring

**Implementation**:

Created three files in `machines/oppy/`:

1. **`cslab-infrastructure.nix`**:
   - Creates `imaging` group (GID 1000) for all lab members
   - Adds `imaging` to extraGroups for all normal users (modifies users from neusisOS)
   - Creates `/work/{datasets,users,scratch,tools,users/_archive}` via systemd.tmpfiles (750 permissions, root:imaging)
   - Per-user directories via activation script: `/work/users/<user>` and `/work/scratch/<user>` (750, user:imaging)

2. **`cslab-monitoring.nix`**:
   - systemd timer: `cslab-check-quotas` (weekly, Monday 9 AM)
   - systemd service: Placeholder for quota monitoring (script path to be configured)
   - Log directory: `/var/log/lab-scripts/`
   - Future: scratch cleanup timer (commented out, ready when script exists)

3. **Updated `default.nix`**: Added imports for both cslab modules

**Testing**: ✅ Deployed and verified on production Oppy

**Verification Results**:
```bash
# imaging group created with all 8 users
getent group imaging
# imaging:x:1000:amunoz,ank,jewald,jfredinh,ngogober,rshen,shsingh,spathak

# Users have imaging in their groups
id ank | grep imaging
# groups=...1000(imaging)

# /work/* structure exists (750 root:imaging)
ls -la /work/
# datasets, scratch, tools, users, users/_archive ✅

# Per-user directories exist (750 user:imaging)
ls -la /work/users/ank
# drwxr-x--- 2 ank imaging ✅

# systemd timer active
systemctl status cslab-check-quotas.timer
# Active: active (waiting), Next: Mon 09:03:59 EDT ✅
```

**Status**: ✅ Complete - Infrastructure deployed successfully

**Next Steps**:
1. Configure monitoring script path in cslab-monitoring.nix (link to imaging-server-maintenance/scripts/monitoring/check-quotas.nu)
2. Add Slack webhook via agenix secret (when notifications needed)
3. Implement scratch cleanup timer when script ready

**Notes**:
- Build succeeded on first try after fixing circular dependency (importing users/cslab.nix directly)
- Kept implementation machine-specific as planned - will extract to modules/ when Spirit proves it needs identical setup
- imaging group modifies users already created by neusisOS lib (clean separation of concerns)
- Monitoring service has placeholder script execution (needs script path configuration)
- All policies from imaging-server-maintenance now implemented in NixOS declaratively

---
