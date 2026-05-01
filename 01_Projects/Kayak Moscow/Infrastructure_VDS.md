---
created: 2026-04-07
updated: 2026-05-01
type: reference
project: KayakMoscow
status: active
tags: [kayakmoscow, infrastructure, vds, docker, timeweb]
---

# Infrastructure — Timeweb VDS

Timeweb VDS `176.124.208.237` — общая инфраструктура для ERP, n8n и Ads Automation. Не путать с хостингом сайта `kayakmoscow.ru` (он на shared hosting под ISP Manager — см. [[Site]]).

## Docker stack

Расположение:
- `/root/kayak/docker-compose.yml`
- `/root/kayak/.env`

Сервисы:
- `kayak-postgres` — `postgres:16-alpine`
- `kayak-directus` — `directus/directus:latest`
- `kayak-n8n` — `n8nio/n8n:latest`

Docker network:
- `kayak-network`

Volumes:
- `kayak_kayak_postgres_data`
- `kayak_kayak_directus_uploads`
- `kayak_kayak_n8n_data`

## Порты

- `8055` → Directus
- `5679` → n8n
- Postgres наружу не опубликован

## Домены / edge

Через Caddy проброшены:
- `admin.kayakmoscow.com` → `localhost:8055`
- `n8n.kayakmoscow.com` → `localhost:5679`

TLS для этих доменов делается через Cloudflare DNS challenge.

Дополнительно (Ads Automation, см. [[Ads_Automation]]):
- `direct.kayakmoscow.com` → `kayak-ads-web:8090`
- `n8n-ads.kayakmoscow.com` → `kayak-ads-n8n:5680`

## Конфигурация приложения

По compose видно:
- база Directus: `kayak_moscow`
- пользователь БД: `kayak`
- n8n тоже ходит в Postgres
- timezone: `Europe/Moscow`
- у Directus выключена telemetry
- у Directus включён `LOG_LEVEL=debug`
- у n8n включён basic auth
- у n8n включён prune старых execution data

## Файлы проекта

В каталоге `/root/kayak` лежат:
- `.env`
- `docker-compose.yml`
- `schema.sql`

## Наблюдения

- Сервисы выглядят живыми: Postgres healthy, Directus и n8n работают
- Directus логирует в основном рутинные GET-запросы (`/robots.txt`, `/admin`)
- Directus и n8n открыты не только через Caddy, но и напрямую наружу по `8055` и `5679`
- Это стоит учитывать при дальнейшем харднинге

## Что стоит проверить позже

- нужен ли Directus `debug` log level на проде
- нужен ли прямой внешний доступ к `8055/5679`, если уже есть Caddy
- не пора ли закрепить версии образов вместо `latest`

## Связанные заметки

- [[KayakMoscow]] — родительский хаб
- [[Ads_Automation]] — наши контейнеры `kayak-ads-engine`/`kayak-ads-web`/`kayak-ads-n8n` в этой же сети
- [[SYSTEM_snapshot_2026-05-01]] — полная карта системы для disaster recovery
- [[ERP]] — общий стек ERP
- [[Site]] — для сравнения: хостинг `kayakmoscow.ru` (отдельный, не этот VDS)
