#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

status=0

fail() {
  printf '[missing] %s\n' "$1"
  status=1
}

ok() {
  printf '[ok] %s\n' "$1"
}

warn() {
  printf '[warn] %s\n' "$1"
}

if command -v docker >/dev/null 2>&1; then
  ok "docker is installed"
else
  fail "docker is not installed"
fi

if docker compose version >/dev/null 2>&1; then
  ok "docker compose plugin is available"
else
  fail "docker compose plugin is not available"
fi

if [ -f "$ENV_FILE" ]; then
  ok ".env exists"
else
  fail ".env missing; copy .env.example to .env"
fi

if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  set -a && . "$ENV_FILE" && set +a
  [ -n "${EVILGINX_DOMAIN:-}" ] && ok "EVILGINX_DOMAIN is set" || fail "EVILGINX_DOMAIN is empty"
  [ -n "${EVILGINX_VM_IP:-}" ] && ok "EVILGINX_VM_IP is set" || fail "EVILGINX_VM_IP is empty"
fi

mkdir -p "$SCRIPT_DIR/runtime/phishlets" "$SCRIPT_DIR/runtime/logs" "$SCRIPT_DIR/runtime/config"
ok "runtime directories exist"

if [ -d "$SCRIPT_DIR/runtime/phishlets" ] && ! find "$SCRIPT_DIR/runtime/phishlets" -maxdepth 1 -type f | grep -q .; then
  warn "runtime/phishlets is empty; this repo intentionally does not provide phishlets"
fi

for port in 80 443 53; do
  if command -v ss >/dev/null 2>&1 && ss -ltnu | awk '{print $5}' | grep -Eq "[:.]${port}$"; then
    warn "port $port already appears to be in use"
  else
    ok "port $port appears available"
  fi
done

exit "$status"
