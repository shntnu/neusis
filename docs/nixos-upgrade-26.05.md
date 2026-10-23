# NixOS 26.05 upgrade — completed 2026-10-22

Oppy was upgraded and rebooted first. Fresh authenticated SSH to Oppy's
Tailscale address through Spirit succeeded before Spirit was changed.
Spirit was then upgraded and rebooted. Both active systems match their system
profiles and both are reachable through Tailscale.

| Host | Generation | Running system |
| --- | --- | --- |
| Oppy | 84 | `/nix/store/9n6g2n4k6qcsn2j201w3yk30dfm8i8a4-nixos-system-oppy-26.05.20261020.cd4ea8d` |
| Spirit | 16 | `/nix/store/iww1svbi5pk092449h2yjpnj3bgwhm6c-nixos-system-spirit-26.05.20261020.cd4ea8d` |

Both run Linux **6.18.57**, stock closed NVIDIA **580.159.03** (`dc_580`)
and ZFS **2.4.4**. All four H100 NVL GPUs on each host report the new driver.
There are no failed system services. Grafana health returns HTTP 200 on both;
Oppy's Overleaf login returns HTTP 200. Alloy, Loki and Prometheus are active.
No extended post-upgrade test suite was run, as requested by the operator.

## Scope and preservation

- Nixpkgs, Home Manager, Nixvim, Stylix, nix-darwin and NixOS-WSL follow26.05.
- Removed Node package references and obsolete Ollama acceleration settings
  were updated; the separate Ollama and personal Home Manager pins were retained.
- The compatible Overleaf/MongoDB/Redis runtime pin was retained.
- No `system.stateVersion` values or ZFS pool feature flags were changed.
- NVIDIA uses the native headless module with matching driver/GSP/persistenced.
  No custom driver patch, firmware override or kernel downgrade is used.
- The earlier monitoring/history-v1 hardening remains in place.
- Spirit's build retained its deployed `machines/spirit/network.nix` and
  `users/cslab_spirit.nix`: the unrelated NetworkManager unmanaged-interface
  change and additional kshimofu MacBook SSH key were not deployed. Those
  preexisting source changes were not reverted in this branch.
- Karkinos was not contacted or deployed. Shared version/GPU changes affect
  it only when it is subsequently rebuilt; this is not runtime acceptance
  for Karkinos or a claim of NVIDIA platform certification.

## Boot and rollback

The realized system closure was copied to Spirit using `nix copy --to ssh://spirit`.
Each target was selected with `nix-env --profile /nix/var/nix/profiles/system
--set <target>`, then staged with `NIXOS_INSTALL_BOOTLOADER=1
<target>/bin/switch-to-configuration boot`, followed by a normal reboot.
There was no live switch mixing new NVIDIA userspace with old loaded modules.

Oppy's first `bootctl update` failed because its fallback EFI executable had
GRUB/shim metadata rather than systemd version information. The old profile
and primary bootloader were restored before retrying. The final standard
bootloader reinstall installed systemd-boot260.5 normally; the original fallback
was privately backed up. Spirit's EFI files were also backed up before its
standard reinstall. No custom bootloader override was added.

Retained rollback systems are Oppy83 (also previously booted82) and Spirit15
(also14). Application rollback after a Grafana schema upgrade must use its
matching pre-upgrade database/key backup, not merely an older OS generation.
Do not prune those generations or upgrade ZFS pool features as part of this work.

## Monitoring data

Both Grafana instances kept their existing encryption keys, provisioned as
root-only `/var/lib/grafana-secrets/secret-key` and loaded through systemd
credentials. Consistent SQLite/config/key backups were taken before reboot.
No key rotation or database re-encryption was performed.

Promtail's journal positions were copied through its live PrivateTmp namespace.
`scripts/upgrade/alloy-journal-position.py` converted each preserved copy into
Alloy's corrected checkpoint format, installed inside its actual
DynamicUser/StateDirectory context. The defective Alloy1.16 legacy import was
not used. The journal boundary/checkpoint lag can replay already-collected logs.

