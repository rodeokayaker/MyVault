---
type: project-note
status: active
tags: [project, project/vpn]
updated: 2026-05-01
---

# Timeweb Transit VPN — System Description

## Status

Состояние заметки: актуально на `2026-04-08`.

Система находится в рабочем состоянии.

Текущий runtime:
- `current-mode = us`
- основной non-RU egress: `US`
- резервный egress: `NL`
- аварийный fallback: `direct`

Ingress сейчас двух типов:
- `WG` на `UDP 585`
- `AmneziaWG 2.0` на `UDP 586`

## Purpose

Цель системы:
- принимать клиентский трафик по `WG` и `AmneziaWG`
- разделять трафик по назначению
- российский и private трафик не отправлять через `US`
- остальной трафик выпускать через внешний `US`
- при отказе `US` переходить на `NL`
- при отказе `NL` переходить на `direct`
- не ломать другие проекты на VDS

## Host

Хост:
- provider: `Timeweb`
- public IP: `176.124.208.237`
- hostname: `6577929-wl260063.twc1.net`
- OS: `Ubuntu 24.04`

Контекст:
- на сервере живут и другие Docker-проекты
- transit-stack развернут отдельно в `/opt/transit-vpn`
- старый host-level `awg-split` не является частью этого стека

## High-Level Topology

```text
Client
  |
  |  WG :585  or  AmneziaWG 2.0 :586
  v
transit-amnezia-entry
  |
  | iif awg0/awg1 -> table 300 -> sbtun0
  v
transit-sing-box
  |
  | route rules
  |  - RU/private -> direct
  |  - gosuslugi -> NL
  |  - everything else -> final
  v
final = us-out | nl-out | direct-fallback
```

Probe-контейнеры:

```text
transit-wg-primary   -> US probe
transit-wg-backup    -> NL probe
```

Они нужны для проверки каналов и failover, а не как основной data plane.

## Why The Final Architecture Looks Like This

### 1. Классификация живет в `sing-box`

Именно там сосредоточены:
- `sniff`
- `hijack-dns`
- `reverse_mapping`
- `geoip/geosite rule_set`
- domain/IP exceptions

Это делает поведение предсказуемым и не размазывает routing-логику между несколькими слоями.

### 2. Ingress и egress разведены

`AmneziaWG/WG` ingress только принимает клиентский трафик и отправляет его в `sbtun0`.
Решение, куда выпускать соединение, принимает `sing-box`.

### 3. Failover не завязан на активный клиентский peer

Healthcheck использует отдельные probe-контейнеры.
Это исключает конфликт между активным пользовательским трафиком и проверкой внешних каналов.

### 4. Для полного `AmneziaWG 2.0` понадобилась замена рантайма

Изначально ingress работал на legacy image `metaligh/amneziawg`.
Практика показала:
- он не принимал полный набор `AmneziaWG 2.0`
- не поддерживал рабочий профиль с `H1-H4`, `S3-S4`, `I1`

В итоге ingress был переведен на custom image, собранный из:
- `amneziawg-go`
- `amneziawg-tools v1.0.20250903`

Именно после этого заработал полноценный `AmneziaWG 2.0`.

## Directory Layout On Host

Основной каталог:
- `/opt/transit-vpn`

Ключевые файлы:
- `/opt/transit-vpn/docker-compose.yml`
- `/opt/transit-vpn/sing-box/config.json`
- `/opt/transit-vpn/amnezia-ingress/data/awg0.conf`
- `/opt/transit-vpn/amnezia-ingress/data/awg1.conf`
- `/opt/transit-vpn/amnezia-ingress/data/metaligh.conf`
- `/opt/transit-vpn/amnezia-ingress/data/metaligh-amnezia.conf`
- `/opt/transit-vpn/amnezia-ingress/clients/`
- `/opt/transit-vpn/amnezia2-image/Dockerfile`
- `/opt/transit-vpn/host-routing/apply-routes.sh`
- `/opt/transit-vpn/host-routing/healthcheck.sh`
- `/opt/transit-vpn/host-routing/current-mode`
- `/usr/local/bin/addawguser`

