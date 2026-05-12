#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT="$ROOT_DIR/05-detection/detection-pack.kql"
OUTPUT_DIR="$ROOT_DIR/generated/kql"

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR"/*.kql

awk -v outdir="$OUTPUT_DIR" '
  /^\/\/ [0-9]+\.[0-9]+/ {
    if (file != "") {
      close(file)
    }
    title = $0
    sub(/^\/\/ /, "", title)
    slug = tolower(title)
    gsub(/[^a-z0-9]+/, "-", slug)
    gsub(/^-|-$/, "", slug)
    file = outdir "/" slug ".kql"
  }
  file != "" {
    print $0 > file
  }
' "$INPUT"

count="$(find "$OUTPUT_DIR" -maxdepth 1 -type f -name '*.kql' | wc -l | tr -d ' ')"
printf '[ok] Wrote %s KQL files to %s\n' "$count" "$OUTPUT_DIR"
