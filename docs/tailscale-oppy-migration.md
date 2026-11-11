# Oppy lab-tailnet migration — November 11, 2026

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

Destination Nix configuration and encrypted key are prepared and evaluated.
Runtime cutover is pending. No full NixOS activation or reboot is part of this
step; the running OS and application workloads must remain unchanged.

Before enrollment, guard the installed old enrollment, hostname-claim, and
key-expiry units using root-owned persistent systemd drop-ins. Launch a bounded,
root-owned local job, read the key from a root-only file, and retain old profile
`85df` without selecting it again. Verify destination suffix `tail27b080.ts.net`,
hostname `oppy`, tag, unchanged route/DNS/SSH preferences, and independent SSH.
Leave old-enrollment guards in place until reviewed destination activation.

The existing private Overleaf and Marimohub/Dex listeners still refer to Oppy's
old IP. Update their new destination IPs and narrowly scoped connector firewall
rules during the corresponding connector migration; do not silently widen them.

## Validation

Run `bash tests/tailscale-oppy.sh`. This evaluates only Oppy's enrollment settings,
disabled old OAuth helpers, and encryption recipients. It neither enrolls a node
nor decrypts a secret. Runtime evidence will be appended after the cutover.