Бэкапы:
- `/opt/transit-vpn/backup/`

## Docker Services

### `transit-amnezia-entry`

Назначение:
- поднимает ingress-интерфейсы `awg0` и `awg1`
- слушает:
  - `585/udp`
  - `586/udp`
- отправляет клиентский ingress-трафик в `table 300 -> sbtun0`

Текущий image:
- `local/transit-amneziawg2:2026-04-08`

Почему это важно:
- это уже не legacy image
- этот образ умеет полный `AmneziaWG 2.0`

Runtime-логика внутри `command`:
- `awg-quick up awg0`
- `awg-quick up awg1`
- `ip rule add pref 101 iif awg0 table 300`
- `ip rule add pref 103 iif awg1 table 300`
- reconcile-цикл:
  - `ip route replace table 300 default dev sbtun0`
  - `FORWARD` rules для `awg0 <-> sbtun0`
  - `FORWARD` rules для `awg1 <-> sbtun0`

### `transit-sing-box`

Назначение:
- поднимает `sbtun0`
- принимает ingress-трафик
- решает, куда выпускать соединение

Особенность:
- `network_mode: service:amnezia-entry`

Значит:
- `awg0`, `awg1`, `eth0`, `sbtun0` живут в одном namespace
- policy routing и forwarding работают без лишних bridge-hop’ов

### `transit-wg-primary`

Назначение:
- probe для `US`

### `transit-wg-backup`

Назначение:
- probe для `NL`

## Ingress Layers

### `awg0` -> `WG` legacy-compatible ingress

Порт:
- `585/udp`

Используется как сохраненный рабочий WG-контур.

### `awg1` -> full `AmneziaWG 2.0`

Порт:
- `586/udp`

Использует полный набор:
- `Jc/Jmin/Jmax`
- `S1/S2/S3/S4`
- `H1/H2/H3/H4`
- `I1`

Именно на `awg1` заведены все новые пользователи.

## sing-box Configuration

Файл:
- `/opt/transit-vpn/sing-box/config.json`

### DNS

Используется:
- `prefer_ipv4`
- `reverse_mapping`
- `DoH` на `1.1.1.1`
- `bind_interface = eth0`

Почему так:
- доменные правила реально срабатывают
- DNS не уходит в случайный failover path

### Inbound

Один inbound:
- type: `tun`
- interface: `sbtun0`
- address: `172.19.0.1/30`
- `auto_route = false`

### Route rule-set

Используются remote rule-set:
- `geoip-ru`
- `geosite-category-ru`
- `geosite-tld-ru`
- `geosite-category-bank-ru`
- `geosite-category-gov-ru`

### Route rules

Порядок важен:

1. `sniff`
2. `dns -> hijack-dns`
3. `gosuslugi.ru`, `gu-st.ru` -> `nl-out`
4. `213.59.253.0/24`, `213.59.254.0/24` -> `nl-out`
5. `ip_is_private = true` -> `ru-direct`
6. RU rule-set -> `ru-direct`
7. everything else -> `route.final`

### Egress endpoints

`us-out`:
- endpoint `107.175.35.94:43094`
- local address `10.8.1.2/32`

`nl-out`:
- endpoint `178.208.88.56:47555`
- local address `10.8.1.9/32`

### Route final

Healthcheck переключает `route.final` между:
- `us-out`
- `nl-out`
- `direct-fallback`

## Traffic Classes

### 1. Private / local

Маршрут:
- `ru-direct`

### 2. Обычный российский трафик

Маршрут:
- `ru-direct`

Используются:
- `geoip-ru`
- `geosite-category-ru`
- `geosite-tld-ru`
- `bank-ru`
- `gov-ru`

### 3. `gosuslugi`

Маршрут:
- `nl-out`

Причина:
- с `Timeweb` IP direct-connect до `Gosuslugi` не отвечал
- через `NL` сайт и `ESIA` открывались

