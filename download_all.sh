#!/bin/bash
# Project NOMAD — Full Dataset Download Script
# Downloads all ZIM files, Wikipedia, and maps to NAS
# Resumable (curl -C -), skips existing files

set -euo pipefail

BASE_DIR="${1:-$HOME/NAS/archives/project-nomad-data}"
LOG_FILE="$BASE_DIR/download.log"

mkdir -p "$BASE_DIR"/{medicine,survival,education,diy,agriculture,computing,wikipedia,maps}

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

download() {
  local url="$1"
  local dest="$2"
  local filename
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

# ─── MEDICINE ───
log "=== MEDICINE ==="
for url in \
  "https://download.kiwix.org/zim/other/zimgit-medicine_en_2024-08.zim" \
  "https://download.kiwix.org/zim/zimit/nhs.uk_en_medicines_2025-12.zim" \
  "https://download.kiwix.org/zim/zimit/fas-military-medicine_en_2025-06.zim" \
  "https://download.kiwix.org/zim/zimit/wwwnc.cdc.gov_en_all_2024-11.zim" \
  "https://download.kiwix.org/zim/zimit/medlineplus.gov_en_all_2025-01.zim" \
  "https://download.kiwix.org/zim/wikipedia/wikipedia_en_medicine_maxi_2026-10.zim" \
  "https://download.kiwix.org/zim/libretexts/libretexts.org_en_med_2025-01.zim" \
  "https://download.kiwix.org/zim/other/librepathology_en_all_maxi_2026-09.zim"; do
  ((TOTAL++))
  download "$url" "$BASE_DIR/medicine" || ((FAILED++))
done

# ─── SURVIVAL ───
log "=== SURVIVAL ==="
for url in \
  "https://download.kiwix.org/zim/gutenberg/gutenberg_en_lcc-u_2026-03.zim"; do
  ((TOTAL++))
  download "$url" "$BASE_DIR/survival" || ((FAILED++))
done

# ─── EDUCATION ───
log "=== EDUCATION ==="
for url in \
  "https://download.kiwix.org/zim/ted/ted_mul_ted-ed_2026-09.zim" \
  "https://download.kiwix.org/zim/wikiversity/wikiversity_en_all_maxi_2026-05.zim" \
  "https://download.kiwix.org/zim/libretexts/libretexts.org_en_math_2025-01.zim" \
  "https://download.kiwix.org/zim/libretexts/libretexts.org_en_phys_2025-01.zim" \
  "https://download.kiwix.org/zim/libretexts/libretexts.org_en_chem_2025-01.zim" \
  "https://download.kiwix.org/zim/libretexts/libretexts.org_en_bio_2025-01.zim" \
  "https://download.kiwix.org/zim/wikibooks/wikibooks_en_all_maxi_2026-04.zim" \
  "https://download.kiwix.org/zim/ted/ted_mul_ted-conference_2026-09.zim" \
  "https://download.kiwix.org/zim/libretexts/libretexts.org_en_human_2025-01.zim" \
  "https://download.kiwix.org/zim/libretexts/libretexts.org_en_geo_2025-01.zim" \
  "https://download.kiwix.org/zim/libretexts/libretexts.org_en_eng_2025-01.zim" \
  "https://download.kiwix.org/zim/libretexts/libretexts.org_en_biz_2025-01.zim"; do
  ((TOTAL++))
  download "$url" "$BASE_DIR/education" || ((FAILED++))
done

# ─── DIY ───
log "=== DIY ==="
for url in \
  "https://download.kiwix.org/zim/stack_exchange/woodworking.stackexchange.com_en_all_2026-10.zim" \
  "https://download.kiwix.org/zim/stack_exchange/mechanics.stackexchange.com_en_all_2026-10.zim" \
  "https://download.kiwix.org/zim/stack_exchange/diy.stackexchange.com_en_all_2026-10.zim" \
  "https://download.kiwix.org/zim/ifixit/ifixit_en_all_2025-12.zim"; do
  ((TOTAL++))
  download "$url" "$BASE_DIR/diy" || ((FAILED++))
done

# ─── AGRICULTURE ───
log "=== AGRICULTURE ==="
for url in \
  "https://download.kiwix.org/zim/zimit/foss.cooking_en_all_2026-05.zim" \
  "https://download.kiwix.org/zim/zimit/based.cooking_en_all_2026-08.zim" \
  "https://download.kiwix.org/zim/stack_exchange/gardening.stackexchange.com_en_all_2026-10.zim" \
  "https://download.kiwix.org/zim/stack_exchange/cooking.stackexchange.com_en_all_2026-10.zim" \
  "https://download.kiwix.org/zim/other/zimgit-food-preparation_en_2025-04.zim" \
  "https://download.kiwix.org/zim/videos/lrnselfreliance_en_all_2026-09.zim" \
  "https://download.kiwix.org/zim/gutenberg/gutenberg_en_lcc-s_2026-03.zim"; do
  ((TOTAL++))
  download "$url" "$BASE_DIR/agriculture" || ((FAILED++))
done

# ─── COMPUTING ───
log "=== COMPUTING ==="
for url in \
  "https://download.kiwix.org/zim/freecodecamp/freecodecamp_en_all_2026-08.zim" \
  "https://download.kiwix.org/zim/devdocs/devdocs_en_python_2026-08.zim" \
  "https://download.kiwix.org/zim/devdocs/devdocs_en_javascript_2026-10.zim" \
  "https://download.kiwix.org/zim/devdocs/devdocs_en_html_2026-10.zim" \
  "https://download.kiwix.org/zim/devdocs/devdocs_en_css_2026-10.zim" \
  "https://download.kiwix.org/zim/stack_exchange/arduino.stackexchange.com_en_all_2026-10.zim" \
  "https://download.kiwix.org/zim/stack_exchange/raspberrypi.stackexchange.com_en_all_2026-10.zim" \
  "https://download.kiwix.org/zim/devdocs/devdocs_en_node_2026-08.zim" \
  "https://download.kiwix.org/zim/devdocs/devdocs_en_react_2026-05.zim" \
  "https://download.kiwix.org/zim/devdocs/devdocs_en_git_2026-10.zim" \
  "https://download.kiwix.org/zim/stack_exchange/electronics.stackexchange.com_en_all_2026-10.zim" \
  "https://download.kiwix.org/zim/stack_exchange/robotics.stackexchange.com_en_all_2026-10.zim" \
  "https://download.kiwix.org/zim/devdocs/devdocs_en_docker_2026-10.zim" \
  "https://download.kiwix.org/zim/devdocs/devdocs_en_bash_2026-10.zim"; do
  ((TOTAL++))
  download "$url" "$BASE_DIR/computing" || ((FAILED++))
done

# ─── WIKIPEDIA (Complete Full) ───
log "=== WIKIPEDIA ==="
download "https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_maxi_2026-02.zim" "$BASE_DIR/wikipedia" || ((FAILED++))
((TOTAL++))

# ─── MAPS (All US States) ───
log "=== MAPS ==="
MAPS_BASE="https://github.com/Crosstalk-Solutions/project-nomad-maps/raw/refs/heads/master/pmtiles"
for state in \
  alaska california hawaii oregon washington \
  arizona colorado idaho montana nevada new_mexico utah wyoming \
  arkansas louisiana oklahoma texas \
  alabama kentucky mississippi tennessee \
  delaware district_of_columbia florida georgia maryland north_carolina south_carolina virginia west_virginia \
  iowa kansas minnesota missouri nebraska north_dakota south_dakota \
  illinois indiana michigan ohio wisconsin \
  new_jersey new_york pennsylvania \
  connecticut maine massachusetts new_hampshire rhode_island vermont; do
  ((TOTAL++))
  download "${MAPS_BASE}/${state}_2025-12.pmtiles" "$BASE_DIR/maps" || ((FAILED++))
done

# ─── SUMMARY ───
log "========================================="
log "COMPLETE: $((TOTAL - FAILED))/$TOTAL succeeded, $FAILED failed"
log "Location: $BASE_DIR"
log "Total size: $(du -sh "$BASE_DIR" | cut -f1)"
log "========================================="
