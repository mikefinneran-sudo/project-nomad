#!/bin/bash
# Project NOMAD — Homesteading Gap-Fill Downloads
set -euo pipefail

BASE_DIR="${1:-$HOME/NAS/archives/project-nomad-data}"
LOG_FILE="$BASE_DIR/download.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

download() {
  local url="$1" dest="$2" filename
  filename=$(basename "$url")
  local filepath="$dest/$filename"
  if [[ -f "$filepath" ]]; then
    log "SKIP (exists): $filename"
    return 0
  fi
  log "DOWNLOADING: $filename → $dest/"
  if curl -L -C - --retry 3 --retry-delay 10 -o "$filepath.part" "$url" 2>>"$LOG_FILE"; then
    mv "$filepath.part" "$filepath"
    log "DONE: $filename ($(du -h "$filepath" | cut -f1))"
  else
    log "FAILED: $filename"
    return 1
  fi
}

FAILED=0
TOTAL=0

mkdir -p "$BASE_DIR"/{energy,homesteading}

log "=== ENERGY ==="
for url in \
  "https://download.kiwix.org/zim/other/energypedia_en_all_maxi_2025-12.zim" \
  "https://download.kiwix.org/zim/zimit/solar.lowtechmagazine.com_mul_all_2025-01.zim" \
  "https://download.kiwix.org/zim/videos/project-fuel_en_all_2026-07.zim"; do
  ((TOTAL++))
  download "$url" "$BASE_DIR/energy" || ((FAILED++))
done

log "=== HOMESTEADING ==="
for url in \
  "https://download.kiwix.org/zim/other/zimgit-water_en_2024-08.zim" \
  "https://download.kiwix.org/zim/other/appropedia_en_all_maxi_2026-02.zim" \
  "https://download.kiwix.org/zim/other/zimgit-post-disaster_en_2024-05.zim" \
  "https://download.kiwix.org/zim/stack_exchange/homebrew.stackexchange.com_en_all_2026-10.zim" \
  "https://download.kiwix.org/zim/zimit/grimgrains_en_all_2026-08.zim" \
  "https://download.kiwix.org/zim/stack_exchange/sustainability.stackexchange.com_en_all_2026-10.zim" \
  "https://download.kiwix.org/zim/other/zimgit-knots_en_2024-08.zim" \
  "https://download.kiwix.org/zim/stack_exchange/crafts.stackexchange.com_en_all_2026-10.zim"; do
  ((TOTAL++))
  download "$url" "$BASE_DIR/homesteading" || ((FAILED++))
done

log "========================================="
log "HOMESTEAD FILL: $((TOTAL - FAILED))/$TOTAL succeeded, $FAILED failed"
log "========================================="