### 4. Всё остальное

Маршрут:
- `route.final`

Нормально:
- `US`

## Failover Logic

Healthcheck:
- `/opt/transit-vpn/host-routing/healthcheck.sh`

Timer:
- `transit-vpn-failover.timer`

Логика:
- если жив `US`, используется `US`
- если `US` недоступен, пробуется `NL`
- если `NL` тоже недоступен, используется `direct`

Текущий режим:
- `us`

## Active AWG Users

На `2026-04-08` в `awg1` есть:
- `vanya-amnezia` -> `192.168.201.2/32`
- `phone_vanya` -> `192.168.201.3/32`
- `natalie_comp` -> `192.168.201.4/32`
- `natalie_phone` -> `192.168.201.5/32`
- `baga` -> `192.168.201.6/32`

Клиентские конфиги хранятся в:
- `/opt/transit-vpn/amnezia-ingress/clients/`

## Utility: `addawguser`

Установлен:
- `/usr/local/bin/addawguser`

Назначение:
- добавить нового пользователя в `awg1`
- сделать это без полного recreate ingress

Что делает:
- валидирует имя
- берет следующий свободный IP из `192.168.201.0/24`
- генерирует `PrivateKey`
- генерирует `PublicKey`
- генерирует `PresharedKey`
- читает `server_pub` у `awg1`
- дописывает новый `[Peer]` в `/opt/transit-vpn/amnezia-ingress/data/awg1.conf`
- выполняет `awg syncconf awg1`
- создает обратный маршрут `192.168.201.x/32 dev awg1`
- пишет клиентский конфиг в `/opt/transit-vpn/amnezia-ingress/clients/<user>.conf`
- печатает конфиг в stdout

Использование:

```bash
addawguser some_user
```

Пример:

```bash
addawguser baga
```

## Runbook

### Проверить статус контейнеров

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep transit
```

### Проверить текущий egress-режим

```bash
cat /opt/transit-vpn/host-routing/current-mode
```

### Проверить `awg1`

```bash
docker exec transit-amnezia-entry awg show awg1
```

### Посмотреть клиентские конфиги

```bash
ls -la /opt/transit-vpn/amnezia-ingress/clients
```

### Сгенерировать нового пользователя

```bash
addawguser some_user
```

### Проверить конкретный клиентский конфиг тестовым раннером

Серверный helper:
- `/opt/transit-vpn/amnezia2-image/remote_awg2_conf_test.sh`

Пример:

```bash
/opt/transit-vpn/amnezia2-image/remote_awg2_conf_test.sh /opt/transit-vpn/amnezia-ingress/clients/baga.conf
```

## Local Project Files

Локально в рабочей папке:
- `/Users/vanya/Documents/VPN/deploy_transit_rework.sh`
- `/Users/vanya/Documents/VPN/amnezia2.Dockerfile`
- `/Users/vanya/Documents/VPN/addawguser`
- `/Users/vanya/Documents/VPN/remote_awg2_conf_test.sh`

Это локальный source-of-truth для воспроизводимого деплоя и сервисных скриптов.

## Practical Notes

- один конфиг нельзя использовать на нескольких устройствах
- один девайс = один peer = один `PrivateKey`
- если пользователь добавлен через `addawguser`, маршрут для него создается автоматически
- если peer добавлять руками через `syncconf`, нужно не забыть про `ip route replace <client-ip>/32 dev awg1`

## Verification Summary

Подтверждено на практике:
- полный `AmneziaWG 2.0` ingress работает
- `WG` ingress на `585` сохранен
- `addawguser` работает
- `baga`-конфиг успешно поднят в тестовом `AWG 2.0`-клиенте
- внешний IP через `baga` = `107.175.35.94`

## Связанные заметки
- [[MOC_Projects]]
- [[01_Projects/VPN/RackNerd/Secrets]]
- [[01_Projects/VPN/Timeweb_Transit_VPN_Progress]]
- [[01_Projects/VPN/Timeweb_VDS]]
