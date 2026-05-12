#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="$ROOT_DIR/generated/redteam-phase2.zip"

mkdir -p "$ROOT_DIR/generated"

cd "$ROOT_DIR"
python3 - "$OUTPUT" <<'PY'
import os
import sys
import zipfile

output = sys.argv[1]
root = os.getcwd()
excluded_dirs = {".git", ".agents", ".codex", ".venv", "__pycache__", "generated"}
excluded_files = {".env"}

with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for current, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in excluded_dirs]
        rel_dir = os.path.relpath(current, root)
        for name in files:
            if name in excluded_files or name.endswith(".pyc"):
                continue
            path = os.path.join(current, name)
            rel = os.path.normpath(os.path.join(rel_dir, name))
            if rel.startswith(".."):
                continue
            zf.write(path, rel)
PY

printf '[ok] Wrote %s\n' "$OUTPUT"
