#!/bin/bash
# Nightly library maintenance on the Mac mini (launchd: com.waltersignal.kiwix-nightly).
# 1. Sync library.xml with the ZIMs on the NAS  2. Rebuild the index page
# 3. Open every book's main page; restart the server if it stops answering.
set -uo pipefail
export PATH="$HOME/.orbstack/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

KDIR="$HOME/kiwix"
DATA="$HOME/NAS/archives/project-nomad-data"
IMAGE="ghcr.io/kiwix/kiwix-serve:3.7.0"
URL="http://localhost:8090"
LOG="$KDIR/logs/nightly.log"
mkdir -p "$KDIR/logs"
exec >>"$LOG" 2>&1
log() { echo "[$(date '+%F %T')] $*"; }

log "=== nightly start"
if ! mount | grep -q " on $HOME/NAS "; then
  log "NAS not mounted; skipping"; exit 1
fi

docker run --rm --name kiwix-sync --entrypoint sh \
  -v "$DATA":/data:ro -v "$KDIR":/library "$IMAGE" /library/sync-library.sh \
  | while read -r line; do log "$line"; done

sleep 10  # let --monitorLibrary pick up library.xml changes
python3 "$KDIR/build_kiwix_index.py" --library "$KDIR/library.xml" --server "$URL" --out "$KDIR/index.html" \
  | while read -r line; do log "$line"; done

ok=0; bad=0
for path in $(grep -oE 'href="/content/[^"]+"' "$KDIR/index.html" | sed 's/href="//; s/"$//' | sort -u); do
  code=$(curl -s -o /dev/null -L --max-time 60 -w '%{http_code}' "$URL$path")
  if [[ "$code" == 200 ]]; then ok=$((ok + 1)); else bad=$((bad + 1)); log "LINK $code $path"; fi
done
log "LINKS ok=$ok bad=$bad"

if ! curl -sf -o /dev/null --max-time 20 "$URL/catalog/v2/entries?count=1"; then
  log "server not answering after checks; restarting"
  docker restart -t 10 kiwix >/dev/null
fi
log "=== nightly done"
