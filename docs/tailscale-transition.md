# Spirit-first lab tailnet migration

## Status and scope (2026-11-04)

**Connectivity is proven; permanent deployment and reboot acceptance are not.**

- Spirit is live in Runxi's lab tailnet, retaining its original profile for recovery.
  Fresh Mac numeric SSH, FQDN SSH and a Spirit-to-Oppy LAN jump succeeded with the
  original host keys and account `amunoz`. Following a reported client reconnect
  failure, eight further fresh SSH sessions passed without another server change.
  Do not dismiss setup/intermittency reports or treat `Running` as acceptance.
- Only Spirit's Tailscale daemon was restarted during diagnostics. No OS reboot,
  Nix generation activation, research process restart or fleet migration occurred.
- Spirit still runs its previously activated generation, with persistent guards
  blocking that generation's **old-tailnet enrollment/OAuth jobs**. Keep those
  guards until a reviewed destination generation is activated and verified.
- A requested reboot test is **blocked on workload-owner clearance/checkpointing**:
  active multi-day GPU jobs and user sessions were discovered. Do not reboot to
  test networking while silently terminating that work.
- Oppy and Karkinos remain in the old tailnet. Oppy's physical LAN recovery to
  Spirit is verified; Karkinos's independent recovery is not. Karkinos is still on
  NixOS 25.11. Do not deploy a broad current-main fleet rebuild or upgrade it as a
  side effect of this migration.

This change prepares Spirit's declarative configuration only. It does not activate
that configuration, change tailnet policy, move another server, or grant new sudo
privileges. The full application/second-user/reboot acceptance gates below remain.

## Agreed access model

The original individual-server-sharing proposal was superseded by **group-based
membership**:

| Item | Value |
| --- | --- |
| Destination tailnet ID | `ToFdp7kzyV11CNTRL` |
| Real tailnet name / display name | `runxi-shen.github` / `cs-lab-ts` |
| DNS suffix | `tail27b080.ts.net` |
| Human clients | untagged, user-owned, members of `group:cs-lab` |
| Servers | `tag:cslab-servers` (plural) |
| Remote login | existing OpenSSH users and keys; Alan uses `amunoz` |
| Tailscale SSH | disabled on Spirit; no conversion of existing SSH accounts |

The operator confirmed active group-to-server and server-to-server grants with
`ip: ["*"]`. Spirit's actual installed filter was inspected and permits the Mac's
lab IPv4/IPv6 addresses on TCP, UDP and ICMP. ICMP failure is **not expected** under
these grants. Do not widen policy to compensate for a transport failure.

[`tailscale-lab-policy.draft.json`](tailscale-lab-policy.draft.json) preserves the
operator-supplied broader policy/roster for review. **It is not a verified export
of the deployed policy and must not be pasted over the live policy blindly.**
Its admin/Funnel settings are not all confirmed deployed. `leoank@github` remains
a normal group member; the special Leoank subnet/`tag:neusis` grant is excluded.
A policy's SSH section does not enable Tailscale SSH on a server whose RunSSH is
false.

## Identities and recovery

| Host/profile | Address / name |
| --- | --- |
| Spirit lab profile `884d` | `100.107.101.71`, `spirit.tail27b080.ts.net` |
| Spirit old profile `57fb` | `100.126.147.16`, `spirit.tail5e510f.ts.net` |
| Oppy (unchanged old tailnet) | `100.79.40.39` |
| Karkinos (unchanged old tailnet) | `100.69.243.77` |
| Oppy → Spirit physical LAN | `10.192.6.25` → `10.192.6.24` |

Spirit's original ED25519 host fingerprint is
`SHA256:aqcjtycA6MuBOyTeKVi36Q8FWnEQakK1yMsNLOWLVvM`. Preserve trust aliases and
strict verification; never disable host-key checking to make a migration test pass.