Private operational evidence/backups are retained outside Git. On Oppy the
handoff and receipts are under
`~/.local/state/neusis/upgrade-2605-20261021/`; Spirit's receipts are under
`~/.local/state/neusis/spirit-upgrade-NAf0YZ31/`. Root-private backups on both
hosts are under `/var/lib/neusis-upgrade-backups/20261022/`.

## Operator choices and remaining work

- Process restarts are **manual**. Existing enabled systemd jobs may start
  normally, but no claim is made that arbitrary process memory or computation
  state survived. The custom job-restoration task was removed without running.
- The one-time Pi continuation resumed this session after Oppy's reboot; its
  startup enablement was then removed. No permanent recovery framework remains.
- Process-specific security/migration tests and Grafana rehearsal helpers were
  removed after deployment. Preexisting checks remain. The only new runtime
  test retained is `bash tests/overleaf-running.sh`, run on Oppy.
- Direct Broad LAN dashboard access remains pending confirmation of client/VPN
  CIDRs and the desired HTTP/HTTPS setup. Grafana authentication and private raw
  monitoring backends remain intact. LAN SSH forwarding is already an encrypted
  alternative to Tailscale; the OS upgrade was not held for additional networking.
- The previously observed public Marimohub Cloudflare1033 and IPMI scrape issue
  were not investigated or claimed fixed by this upgrade. Email remains paused.

## Follow-up: shell responsiveness and personal packages — 2026-10-22–23

### Oppy — repaired and checked

The apparent interactive slowness was traced to amunoz's Fish pre-command
Atuin hook, not host-wide memory or disk pressure. The effective client was
18.21.0 from an earlier targeted Home Manager rollout, while the system-applied
Home Manager unit ran 18.17.0. That daemon rejected an already-applied database
migration and restarted about 2,280 times; commands waited minutes before
execution. Fish startup alone took 0.12 seconds.

- `homes/amunoz/machines/oppy.nix` now selects Atuin through Home Manager from
  Neusis's existing newer Nixpkgs input (`nixpkgs-ollama`), independently of the
  personal/Moby package pin. No input lock or other user's package selection
  changed. The client path and daemon share this one package selection.
- Only the generated `atuin-daemon.service.d/10-home-manager-package.conf`
  drop-in was installed live. It uses the selected package, requires the
  existing encryption key to be nonempty, and sets umask 0077. The generated
  output is GC-rooted. This persistent drop-in also covers the older base unit
  until the complete system-managed Home Manager generation is rebuilt.
- No complete Home Manager/system activation or reboot was performed. The
  existing user package profile remains unchanged; Fish's existing managed
  `~/.local/bin/atuin` resolves to the same package as the repaired daemon.
  No compute jobs or unrelated services were stopped.
- All five SQLite databases were consistently backed up and passed
  `quick_check` before and after the repair. All 47,100 pre-repair history rows
  remained present; no database deletion, schema downgrade or key rotation.
- Verification: healthy daemon 18.21.0, zero subsequent restarts, all three
  observed blocked clients gone, and a fresh Fish login plus actual Atuin
  pre/post-command hooks completed in 0.219 seconds. No failed system units;
  approximately 1.3 TiB available memory and negligible I/O wait remained.
- Rechecked at 2026-10-23 01:04 and 01:18 EDT: same daemon PID still healthy
  after six hours, zero restarts and no new error-level service logs. The 01:04
  fresh Fish login and client-version check completed in 0.157 seconds;
  no failed system units.
- Both the main and upgrade checkouts evaluate the selected client package
  consistently; the upgrade checkout generated the applied drop-in.
  `git diff --check` passed. Source publication is separate from the targeted
  live repair; include this module in future full deployments to keep client
  and daemon package selection aligned.

Private backup and verification receipts:
`~/.local/state/neusis/atuin-repair-20261022T191326/` on Oppy.
Do not remove the compatibility override or run the older daemon against the
current database as a rollback; retain the backup and use compatible software.

### Spirit — amunoz packages deployed and checked

The operator confirmed that **Alan** means Unix account `amunoz` (UID 1000,
`/home/amunoz`), not a separate `alan` login. The separate subagent completed
this user's package-only reconciliation on 2026-10-23. Other users and the
system configuration were not changed.

