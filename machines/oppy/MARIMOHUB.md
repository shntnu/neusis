# marimohub.quasimorphic.com on Oppy

This machine hosts a collaborator marimohub at:

- <https://marimohub.quasimorphic.com>
- Dex issuer: <https://marimohub.quasimorphic.com/dex>
- OIDC callback: <https://marimohub.quasimorphic.com/api/auth/callback>

The public URL is intentionally reachable, but marimohub only admits the local
Dex username/password accounts declared in `machines/oppy/marimohub.nix`.

## Fill deployment secrets

One age env file backs the Oppy services:

```bash
cd secrets
agenix -e oppy/marimohub.env.age
cd ..
```

`secrets/oppy/marimohub.env.age` contains generated values for
`MARIMOHUB_AUTH_OIDC_CLIENT_SECRET`, `MARIMOHUB_AUTH_SESSION_SECRET`, and
`MARIMOHUB_SECRETS_KEK`. Replace the password-hash placeholders:

```dotenv
MARIMOHUB_AUTH_OIDC_CLIENT_SECRET=<already-generated-or-rotate-with-random-bytes>
MARIMOHUB_AUTH_SESSION_SECRET=<already-generated-or-rotate-with-32-random-bytes>
MARIMOHUB_SUPER_ADMINS=alan@quasimorphic.com
MARIMOHUB_SECRETS_KEK=<already-generated-or-rotate-with-32-random-bytes>

DEX_ALAN_QUASIMORPHIC_COM_PASSWORD_HASH='$2y$12$...'
```

Generate random initial passwords and matching bcrypt hashes from collaborator
emails:

```bash
nix shell nixpkgs#apacheHttpd nixpkgs#openssl -c \
  machines/oppy/generate-marimohub-dex-credentials.sh \
  alan@quasimorphic.com collaborator@example.com
```

The script prints three things: email entries for `collaboratorEmails` in
`machines/oppy/marimohub.nix`, hash lines for the age secret, and one-time
plaintext passwords to give directly to each collaborator. The email determines
the username and env var name; the password itself is random.

To add collaborators, add their emails to `collaboratorEmails` in
`machines/oppy/marimohub.nix`, then add the generated `DEX_*_PASSWORD_HASH`
lines to this age secret. Do not commit plaintext passwords.

The systemd units refuse to start while placeholder values remain.

## Local testing

Oppy's monitoring stack uses remote port `3000` for Grafana, so marimohub runs
on remote port `18081`. If local `18081` is also occupied, choose any free local
port and forward it to remote `18081`:

```bash
ssh -N -o ExitOnForwardFailure=yes \
  -L 18082:127.0.0.1:18081 \
  -L 5556:127.0.0.1:5556 \
  amunoz@oppy
```

Then health-check marimohub at the local port you chose:

```bash
curl --fail http://localhost:18082/api/health
curl --fail http://localhost:5556/dex/.well-known/openid-configuration
```

Full browser login still expects the configured public issuer/callback URLs
under `https://marimohub.quasimorphic.com`; these forwards are primarily for
service health checks unless you also test with that hostname routed locally.

## Cloudflare Tunnel

The connector runs separately on Moby and forwards its loopback origins to the
private Oppy origin sockets. Its declarative ingress rules route `/dex/*` to Dex
and all other requests to marimohub. Cloudflare is transport only; do not create
a Cloudflare Access application unless a second authentication layer is
intentional, because marimohub handles identity through Dex OIDC.

## Password model

Dex static-password mode supports multiple distinct marimohub users, but not
self-service first-login password creation. Each collaborator gets a random
initial password out-of-band; only its bcrypt hash is stored.

Plaintext passwords should be visible only at generation/handout time. The repo
contains age-encrypted hashes, and the decrypted env file is root-only on the
host. Root/sudo users can always read host secrets; ordinary shell users should
not be able to read the age file, service env, or Dex runtime config. If a hash
leaks, it can be brute-forced offline, so keep passwords long and random.

If self-service account creation or password resets become important, switch the
issuer to Keycloak or another full IdP and keep marimohub on OIDC.

## fgx project setup after deployment

1. Sign in as `MARIMOHUB_SUPER_ADMINS`.
2. Create a project named `fgx`.
3. Add the GeneGenie token as a project **Environment variables** integration:
   - secret variable name: `GENEGENIE_TOKEN`
   - value: the GeneGenie API token
4. Add collaborators to the project as viewer/editor/manager.
5. Restart active notebook sessions so newly configured environment variables
   are injected.
6. Import the FGX notebooks only after establishing a repository-aware workflow
   that preserves sibling imports and submits changes through GitHub branches
   and pull requests. Marimohub synced notebooks are read-only and are not a
   replacement for that editable workflow.

Viewer mode is `ephemeral-sandbox`, so trusted viewers may start private live
kernels whose edits are discarded. Editors use shared live editor kernels; switch
`MARIMOHUB_EDITOR_SANDBOX_SHARING` to `exclusive` in `machines/oppy/marimohub.nix`
if this becomes noisy.

## Deploy/check

```bash
nixos-rebuild switch --flake .#oppy
systemctl status dex.service marimohub.service
curl --fail http://127.0.0.1:18081/api/health
curl --fail http://127.0.0.1:5556/dex/.well-known/openid-configuration
```