The Mac's retained profiles are lab `c21b` and old `9f12`. While on the lab profile,
ordinary old-tailnet Oppy access is not a fallback. The verified new entry path is
Mac → Spirit → Oppy LAN (`oppy-via-spirit` in Alan's personal SSH configuration).
For independent recovery during a Spirit outage, deliberately return the Mac to
its old profile and reach Oppy's old numeric IP, then Spirit's LAN IP. Mac direct
Broad LAN/VPN recovery was **not** verified.

No private key is copied between hosts and no agent forwarding is needed for the
jump. Existing personal SSH settings belong in the user's own configuration, not
in a fleet-wide home module.

## What failed, and what fixed it

### Separate Mac resolver ownership conflict

A Nix-managed `/etc/resolver/ts.net` symlink escaped through `/etc/static` into the
Nix store. Tailscale 1.102.4's directory-scoped resolver writes rejected it with
`openat ts.net: path escapes from parent`.

A separately approved Mac-admin repair backed up the link/content outside the
resolver directory, replaced only that link with an equivalent regular file and
reapplied the existing Tailscale DNS settings. Both public DNS and MagicDNS passed;
the DNS health warning cleared. The owning `nixos-config` change disables the
pinned nix-darwin module's static `environment.etc."resolver/ts.net"` entry so it
will not recreate the conflict. Do not edit immutable store targets, reset all
DNS, install a competing daemon, or leave accept-DNS disabled.

**DNS repair alone did not restore numeric TCP/SSH.** That was tested explicitly.

### Missing Spirit relay advertisement after a profile switch

The Mac's fresh, non-cached lab peer map showed Spirit online with private LAN
endpoints but no home DERP relay. The old-profile record had a New York relay.
Spirit's direct UDP path was unavailable, so relay fallback mattered even though
its daemon locally reported a DERP connection.

In a guarded window, selecting retained profile `884d` and restarting **only
`tailscaled`** caused the client-visible home relay to become available. Discovery,
TSMP and ICMP then worked. Initial TCP attempts preceded handshake readiness; a
subsequent readiness-checked test proved fresh numeric/FQDN OpenSSH and the Oppy
LAN jump. All used existing keys and strict host verification.

The server ran Tailscale 1.98.10. Source inspection is consistent with unchanged
network-info notifications not being replayed to a new profile's control client,
but no upstream bug or fixed release has been confirmed. Record the observed
advertisement failure and tested workaround, not an invented vendor diagnosis.
Do not add an unconditional restart/re-authentication loop to every boot/rebuild.

For future switches, verify **peer reachability and fresh authentication**, not
just a successful `tailscale switch` or control-plane `Online` state:

```sh
# Only when both endpoints are confirmed in the destination tailnet.
tailscale ping --c=2 --timeout=3s 100.107.101.71
tailscale ping --tsmp --c=3 --timeout=3s 100.107.101.71
ssh -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=1 \
  -o ControlMaster=no -o ControlPath=none -o ForwardAgent=no \
  -o HostKeyAlias=spirit -o StrictHostKeyChecking=yes \
  amunoz@spirit.tail27b080.ts.net 'hostname; id -un'
```

If the peer has no relay advertisement and direct reachability is unavailable,
use verified LAN access to investigate. A controlled daemon restart was effective
here; keep old-enrollment guards and rollback armed first. Do not logout, force
reauth, reuse the consumed key, disable host verification or widen grants.

## Enrollment secret and declarative activation

Spirit's destination encrypted enrollment material is isolated under
`secrets/runxi-tailnet/`, with the same recipients as its old Spirit-specific
secret. The old encrypted material is retained; **the saved old profile**, not an
assumption about an old key's validity, is the tested recovery method.

The destination one-time key was **already consumed** by the successful enrollment.
It is not a reusable provisioning/disaster-recovery key. Retain existing daemon
state and switch saved profiles. Before any fresh enrollment after state loss,
an authorized lab administrator must issue a new properly tagged key and update
the encrypted material through the normal secret-management workflow. Never print
or decrypt a key merely for diagnostics.

The configuration removes Spirit's old shared enrollment/OAuth selections,
disables old hostname-claim/key-expiry helpers, requests `tag:cslab-servers` for
new enrollment and sets RunSSH false. Up flags do not migrate an already logged-in
daemon: verify the selected tailnet/profile explicitly. Do not assume a Nix switch
by itself changes membership or that a consumed key will recover deleted state.

Before activation, review/build **Spirit only**, inspect the proposed generation
and preserve an independent LAN/root path. No whole-fleet rebuild is authorized
by this runbook. Existing temporary guards live under the supported writable
`/etc/systemd/system.control`, not the read-only `/etc/systemd/system` symlink.
Reconcile them deliberately only after the reviewed destination generation is
active and the old credential/helper behavior is absent. Do not remove guards
while the old installed generation can still enroll into the old tailnet.

## Rollback, reboot and remaining acceptance gates

Diagnostics must run locally on the client, with bounded commands, EXIT cleanup
and a separate restore watchdog. Record the actual backend/IP/routes while the
lab profile is selected. Restore the profile active at the start of that test;
do not overwrite a later deliberate user profile choice.

Before a server switch, arm an independent server rollback and verify its live
remaining duration. Host clocks differed during this migration; use the actual
timer, not cross-host wall-clock arithmetic. Do not cancel rollback until fresh
client SSH is proven. The final connectivity window's rollback was stopped only
after numeric/FQDN SSH and the Oppy LAN jump passed, while old-enrollment guards
were retained. **No reboot fallback was installed by those tests.**

A transient `systemd-run` timer does **not** survive reboot. Before the requested
reboot test:

1. Obtain workload-owner maintenance/checkpoint clearance. Active GPU jobs and
   sessions are a stop condition, not permission to terminate them.
2. Verify Mac-old-tailnet → Oppy → Spirit LAN recovery independently of Spirit's
   new-tailnet entry path. Ensure privileged recovery can be reacquired after the
   current root SSH shell dies during reboot.
3. Prepare and verify a **persistent reboot-surviving fallback** that restores the
   retained old profile if destination acceptance is not confirmed. Retain the
   old-enrollment guards until verified restoration or reviewed activation.
4. Record boot ID/system generation, reboot only Spirit, then prove changed boot
   ID, unchanged intended generation, correct destination identity/tag, restored
   DNS/relay/handshake, fresh strict-key client SSH and the Oppy LAN jump.
5. Check services and research applications before cancelling that fallback.

Outstanding:

- [ ] Workload-owner clearance and reboot/persistence test.
- [ ] Reviewed Spirit-only generation build/activation and guard reconciliation.
- [ ] Broad application checks and a second independent lab-group member's SSH.
- [ ] Coordinate `kata`, which still binds the old Spirit IP on TCP7777; do not
  silently restart/rebind/retire someone else's process.
- [ ] Finalize lab owner/roster/policy review and recovery responsibility.
- [ ] Establish independent Karkinos recovery and a coordinated Oppy/Karkinos
  window without unrelated OS upgrades.

**We are not ready to declare the fleet migration complete or move Oppy/Karkinos.**
