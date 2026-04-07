# TG_Business — Infrastructure on Timeweb VDS

## Docker stack

Расположение:
- `/opt/tg-business/docker-compose.yml`
- `/opt/tg-business/.env`

Сервисы:
- `tg-business-postgres-1` — кастомный образ `tg-business-postgres`
- `tg-business-n8n-1` — `n8nio/n8n:latest`

Docker network:
- `tg-business_n8n-network`

## Порты

- `5678` → n8n
- Postgres наружу не опубликован

## Домены / edge

Через Caddy:
- `n8n.x-citrus.ru` → `localhost:5678`

## Особенность Postgres-образа

Используется кастомный `Dockerfile.postgres`, который собирает `pgvector` поверх `postgres:16-alpine`.

Это намекает, что проекту нужен vector search / embeddings / похожие фичи внутри Postgres.

## Файлы в каталоге проекта

В `/opt/tg-business` лежат:
- `.env`
- `docker-compose.yml`
- `Dockerfile.postgres`
- `backup_20260221.sql`
- `check_database.sql`
- `backups/`
- `scripts/`
- `n8n_data/`
- `postgres_data/`

## Наблюдения

- n8n работает давно и стабильно по uptime контейнера
- В логах есть ошибки вида `WebSocket connection is missing` в chat-related flow/endpoint
- Возможно, часть n8n/chat-функций ожидает websocket/realtime-сессию и работает не во всех сценариях корректно
- Также сервис открыт не только через Caddy, но и напрямую на `5678`

## Что стоит проверить позже

- нужен ли прямой внешний доступ к `5678`, если есть Caddy
- как именно используется `pgvector`
- нужен ли отдельный backup policy для `backup_20260221.sql` и `backups/`
- какие n8n workflows сейчас завязаны на chat/websocket поведение
