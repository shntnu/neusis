#!/usr/bin/env bash
set -euo pipefail

expected=${1:?expected hostname is required}
current=${2:?current hostname is required}

if [[ "$expected" == "$current" ]]; then
  exit 0
fi

if [[ "${NEUSIS_ALLOW_HOSTNAME_CHANGE:-}" == 1 ]]; then
  printf 'WARNING: allowing NixOS hostname change from %s to %s.\n' "$current" "$expected" >&2
  exit 0
fi

printf 'Refusing to switch to NixOS configuration for %s on %s.\n' "$expected" "$current" >&2
printf '%s\n' \
  'Select the correct flake output or use --target-host for remote deployment.' \
  'For an intentional rename/bootstrap, set NEUSIS_ALLOW_HOSTNAME_CHANGE=1 on the target.' \
  'The system profile may already have changed; inspect it before rebooting.' >&2
exit 1
