# Adblock

Mihomo rule-sets generated from Schakal source.

Источник: https://schakal.ru/hosts/alive_hosts_ru_com.txt

Ежедневное обновление GitHub Actions в 02:23 UTC.

## Домены

Файл: `ruleset/schakal_ru_com.yaml`

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

Применение (действие выбери сам):

```yaml
- RULE-SET,schakal-ru-com,REJECT
```

## IP-адреса

Файл: `ruleset/schakal_ips.yaml`

```yaml
rule-providers:
  schakal-ips:
    type: http
    behavior: ipcidr
    format: yaml
    url: https://raw.githubusercontent.com/spothz/Adblock/main/ruleset/schakal_ips.yaml
    path: ./ruleset/schakal_ips.yaml
    interval: 86400
```

Применение (действие выбери сам):

```yaml
- RULE-SET,schakal-ips,REJECT
```

IP-правило формируется только из реальных IP в первом поле hosts-записи. Служебный адрес `0.0.0.0`, которым в hosts-файле блокируются домены, в IP-набор не попадает. Если в источнике нет реальных IP-адресов, IP rule-set будет пустым (`payload:`).
