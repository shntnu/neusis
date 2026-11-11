# Oppy lab-tailnet migration — November 11, 2026

## November 11 fleet follow-up

Karkinos's manual recovery and the Overleaf connector migration are now accepted.
PR #51 includes the final three-server configuration and supersedes its earlier
Oppy-only scope. See [the fleet acceptance record](tailscale-lab-migration.md)
for verified SSH, public HTTPS, authenticated Git access, the Karkinos-only origin
firewall, and persistent runtime overrides pending reviewed Nix activation.
Moby and its Marimohub/Dex ingress remain deferred. The earlier Oppy cutover
record below is retained; its deferred Overleaf statements are superseded.

## Historical Oppy-only cutover

This change is scoped to Oppy. Spirit is covered by PR #50; Karkinos waits for
Runxi and Moby is explicitly deferred. Preserve existing lab profiles and do not
automatically switch any machine back to its old tailnet.

## Authorization and dependencies

The operator confirmed the supplied enrollment key is non-ephemeral and tagged
`tag:cslab-servers`; its temporary filename was misleading. It is encrypted for
the existing administrators and Oppy's verified SSH host key, without expanding
decryption access. Root-side decryption matched the supplied key without printing
its contents. Key reusability was not independently established; a consumed
single-use key cannot enroll a fresh machine. Preserve Tailscale's existing state.

The operator approved switching Oppy before migrating Karkinos after being told
that public Overleaf would be unavailable until Karkinos and the ingress settings
are migrated. Do not claim loopback health proves public availability. Do not
create a relay, broaden firewalls, or change Karkinos as part of this step.
Marimohub/Dex ingress through deferred Moby also remains a follow-up.

## Recovery and baseline

- Old Oppy profile: `85df`, node `nryaNa1uo721CNTRL`, IP `100.79.40.39`.
- Independent LAN address: `10.192.6.25`, reachable through Spirit `10.192.6.24`.
- The MBP already joined the lab tailnet and verified both Spirit and Oppy's LAN
  SSH path on November 10. Preserve its current lab profile.
- Fresh strict-host-key ProxyJump to Oppy's LAN succeeded on November 11 using
  the originating client's key. No private-key copying or agent forwarding.
- Existing root Ghostel verified `hostname=oppy`, UID 0.
- Baseline loopback HTTP 200: Overleaf `18080/login`, Marimohub `18081/api/health`,
  Dex `5556/dex/.well-known/openid-configuration`.

## Deployment status

Runtime cutover completed successfully at **2026-11-11 14:11:14 UTC**. Oppy is
online in `runxi-shen.github` / `tail27b080.ts.net`:

- Selected profile `3875` (`runxi-lab`); old profile `85df` retained, not selected.
- Node `nMSkAdN8Uu11CNTRL`, DNS `oppy.tail27b080.ts.net`.
- IPv4 `100.93.122.65`, IPv6 `fd7a:115c:a1e0::d332:7a42`.
- Tag `tag:cslab-servers`; health warnings empty.
- Fresh strict-host-key SSH through Spirit succeeded to both the new lab IPv4
  and DNS name. A separate SSH connection to Oppy's LAN address also passed.
- All three baseline loopback HTTP endpoints still return 200.
- No reboot, full NixOS activation, application restart, or automatic rollback.
  Only tailscaled restarted after enrollment; route/DNS/SSH preferences and the
  running closure/boot ID matched their captured pre-cutover values.
- The existing failed `user@991.service` is unchanged, not a new migration failure.

The MBP's earlier outbound access gate remains the recorded client evidence.
Oppy-initiated SSH to the MBP's new address timed out after cutover; this does not
establish a failure of MBP-to-Oppy access and no ACLs were changed to permit it.
For a fresh direct test from the MBP, retaining strict existing host-key checks:

```sh
ssh -o HostKeyAlias=oppy -o StrictHostKeyChecking=yes amunoz@100.93.122.65
```

Root-owned job/evidence: `/var/lib/neusis-tailscale-transition/20261111T140654Z/`.
Filtered receipts: `/run/neusis-oppy-transition-20261111T140654Z.{result,status,profiles,accepted}.json`.
The decrypted root staging key was removed on completion. The original user
file remains mode 0600; no plaintext key was committed or printed.

Destination Nix configuration evaluates successfully but has **not been activated**.
Persistent guards below remain required until that separate reviewed activation.

The installed `tailscaled-autoconnect`, `tailscale-force-claim`, and
`tailscale-disable-key-expiry` units are inactive and guarded by root-owned
`/etc/systemd/system.control/<unit>.service.d/90-neusis-tailnet-transition.conf`.
Their condition references the persistent `block-old-automation` marker in the
root evidence directory. Retain these guards until destination activation;
do not replay enrollment or restore old profile `85df` automatically.

The existing private Overleaf and Marimohub/Dex listeners still refer to Oppy's
old IP. Update their new destination IPs and narrowly scoped connector firewall
rules during the corresponding connector migration; do not silently widen them.

## Validation

Run `bash tests/tailscale-oppy.sh`. This evaluates only Oppy's enrollment settings,
disabled old OAuth helpers, and encryption recipients. It neither enrolls a node
nor decrypts a secret. Bash syntax and ShellCheck passed for the local root job
and acceptance script. Public ingress remains an explicitly deferred check for
the corresponding connector migration, not a passed check.
