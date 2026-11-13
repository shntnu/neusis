# Bryan's Oppy and Spirit configuration

The `blye` regular-user account uses the same public SSH key, zsh shell and
personal Home Manager settings on Oppy and Spirit. The shared settings live in
`homes/blye/home.nix`; machine wrappers select the shared imports. Account
registration belongs in `users/cslab.nix` (Oppy) and `users/cslab_spirit.nix`
(Spirit), not in machine configuration files.

After deployment, connect from an authorized lab-tailnet device with your own
private key:

```bash
ssh blye@oppy
ssh blye@spirit
```

Confirm the server's SSH host-key fingerprint with an administrator before
accepting it. The Unix account and public key do not grant Tailscale membership
or change network policy; client-to-server access must also be authorized.
Never share your private key. Deployment and login-test records belong in the
[maintenance log](https://github.com/broadinstitute/imaging-server-maintenance/blob/main/MAINTENANCE_LOG.md).

The account has no wheel/sudo membership. Standard regular-user virtualization
and container groups can provide elevated capabilities; administrators should
review those groups rather than treating this as a sandboxed account.

## Personal tools

On the target server, edit `homes/blye/home.nix` in a checkout containing these
changes. Then build before activating your own profile, without sudo:

```bash
# On Oppy:
home-manager build --flake '.#blye@oppy'
home-manager switch --flake '.#blye@oppy'

# On Spirit instead:
home-manager build --flake '.#blye@spirit'
home-manager switch --flake '.#blye@spirit'
```

Use `nix develop` if `home-manager` is not available. Do not change shared
`homes/common/` settings for personal preferences or bump `home.stateVersion`
to update tools. Submit changes against `shntnu/neusis:main`.
