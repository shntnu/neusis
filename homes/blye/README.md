# Bryan's Spirit quickstart

Your username is **`blye`** (Bryan Lye), with home `/home/blye` and project
workspace `/work/users/blye`. The account and supplied UNSW PC public key were
deployed on **Spirit only** on 2026-11-09 (UID 1009, system generation 18).
Home Manager activated successfully; the home, project workspace and
`/work/scratch/blye` were verified, along with key-only SSH policy. Bryan's own
end-to-end SSH login still needs testing. Never share your private key or use
someone else's account. Connect with `ssh blye@spirit`.

Spirit remains on Shantanu's tailnet; no reboot or tailnet migration occurred.
Fresh administrator SSH from Oppy and Alan's Mac passed, and the activation
rollback timer was cancelled after verification. Private deployment receipts
are on Oppy under `~/.local/state/neusis/blye-onboarding-20261109/`; root-only
backups/scripts are on Spirit under `/var/lib/neusis-onboarding/blye-20261109/`.
The repository changes still need committing/merging for future deployments.
The unused Oppy profile is not registered as an account or standalone Home
Manager configuration.

## Current network notice

The onboarding observations below date from November 9. The fleet migration has
since merged in [PR #51](https://github.com/shntnu/neusis/pull/51): Spirit is now
`spirit.tail27b080.ts.net` (`100.107.101.71`) in the lab tailnet. Arrange current
lab membership/access with the administrators, then use
`ssh blye@spirit.tail27b080.ts.net` with the verified existing SSH host key.
The old-network addresses and policy steps below are historical, not current
connection instructions. This account PR does not alter tailnet membership.

## Edit and apply your Home Manager configuration

Run these commands **on Spirit as `blye`, without sudo**, after onboarding and
merging this profile into the lab repository:

```bash
git clone https://github.com/shntnu/neusis.git ~/neusis
cd ~/neusis
git switch -c blye/home-tools
nano homes/blye/home.nix
```

Add package attribute names inside the existing `home.packages = with pkgs; [
... ];` list (for example, `tree`). Personal program settings also belong in
`homes/blye/home.nix`; `homes/blye/machines/spirit.nix` selects Spirit's imports.
Do not edit `homes/common/` for personal preferences or change `home.stateVersion`
just to upgrade packages.

```bash
# Git-backed flakes ignore new files until Git knows about them.
git add homes/blye
home-manager build --flake '.#blye@spirit'   # validate without activating
home-manager switch --flake '.#blye@spirit'  # apply only your profile
```

If `home-manager` is missing from PATH, enter `nix develop` in the repository
and retry. Restart your shell after shell-related changes. To undo a bad switch,
run `home-manager generations` and execute `<previous-generation-path>/activate`.

Commit your changes and submit a PR to **`shntnu/neusis:main`** (fork it if you
lack write access). Unmerged local changes can be overwritten by the next
system rebuild. To pick up merged updates in a clean checkout:

```bash
git switch main
git pull --ff-only
home-manager switch --flake '.#blye@spirit'
```

## Find available Nix packages

Browse <https://search.nixos.org/packages> (select **26.05**, this repository's
stable channel). Search results may be newer than the revision in `flake.lock`;
the pinned package set and a successful build are the final check.

From `~/neusis`, use the repository's exact pinned nixpkgs, not your global registry:

```bash
NIXPKGS=$(nix eval --impure --raw --expr \
  '(builtins.getFlake (toString ./.)).inputs.nixpkgs.outPath')
nix search "$NIXPKGS" '^ripgrep$'    # replace ripgrep with your search term
nix eval "$NIXPKGS#ripgrep.version" # inspect a package's version
nix shell "$NIXPKGS#ripgrep"        # try temporarily; exit to leave
```

Use the attribute name (`ripgrep`, not its command `rg`) in `home.packages`.
Adding packages does **not** require updating `flake.lock`; coordinate shared
nixpkgs upgrades with an administrator. Keep project Python dependencies in a
project environment rather than installing them globally.

## Historical onboarding network: November 9

Spirit was verified live on **`shntnu.github`** with MagicDNS name
**`spirit.tail5e510f.ts.net`** and IP **`100.126.147.16`** during this setup.
Recheck before deployment: separate, pre-existing Spirit migration edits are
present in this checkout but are not part of Bryan's account setup. Do not
activate those migration settings as a side effect of onboarding.

The live tailnet map showed **`BryanLye@github`** (Bryan Lye) with an online
Windows client during onboarding. That establishes enrollment visibility, not
an independent client-to-Spirit ACL or SSH test. For additional devices, Bryan
should connect his personal, untagged client to Shantanu's network under that
identity; approve the device if required. Administrators manage membership in
**Users** at <https://login.tailscale.com/admin>, using the ordinary **Member**
role rather than granting administration rights.

In **Access controls**, inspect the current policy before editing it. The
recorded old-network lab group is `group:ipdata`: add Bryan's exact accepted
Tailscale login identity to that group's existing member list if its current
rules grant the intended Spirit access. Do not use the Linux username `blye` as
a network identity, guess a GitHub login, replace the whole policy, or add an
allow-all rule. Group membership grants whatever access the existing rules
specify, which may include other lab servers. If Spirit-only network access is
desired, review a narrower rule instead.

Keep conventional OpenSSH and Bryan's own SSH key; no Tailscale SSH setting,
server tag, auth key, or server re-enrollment is needed for this onboarding.
Once the Unix account/key are deployed and network access is approved, test
from Bryan's connected device:

```bash
ssh blye@spirit.tail5e510f.ts.net
# Numeric fallback if MagicDNS is unavailable:
ssh blye@100.126.147.16
```

Verify Spirit's SSH host-key fingerprint with an administrator through an
independent trusted channel before accepting it. A working Tailscale connection
does not itself create the Unix account or authorize an SSH key. Migration to
Runxi's network will be a separate coordinated change.

## Administrator: finish onboarding

- Bryan's supplied UNSW PC public key is configured in
  `homes/blye/id_ed25519.pub` and referenced by `users/cslab_spirit.nix`.
  Confirm fingerprint `SHA256:2VUn1+RMAqaPh8xJoY+PygIIfbWVJKR7qcup2EV8SK8`
  with him before deployment. No private key is needed or generated.
- Confirm Spirit access, required tools, resource needs, and access duration.
  The regular-user role has no `wheel` membership but includes container/VM
  groups (including Docker, which is effectively root-capable); review that
  standard role before deployment.
- Arrange the appropriate Tailscale identity/ACL access separately;
  Home Manager cannot grant network access.
- Review, build and deploy the **Spirit** NixOS configuration through the normal
  maintenance procedure, excluding unrelated pending tailnet migration changes.
  Then verify `id blye`, his workspace, and SSH login. Home Manager alone cannot
  create the Unix account or install its login key.
