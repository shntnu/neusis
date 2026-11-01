# Pi persistence and compatibility review (2026-11-01)

Scope: the personal Pi configuration in this repository and
`afermg/nixos-config`, including GPT-6.1 Sol persistence. No model defaults,
other sessions, package pins, running jobs, or Overleaf deployment changed.
The review was conducted in the existing Astra session, without delegation.

## Confirmed findings and fixes

1. **Pinned-runtime compaction bug.** Neusis evaluates `amunoz@oppy` with Pi
   **0.80.10**; the personal Moby and both MacBook profiles select **0.85.1**.
   The running shell uses **0.87.1**. Earlier validation covered only the last.
   On 0.80.10 the previous hook persisted nonempty `stopReason: "length"`
   responses: old `compact()` did not reject truncated output. The hook now
   rejects every non-`stop` result and text mixed with tool calls before the
   SDK can commit it. Failure of the second split summary cancels the entire
   compaction, without fallback or retry.
2. **Older-SDK accounting.** Pi 0.80.10 does not return compaction usage and
   omits cache/session options. The hook explicitly disables summary caching,
   supplies request IDs when needed, and aggregates usage/cost as a fallback
   without double-counting newer SDK output or mutating provider objects.
3. **Test fixture bug.** The runtime test used `get`/`set`, not the actual
   credential-store `read`/`modify` contract. The corrected fixture works on
   all three SDKs without reading real credentials or making network calls.
4. **Validation gap.** The tests can now target either configuration directory
   via `PI_CONFIG_DIR`, so the Neusis copy is tested directly, not inferred
   from testing the personal checkout. The two compaction hooks remain identical.

## Reproduce the offline matrix

The regression suite is in the personal checkout at
`modules/shared/config/pi/tests/*.test.mjs`. From that repository:

```bash
PI_PACKAGE_DIR=/path/to/pi/lib/node_modules/pi-monorepo \
PI_CONFIG_DIR=/path/to/neusis/homes/amunoz/configs/pi \
  node --test modules/shared/config/pi/tests/*.test.mjs
```

Omit `PI_CONFIG_DIR` to test the personal copy. Select the SDK actually pinned
by each flake, not merely `command -v pi`.

Observed results: **15/15 tests pass for each of three SDKs and both copies**
(90 passing test cases). Before the fixes, the original suite failed 4/12
on Pi 0.80.10. No paid/live model request was made during this review.

Nix evaluation confirms the default is still `gpt-6.1-sol`, the enabled list
is still Sol 6.1 plus Astra, and the override is absent for `ank@oppy` and
`rshen@oppy`. Sol's configured Codex context stays 500k, Astra's 272k.

## Persistence boundaries / outstanding decisions

- **Neusis settings are deliberately store-backed and read-only.** Verified
  that the evaluated `settings.json` source is not writable. Pi writes settings
  directly, so commands that save defaults/scopes cannot persist through this
  link. Session-only selection is different from saving. A writable settings
  migration requires a policy for preserving user edits; none was introduced.
- **Personal config uses out-of-store checkout links.** Moby and the MacBooks
  need their respective `~/.local/share/src/nixos-config` checkouts updated.
  A push or Nix evaluation does not prove those machines have been updated or
  activated. Existing uncommitted checkout edits must not be overwritten.
- **Running/resumed sessions can retain models and scopes.** Project settings
  can override global defaults. The prior promise that every reloaded session
  automatically switches was too strong. No other sessions were modified.
- The pending Sol-switch timer for this session was cancelled for the requested
  Astra review. Persistent Sol 6.1 defaults were left unchanged.
- The 500k limit has documentation and earlier small-request/tool-call evidence,
  but no full-context stress test or live deployment validation in this review.
- The lineno changes remain on their separate PR/worktree. Their source and
  regression harness were inspected; no compiler rerun or service restart was
  performed. The README's browser/editor confirmation remains outstanding.

## Git state at review

After fetching, Neusis `main` is **0 behind / 4 ahead** of `shntnu/main`:
two lineno commits and two Pi commits. The Pi changes are also published as
cherry-picked commits on `origin/personal/pi-sol-default` (PR #49, open), so
an ahead count alone is not an unpublished-change count. Its head was
`94bd9d38`; local `main` was `38d4564`.

The personal checkout was **0 behind / 0 ahead** of `origin/main`, at
`0a53ca9`. This review's fixes are local uncommitted changes, not pushed.
No merge, deployment, branch rewrite, or new publication was performed.
Untracked `homes/blye/` was left untouched.