- Reused the three personal Home Manager package-list files unchanged, but
  resolved their choices with Neusis's deployed NixOS 26.05, Home Manager
  release-26.05 and agenix input locks. No personal/Moby pinned derivations,
  full personal modules or overlays were imported for the requested packages.
- All **107 declarations / 102 distinct package choices / 118 selected outputs**
  are available. A fresh SSH/Fish login audit checked **519 public executable
  entries**: zero missing entries, old-target mismatches or PATH mismatches.
  Non-executable outputs also have direct exported-file evidence.
- Five previously absent CLI package choices are now available: Node/npm,
  Codex, Pi, agenix and the Harper language server. Other requested tools were
  aligned with the host package set. Zero exact host-selected outputs before
  deployment meant older versions were installed, not that all tools were absent.
- Used a package-only Home Manager preservation bridge because rebuilding the
  discovered full personal source would also apply unrelated services, secrets
  and personal version pins. The ordinary generated HM activation changed only
  package/profile state. No ad hoc package installation was used.
- All **642 managed-file links**, the exact existing `home-files` tree,
  session variables and separate Emacs package were preserved. Profile export
  comparison: zero removed, 48 added and 510 changed exports (not package
  counts). Existing unrelated tools/version-specific aliases remain available.
- HM generation advanced **1 → 2** and user profile **4 → 5**. The running
  NixOS system remained unchanged. No reboot, system rebuild, service reload,
  credential/key changes, SSH/network changes or changes to other users.
- The parent repeated the complete package/PATH audit and preservation checks
  over a fresh strict SSH login, and smoke-tested Node, npm, Codex and Pi.
  All checks passed. No failed system units on either server.
- At package-only completion, Spirit's Atuin daemon remained active, Emacs
  remained inactive, and the pre-existing user `agenix.service` was still failed.
  Unit states, MainPIDs and InvocationIDs were unchanged in that task. The
  separately authorized agenix repair is recorded below.

Durable source, activation evidence and guarded rollback are on Spirit at
`~/.local/share/home-manager/spirit-packages-20261022/`. The directory date
labels the original task; deployment completed on 2026-10-23. The source flake
provides `homeConfigurations."amunoz@spirit-packages"`. Its preservation of
existing store paths requires `--impure`; it is not a full reconciliation of
upstream personal Home Manager configuration. A later full HM switch can
supersede this bridge and needs a fresh scope/diff review.

New HM generation:
`/nix/store/jrv7ifgwclv2ni6hzna5lyp6d3wnnr7k-home-manager-generation`.
New effective user profile:
`/nix/store/bkq6zi393kpryv4w7wdns01s1anipqrj-user-environment`.
The old generation/profile are explicitly GC-rooted. Rollback is
`bash ~/.local/share/home-manager/spirit-packages-20261022/rollback.sh`;
it refuses to discard subsequent profile changes and restores pointers without
running the old full activation. The script was checked but not exercised.

Parent verification receipts on Spirit include
`evidence/packages-parent-final.json`, `evidence/managed-links-parent-final.json`
and `evidence/services-parent-final.txt`. The implementation/evidence mirror is
on Oppy at `/work/users/amunoz/projects/.agent-work/spirit-home-packages/`.
GUI applications, external authentication and long-running workloads were not
exercised; package availability and non-disruptive activation were verified.

### Spirit — dedicated agenix identity installed, 2026-10-23

The operator authorized a separate Spirit identity rather than copying Oppy's
SSH private key. The old user unit failed because its configured identity,
`/home/amunoz/.ssh/id_ed25519`, did not exist on Spirit.

- Generated `~/.config/agenix/spirit.agekey` on Spirit: private file mode 0600,
  parent directory 0700, owned by `amunoz`. The private identity stayed on
  Spirit and was never included in a Nix source, derivation or tool output.
- Found that the old shared `atuin.age` decrypts successfully on Oppy but does
  **not** equal Spirit's current Atuin key, even ignoring surrounding whitespace.
  Replacing it would change Atuin's credential. The shared secret and personal
  source checkout were therefore left untouched.
- Created a separate encrypted `atuin-spirit.age` from Spirit's existing key.
  Recipients are the new Spirit age identity and the operator's existing SSH
  public identity on Oppy for recovery. Both decryption routes were verified
  against the working key without displaying plaintext or saving it on Oppy.
  This does not rotate Atuin's key or claim to reconcile cross-host history sync.
