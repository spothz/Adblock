#!/usr/bin/env bash
set -euo pipefail

SOURCE_URL="https://schakal.ru/hosts/alive_hosts_ru_com.txt"
DOMAIN_OUT="ruleset/schakal_ru_com.yaml"
IP_OUT="ruleset/schakal_ips.yaml"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

mkdir -p ruleset
curl -fsSL --retry 3 --retry-delay 5 "$SOURCE_URL" -o "$TMP"

python3 - "$TMP" "$DOMAIN_OUT" "$IP_OUT" <<'PY'
import ipaddress
import re
import sys
from pathlib import Path

src = Path(sys.argv[1])
domain_out = Path(sys.argv[2])
ip_out = Path(sys.argv[3])

domains = set()
ips = set()

for raw in src.read_text(encoding="utf-8", errors="ignore").splitlines():
    line = raw.strip()
    if not line or line.startswith(("!", "#")):
        continue
    parts = line.split()
    if len(parts) < 2:
        continue

    try:
        address = ipaddress.ip_address(parts[0])
    except ValueError:
        continue

    # Hosts blocking placeholders are not real destination IP addresses.
    if not address.is_unspecified and not address.is_loopback and not address.is_link_local and not address.is_multicast:
        ips.add(f"{address}/{32 if address.version == 4 else 128}")

    for item in parts[1:]:
        domain = item.rstrip(".").lower()
        if domain in {"localhost", "localhost.localdomain", "broadcasthost"}:
            continue
        if len(domain) <= 253 and re.fullmatch(
            r"(?=.{1,253}$)(?:[a-z0-9_\-\u0080-\uffff](?:[a-z0-9_\-\u0080-\uffff]*[a-z0-9_\-\u0080-\uffff])?\.)+[a-z0-9_\-\u0080-\uffff]+",
            domain, re.IGNORECASE
        ):
            domains.add(domain)

def write_set(path, values):
    with path.open("w", encoding="utf-8", newline="\n") as f:
        f.write("# Auto-generated from Schakal hosts list\n")
        f.write("# Source: https://schakal.ru/hosts/alive_hosts_ru_com.txt\n")
        if not values:
            f.write("payload: []\n")
        else:
            f.write("payload:\n")
            for value in sorted(values):
                f.write(f"  - '{value}'\n")

write_set(domain_out, domains)
write_set(ip_out, ips)
print(f"Domains: {len(domains)}; IP addresses: {len(ips)}")
PY

test -s "$DOMAIN_OUT"
test -s "$IP_OUT"
grep -q '^payload:' "$DOMAIN_OUT"
grep -q '^payload:' "$IP_OUT"
