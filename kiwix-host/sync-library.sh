#!/bin/sh
# Runs INSIDE the kiwix-serve container (busybox sh), with the NAS data at /data
# and this folder at /library. Adds ZIMs missing from library.xml and drops
# entries whose file is gone. Paths are stored relative to /library (../data/...).
set -u
cd /library
LIB=library.xml
[ -f "$LIB" ] || echo '<library version="20110515"></library>' > "$LIB"

find ../data -name '*.zim' -size +16k | sort > /tmp/disk.txt
grep -oE 'path="[^"]+"' "$LIB" | sed -E 's/path="//; s/"$//' | sort > /tmp/lib.txt

added=0; failed=0; removed=0
for f in $(comm -23 /tmp/disk.txt /tmp/lib.txt); do
  if kiwix-manage "$LIB" add "$f" >/dev/null 2>&1; then
    echo "ADDED $f"; added=$((added + 1))
  else
    echo "FAILED $f"; failed=$((failed + 1))
  fi
done

for f in $(comm -13 /tmp/disk.txt /tmp/lib.txt); do
  id=$(grep -oE "<book id=\"[^\"]+\" path=\"$f\"" "$LIB" | sed -E 's/<book id="([^"]+)".*/\1/')
  [ -n "$id" ] && kiwix-manage "$LIB" remove "$id" >/dev/null 2>&1 && { echo "REMOVED $f"; removed=$((removed + 1)); }
done

echo "SYNC added=$added failed=$failed removed=$removed books=$(grep -c '<book ' "$LIB")"
