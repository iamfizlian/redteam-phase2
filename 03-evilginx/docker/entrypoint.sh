#!/usr/bin/env bash
set -euo pipefail

mkdir -p /data/logs /data/config /opt/evilginx2/phishlets

if ! find /opt/evilginx2/phishlets -maxdepth 1 -type f \( -name '*.yaml' -o -name '*.yml' \) | grep -q .; then
  if [ -d /opt/evilginx2/default-phishlets ]; then
    printf 'Initializing persistent phishlets from upstream Evilginx clone...\n'
    find /opt/evilginx2/default-phishlets -maxdepth 1 -type f \( -name '*.yaml' -o -name '*.yml' \) -exec cp {} /opt/evilginx2/phishlets/ \;
  fi
fi

cat <<'EOF'
Evilginx lab container

Authorized validation only. This image uses the phishlets included in
the upstream Evilginx clone. This repository does not add custom
phishlets, credential collection pages, token replay automation, or
tenant secrets.

Runtime paths:
  /opt/evilginx2/phishlets  persisted phishlets, mounted from runtime/phishlets
  /data/logs       operator logs
  /root/.evilginx  persisted Evilginx config, mounted from runtime/config

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
exec /usr/local/bin/evilginx -p /opt/evilginx2/phishlets "$@"
