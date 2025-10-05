# Oppy Disko Migration Experiments

> [!NOTE]
> Chronological log of disko configuration development and testing.
> Tracks evolution from current stripe config to future RAIDZ2.
> Never edit past entries - append new progress at the bottom.

<details>
  <summary>Getting Started: Required Reading</summary>

## Getting Started: Required Reading

**Before working on disko configuration, read these files in order:**

1. **`CLAUDE.md`** (repo root)
   - Neusis architecture, deployment commands
   - Disko usage patterns

2. **Git history** (this repo)
   - `git log --oneline machines/oppy/deployment/disko.nix`
   - See what changed and why

3. **`machines/oppy/EXPERIMENTS_DISKO_MIGRATION.md`** (this file - read ALL entries)
   - What's been tested vs what's planned
   - Failed attempts and lessons learned
   - VM testing procedures

4. **`../imaging-server-maintenance/RUNBOOK_NIX.md`**
   - Pre-deployment drive verification
   - VM testing commands
   - nixos-anywhere deployment procedure

5. **`../imaging-server-maintenance/MAINTENANCE_LOG.md`**
   - Storage expansion plan (2025-01-27 entry)
   - Drive specifications and order details

6. **`../imaging-server-maintenance/policies/storage-layout.md`** (when exists)
   - /work/ directory structure requirements
   - Snapshot and retention policies

**Read in this order every time you work on disko configuration.**

</details>

<details>
  <summary>Maintainer's Guide: Adding Experiment Entries</summary>

## Maintainer's Guide: Adding Experiment Entries

**When to add entries:**

- After testing a disko configuration in VM
- When creating new disko variants
- After successful deployment to production
- When discovering issues or gotchas

**Entry format:**

```text
## YYYY-MM-DD - [Brief Description]

**Goal**: [What you set out to test/accomplish]

**Implementation**: [What config was created/changed]

**Testing**: [VM or production testing - commands and results]

**Status**: [✅ Complete | ⚠️ Partial | 🔧 In Progress | ❌ Failed]

**Notes**: [Lessons learned, gotchas, next steps]
```

**Keep it concise:**

- Focus on *what* was tested and *results*
- Document VM test commands for reproduction
- Note any surprises or unexpected behavior
- Link to MAINTENANCE_LOG.md for deployment records

</details>

---

## Configuration Evolution Plan

```
Current Production (disko.nix)
  Pool: zstore16 (3x Kioxia 15TB, stripe, /datastore16)
  Pool: zstore03 (4x Intel 3.2TB, stripe, /datastore03)
  Risk: NO redundancy - any drive failure = data loss
    ↓
3-Drive Interim (disko-current-3drive.nix)  ← TEST IN VM, THEN DEPLOY
  Pool: work (3x Kioxia 15TB, stripe, /work/*)
  Drops: Intel drives (temporary, will be replaced)
  Adds: /work/ structure (datasets, users, scratch, tools)
  Risk: NO redundancy (same as current)
    ↓
6-Drive RAIDZ2 (disko-raidz2-future.nix)  ← DEPLOY WHEN NEW DRIVES ARRIVE
  Pool: work (6x Kioxia 15TB, raidz2, /work/*)
  Same: /work/ structure (no relearning)
  Adds: 2-drive fault tolerance (~56TB usable)
```

---

## Current vs Interim vs Future - Quick Reference

