# Adblock

Mihomo rule-set.

## Schakal RU/COM hosts

Источник:

https://schakal.ru/hosts/alive_hosts_ru_com.txt

Список автоматически преобразуется из hosts в Mihomo YAML rule-set:

`ruleset/schakal_ru_com.yaml`

Обновление выполняется GitHub Actions ежедневно в 02:17 UTC.

Подключение в Mihomo:

```yaml
rule-providers:
  schakal-ru-com:
    type: http
    behavior: domain
    format: yaml
    url: https://raw.githubusercontent.com/spothz/Adblock/main/ruleset/schakal_ru_com.yaml
    path: ./ruleset/schakal_ru_com.yaml
    interval: 86400

rules:
  - RULE-SET,schakal-ru-com,REJECT
```

В результате rule-set содержит домены из исходного списка, без IP-адресов и hosts-записей.
