# Personal agent CLI versions on Oppy

Opted in through `homes/amunoz/machines/oppy.nix`. The user-only Home Manager
overlay selects both tools from the existing personal package list:

- **Codex 0.167.1**: official OpenAI Linux package bundle, pinned by SHA-256
  from the GitHub release asset digest. The complete layout includes the
  code-mode/exec companions and runtime resources. Preserve upstream static
  `bwrap` and `rg` binaries byte-for-byte: Codex validates helper digests.
- **Claude Code 2.1.321**: Neusis's updated `claude-code-nix` flake input,
  still following the existing stable Nixpkgs input. The package disables
  its own updater and uses the official Anthropic native release.

Sources:

- <https://github.com/openai/codex/releases/tag/rust-v0.167.1>
- <https://github.com/sadjow/claude-code-nix/tree/7408fb1fbd27a75e8acd655b826ec7d66c54bf68>

Shared Nixpkgs and `llm-agents` pins are unchanged. The latest `llm-agents`
collection requires package-set attributes absent from the existing pin, so
this module uses Codex's official package bundle without upgrading the fleet.
The existing global Claude overlay also consumes the updated Claude input;
other machines/users pick up that pin only through their later rebuilds.

## Apply updates

After reviewing the home configuration and any service changes:

```bash
home-manager build --flake '.#amunoz@oppy'
home-manager switch --flake '.#amunoz@oppy'
codex --version
claude --version
codex sandbox -- /run/current-system/sw/bin/true
```

Update Codex's version and release hashes in `codex.nix`. Update Claude with
`nix flake update claude-code-nix`, reviewing only the intended lock changes.
Do not use npm, `codex update`, or `claude update` over these Nix-managed CLIs.

The initial rollout used the generated Home Manager activation with a one-time
`systemd.user.startServices = "suggest"` override, avoiding T3/Atuin restarts.
Ordinary repository service-management policy was not changed. The older
standalone `claude-code-nix` user-profile entry was removed after successful
activation because it shadowed Home Manager's package with Claude 2.1.119.
The separate Pi and Claude ACP profile entries were retained.

Current and previous deployment outputs, plans, package/profile snapshots,
and integrity receipts are retained privately under
`~/.local/state/neusis/agent-cli-update/` on Oppy. Old outputs are GC-rooted.
Do not blindly activate historical full Home Manager generations: reconcile
previous targeted Atuin repairs and running services before rollback.

## Reboot-safe targeted Codex deployment

Oppy's November 11 reboot ran the older system-integrated Home Manager
activation and restored its `home-manager-path` (Codex 0.146.0). A standalone
Home Manager switch alone does not update that boot-time generation.

Until the system configuration is rebuilt from this source, keep a separate
Nix profile entry for Codex at priority 4 (Home Manager's path uses 5):

```bash
nix build --impure --expr \
  '(builtins.getFlake "/work/users/amunoz/projects/neusis").homeConfigurations."amunoz@oppy".pkgs.codex' \
  --out-link "$HOME/.local/state/neusis/agent-cli-update/codex-current"
nix profile install --priority 4 \
  "$HOME/.local/state/neusis/agent-cli-update/codex-current"
```

Install only if the separate `codex` entry is absent. For later updates,
build first, then replace that entry with the new output. Do not accumulate
same-priority Codex entries. The profile and build link protect the package
from garbage collection. The existing boot activation replaces only
`home-manager-path`, leaving this higher-priority Codex entry intact. T3's
currently deployed service resolves Codex through that persistent profile;
the source service also pins its provider PATH to the selected Nix packages.

After a reviewed NixOS rebuild updates the boot-time Home Manager generation,
remove the temporary separate entry with `nix profile remove codex` and verify
both a fresh shell and T3 still resolve the supported version. Do not remove
it while the boot generation still supplies 0.146.0. Recovery receipts and an
isolated profile-replacement test live under
`~/.local/state/neusis/agent-cli-update/recovery-20261111/`.

## Authentication

The CLI update preserves provider configuration and account settings. Codex was
already logged out before rollout. During post-update Claude authentication
verification, the Claude CLI marked its previous OAuth session ended and
cleared its saved tokens; a fresh login is required. Do not restore stale tokens
or put credentials in Nix/Git. On Oppy, in an interactive SSH session:

```bash
claude auth login
codex login --device-auth
```

Open the printed sign-in link in the Mac's browser and complete each flow.
Choose the intended subscription/account, not API billing unless desired.
For an organization-enforced Claude SSO flow, use `claude auth login --sso`.
Then verify `claude auth status` and `codex login status`. T3 uses these same
Oppy provider configurations; no Mac CLI installation is needed. The operator
subsequently completed Codex login. A targeted T3 provider refresh confirmed
Codex ready/authenticated with two discovered models, without restarting T3.

## Verified during rollout

- Both Home Manager and NixOS-integrated Oppy evaluations select the versions
  above; Nix builds and fresh Fish-session version checks passed.
- The final Codex sandbox executed `true` successfully without bypass flags.
- Existing Codex config/models, Claude settings and Atuin key remained unchanged.
- T3, Atuin and agenix retained their PIDs/invocation IDs throughout activation.
- T3 remained loopback-only and its web UI returned HTTP 200.
- The existing T3 links/settings were adopted into Home Manager without content
  changes or restarting the service.
- No system activation, reboot, tailnet change or paid model task occurred.
- Optional Codex voice/daemon functionality and a signed-in provider task were
  not exercised. CLI authentication must be completed separately as above.
