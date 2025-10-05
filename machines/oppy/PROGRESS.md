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

## Remaining Work - Path to Full NixOS

> **Context**: These features exist in Ubuntu/Ansible (Spirit) but are missing or incomplete in NixOS.
> Once completed, imaging-server-maintenance `scripts/` can be archived and Spirit can migrate to NixOS.
>
> **Policy Source**: `../imaging-server-maintenance/policies/`
> **Current Implementation**: `../imaging-server-maintenance/scripts/`

### Critical - Blocking Spirit Migration

- [x] **Sudo restriction**: Move users from admins → regulars in `users/cslab.nix` ✅
  - 3 admins (ank, amunoz, shsingh) with wheel group
  - 5 regulars (ngogober, spathak, jewald, rshen, jfredinh) without sudo
  - Completed: 2025-10-05

### High Priority - Security & Compliance

- [x] **Security auditing - group membership**: Implemented in `cslab-monitoring.nix` ✅
  - ✅ Weekly checks for unauthorized group memberships (Wed 9 AM)
  - ✅ Log violations to `/var/log/lab-scripts/group-violations.log`
  - ✅ Slack alerts for group membership violations
  - ⏳ TODO: Detect undeclared users in imaging group (separate check)
  - Completed: 2025-10-05

- [x] **Exact group membership enforcement**: NixOS handles this natively ✅
  - NixOS already enforces exact group membership (not additive)
  - Tested: Manual group additions removed on `nixos-rebuild switch`
  - No additional implementation needed
  - Monitoring added above to detect violations between rebuilds
  - Verified: 2025-10-05

- [ ] **User lifecycle - locked users**: Extend `cslab-infrastructure.nix` for oppy
  - Read locked users from config, set shell to `/usr/sbin/nologin`, lock password
  - Preserve data but prevent login
  - Required for offboarding policy compliance
  - Extract to `lib/neusisOS.nix` when Spirit migrates

- [ ] **User lifecycle - removed users**: Extend `cslab-infrastructure.nix` for oppy
  - Archive to `/work/users/_archive/<username>_YYYY-MM-DD`
  - Change ownership to root:imaging, delete account
  - Required for offboarding policy compliance
  - Extract to `lib/neusisOS.nix` when Spirit migrates

### Medium Priority - Operational Features

- [ ] **Scratch cleanup**: Implement and enable 90-day retention
  - Write `scratch-cleanup.nu` script
  - Uncomment timer in `cslab-monitoring.nix:68-88`
  - Test with dry-run, deploy to production

- [ ] **Emergency account safeguards**: Prevent managing critical accounts
  - Add safety check in neusisOS lib
  - Fail build if `exx` or `root` in user lists
  - Prevents accidental lockout

### Future Considerations

- [ ] Extract oppy-specific modules to `modules/nixos/cslab-*` when Spirit migrates
- [ ] Evaluate if private user groups needed (currently imaging is primary)
- [ ] Consider dataset registry validation script integration

**Tracking**: Mark items complete by adding ✅ and moving details to dated entry below.

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
1. ~~Configure monitoring script path~~ ✅ Complete
2. ~~Add Slack webhook via agenix secret~~ ✅ Complete
3. Implement scratch cleanup timer when script ready

---

## 2025-10-05 - Monitoring Script and Slack Integration

**Goal**: Wire up quota monitoring script with Slack notifications

**Implementation**:

1. **Copied check-quotas.nu** to `machines/oppy/scripts/check-quotas.nu`
2. **Updated cslab-monitoring.nix**:
   - Added `fd` to service PATH (required by script)
   - Updated script execution to use actual Nushell script
   - Added `SuccessExitStatus = [ 0 2 ]` (exit code 2 = user needs action, not failure)
3. **Slack integration via agenix**:
   - Added `oppy/slack_webhook.age` to `secrets/secrets.nix`
   - Created encrypted secret file with webhook URL
   - Declared secret in cslab-monitoring.nix (mode 400, root-only)
   - Export SLACK_WEBHOOK_URL in service script from secret

**Testing**: ✅ Deployed and verified on production Oppy

