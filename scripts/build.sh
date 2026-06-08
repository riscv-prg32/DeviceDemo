#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
prg32_repo="${PRG32_REPO:-"$repo_dir/../PRG32"}"
firmware_elf="${1:-"${PRG32_FIRMWARE_ELF:-"$prg32_repo/build/PRG32.elf"}"}"
architecture="${PRG32_ARCHITECTURE:-esp32c6}"

mkdir -p "$repo_dir/dist"

python3 "$prg32_repo/tools/prg32_game.py" build \
  "$repo_dir/src/devicedemo.c" \
  --firmware-elf "$firmware_elf" \
  --entry-prefix devicedemo \
  --name devicedemo \
  --out "$repo_dir/dist/devicedemo-$architecture.raw.prg32"

python3 "$prg32_repo/tools/prg32_game.py" attach-metadata \
  "$repo_dir/dist/devicedemo-$architecture.raw.prg32" \
  --out "$repo_dir/dist/devicedemo-$architecture.prg32" \
  --metadata "$repo_dir/metadata/metadata.json" \
  --icon "$repo_dir/assets/icon.png" \
  --screenshot "$repo_dir/assets/screenshot.png" \
  --colophon "$repo_dir/metadata/colophon.json" \
  --architecture "$architecture"

echo "$repo_dir/dist/devicedemo-$architecture.prg32"
