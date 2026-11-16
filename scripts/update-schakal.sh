#!/usr/bin/env bash
set -euo pipefail

SOURCE_URL="https://schakal.ru/hosts/alive_hosts_ru_com.txt"
OUT="ruleset/schakal_ru_com.yaml"
TMP="$(mktemp)"
DOMAINS="$(mktemp)"
trap 'rm -f "$TMP" "$DOMAINS"' EXIT

mkdir -p ruleset

# Download the complete source and reject error pages or truncated responses.
curl -fL --retry 3 --retry-delay 5 --connect-timeout 20 "$SOURCE_URL" -o "$TMP"
grep -Fq '!Title: 4PDA Community hosts blacklist' "$TMP"
LINES="$(wc -l < "$TMP")"
if [ "$LINES" -lt 10000 ]; then
  echo "Source looks incomplete: only $LINES lines" >&2
  exit 1
fi

# Remove comments/empty lines, strip the first hosts field (the IP),
# then split remaining hostnames into one item per line.
grep -Ev '^[[:space:]]*([#!]|$)' "$TMP" \
  | sed -E 's/^[[:space:]]*[^[:space:]]+[[:space:]]+//' \
  | tr '[:space:]' '\n' \
  | python3 -c '
import re, sys
pattern = re.compile(
    r"(?=.{1,253}$)(?:[a-z0-9_\-\u0080-\uffff]"
    r"(?:[a-z0-9_\-\u0080-\uffff]*[a-z0-9_\-\u0080-\uffff])?\.)+"
    r"[a-z0-9_\-\u0080-\uffff]+",
    re.IGNORECASE
)
excluded = {"localhost", "localhost.localdomain", "broadcasthost"}
for raw in sys.stdin:
    domain = raw.strip().rstrip(".").lower()
    if domain and domain not in excluded and pattern.fullmatch(domain):
        print(domain)
' \
  | sort -u > "$DOMAINS"

COUNT="$(wc -l < "$DOMAINS" | tr -d ' ')"
if [ "$COUNT" -lt 1000 ]; then
  echo "Too few valid domains extracted: $COUNT" >&2
  exit 1
fi

{
  echo "# Auto-generated Mihomo domain rule-set"
  echo "# Source: $SOURCE_URL"
  echo "# Source lines: $LINES"
  echo "# Domains: $COUNT"
  echo "payload:"
  sed "s/^/  - '/; s/$/'/" "$DOMAINS"
} > "$OUT"

# Final sanity checks: payload must contain domains, never IP/CIDR entries.
grep -q '^payload:$' "$OUT"
grep -Eq "^  - '[^']+\.[^']+'$" "$OUT"
if grep -Eq "^  - '[0-9a-fA-F:.]+(/[0-9]+)?'$" "$OUT"; then
  echo "Unexpected IP/CIDR entry in domain rule-set" >&2
  exit 1
fi

echo "Generated $OUT: $COUNT domains from $LINES source lines"
