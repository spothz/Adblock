# Adblock

Mihomo domain rule-set generated from the Schakal / 4PDA hosts list.

Source: https://schakal.ru/hosts/alive_hosts_ru_com.txt

## Automatic update

GitHub Actions downloads the source every day at 02:23 UTC, filters it, validates the domains and publishes the updated file when its content changes. A manual run is also available in the Actions tab.

## Mihomo rule-provider

```yaml
rule-providers:
  schakal-ru-com:
    type: http
    behavior: domain
    format: yaml
    url: https://raw.githubusercontent.com/spothz/Adblock/main/ruleset/schakal_ru_com.yaml
    path: ./ruleset/schakal_ru_com.yaml
    interval: 86400
```

Apply it in `rules:` with the action you want, for example:

```yaml
- RULE-SET,schakal-ru-com,REJECT
```

Only domain rules are generated. IP/CIDR extraction and the separate IP rule-set have been removed.
