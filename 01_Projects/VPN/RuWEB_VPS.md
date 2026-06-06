---
type: project-note
status: active
tags: [project, project/vpn]
updated: 2026-06-06
---

# RuWEB VPS

Второй ingress-узел VPN-системы, параллельный [[Timeweb_VDS]]. Поднят `2026-06-06` как клон Timeweb-стека: тот же клиентский опыт (AmneziaWG/UDP 586 → split-routing → US egress), но через другой хостинг и другую транзитную ссылку на RackNerd.

## Доступ

- IP: `185.11.246.25`
- Hostname: `p696576.kvmvps`
- Провайдер: RuWEB (ru-web.net)
- User: `root`
- SSH key: `~/.ssh/id_ed25519` (`kayak-moscow-deploy`)
- Та же пара ключей, что и для Timeweb VDS

## Базовая информация

- ОС: `Ubuntu 24.04.1 LTS`
- Kernel: `6.8.0-51-generic`
- CPU: `1 vCPU`
- RAM: `503 MiB` (поэтому добавлен `swap 1G` для сборки go-образа AmneziaWG)
- Disk: `12G` ext4, занято ~`40%`
- TUN: доступен (`/dev/net/tun`)

## Сетевое состояние

- Публичный адрес: `185.11.246.25/24` на `eth0`
- Дефолтный шлюз: `185.11.246.1`
- Открыто наружу:
  - `22/tcp` — SSH
  - `586/udp` — AmneziaWG ingress (через docker-proxy)
- В отличие от Timeweb здесь **нет** Caddy / n8n / Directus / Zabbix — это чистая VPN-нода.

## Архитектура (что именно тут поднято)

```
                                  ┌──────────────────────────┐
client (AmneziaVPN, UDP/586) ─▶──┤ transit-amnezia-entry    │
                                  │   awg1 ListenPort 586    │
                                  │   (только AmneziaWG)     │
                                  └────────────┬─────────────┘
                                               │ sbtun0 (sing-box TUN inbound)
                                               ▼
                                  ┌──────────────────────────┐
                                  │ transit-sing-box         │
                                  │ split-routing rules      │
                                  │ final = us-out           │
                                  └──────┬───────────────────┘
                                         │ direct outbound, bind_interface=awg-us
                                         ▼
                                  ┌──────────────────────────┐
                                  │ transit-awg-us           │
                                  │ AmneziaWG userspace      │
                                  │ → 107.175.35.94:37078    │
                                  │ (RackNerd, отдельный     │
                                  │  AmneziaWG-instance)     │
                                  └──────────────────────────┘
```

Все три контейнера живут в одной netns (`transit-us` и `sing-box` через `network_mode: service:amnezia-entry`).

### Главное отличие от Timeweb

- Timeweb-стек гонит транзит через **plain WireGuard** (`107.175.35.94:43094` и `178.208.88.56:47555`) и пользуется встроенным `wireguard`-endpoint в sing-box.
- RuWEB подключён к RackNerd через **AmneziaWG** на отдельном порту `37078`. Sing-box AmneziaWG не умеет, поэтому ставится отдельный userspace-контейнер `transit-awg-us`, а sing-box роутит через него `direct`-outbound с `bind_interface: awg-us` (SO_BINDTODEVICE).
- Только один ingress: `awg1` на UDP/586. Plain WG (UDP/585) не поднимался — старого клиента под него тут нет.
- Failover упрощён: `us ↔ direct`. NL пока не настроен — оставлен как stub.

## Egress / транзит

- Источник доступа: `/Users/vanya/Downloads/amnezia_config_racknerd_4ruwebvds.vpn` (Amnezia client export)
- Peer на стороне RackNerd: отдельный AmneziaWG-instance на `107.175.35.94:37078`, **не** тот, которым пользуется Timeweb (`:43094`).
- Tunnel-адрес RuWEB-стороны: `10.8.1.6/32`
- MTU: `1376`
- AmneziaWG-параметры RackNerd-стороны (Jc/S/H/I1) отличаются от Timeweb-ingress — не путать.

## Split-routing (sing-box)

- `RU/private` → `ru-direct` (`bind_interface: eth0`, то есть напрямую с `185.11.246.25`)
- `geoip-ru` + `geosite-*-ru` → `ru-direct`
- `gosuslugi.ru`, `gu-st.ru`, `213.59.253.0/24`, `213.59.254.0/24` → `nl-out` (**сейчас stub = eth0**, пока NL не подключён)
- Остальное → `us-out` (через `awg-us` → RackNerd)

> [!warning] gosuslugi
> Через US-IP RackNerd скорее всего не работают. Пока не подключён NL — `gosuslugi.ru` фактически идут как `direct` с IP `185.11.246.25`. Если они там тоже не работают — надо поднимать NL-транзит.

## Failover