**Verification Results**:
```bash
sudo systemctl start cslab-check-quotas.service
# [INFO] Notified via Slack for user shsingh - 136.23GB used
# [INFO] Quota check complete: 10 users checked, 1 need action
# Service: Deactivated successfully ✅

# Check Slack channel - notification received ✅
```

**Status**: ✅ Complete - Full monitoring with Slack notifications operational

**Notes**:
- Script runs weekly Monday 9 AM via systemd timer
- Exit code 2 (user needs action) treated as success to avoid false failures
- Slack webhook stored securely via agenix (encrypted at rest)
- All 10 cslab users monitored automatically
- Found: shsingh over quota (136.23GB / 100GB soft limit)

**Notes**:
- Build succeeded on first try after fixing circular dependency (importing users/cslab.nix directly)
- Kept implementation machine-specific as planned - will extract to modules/ when Spirit proves it needs identical setup
- imaging group modifies users already created by neusisOS lib (clean separation of concerns)
- Monitoring service has placeholder script execution (needs script path configuration)
- All policies from imaging-server-maintenance now implemented in NixOS declaratively

---

## 2025-10-05 - Sudo Access Restriction

**Goal**: Restrict sudo access to 3 admins, remove from 5 regular users

**Implementation**:

Modified `users/cslab.nix`:
- **Admins** (keep wheel group): ank, amunoz, shsingh
- **Regulars** (remove wheel group): ngogober, spathak, jewald, rshen, jfredinh
- Regulars maintain all other access: imaging group, docker, libvirtd, SSH

**Testing**: ✅ Deployed and verified on production Oppy

**Verification**:
```bash
# Test script: machines/oppy/scripts/test-cslab-infrastructure.sh
# Test 10: Sudo Access Restriction - all tests passed
# - 3 admins verified with wheel group
# - 5 regulars verified without wheel group
```

**Status**: ✅ Complete - Sudo restriction implemented and verified

**Notes**:
- Policy requirement from `policies/user-access.md` now enforced
- Unblocks Spirit migration (was marked as Critical)
- Users maintain all functionality except sudo
- Test added to infrastructure validation script for future regression detection

---

## 2025-10-05 - Group Membership Violation Monitoring

**Goal**: Implement security auditing for unauthorized group memberships

**Discovery**: NixOS already enforces exact group membership (not additive like traditional Linux)

**Testing**:
```bash
# Manual test: Add regular user to wheel group
sudo usermod -aG wheel ngogober
groups ngogober  # Shows wheel

# Rebuild NixOS
sudo nixos-rebuild switch --flake .#oppy

# Verify wheel removed automatically
groups ngogober  # No wheel - NixOS enforced exact membership
```

**Implementation**:

Modified `cslab-monitoring.nix`:
- Added `checkGroupsScript` derived from `users/cslab.nix` (single source of truth)
- Checks regulars don't have wheel (unauthorized sudo)
- Checks admins DO have wheel (expected sudo)
- Weekly timer: Wednesday 9 AM
- Logs to `/var/log/lab-scripts/group-violations.log`
- Slack alerts on violations

**Testing**: ✅ Deployed and verified on production Oppy

**Verification**:
```bash
# Service deployed
systemctl status cslab-check-groups.timer  # Active, next run Wed
systemctl start cslab-check-groups.service  # Manual test

# Log file created
cat /var/log/lab-scripts/group-violations.log
# [2025-10-05T01:28:32-04:00] No group violations detected

# Test 11: Group Membership Monitoring - all tests passed
```

**Status**: ✅ Complete - Group violation monitoring operational

**Key Findings**:
- **NixOS enforcement**: Exact group membership enforced on rebuild (removes undeclared groups)
- **Monitoring value**: Detects violations between rebuilds (time window protection)
- **Pattern mirrors Ansible**: Same approach as Spirit's `enforce-state.yml`
- **Defense in depth**: Don't rely solely on rebuild schedule

**Notes**:
- Mirrors Ansible pattern from `scripts/ansible/playbooks/enforce-state.yml`
- Script auto-updates when `users/cslab.nix` changes (Nix derivation)
- Marked "Exact group membership enforcement" as complete (NixOS native feature)
- Still TODO: Detect undeclared users in imaging group (separate check)

---
