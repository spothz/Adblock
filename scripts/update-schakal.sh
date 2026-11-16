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
ip_networks = set()

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

    # 0.0.0.0 / :: are hosts-file blocking targets, not destination IPs.
    if not address.is_unspecified or address.version == 6 and str(address) != "::":
        if not address.is_loopback and not address.is_link_local and not address.is_multicast:
            prefix = 32 if address.version == 4 else 128
            ip_networks.add(f"{address}/{prefix}")

    for item in parts[1:]:
        domain = item.rstrip(".").lower()
        if domain in {"localhost", "localhost.localdomain", "broadcasthost"}:
            continue
        if len(domain) <= 253 and re.fullmatch(
            r"(?=.{1,253}$)(?:[a-z0-9_\-\u0080-\uffff](?:[a-z0-9_\-\u0080-\uffff]*[a-z0-9_\-\u0080-\uffff])?\.)+[a-z0-9_\-\u0080-\uffff]+",
            domain, re.IGNORECASE
        ):
            domains.add(domain)

def write_rule_set(path, title, values):
    with path.open("w", encoding="utf-8", newline="\n") as f:
        f.write(f"# Auto-generated from Schakal hosts list\n# {title}\n# Source: {SOURCE_URL}\npayload:\n")
        for value in sorted(values):
            f.write(f"  - '{value}'\n")

write_rule_set(domain_out, "Mihomo domain rule-set", domains)
write_rule_set(ip_out, "Mihomo IP-CIDR rule-set", ip_networks)

print(f"Generated {len(domains)} domains -> {domain_out}")
print(f"Generated {len(ip_networks)} IPs -> {ip_out}")
PY

test -s "$DOMAIN_OUT"
test -s "$IP_OUT"
grep -q '^payload:$' "$DOMAIN_OUT"
grep -q '^payload:$' "$IP_OUT"