- systemd-таймер: `transit-vpn-failover.timer` (`OnBootSec=20s`, `OnUnitActiveSec=30s`)
- Скрипт: `/opt/transit-vpn/host-routing/healthcheck.sh`
- Логика:
  - `us`: проверить latest handshake `awg-us` ≤ 180 с **и** check_active_path → `107.175.35.94`. Если ок — остаёмся в `us`. Иначе → `direct`.
  - `direct`: попробовать handshake → если живой → `us`. Иначе остаёмся в `direct`.
- `check_active_path` — тот же приём, что на Timeweb: veth с хоста в netns контейнера + ip rule + curl через ipify.

Файл состояния: `/opt/transit-vpn/host-routing/current-mode` (`us` / `direct` / отсутствует = ещё не пробовали).

## Где что лежит на сервере

- `/opt/transit-vpn/docker-compose.yml`
- `/opt/transit-vpn/sing-box/config.json`
- `/opt/transit-vpn/amnezia-ingress/data/awg1.conf` — серверный ingress
- `/opt/transit-vpn/amnezia-ingress/clients/` — выданные клиентские конфиги
- `/opt/transit-vpn/transit-us/awg-us.conf` — клиентский конфиг к RackNerd
- `/opt/transit-vpn/amnezia2-image/Dockerfile` — сборка `local/transit-amneziawg2:2026-04-08`
- `/opt/transit-vpn/host-routing/{apply-routes,healthcheck,rollback-routes}.sh`
- `/etc/systemd/system/transit-vpn-failover.{service,timer}`
- `/usr/local/bin/addawguser` — генератор клиентов (Endpoint по умолчанию `185.11.246.25:586`)

## Где что лежит локально

- `/Users/vanya/Documents/VPN/deploy_ruweb_vps.sh` — source-of-truth скрипта деплоя
- `/Users/vanya/Documents/VPN/awg2-client-ruweb.conf` — конфиг первого клиента (`vanya-amnezia` на этом VPS), `192.168.201.2/32`
- `/Users/vanya/Documents/VPN/addawguser` — общий шаблон (Endpoint Timeweb), на RuWEB кладётся версия с другим default-Endpoint
- `/Users/vanya/Downloads/amnezia_config_racknerd_4ruwebvds.vpn` — исходник RackNerd-доступа

## Ingress-пользователи

- `vanya-amnezia` → `192.168.201.2/32`

Адресная сетка та же, что на Timeweb (`192.168.201.0/24`), но **ключи и PSK другие** — клиентский конфиг от Timeweb здесь не подойдёт. Если нужно одно устройство переключать между Timeweb и RuWEB — нужны два разных профиля в AmneziaVPN.

## Как добавить пользователя

```bash
ssh root@185.11.246.25
addawguser bob
```

Выдаст:
- новый peer в `awg1.conf`
- маршрут `192.168.201.x/32 dev awg1` внутри контейнера
- `/opt/transit-vpn/amnezia-ingress/clients/bob.conf` (Endpoint `185.11.246.25:586`)

Если надо сгенерить конфиг с другим Endpoint (например для тестов):

```bash
AWG_ENDPOINT_HOST=other.host addawguser bob
```

## Сломалось — что смотреть

1. `docker ps` — все три контейнера должны быть `Up`.
2. `docker exec transit-awg-us awg show awg-us` — должен быть свежий `latest handshake` и ненулевой `transfer`.
3. `cat /opt/transit-vpn/host-routing/current-mode` — `us` если egress в порядке, `direct` если упал.
4. `journalctl -u transit-vpn-failover.service -n 30` — лог последних healthcheck.
5. `/opt/transit-vpn/host-routing/healthcheck.sh` — прогнать вручную.
6. `docker logs --tail 50 transit-sing-box` — sing-box-side ошибки.

## Известные ограничения

- `awg-quick up` не работает в shared-netns режиме из-за `sysctl: Read-only file system` — поэтому в `transit-us` сделан ручной набор команд, повторяющий awg-quick, минус sysctl. Менять — аккуратно.
- `awg setconf` не понимает awg-quick'овские директивы (`Address`, `MTU`, `DNS`), поэтому в скрипте поднятия эти строки фильтруются через `grep -v`.
- RAM в обрез: даже `1G swap` не страховка от OOM, если кто-то параллельно начнёт build go-образа во время рантайма. Не апгрейдить compose-стек на этом VPS под нагрузкой.

## Что ещё можно сделать

- Подключить NL-транзит (когда появится RackNerd NL-инстанс). Заменить `nl-out` outbound на second AmneziaWG-контейнер по схеме `transit-awg-us`, поправить healthcheck на двойную проверку.
- Поднять plain WG/585 ingress, если нужен legacy-клиент без AmneziaWG.
- Поставить мониторинг handshake-возраста (Prometheus node_exporter + textfile из `awg show`).

## Связанные заметки

- [[Timeweb_VDS]]
- [[Timeweb_Transit_VPN_System]]
- [[Timeweb_Transit_VPN_Progress]]
- [[MOC_Projects]]
- [[01_Projects/VPN/RackNerd/Secrets]]
