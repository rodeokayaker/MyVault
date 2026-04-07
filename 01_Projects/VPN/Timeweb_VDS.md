# Timeweb VDS

## Доступ

- IP: `176.124.208.237`
- Hostname: `6577929-wl260063.twc1.net`
- User: `root`
- SSH key: `~/.openclaw/ssh/timeweb_vds_ed25519`
- Public key label: `openclaw-timeweb-vds`

## Базовая информация

- Провайдер/VDS: Timeweb
- ОС: `Ubuntu 24.04.3 LTS`
- Kernel: `6.8.0-100-generic`
- Виртуализация: KVM
- CPU: `2 vCPU`
- RAM: `3.8 GiB`
- Swap: нет
- Disk: `~48G ext4`, занято около `20%`
- Uptime на момент обследования: `56+ дней`

## Сетевое состояние

- Публичный адрес на `eth0`: `176.124.208.237/24`
- Дефолтный шлюз: `176.124.208.1`
- Открытые наружу сервисы:
  - `22/tcp` — SSH
  - `80/tcp` — Caddy
  - `443/tcp+udp` — Caddy
  - `5678/tcp` — n8n (TG_Business)
  - `5679/tcp` — n8n (Kayak)
  - `8055/tcp` — Directus (Kayak)
  - `10050/tcp` — Zabbix agent
  - `53/tcp+udp` — dnsmasq слушает на `0.0.0.0`
- Docker bridge сети:
  - `kayak-network` → `172.19.0.0/16`
  - `tg-business_n8n-network` → `172.18.0.0/16`

## Уже найденные VPN/маршрутизация артефакты

На сервере уже есть следы старой/черновой split-конфигурации:

- интерфейс `awg-split` с адресом `10.8.1.30/32`
- установлен `dnsmasq`
- есть сервис `awg-quick@.service`
- файл: `/etc/amnezia/amneziawg/awg-split.conf`
- файл: `/etc/wireguard/wg-split.conf`
- файл: `/etc/wireguard/wg0.conf`

### Что видно по конфигам

- `wg0.conf` — full-tunnel WireGuard (`AllowedIPs = 0.0.0.0/0, ::/0`)
- `wg-split.conf` — частичный tunnel по спискам сетей (Cloudflare/AWS/Google)
- `awg-split.conf` — AmneziaWG-вариант split tunnel с тем же общим замыслом
- endpoint в этих конфигах указывает на `178.208.88.56`, но сами секреты не переносились в заметки
- сервис `awg-quick@awg-split` сейчас **inactive**

## Reverse proxy / web edge

Используется **Caddy**.
В Caddy настроены домены:

- `n8n.x-citrus.ru` → `localhost:5678` (TG_Business)
- `admin.kayakmoscow.com` → `localhost:8055` (Kayak Directus)
- `n8n.kayakmoscow.com` → `localhost:5679` (Kayak n8n)

Для доменов `kayakmoscow.com` используется DNS challenge через Cloudflare.

## Наблюдения / риски

- На сервере нет swap
- `dnsmasq` слушает глобально на `53`, это надо учесть перед новой VPN-схемой
- Порты `5678`, `5679`, `8055` открыты напрямую наружу через docker-proxy, хотя поверх уже стоит Caddy
- Значит перед новой сетевой схемой полезно решить: оставить ли прямой доступ на эти порты или закрыть и пускать только через reverse proxy
- Транзитный VPN лучше поднимать **в Docker**, как и планируется, но надо аккуратно увязать его с уже существующими контейнерами и policy routing

## Назначение

Промежуточный узел для схемы:
- вход через AmneziaVPN
- выход через WireGuard в США
- policy routing / split tunneling:
  - трафик на российские сервисы напрямую
  - остальной трафик через US VPN

## Практический вывод

Сервер подходит для роли VPN-транзита, но на нём уже есть рабочая проектная нагрузка (Kayak + TG_Business), поэтому сетевые изменения надо делать поэтапно и желательно без ломания текущего Caddy/Docker контура.
