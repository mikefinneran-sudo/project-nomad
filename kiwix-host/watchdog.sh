#!/bin/bash
# Every 5 min (launchd: com.waltersignal.kiwix-watchdog). Restarts kiwix-serve
# after two consecutive failed checks. Skips while the NAS is unmounted, since a
# restart cannot fix that (com.waltersignal.nas-mount handles remounting).
export PATH="$HOME/.orbstack/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
KDIR="$HOME/kiwix"
STATE="$KDIR/.watchdog-fails"
LOG="$KDIR/logs/watchdog.log"
mkdir -p "$KDIR/logs"
log() { echo "[$(date '+%F %T')] $*" >>"$LOG"; }

mount | grep -q " on $HOME/NAS " || { log "NAS not mounted; skip"; exit 0; }

if curl -sf -o /dev/null --max-time 20 http://localhost:8090/ \
   && curl -sf -o /dev/null --max-time 20 "http://localhost:8090/catalog/v2/entries?count=1"; then
  rm -f "$STATE"; exit 0
fi

fails=$(( $(cat "$STATE" 2>/dev/null || echo 0) + 1 ))
echo "$fails" >"$STATE"
log "check failed ($fails)"
if (( fails >= 2 )); then
  if docker ps -a --format '{{.Names}}' | grep -qx kiwix; then
    docker restart -t 10 kiwix >/dev/null && log "restarted kiwix"
  else
    log "kiwix container missing; run kiwix-host/README steps"
  fi
  rm -f "$STATE"
fi
