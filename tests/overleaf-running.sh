#!/usr/bin/env bash
# Run on Oppy: confirm the Overleaf web service and login page are available.
set -euo pipefail
systemctl is-active --quiet overleaf-web.service
status=$(curl --silent --show-error --max-time 10 --output /dev/null \
  --write-out '%{http_code}' http://127.0.0.1:3000/login)
if [[ "$status" != 200 ]]; then
  printf 'Overleaf login returned HTTP %s\n' "$status" >&2
  exit 1
fi
printf 'Overleaf is running (service active; login HTTP 200).\n'
