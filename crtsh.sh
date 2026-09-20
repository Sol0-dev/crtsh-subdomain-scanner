#!/bin/bash
# crtsh - query crt.sh Certificate Transparency logs and extract clean subdomains
# usage: crtsh [options] <domain>
#   options:
#     -o <file>    write deduped, sorted subdomains to file (also printed to stdout)
#     -w           keep wildcard entries (by default *.domain entries are dropped)
#     -v           verbose; show how many entries crt.sh returned vs emitted
# examples:
#   crtsh example.com
#   crtsh -o subs.txt example.com

set -u

OUT=""
KEEP_WILDCARD=0
VERBOSE=0

while getopts ":o:wv" opt; do
  case "$opt" in
    o) OUT="$OPTARG" ;;
    w) KEEP_WILDCARD=1 ;;
    v) VERBOSE=1 ;;
    *) echo "usage: crtsh [-o file] [-w] [-v] <domain>"; exit 1 ;;
  esac
done
shift $((OPTIND-1))

[ $# -lt 1 ] && { echo "error: no domain given"; exit 1; }
DOM="$1"

RAW=$(curl -s --max-time 30 "https://crt.sh/?q=%25.$DOM&output=json")
if [ -z "$RAW" ] || [ "$RAW" = "[]" ]; then
  echo "no results from crt.sh for $DOM"; exit 0
fi

COUNT=$(echo "$RAW" | jq 'length' 2>/dev/null)
ESC=$(printf '%s' "$DOM" | sed 's/\./\\./g')
TMP=$(mktemp)

echo "$RAW" \
  | jq -r '.[].name_value' \
  | tr '\\n' '\n' \
  | grep -iE '\.'"$ESC"'$' \
  | grep -vE '^[[:space:]]*$' \
  > "$TMP"

if [ "$KEEP_WILDCARD" -eq 0 ]; then
  grep -vE '^\*\.' < "$TMP" | sort -u > "$TMP.f"
else
  sort -u "$TMP" > "$TMP.f"
fi
mv "$TMP.f" "$TMP"

cat "$TMP"

if [ -n "$OUT" ]; then
  cp "$TMP" "$OUT"
fi

if [ "$VERBOSE" -eq 1 ]; then
  echo "crt.sh returned $COUNT cert entries; kept $(wc -l < "$TMP") unique hostnames"
fi

rm -f "$TMP"
exit 0    
