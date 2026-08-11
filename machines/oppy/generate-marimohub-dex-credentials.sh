#!/usr/bin/env bash
set -eu

usage() {
  cat >&2 <<'USAGE'
Usage:
  machines/oppy/generate-marimohub-dex-credentials.sh <email> [<email> ...]

Recommended invocation with dependencies:
  nix shell nixpkgs#apacheHttpd nixpkgs#openssl -c \
    machines/oppy/generate-marimohub-dex-credentials.sh alice@example.com bob@example.com

The script prints:
  - collaboratorEmails entries for machines/oppy/marimohub.nix
  - bcrypt hash lines for secrets/oppy/marimohub.env.age
  - one-time plaintext passwords to give directly to collaborators

Plaintext passwords are only printed to this terminal. Do not redirect the
handout section into the repo.
USAGE
}

if [ "$#" -lt 1 ]; then
  usage
  exit 2
fi

for cmd in htpasswd openssl sed tr; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing required command: $cmd" >&2
    usage
    exit 127
  fi
done

username_for_email() {
  email="$1"
  printf '%s' "$email"
}

env_for_email() {
  email="$1"
  stem=$(printf '%s' "$email" | tr '[:lower:]' '[:upper:]' | tr '@.+-' '____' | tr -c 'A-Z0-9_' '_')
  printf 'DEX_%s_PASSWORD_HASH' "$stem"
}

password_for_email() {
  # The email is an account label, not entropy. The password itself is random.
  openssl rand -base64 24 | tr '+/' '-_' | tr -d '='
}

echo "# Add these emails to collaboratorEmails in machines/oppy/marimohub.nix:"
for email in "$@"; do
  echo "    \"$email\""
done

echo
echo "# Add these hash lines to secrets/oppy/marimohub.env.age:"

: > /tmp/marimohub-dex-handout.$$
chmod 0600 /tmp/marimohub-dex-handout.$$
trap 'rm -f /tmp/marimohub-dex-handout.$$' EXIT

for email in "$@"; do
  username=$(username_for_email "$email")
  env_name=$(env_for_email "$email")
  password=$(password_for_email "$email")
  hash=$(printf '%s\n' "$password" | htpasswd -niBC 12 "$username" | sed 's/^[^:]*://')
  printf "%s='%s'\n" "$env_name" "$hash"
  {
    printf 'email: %s\n' "$email"
    printf 'username: %s\n' "$username"
    printf 'initial password: %s\n\n' "$password"
  } >> /tmp/marimohub-dex-handout.$$
done

echo
echo "# One-time handout. Give each collaborator their own block directly:"
cat /tmp/marimohub-dex-handout.$$
