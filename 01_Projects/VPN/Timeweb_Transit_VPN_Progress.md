# Timeweb Transit VPN — Progress

## Goal

Построить на Timeweb VDS транзитную VPN-схему:
- вход через AmneziaWG / AmneziaVPN
- outbound primary через US WireGuard
- outbound backup через второй WireGuard
- для клиентского трафика:
  - RU/local/private → direct
  - остальное → primary WG
  - если primary down → backup WG
  - если backup down → direct

При этом нельзя сломать существующие сервисы:
- TG_Business
- KayakMoscow
- Caddy
- существующий host-level `awg-split`

## Что уже сделано

### Исследование сервера
- Подтверждён доступ по SSH
- Собрана информация по ОС, Docker, сетям, Caddy, контейнерам
- Выявлено, что на хосте уже есть старый `awg-split` для части AI/Cloudflare/AWS/Google трафика

### Existing production baseline
Проверено, что работают:
- `n8n.x-citrus.ru`
- `admin.kayakmoscow.com`
- `n8n.kayakmoscow.com`
- контейнеры TG_Business и KayakMoscow

### Новый staging-контур
Создан каталог:
- `/opt/transit-vpn`

Подготовлены:
- backups существующих wireguard/amnezia конфигов
- `wg-primary`
- `wg-backup`
- `amnezia-ingress/` (staging)
- `host-routing/` (staging)

### Outbound WG verified
Подняты и проверены:
- `transit-wg-primary`
- `transit-wg-backup`

Подтверждён egress:
- primary → `107.175.35.94`
- backup → `178.208.88.56`

### Safety checks
После запуска новых WG-контейнеров перепроверено:
- prod-сервисы отвечают штатно
- host routing не сломан
- существующие контейнеры живы

## Текущий статус

### Уже готово
- изолированные outbound primary/backup WG работают
- подготовлены host-routing scripts (staging only)
- compose приведён к честному минимальному виду

### Ещё не сделано
- ingress AmneziaWG не поднят
- host-side policy routing не применён
- failover не включён
- клиентский subnet ещё не маршрутизируется

## Важный инженерный вывод

Следующий шаг уже потенциально влияет на реальный трафик.
Безопасная подготовка завершена.
Дальше нужны точечные state-changing действия:
- применение host-side policy routing для нового client subnet
- или запуск ingress + последующее связывание с routing

## Артефакты на сервере
- `/opt/transit-vpn/docker-compose.yml`
- `/opt/transit-vpn/README.md`
- `/opt/transit-vpn/wg-primary/wg_confs/wg0.conf`
- `/opt/transit-vpn/wg-backup/wg_confs/wg0.conf`
- `/opt/transit-vpn/host-routing/apply-routes.sh`
- `/opt/transit-vpn/host-routing/rollback-routes.sh`
- `/opt/transit-vpn/host-routing/failover.sh`
- `/opt/transit-vpn/amnezia-ingress/`

## Recommendation

Продолжать дальше по шагам с явным подтверждением перед любым действием, которое уже может повлиять на маршрут реального трафика.
