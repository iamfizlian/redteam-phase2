#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

status=0

check_file() {
  if [ -f "$1" ]; then
    printf '[ok] %s\n' "$1"
  else
    printf '[missing] %s\n' "$1"
    status=1
  fi
}

check_dir() {
  if [ -d "$1" ]; then
    printf '[ok] %s/\n' "$1"
  else
    printf '[missing] %s/\n' "$1"
    status=1
  fi
}

check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    printf '[ok] command: %s\n' "$1"
  else
    printf '[warn] command not found: %s\n' "$1"
  fi
}

printf 'Repo layout\n'
check_file README.md
check_file quickstart.md
check_file DEPLOYMENT.md
check_file .env.example
check_file 05-detection/detection-pack.kql
check_file 03-evilginx/deploy.sh
check_dir 01-oauth-consent
check_dir 02-device-code
check_dir 03-evilginx
check_dir 04-endpoint
check_dir 05-detection

printf '\nLocal tooling\n'
check_cmd bash
check_cmd git
check_cmd python3
check_cmd pwsh
check_cmd az
check_cmd gh

if [ -f .env ]; then
  printf '\n[ok] .env exists\n'
else
  printf '\n[warn] .env missing; copy .env.example to .env before running a lab\n'
fi

if [ -d "{01-oauth-consent,02-device-code,03-evilginx,04-endpoint,05-detection}" ]; then
  printf '[warn] Found literal brace directory from a shell expansion typo; it is empty and not used.\n'
fi

exit "$status"
