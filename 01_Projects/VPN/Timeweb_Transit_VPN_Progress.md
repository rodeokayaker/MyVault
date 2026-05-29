---
type: project-note
status: active
tags: [project, project/vpn]
updated: 2026-05-29
---

# Timeweb Transit VPN — Progress

## Status

Состояние: `done / operational`.

Актуально на `2026-05-29`.

Система в рабочем состоянии и сейчас состоит из двух слоев:
- transit VPN для split-routing и egress failover
- ingress VPN для пользовательских подключений по `WG` и `AmneziaWG 2.0`

Текущая логика маршрутизации:
- `RU/private` -> `direct`
- `gosuslugi` -> `NL`
- остальное -> `US`
- failover: `US -> NL -> direct`

Текущий runtime-режим:
- `current-mode = us`

## Update 2026-05-29

Проблема:
- Google / NotebookLM перестали видеть подключение как `US`.
- Transit-stack ушел в failover-режим `NL`.

Диагностика:
- `current-mode` был `nl`.
- `sing-box route.final` был `nl-out`.
- e2e через transit показывал `178.208.88.56`, `NL / Amsterdam`.
- US egress `107.175.35.94:43094` на [[01_Projects/VPN/RackNerd/Secrets|RackNerd]] был жив, `amnezia-wireguard` работал, peer Timeweb был в конфиге.
- На Timeweb завис probe-контейнер `transit-wg-primary`: `wg show` показывал `0 B received`, handshake не поднимался.

Что сделано:
- перезапущен `transit-wg-primary` на Timeweb;
- после restart появился свежий WireGuard handshake с `107.175.35.94:43094`;
- выполнен возврат active route на `US` через `/opt/transit-vpn/host-routing/apply-routes.sh us`;
- live `/opt/transit-vpn/host-routing/healthcheck.sh` обновлен: если probe-контейнер не проходит проверку, healthcheck один раз делает `docker restart "$container"` и повторяет проверку;
- локальный source-of-truth `/Users/vanya/Documents/VPN/deploy_transit_rework.sh` обновлен тем же retry/restart behavior.

Проверено после восстановления:
- `current-mode = us`;
- `sing-box route.final = us-out`;
- `transit_e2e_test.sh https://api.ipify.org` -> `107.175.35.94`;
- `ipinfo.io` -> `US / Buffalo, New York`;
- `transit-vpn-failover.service` несколько раз подряд вернул `us`.

## Что в итоге сделано

- поднят отдельный стек в `/opt/transit-vpn`
- ingress переведен с legacy `metaligh/amneziawg` на полноценный `AmneziaWG 2.0` runtime
- собран и используется кастомный образ:
  - `local/transit-amneziawg2:2026-04-08`
- ingress сейчас принимает:
  - `WG` на `UDP 585`
  - `AmneziaWG 2.0` на `UDP 586`
- data plane и split-routing реализованы через `sing-box`
- egress-схема:
  - `US` primary
  - `NL` backup
  - `direct` emergency fallback
- для `gosuslugi` добавлено отдельное исключение через `NL`
- установлен server-side utility:
  - `/usr/local/bin/addawguser`
- скрипт `addawguser`:
  - создает нового peer
  - выбирает следующий IP
  - добавляет peer в `awg1.conf`
  - делает `syncconf`
  - добавляет обратный маршрут
  - сохраняет клиентский конфиг

## Что подтверждено тестами

- обычный внешний трафик клиента выходит через `US`
- `RU/private` не уходит в `US`
- `gosuslugi.ru` и `esia.gosuslugi.ru` работают через отдельный `NL`-route
- failover `US -> NL -> direct` работает
- после инцидента `2026-05-29` US egress восстановлен и снова дает `107.175.35.94`
- старый `WG` ingress на `585/udp` после миграции не сломан
- новый полный `AmneziaWG 2.0` ingress на `586/udp` работает с:
  - `Jc/Jmin/Jmax`
  - `S1/S2/S3/S4`
  - `H1/H2/H3/H4`
  - `I1`
- `addawguser` протестирован на пользователе `baga`
- `baga`-конфиг поднят и дал внешний IP `107.175.35.94`

## Активные ingress-пользователи

На `2026-04-08` в `awg1` заведены:
- `vanya-amnezia` -> `192.168.201.2/32`
- `phone_vanya` -> `192.168.201.3/32`
- `natalie_comp` -> `192.168.201.4/32`
- `natalie_phone` -> `192.168.201.5/32`
- `baga` -> `192.168.201.6/32`

Старый отдельный `WG`-клиент на `awg0` сохранен как отдельный ingress-контур.

## Где лежит главное

На сервере:
- `/opt/transit-vpn/docker-compose.yml`
- `/opt/transit-vpn/sing-box/config.json`
- `/opt/transit-vpn/amnezia-ingress/data/awg0.conf`
- `/opt/transit-vpn/amnezia-ingress/data/awg1.conf`
- `/opt/transit-vpn/amnezia-ingress/clients/`
- `/opt/transit-vpn/amnezia2-image/Dockerfile`
- `/usr/local/bin/addawguser`
- `/opt/transit-vpn/host-routing/apply-routes.sh`
- `/opt/transit-vpn/host-routing/healthcheck.sh`
- `/opt/transit-vpn/host-routing/current-mode`

Локально:
- `/Users/vanya/Documents/VPN/deploy_transit_rework.sh`
- `/Users/vanya/Documents/VPN/amnezia2.Dockerfile`
- `/Users/vanya/Documents/VPN/addawguser`
- `/Users/vanya/Documents/VPN/remote_awg2_conf_test.sh`

## Как пользоваться

Добавить нового пользователя на сервере:

```bash
addawguser some_user
```

Что получится:
- новый peer в `awg1`
- новый маршрут `192.168.201.x/32 dev awg1`
- клиентский конфиг в:
  - `/opt/transit-vpn/amnezia-ingress/clients/some_user.conf`

## Важные ограничения и замечания

- один конфиг нельзя безопасно ставить на несколько устройств
- одно устройство = один peer = один `PrivateKey`
- `gosuslugi` с direct через `Timeweb` IP не работают, поэтому для них отдельный route через `NL`
- старый host-level `awg-split` не трогать без отдельной причины

## Детальное описание

Полный runbook и системное описание:
- `[[Timeweb_Transit_VPN_System]]`

## Related Notes

- `[[Timeweb_VDS]]`

## Связанные заметки
- [[MOC_Projects]]
- [[01_Projects/VPN/RackNerd/Secrets]]
- [[01_Projects/VPN/Timeweb_Transit_VPN_System]]
- [[01_Projects/VPN/Timeweb_VDS]]
