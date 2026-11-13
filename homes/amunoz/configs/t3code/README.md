# Personal T3 Code on Oppy

Opted in only by `homes/amunoz/machines/oppy.nix`. No common user configuration,
firewall, Tailscale enrollment, or system service is changed.

## Installation

`package.nix` packages the official **v0.1.8** standalone Linux release, with
hashes checked against that release's `SHA256SUMS`. The repository's existing
pinned Nixpkgs supplies the NixOS ELF/runtime adaptations. No shared input or
lock-file update is required. Linux x86-64 was built and tested on Oppy; ARM64
has a pinned upstream artifact but has not been tested.

Upstream install/service/remote-access documentation:

- <https://github.com/pingdotgg/t3code/blob/v0.1.8/docs/user/install.md>
- <https://github.com/pingdotgg/t3code/blob/v0.1.8/docs/user/background-service.md>
- <https://github.com/pingdotgg/t3code/blob/v0.1.8/docs/user/remote-access.md>

The personal Home Manager module installs `t3`, a `~/.local/bin/t3` link, a
non-secret `~/.t3/service.env`, and `t3code.service`. It uses the existing
`amunoz` login/provider configuration, a private umask, and data under `~/.t3`.
The service explicitly binds **127.0.0.1:3773**. LAN access and T3 Connect are
disabled. Oppy's existing linger setting lets the user service run after logout
and start at boot. Boot persistence is configured, not reboot-tested.

## Browser runtime on NixOS

The Home Manager package wrapper supplies `LD_LIBRARY_PATH` and
`NIX_LD_LIBRARY_PATH` for T3's downloaded Chrome headless shell, using this
flake's pinned GLib, NSS/NSPR, accessibility, X11, GBM, audio and font libraries.
Both the managed CLI and user service use that wrapper. The library paths are
scoped to T3 and its children, not exported into every shell. Chrome sandboxing
remains enabled. No `apt-get`, global library symlinks or system rebuild is needed.

Use the managed `t3` launcher, not `libexec/t3code/t3` directly. Upstream
`t3 browser setup` automatically installs libraries only on apt-based hosts;
it is not the dependency installer for this NixOS configuration.

The live-session repair can patch the existing cached headless-shell ELF RPATH
with `package.browserLibraryPath` after backing it up, without restarting T3.
That cached-file repair is only a bridge for a server already running the old
wrapper. New browser downloads are supported by the managed wrapper after the
next T3 restart. Keep a GC root for the deployed package. Do not disable the
sandbox to work around library failures.

The November 11 browser rollout built only the Home Manager-selected T3 package,
unit and service environment, rooted at
`~/.local/state/neusis/t3code-browser-runtime`. It restored the missing launcher,
service environment and enabled user unit without restarting the running server.
Their direct links to the rooted bundle are intentionally outside a
`*-home-manager-files` tree: Oppy's older system-integrated Home Manager boot
generation must not delete them as orphaned files before that system generation
is updated. A later activation of the current source can adopt the same files.

A separate `t3code-cli` Nix profile entry at priority 4 exposes `t3` in login
shells and survives the older boot-time `home-manager-path` replacement, matching
the targeted Codex deployment strategy. It uses the exact package selected by
this Home Manager module, not a separate version. Once the boot-time Home Manager
generation includes this module and browser wrapper, remove that temporary
profile entry with `nix profile remove t3code-cli`; otherwise it would shadow a
future Home Manager package update. Do not run a full system switch merely to
apply this browser repair while unrelated configuration edits are pending.

The original cached Chrome executable and pre-patch RPATH are retained under
`~/.local/state/neusis/t3code-browser-backup-20261111/`. Both the live HTML preview
and the original, unpatched executable were tested with sandboxing enabled;
the latter was launched beside its ICU/resources using the wrapper's library
path. `t3 browser setup --base-dir ~/.t3` reports the host ready. Reboot behavior
has not been tested, and the old server process is deliberately still running.

The initial targeted rollout built the package and Home Manager-generated unit
without running a full Home Manager or system switch. Its outputs are GC-rooted
at `~/.local/state/neusis/t3code-package`,
`~/.local/state/neusis/t3code/unit`, and
`~/.local/state/neusis/t3code/service-env`. The normal Home Manager configuration
contains the same artifacts for later reviewed rebuilds. The subsequent agent
CLI rollout activated that Home Manager configuration and adopted the four T3
artifacts into its generated file tree, without restarting the T3 process.

## Connect from the Mac

Open a terminal **on the Mac**:

```bash
ssh -L 127.0.0.1:3773:127.0.0.1:3773 amunoz@oppy
```

Leave that SSH session open. In its Oppy shell, run:

```bash
t3 pair
```

Open the printed **local HTTP pairing URL** in the Mac's browser. It reaches
Oppy through the tunnel; no Mac application installation is required. Pairing
links are one-time credentials and normally expire after five minutes. Do not
paste them into chat, Git, logs, or screenshots. A plain HTTP tunnel should use
the direct local web app, not the HTTPS-hosted `app.t3.codes` client.

The web UI is at <http://127.0.0.1:3773/> while the tunnel is open. If that local
port is occupied, choose a different local forward port and adjust the local
pairing URL to match, or close the conflicting application deliberately.

Default pairing grants full control of this user's T3 environment, including
terminals and files. Only pair trusted clients. For limited clients, use
`t3 pair --help` to choose explicit scopes.

## Local Emacs / Magit integration

