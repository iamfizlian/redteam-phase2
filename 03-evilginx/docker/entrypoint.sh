#!/usr/bin/env bash
set -euo pipefail

mkdir -p /data/phishlets /data/logs /data/config

cat <<'EOF'
Evilginx lab container

Authorized validation only. This image does not include phishlets,
credential collection pages, token replay automation, or tenant secrets.

Runtime paths:
  /data/phishlets  mounted phishlets, read-only from host
  /data/logs       operator logs
  /data/config     lab notes/config artifacts

Attach with:
  docker attach evilginx-lab

Detach without stopping:
  Ctrl-p Ctrl-q
EOF

if [ -n "${EVILGINX_DOMAIN:-}" ]; then
  printf '\nConfigured EVILGINX_DOMAIN=%s\n' "$EVILGINX_DOMAIN"
fi

if [ -n "${EVILGINX_VM_IP:-}" ]; then
  printf 'Configured EVILGINX_VM_IP=%s\n' "$EVILGINX_VM_IP"
fi

printf '\nStarting Evilginx console...\n\n'
exec /usr/local/bin/evilginx -p /data/phishlets "$@"
