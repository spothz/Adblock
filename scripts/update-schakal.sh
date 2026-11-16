#!/usr/bin/env bash
set -euo pipefail

SOURCE_URL="https://schakal.ru/hosts/alive_hosts_ru_com.txt"
OUT="ruleset/schakal_ru_com.yaml"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

mkdir -p "$(dirname "$OUT")"

curl -fsSL --retry 3 --retry-delay 5 "$SOURCE_URL" -o "$TMP"

python3 - "$TMP" "$OUT" <<'PY'
import re
import sys
from pathlib import Path

src = Path(sys.argv[1])
out = Path(sys.argv[2])

domains = set()

for line in src.read_text(encoding="utf-8", errors="ignore").splitlines():
    line = line.strip()
    if not line or line.startswith(("!", "#")):
        continue

    parts = line.split()
    if len(parts) < 2 or parts[0] != "0.0.0.0":
        continue

    domain = parts[1].rstrip(".").lower()

    # Keep DNS hostnames only. The source is a hosts file, so this removes
    # localhost/IP/etc. while preserving normal and IDN/punycode hostnames.
    if domain in {"localhost", "localhost.localdomain", "broadcasthost"}:
        continue
    if len(domain) > 253:
        continue
    if re.fullmatch(r"(?=.{1,253}$)(?:[a-z0-9_\-\u0080-\uffff](?:[a-z0-9_\-\u0080-\uffff]*[a-z0-9_\-\u0080-\uffff])?\.)+[a-z0-9_\-\u0080-\uffff]+", domain, re.IGNORECASE):
        domains.add(domain)

ordered = sorted(domains)

with out.open("w", encoding="utf-8", newline="\n") as f:
    f.write("# Auto-generated from Schakal 4PDA Community hosts blacklist\n")
    f.write("# Source: https://schakal.ru/hosts/alive_hosts_ru_com.txt\n")
    f.write("# Do not edit manually; GitHub Actions updates this file daily.\n")
    f.write("payload:\n")
    for domain in ordered:
        f.write("  - '" + domain.replace("'", "''") + "'\n")

print(f"Generated {len(ordered)} domains -> {out}")
PY

test -s "$OUT"
grep -q '^payload:$' "$OUT"
