# Lab server migration — November 11, 2026

## Accepted membership

Spirit, Oppy and Karkinos are online in the lab tailnet (`cs-lab-ts` in the
profile listing, `runxi-shen.github` in status, ID `ToFdp7kzyV11CNTRL`). All three
have `tag:cslab-servers` and MagicDNS suffix `tail27b080.ts.net`. Moby is deferred.

| Server | Lab IPv4 | Selected profile | Retained old profile |
| --- | --- | --- | --- |
| Spirit | 100.107.101.71 | 884d | 57fb |
| Oppy | 100.93.122.65 | 3875 | 85df |
| Karkinos | 100.117.220.62 | b788 | 823e |

Do not switch to the retained old profiles automatically. Spirit was returned to
its lab profile after the explicitly authorized temporary Karkinos jump; its
return timer is inactive. Its accepted pilot was not repeated.

## Karkinos recovery and credential handling

The staged key enrollment failed at 15:00:14 UTC with `requested tags
[tag:cslab-servers] are invalid or not permitted`. The operator recovered at the
local console by logging into Runxi's account, then setting the name to
`karkinos` and assigning the server tag. The accepted node is
`nTUtgm6nnv11CNTRL`; OS hostname remains `GPFDA-11A`.

Do not reuse the rejected key or mistake the failed automated receipt for the
later successful manual recovery. Both root plaintext staging copies were
verified absent. The original operator key and untracked ciphertext are not
published by this PR.

Karkinos uses `neusis.tailscale.autoEnroll = false`: no agenix enrollment key is
selected and `tailscaled-autoconnect` is disabled. Its existing persistent
Tailscale state remains authoritative. This does not provision a fresh machine;
a new installation needs manual login or a separately validated, authorized
tagged key before enabling automatic enrollment. Spirit and Oppy retain their
host-specific agenix enrollment configuration. Old OAuth helpers are disabled
on all three hosts in source.

## Overleaf acceptance

- Strict existing-host-key SSH passed Oppy → Karkinos by lab IP and DNS, and
  Karkinos → Oppy by lab IP. A fresh strict-host-key connection through Spirit's
  LAN SSH jump also passed using the initiating client's existing host key.
- Karkinos → `http://100.93.122.65:18080/login`: HTTP 200.
- Karkinos's connector socket `http://127.0.0.1:18080/login`: HTTP 200.
- Public `https://overleaf.quasimorphic.com/login`: HTTP 200 from both hosts.
- Authenticated, read-only Git `ls-remote` through the public Overleaf bridge
  returned manuscript `master` at `2001daf35f8758422c905da60a1ce9fad49b08d0`.
  No manuscript was fetched, edited, compiled or pushed.
- Spirit → Oppy's private TCP 18080 timed out as intended: only Karkinos is
  allowed. The dedicated nftables table retains the non-loopback port 3100 fence.
- Oppy's nginx, Overleaf web and CLSI PIDs did not change; Karkinos's Cloudflared
  PID did not change. Only ingress proxy/socket units were restarted for routing.

After manual login, Karkinos initially appeared without a relay endpoint to other
servers. Its outbound relay ping enabled Oppy access, but new access through
Spirit still failed. A saved-state-preserving restart of Karkinos's tailscaled
restored the advertised Chicago relay (`ord`). The refresh unit
`neusis-karkinos-refresh-20261111.service` returned success; fresh SSH through
Spirit and public HTTPS passed afterward. No profile switch was performed.

Fresh MBP-originated SSH was not independently repeated; the operator's console
session and the previously recorded MBP access gate are separate evidence.

## Runtime bridge to a reviewed Nix activation

No full NixOS activation or reboot occurred. Karkinos retains its running 25.11
closure; do not upgrade it incidentally using this repository's newer pin.
Persistent runtime overrides keep ingress on the accepted addresses until a
separate, reviewed deployment:

- Oppy: `/etc/systemd/system.control/overleaf-private-origin.socket.d/90-neusis-overleaf-transition.conf`
  binds `100.93.122.65:18080`.
- Oppy: `/etc/systemd/system.control/nftables.service.d/90-neusis-overleaf-transition.conf`
  uses the root-owned rules under
  `/var/lib/neusis-overleaf-transition/20261111T1530Z/nftables-rules` for start
  and reload. Only Karkinos `100.117.220.62` may access the origin over tailscale0.
- Karkinos: `/etc/systemd/system.control/overleaf-oppy-origin.service.d/90-neusis-overleaf-transition.conf`
  targets `100.93.122.65:18080`; Cloudflared still targets its loopback socket.
- Each host retains its three `90-neusis-tailnet-transition.conf` guards on the
  installed old enrollment/OAuth services. Do not remove these before the
  destination configuration is active and verified.

Root-owned before/after evidence is under
`/var/lib/neusis-overleaf-transition/20261111T1530Z/` on both ingress hosts.
Filtered `/run/neusis-{oppy,karkinos}-overleaf-20261111.{exit,log}` receipts report
exit 0. Karkinos's original failed enrollment evidence remains under
`/var/lib/neusis-tailscale-transition/karkinos-20261111/`.

After reviewed destination activation, confirm the generated origin addresses,
firewall, disabled old helpers and Karkinos manual-enrollment mode. Only then
remove the corresponding temporary overrides, daemon-reload, restart the two
ingress proxies/sockets, and recheck HTTP, SSH and the source restriction. Never
remove the overrides first while the installed configuration still points at the
old tailnet. Retire their root-owned rules only after nftables no longer references
them. Keep credential-bearing recovery snapshots private.

## Repository validation and remaining scope

Run `bash tests/tailscale-lab.sh` and `bash tests/tailscale-oppy.sh`. These evaluate
configuration without enrolling nodes or decrypting credentials. The new
`autoEnroll` option defaults to true, preserving other hosts' behavior.

PR #51 incorporates the final three-server configuration and Overleaf addresses.
It overlaps Spirit's older preparation PR #50; reconcile that PR before merging
it rather than replaying its obsolete preparation status. No Moby changes,
subnet-router advertisements, access-policy changes, or unrelated local files
are included. Marimohub/Dex's Moby-dependent ingress remains deferred.