- Built only Home Manager/agenix-generated service drop-ins using the same
  host-selected 26.05 inputs. Agenix now uses the dedicated identity, keeps a
  successful `active (exited)` state and atomically installs the key as a regular
  mode-0400 file (`symlink = false`). Atuin now Requires/After agenix and checks
  the key before future starts. Its package and ExecStart were not changed.
- Agenix completed two successful runs. After each, the installed key matched
  the pre-repair key byte-for-byte. Atuin stayed running with original PID 9952;
  it was not restarted. No system rebuild/reboot or full HM activation occurred.
- Fresh-login checks passed: all 118 requested outputs / 519 executable entries
  still resolve correctly, and system, user-profile and HM-profile pointers are
  unchanged. There are now **zero failed user units and zero failed system units**
  on Spirit. `systemd-analyze --user verify`, Bash syntax, ShellCheck and Nix
  formatting checks passed. Startup behavior is configured, not reboot-tested.
- One transient SSH connection error occurred before activation; reinspection
  confirmed activation had not run, and the same strict-host connection and
  reviewed deployment were then retried successfully. No host verification was
  disabled or SSH/network configuration changed.

Durable source, public recipient policy, encrypted secret, generated output GC
root and evidence are at
`~/.local/share/home-manager/spirit-agenix-20261023/` on Spirit. The standalone
source exports `homeModules.spirit-agenix` and builds only the two drop-ins.
Integrate/reconcile that module when making future full secret-management
changes; do not revert to the missing SSH identity or the mismatching shared
ciphertext. The package-only bridge remains unchanged; its old service snapshot
is historical. Current verification:

```sh
fish -l -c 'bash ~/.local/share/home-manager/spirit-agenix-20261023/verify.sh'
```

A protected **Spirit-local-only** rollback key is retained in
`rollback/atuin.key.before` (0600 inside 0700). Never publish/copy that directory
into Git or the Nix store; only `source/` contains publishable encrypted/public
material. The guarded `rollback.sh` removes this repair's exact drop-ins while
preserving the key and new identity; it was checked but not run and would
reintroduce the unrepaired old agenix configuration. Private identity loss can
be recovered by re-encrypting the ciphertext for a replacement identity using
the operator recovery recipient, without copying an SSH private key to Spirit.

### Brief user-facing follow-up summary

- **Oppy:** fixed the Atuin version mismatch that stalled Alan's Fish commands.
  Shell responsiveness is restored; history was preserved and the daemon is stable.
- **Spirit:** restored/updated Alan's (`amunoz`) declared Home Manager package
  set using Spirit's package versions; all 102 package choices and 519 executable
  entries passed availability checks. Existing configuration and Emacs were preserved.
- **Spirit secrets:** fixed agenix with a dedicated local age identity, preserved
  the working Atuin key and added correct service startup ordering. No failed
  user or system units remain on Spirit.
- These follow-ups required no reboot or system rebuild and did not change other
  users' accounts.

### Requested Spirit system refresh — prepared, activation pending

The original NixOS upgrade is already merged in canonical `shntnu/neusis` PR
[#45](https://github.com/shntnu/neusis/pull/45), commit `b6802c7`. The follow-up
source repair and this log are published separately in
[#46](https://github.com/shntnu/neusis/pull/46) against that main.

A fresh canonical-main-based Spirit system candidate built successfully:
`/nix/store/mpv5gqkyjy29bfns1vi8dlz197czfr08-nixos-system-spirit-26.05.20261020.cd4ea8d`.
Its kernel, kernel modules and system package tree are identical to the running
system. The only generated `/etc` content differences are NetworkManager's
unmanaged-interface configuration, its two service restart-trigger overrides,
and the previously merged additional kshimofu SSH public key. These changes
were intentionally held out of the initial upgrade and are not new Atuin changes.
The separate amunoz package/agenix repairs are already live and preserved.

System activation has **not** occurred: `sudo -n true` on Spirit requires a
password. The operator was asked to authorize sudo interactively; no credentials
were requested in chat and no privilege or host-verification bypass was used.
The existing Spirit system remains selected until that authorization and an
activation-plan/access check complete.