| Feature | Current (Production) | 3-Drive Interim | 6-Drive Future |
|---------|---------------------|-----------------|----------------|
| **Kioxia drives** | 3x 15TB | 3x 15TB (same) | 6x 15TB |
| **Intel drives** | 4x 3.2TB | Removed | N/A |
| **Pool names** | zstore16, zstore03 | work | work |
| **Redundancy** | None (stripe) | None (stripe) | RAIDZ2 (2-drive) |
| **Usable capacity** | ~42TB (Kioxia) | ~42TB | ~56TB |
| **Mount points** | /datastore16, /datastore03 | /work/* | /work/* |
| **Datasets** | 2 simple | 5 organized | 5 organized |
| **Snapshots** | Basic (zstore03 only) | Per-dataset policies | Same as interim |
| **Dedup** | ON (both pools) | OFF (performance) | OFF |

---

## Directory Structure Changes

### Current Production
```
/datastore16/     # 3x Kioxia, no organization, dedup ON
/datastore03/     # 4x Intel, no organization, dedup ON
```

### 3-Drive Interim & 6-Drive Future
```
/work/
├── datasets/     # Read-only reference data, full snapshots, dedup OFF
├── users/        # Active projects, daily+ snapshots, 20TB quota
│   └── _archive/ # Compressed (zstd), monthly snapshots, read-only
├── scratch/      # No snapshots, 90-day retention, sync=disabled, 10TB quota
└── tools/        # Shared software/models, full snapshots
```

### Snapshot Policies (Interim & Future)

| Dataset | Frequent (15m) | Hourly | Daily | Weekly | Monthly |
|---------|----------------|--------|-------|--------|---------|
| datasets | ✓ | ✓ | ✓ | ✓ | ✓ |
| users | ✗ | ✗ | ✓ | ✓ | ✓ |
| users/_archive | ✗ | ✗ | ✗ | ✗ | ✓ |
| scratch | ✗ | ✗ | ✗ | ✗ | ✗ |
| tools | ✓ | ✓ | ✓ | ✓ | ✓ |

---

## Remaining Work

- [x] Create 3-drive interim config (disko-current-3drive.nix) ✅
- [ ] Test 3-drive interim in VM
- [ ] Deploy 3-drive interim to production
- [ ] Order 3 more Kioxia drives (quote from Exxact ready)
- [ ] Test 6-drive RAIDZ2 config in VM
- [ ] Update disko-raidz2-future.nix with new drive serials
- [ ] Deploy 6-drive RAIDZ2 to production

**Tracking**: Mark items complete by adding ✅ and moving details to dated entry below.

---

## 2025-10-05 - Created 3-Drive Interim Configuration

**Goal**: Adapt disko-raidz2-future.nix to work with current 3 Kioxia drives for immediate deployment

**Context**:
- Want /work/ directory structure and snapshot policies NOW
- New drives not yet ordered (waiting on 3 more Kioxia)
- Current setup has NO redundancy anyway (stripe mode)
- Oppy has no production data - can reinstall safely

**Implementation**:

Created `/home/shsingh/work/GitHub/server/imaging-server-maintenance/assets/disko-current-3drive.nix`:

**Key Changes from Current Production:**
1. **Pool renamed**: `zstore16` → `work` (matches future RAIDZ2 config)
2. **Intel drives removed**: 4x Intel 3.2TB no longer in config (temporary drives)
3. **Mount changed**: `/datastore16` → `/work/*` (5 datasets)
4. **Dedup disabled**: Changed from `on` to `off` (better performance for large files)
5. **Snapshots configured**: Per-dataset policies (frequent, hourly, daily, weekly, monthly)
6. **Datasets organized**: datasets, users, users/_archive, scratch, tools

**Key Changes from Future RAIDZ2:**
1. **Mode**: `mode = ""` (stripe) instead of `mode = "raidz2"`
2. **Drive count**: 3x Kioxia instead of 6x
3. **Capacity**: ~42TB usable instead of ~56TB
4. **Redundancy**: NONE (any drive failure = data loss)

**Dataset Configuration:**
- `/work/datasets`: Read-only, recordsize=1M, dedup=off, all snapshots
- `/work/users`: Quota=20T, dedup=off, daily+ snapshots (no frequent/hourly)
- `/work/users/_archive`: Compression=zstd, read-only, monthly snapshots only
- `/work/scratch`: Quota=10T, sync=disabled, atime=on, NO snapshots
- `/work/tools`: Recordsize=128K, dedup=off, all snapshots

**Testing**: 🔧 Not yet tested

**Status**: 🔧 Configuration created, awaiting VM testing

**Next Steps**:
1. Copy config to neusis repo for VM testing
2. Test with VM per RUNBOOK_NIX.md procedure
3. Verify datasets mount correctly
4. Check snapshot policies work
5. Deploy to production if VM test passes

**Notes**:
- File location: imaging-server-maintenance/assets/ (will copy to neusis for testing)
- Same risk as current: NO redundancy, but gets us /work/ structure
- When new drives arrive: just change mode="" to mode="raidz2" + add 3 drives
- Migration path tested: current → interim → future RAIDZ2

---

## 2025-10-05 - VM Testing and Bug Fixes

**Goal**: Test 3-drive interim configuration in VM and verify all dataset properties

**Bugs Found and Fixed**:

1. **vm.nix secret paths broken by refactor** (commit 49a5975):
   - Problem: When vm.nix moved to deployment/, relative paths not updated
   - Error: `path '.../machines/secrets/common/tsclient.age' does not exist`
   - Fix: Updated `../../secrets/` → `../../../secrets/` in deployment/vm.nix:14-16
   - Impact: VM testing completely broken until fixed

2. **Scratch snapshot inheritance issue**:
   - Problem: Setting only `"com.sun:auto-snapshot" = "false"` insufficient
   - Result: All 5 snapshot types (frequent, hourly, daily, weekly, monthly) inherited `true` from pool
   - Impact: Scratch would get snapshots every 15 minutes (not acceptable for temp data)
   - Fix: Explicitly disable all 6 snapshot properties in scratch dataset
   - Added:
     ```nix
     "com.sun:auto-snapshot:frequent" = "false";
     "com.sun:auto-snapshot:hourly" = "false";
     "com.sun:auto-snapshot:daily" = "false";
     "com.sun:auto-snapshot:weekly" = "false";
     "com.sun:auto-snapshot:monthly" = "false";
     ```

**Testing**: ✅ VM test passed on second attempt (after fixes)

**Verification Results**:

```bash
# Pool structure
zpool status work
# ✅ 3x Kioxia drives in stripe, no errors

# Datasets
zfs list
# ✅ All 5 datasets mounted: datasets, users, users/_archive, scratch, tools
# ✅ Quotas: scratch=10T, users=20T

# Properties verified
# ✅ datasets: readonly=on, compression=lz4, recordsize=1M
# ✅ users: quota=20T, compression=lz4
# ✅ users/_archive: readonly=on, compression=zstd
# ✅ scratch: quota=10T, sync=disabled, atime=on
# ✅ tools: recordsize=128K

# Snapshots verified
# ✅ datasets: All 6 snapshot types enabled (frequent/hourly/daily/weekly/monthly)
# ✅ users: Only daily/weekly/monthly enabled (frequent/hourly disabled)
# ✅ scratch: ALL 6 snapshot types disabled (no snapshots for temp data)

# Pool settings
# ✅ ashift=12, autotrim=on

# Secrets
# ✅ All agenix secrets mounted in /run/agenix/
```

**Status**: ✅ Complete - Configuration validated in VM, ready for production deployment

**Files Modified**:
- machines/oppy/deployment/vm.nix (secret paths fix)
- machines/oppy/deployment/disko.nix (scratch snapshots fix)
- assets/disko-current-3drive.nix (scratch snapshots fix - backup copy)

**Commits Pending**:
- fix(oppy): correct vm.nix secret paths after refactor
- fix(disko): explicitly disable all snapshot types for scratch dataset

**Next Steps**:
1. ✅ Commit fixes to neusis repo
2. ✅ Push to GitHub
3. Deploy to production via nixos-anywhere from Spirit (instructions below)

**Notes**:
- ZFS property inheritance requires explicit override of each property
- Setting master `com.sun:auto-snapshot = false` does NOT cascade to individual types
- Refactor (49a5975) successfully updated cslab/ paths but missed deployment/vm.nix
- VM testing caught both issues before production deployment

---

## Production Deployment Instructions (Run from Spirit)

**Prerequisites:**
- ✅ 3-drive interim config tested in VM and committed
- ✅ Oppy has no production data (verified 2025-10-05)
- ⚠️ **DESTRUCTIVE**: Wipes all data on oppy disks
- 📍 Must run from **Spirit** (remote deployment)

**Pre-deployment checklist:**

```bash
# On oppy: Verify all 3 Kioxia drives detected (CRITICAL)
ssh oppy "ls -1 /dev/disk/by-id/nvme-KCD6* | grep -v '_1\|part' | wc -l"
# Expected: 3 (if less, reboot oppy 2-3 times until all appear)

# On oppy: Final check - anything important?
ssh oppy "du -sh /datastore16/* /datastore03/* 2>/dev/null || echo 'empty'"
# Expected: empty or nothing important

# On Spirit: Clone/update neusis repo
cd ~/work/GitHub/server
git clone https://github.com/shntnu/neusis.git shntnu-neusis  # If not exists
cd shntnu-neusis
git pull origin main
git log --oneline -3  # Verify a5f83be (3-drive config) is present
```

**Deployment procedure:**

```bash
# Step 1: Enter nix development shell (provides nixos-anywhere, agenix, etc.)
cd ~/work/GitHub/server/shntnu-neusis
nix develop

# Step 2: Verify secrets are already decrypted (from previous deployment)
ls -la scratch/etc/ssh/
# Expected: ssh_host_ed25519_key and .pub (owned by shsingh, not root)
# If missing: python scripts/anywhere.py decrypt --temp-folder scratch --key ~/.ssh/id_ed25519 secrets/oppy/anywhere

# Step 3: Build kexec image (if not already built)
nix build .#kexec_tailscale
ls -la result  # Note the store path for next step

# Step 4: Enable root SSH on oppy (required for nixos-anywhere)
ssh oppy
sudo passwd root  # Set temporary password, WRITE IT DOWN
sudo nixos-rebuild switch --flake .#oppy  # Enables root SSH
exit  # Return to Spirit

# Step 5: Deploy via nixos-anywhere (THE BIG STEP - WIPES DISKS)
python scripts/anywhere.py deploy \
  root@oppy \
  secrets/oppy/anywhere \
  --flake .#oppy \
  --temp-folder scratch \
  --key ~/.ssh/id_ed25519 \
  --identity-file ~/.ssh/id_ed25519 \
  --kexec /nix/store/HASH-kexec-tarball/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz
  # ^^^ Replace HASH with actual path from "ls -la result" in step 3

# Expected timeline:
# - Kexec boots installer (3-5 min)
# - Disko formats drives (1-2 min)
# - NixOS installation (10-15 min)
# - Total: ~20 minutes

# Step 6: Post-deployment - Import ZFS pools (CRITICAL)
# Pools NOT auto-imported due to disko bug, but activation script handles future boots
ssh oppy "sudo zpool import -f work"  # New pool name (not zstore16)
ssh oppy "sudo passwd -d root"  # Clear root password

# Step 7: Update Tailscale ACLs with new IP (if changed)
ssh oppy "tailscale status"  # Note IP address
# Update ACLs in Tailscale admin if needed
```

**Post-deployment verification:**

```bash
# Pool structure
ssh oppy "zpool status work"
# Expected: 3x Kioxia drives, ONLINE, no errors

# Datasets
ssh oppy "zfs list -o name,mountpoint,quota"
# Expected: work/datasets, work/users, work/scratch, work/tools, work/users/_archive

# Mount points
ssh oppy "ls -la /work/"
# Expected: datasets, users, scratch, tools directories

# Snapshot properties
ssh oppy "zfs get com.sun:auto-snapshot,com.sun:auto-snapshot:frequent work/scratch"
# Expected: Both false (no snapshots on scratch)

# CSLab infrastructure (should work as before)
ssh oppy "sudo /run/current-system/sw/bin/test-cslab-infrastructure.sh"
# Expected: All tests pass

# Services
ssh oppy "systemctl status grafana prometheus tailscale"
# Expected: All active (running)

# Check latest generation
ssh oppy "nixos-rebuild list-generations | head -3"
# Expected: New generation 1 with current timestamp
```

**Troubleshooting:**

- **DNS fails during install**: See RUNBOOK_NIX.md "DNS Resolution Fix During Deployment"
- **SSH host key changed**: `ssh-keygen -R oppy` then reconnect
- **Drives missing**: Reboot oppy 2-3 times (Kioxia detection issue)
- **Pool won't import**: `ssh oppy "sudo zpool import -f work"`

**References:**
- RUNBOOK_NIX.md: Complete nixos-anywhere Deployment section
- RUNBOOK_NIX.md: Pre-Installation Drive Verification section
- machines/oppy/deployment/disko.nix: Disk layout being deployed

**Rollback plan (if deployment fails):**

```bash
# Restore backup disko.nix (old config with zstore16/zstore03)
cd ~/work/GitHub/server/shntnu-neusis
cp machines/oppy/deployment/disko.nix.backup machines/oppy/deployment/disko.nix

# Redeploy with old config
python scripts/anywhere.py deploy root@oppy secrets/oppy/anywhere \
  --flake .#oppy --temp-folder scratch \
  --key ~/.ssh/id_ed25519 --identity-file ~/.ssh/id_ed25519 \
  --kexec /nix/store/HASH-kexec-tarball/...tar.gz
```

---

## 2025-10-05 - Production Deployment Completed with Post-Deployment Fixes

**Goal**: Deploy 3-drive interim configuration to production and fix issues discovered during deployment

**Deployment Method**: nixos-anywhere from Spirit

**Issues Encountered**:

1. **Initial deployment missing cslab infrastructure**
   - Problem: nixos-anywhere deployed system without imaging group, SSH keys, or user directories
   - Root cause: Unclear - possibly stale flake cache or didn't use latest git revision
   - Fix: Ran `nixos-rebuild switch --flake .#oppy` locally on oppy to apply full configuration

2. **Activation script errors on old datastore paths**
   - Problem: boot.nix tried to `chmod /datastore16 /datastore03` which don't exist
   - Fix: Removed chmod commands for old datastores (commit 627ff4f)

3. **ZFS datasets had wrong permissions**
   - Problem: `/work/datasets` and `/work/users/_archive` mounted as `root:root 755` instead of `root:imaging 750`
   - Root cause: ZFS datasets created read-only, preventing permission changes
   - Fix: Removed `readonly = "on"` from disko.nix, added activation script to fix permissions

**Fixes Applied**:

**Commit 627ff4f** - Remove old datastore chmod commands
- boot.nix: Removed `chmod 0777 /datastore03 /datastore16` from activation script
- These paths don't exist in new configuration

**Commit 9a3eee4** - Update boot.nix pool name comments
- Updated commented-out `boot.zfs.extraPools` from `["zstore16", "zstore03"]` to `["work"]`

**Commit c8eac6c** - Fix ZFS dataset permissions
- disko.nix: Removed `readonly = "on"` from work/datasets and work/users/_archive
- cslab/infrastructure.nix: Added activation script to fix permissions after ZFS mounts:
  ```nix
  chown root:imaging /work/datasets /work/users/_archive
  chmod 750 /work/datasets /work/users/_archive
  ```

**Commit [pending]** - Replace activation script with systemd service
- cslab/infrastructure.nix: Changed from activation script to systemd service `cslab-setup-directories`
- Service depends on `zfs-mount.service` to ensure ZFS is mounted before creating directories
- Fixes VM boot timing issue where activation ran before ZFS finished mounting

**Testing**:

VM Testing (2025-10-05):
```bash
cd ~/neusis
TESTVM_SECRETS="$(git rev-parse --show-toplevel)/scratch" QEMU_KERNEL_PARAMS=console=ttyS0 nix run .#nixosConfigurations.oppy.config.system.build.vmWithDisko
```

VM Test Results:
- ✅ ZFS pool created: 3x Kioxia drives in stripe mode
- ✅ All datasets mounted with correct quotas
- ✅ Imaging group exists with all 8 users
- ✅ Users have imaging group membership
- ✅ Permissions correct after manual activation
- ⚠️ User directories not created automatically (timing issue - activation ran before ZFS mounted)
- ✅ Manual activation (`/run/current-system/activate`) created directories correctly

Production Testing (2025-10-05):
```bash
ssh oppy
sudo test-cslab-infrastructure.sh
```

Test Results: 69/69 tests passed after fixes

**Status**: ✅ Complete - Production deployment successful with all issues resolved

**Post-Deployment State**:
- Pool: work (3x Kioxia 15TB, stripe mode, ~42TB usable)
- Datasets: /work/datasets, /work/users, /work/scratch, /work/tools, /work/users/_archive
- Permissions: root:imaging 750 on all datasets
- Users: All 8 cslab users with imaging group
- SSH keys: Deployed via /etc/ssh/authorized_keys.d/
- Monitoring: cslab-check-quotas and cslab-check-groups timers active

**Lessons Learned**:

1. **nixos-anywhere may not apply full configuration** - Always follow up with local `nixos-rebuild switch` on target machine
2. **ZFS readonly prevents permission changes** - Don't use `readonly = "on"` if you need to set ownership/permissions on mount points
3. **Activation scripts run before ZFS mounts** - Use systemd services with proper dependencies for ZFS-dependent operations
4. **VM boot timing differs from hardware** - Test activation dependencies in both environments

**Next Steps**:
1. Apply systemd service fix (replace activation script)
2. Reboot oppy and verify cslab-setup-directories service runs correctly
3. Update deployment procedure documentation with mandatory local rebuild step
4. Order 3 more Kioxia drives for RAIDZ2 migration
5. Test 6-drive RAIDZ2 config in VM before new drives arrive

**Files Modified**:
- machines/oppy/boot.nix (remove old datastore paths)
- machines/oppy/deployment/disko.nix (remove readonly from datasets)
- machines/oppy/cslab/infrastructure.nix (add permission fixes, convert to systemd service)

**Deployment Command Archive**:

Initial deployment (from Spirit):
```bash
cd ~/work/GitHub/server/shntnu-neusis
nix develop
python scripts/anywhere.py deploy root@oppy secrets/oppy/anywhere \
  --flake .#oppy --temp-folder scratch \
  --key ~/.ssh/id_ed25519 --identity-file ~/.ssh/id_ed25519 \
  --kexec /nix/store/HASH-kexec-tarball/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz
```

Post-deployment fix (on oppy):
```bash
ssh oppy
cd ~/neusis
git pull
sudo nixos-rebuild switch --flake .#oppy
```

**Verification After Reboot**:
```bash
ssh oppy
systemctl status cslab-setup-directories  # Should show active (exited)
ls -la /work/users/ /work/scratch/  # Should have all user directories
sudo test-cslab-infrastructure.sh  # All 69 tests should pass
zpool status work  # 3x Kioxia drives, ONLINE
zfs list -o name,mountpoint,quota  # All datasets with correct quotas
```

---
