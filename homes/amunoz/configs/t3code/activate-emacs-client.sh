#!/usr/bin/env bash
set -euo pipefail

if [[ ${1:-} != --restart || $# != 1 ]]; then
  printf 'Usage: bash %s --restart\nThis restarts T3 and interrupts running agent turns and terminals.\n' "$0" >&2
  exit 2
fi

package="$HOME/.local/state/neusis/t3code-emacs-package"
binary="$package/bin/t3"
if [[ ! -x "$binary" || ! -f "$package/libexec/t3code/client/index.html" ]]; then
  printf 'Build the staged Emacs client package first: %s\n' "$package" >&2
  exit 1
fi

umask 077
directory="$HOME/.config/systemd/user/t3code.service.d"
override="$directory/50-emacs-client.conf"
mkdir -p "$directory"
temporary=$(mktemp "$directory/.emacs-client.XXXXXX")
trap 'rm -f "$temporary"' EXIT
printf '[Service]\nExecStart=\nExecStart="%s" serve --host 127.0.0.1 --port 3773 --no-browser\n' "$binary" > "$temporary"
if [[ -e "$override" ]] && ! cmp -s "$temporary" "$override"; then
  printf 'Refusing to replace an existing, different override: %s\n' "$override" >&2
  exit 1
fi
mv "$temporary" "$override"
systemctl --user daemon-reload
systemctl --user restart t3code.service
systemctl --user --no-pager status t3code.service
