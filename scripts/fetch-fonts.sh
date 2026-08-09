#!/usr/bin/env bash
# Download the fonts the Typst CV builds need into fonts/.
# Run once after cloning; fonts/ is gitignored. Safe to re-run — existing
# files are skipped.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(dirname "$here")"
dest="$root/fonts"
list="$here/fonts.txt"

mkdir -p "$dest"

while read -r url; do
  url="${url%%#*}"
  url="$(echo "$url" | tr -d '[:space:]')"
  [ -z "$url" ] && continue

  name="$(basename "$url")"
  if [ -s "$dest/$name" ]; then
    echo "  have $name"
    continue
  fi

  echo "  get  $name"
  curl -fsSL "$url" -o "$dest/$name"
done < "$list"

echo "Fonts ready in $dest"