The custom T3 source checkout is `/work/users/amunoz/projects/t3code`, based on
upstream `v0.1.8`. Its **Emacs (Magit)** editor action opens a URL on the viewing
computer, never an editor process on Oppy. It passes the active thread's actual
checkout, including worktrees. It also works through a localhost SSH tunnel.

The macOS handler is installed at `~/Applications/T3 Emacs.app` on
`alan@alan-purdue-mbp`. Its local environment mapping selects `amunoz@oppy`.
It asks for confirmation before opening Magit through the Mac's own Emacs and
TRAMP. For other Macs, run `scripts/emacs-magit/install-macos.py` from the T3
checkout and configure their own SSH route. The current installer is macOS-only.

`package.nix` accepts an optional `clientAssets` directory for a built web
client. The normal Home Manager package still defaults to upstream assets;
this opt-in does not change its backend binary or protocol. The custom source
also patches the desktop URL allowlist, but that requires a separate desktop
build; it is not needed when using the Mac's browser.

Build the client from the T3 checkout with
`APP_VERSION=0.1.8 VITE_RELEASE_CHANNEL=stable node_modules/.bin/vp build` in
`apps/web`. Then, from the Neusis root, stage its Nix package:

```sh
nix build --impure --expr '
  let
    flake = builtins.getFlake ("path:" + toString ./.);
    pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  in pkgs.callPackage ./homes/amunoz/configs/t3code/package.nix {
    clientAssets = /work/users/amunoz/projects/t3code/apps/web/dist;
  }
' --out-link "$HOME/.local/state/neusis/t3code-emacs-package"
```

The build does not change the running service. When no agent turns or terminals
need to survive, activate it explicitly:

```sh
bash homes/amunoz/configs/t3code/activate-emacs-client.sh --restart
```

This adds a user-service drop-in referencing the GC-rooted package, reloads the
unit and restarts T3. Refresh the Mac's browser afterward. Select
**Emacs (Magit)** in **Open in…**, then use the main button or the normal
open-favorite-editor shortcut. The drop-in remains across Home Manager switches;
remove it deliberately before upgrading the base server or returning to stock:

```sh
rm "$HOME/.config/systemd/user/t3code.service.d/50-emacs-client.conf"
systemctl --user daemon-reload
systemctl --user restart t3code.service
```

## Providers

**Deployment dependency:** merge the personal CLI update in
[PR #53](https://github.com/shntnu/neusis/pull/53) before activating this service.
Without it, current main selects Codex 0.146.0, below T3's recommended range.
This service's explicit package PATH takes precedence over temporary profile
repairs, so those repairs are not a substitute for the updated source.

At initial setup, Oppy's Claude Code CLI was authenticated. A later Home
Manager rollout updated Claude to 2.1.321 and Codex to 0.167.0; Claude's OAuth
session was subsequently marked ended during authentication verification, so
it now needs `claude auth login`. Codex was already logged out and still needs
`codex login --device-auth` **on Oppy**. Follow each flow's browser instructions;
credentials stay out of Nix/Git. See `../agent-clis/README.md` for the rollout.

T3's live Codex provider cache confirms **enabled**, **installed**, version
**0.167.0**, and **supported** compatibility (recommended range >=0.159.0).
After the operator completed Codex login, the cached pre-login status remained
stale. A targeted authenticated `server.refreshProviders` RPC refreshed only
Codex, without a service restart; T3 now reports **ready**, **authenticated**,
and two discovered models. The temporary least-privilege diagnostic session was
revoked immediately. Refresh the browser if it still shows the old status.
No paid agent task was started as an installation test.

Provider CLIs are found through this user's `~/.local/bin`, `~/.nix-profile/bin`,
per-user system profile, and the system PATH. For a provider not discovered by
T3, set its existing binary path in Settings rather than installing another
unmanaged CLI.

## Manage and update

```bash
systemctl --user status t3code.service
systemctl --user restart t3code.service
systemctl --user stop t3code.service
systemctl --user disable --now t3code.service
t3 status --json
```

Inspect logs locally with `journalctl --user -u t3code.service`; review/redact
credentials or pairing information before sharing any log output.

This service and CLI are **Nix-managed**. Do not run the upstream installer,
`t3 install`, `t3 update`, `t3 service install`, or `t3 up --lan` over them.
Update the release/version/checksums in `package.nix`, build and validate it,
then perform a reviewed Home Manager or targeted rollout and restart only this
service. Agent turns and terminals may be interrupted by a restart.

The managed `service.env` contains only loopback/access settings, never
credentials. Keep provider credentials in the provider's normal private store
or T3's private provider settings. A downloaded browser or provider-managed
runtime may require additional NixOS packaging; do not run apt-based
`t3 browser setup` or disable the browser sandbox as a workaround.

To remove the feature, disable/stop the user service, remove the T3 import from
`homes/amunoz/machines/oppy.nix`, and apply the reviewed home configuration.
Retain `~/.t3` unless you deliberately want to delete project/thread/settings
data. The temporary rollout roots/links can be removed after normal Home
Manager adoption or deliberate removal.

## Verification

- Official archive checksum matched; Nix build and CLI `--version` passed.
- Generated systemd unit passed `systemd-analyze --user verify`.
- User service is enabled/running with zero restarts; socket is loopback-only.
- LAN and T3 Connect disabled in `t3 status --json`.
- Local web UI returned HTTP 200.
- A temporary SSH tunnel from Alan's Mac returned HTTP 200 and was then closed.
- No full Home Manager/system activation, firewall change, or reboot performed.
- Browser pairing and the first provider task remain user acceptance steps.
