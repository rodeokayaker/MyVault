---
created: 2026-05-08
updated: 2026-05-08
type: snapshot
project: KayakMoscow
status: reference
tags: [kayakmoscow, ads, automation, disaster-recovery, snapshot]
parent: "[[Ads_Automation]]"
source: rodeokayaker/kayakmoscow-ads/docs/SYSTEM.md
source_commit: 0c94458 + локальные правки 2026-05-08 (ещё не закоммичены)
---

# SYSTEM snapshot 2026-05-08 — Kayak Moscow Ads Automation

> Снапшот `docs/SYSTEM.md` на 2026-05-08 после внедрения runtime UI и per-campaign стратегий. Заменяет [[SYSTEM_snapshot_2026-05-01]] (тот делался по версии fd95bcc, без Runtime UI).

# SYSTEM.md — полное описание Kayak Moscow Ads Automation

Дата актуальности: 2026-05-08 (последний коммит `0c94458`).
Назначение: единственный документ, по которому можно полностью восстановить систему, если репо/инфра/ноутбук — всё стёрто. Здесь нет секретов в открытом виде, но указано, где они физически живут.

Если файл и репо есть, всё восстанавливается за **~30 минут**. Если стёрто всё, кроме Cloudflare и Yandex учёток, — за **~3-4 часа** с прохождением OAuth-флоу.

---

## 1. Что это за система

Внутренний сервис ИП Рыбников И.Г. (ИНН 772861688006), автоматизирующий рекламные кампании Kayak Moscow в Яндекс Директе. Не публичный, не SaaS, не API для третьих лиц. Работает на одном рекламном кабинете `kayakmoscow@yandex.ru`.

**Что делает:**

1. **Hourly bid loop (per-campaign).** Раз в час пересчитывает погодный индекс по прогнозу Open-Meteo и обновляет `MobileAdjustment` BidModifier'ы у целевых AdGroup'ов в Direct. С 2026-05-07 — per-campaign: каждая кампания имеет свою стратегию в `ads_campaign_strategy` со своей кривой и target ad-group'ами. Двух-режимная кривая (будни/выходные), редактируется через UI.
2. **Daily negatives pipeline.** Раз в сутки тянет `SEARCH_QUERY_PERFORMANCE_REPORT` за 7 дней (с `CampaignId`), прогоняет через OpenAI (gpt-4o-mini), сохраняет кандидатов в БД со статусом `pending`. Применение в Direct идёт **только** после ручного approval оператором в дашборде (`/dashboard/negatives`).
3. **Daily Telegram digest.** Раз в сутки шлёт HTML-сводку в Telegram-чаты команды.
4. **Public dashboard** — `https://direct.kayakmoscow.com` с landing, privacy policy 152-ФЗ, terms, contacts + Yandex OAuth login + защищённые страницы:
   - `/dashboard` — сводка статуса
   - `/dashboard/settings` — тогглы и cron-пресеты для всех 3 джобов (читаются из БД через `RuntimeConfig`)
   - `/dashboard/campaigns` — список из Direct + статус привязанных стратегий
   - `/dashboard/campaigns/{id}/strategy` — редактор per-campaign кривой и target ad-group'ов
   - `/dashboard/decisions` — журнал hourly-bid решений с фильтром по кампании
   - `/dashboard/weather` — индекс + сырые поля прогноза + per-campaign превью ставки
   - `/dashboard/negatives` — approval flow для минус-слов

Все мутации в Direct API проходят через жёсткие guardrails (см. § 11).

**Сезонность бизнеса:** июнь-август пик; май-октябрь сезон. Сервис работает круглый год, в межсезонье daily-задачи продолжают идти.

---

## 2. Карта системы (физическая)

```
                  ┌────────────────────────────────────────┐
                  │ Yandex                                 │
                  │  • Direct API (sandbox/prod)           │
                  │  • Audiences API                       │
                  │  • Metrika (счётчик 49922815)          │
                  │  • Yandex ID (OAuth для пользователей) │
                  │  • Yandex Weather (сейчас не исп.)     │
                  └──┬───────────────────┬──────────────┬──┘
                     │                   │              │
                ┌────┴────┐         ┌────┴────┐    ┌────┴───┐
                │OpenAI   │         │Telegram │    │Open-   │
                │(gpt-4o- │         │Bot API  │    │Meteo   │
                │mini)    │         │         │    │(forecast│
                │         │         │         │    │+archive)│
                └────┬────┘         └────┬────┘    └────┬───┘
                     │                   │              │
                     ▼                   ▼              ▼
   ┌─────────────────────────────────────────────────────────┐
   │ VDS Timeweb 176.124.208.237 (Ubuntu, 4GB RAM, 50GB)     │
   │                                                         │
   │ host: Caddy (80/443, SSL via Cloudflare DNS-01)         │
   │   • admin.kayakmoscow.com → Directus :8055              │
   │   • n8n.kayakmoscow.com → kayak-n8n :5679 (ERP)         │
   │   • direct.kayakmoscow.com → kayak-ads-web :8090        │
   │   • n8n-ads.kayakmoscow.com → kayak-ads-n8n :5680       │
   │                                                         │
   │ Docker network: kayak-network                           │
   │   • kayak-postgres (БД kayak_moscow + kayak_ads)        │
   │   • kayak-directus (общий с ERP)                        │
   │   • kayak-n8n (ERP, не наш)                             │
   │   • kayak-ads-engine (scheduler)        ← наш           │
   │   • kayak-ads-web (FastAPI uvicorn)     ← наш           │
   │   • kayak-ads-n8n (n8n для рекламы)     ← наш           │
   │                                                         │
   │ /root/kayak-ads/                                        │
   │   ├── deploy/docker-compose.yml                         │
   │   ├── deploy/.env (секреты, chmod 600)                  │
   │   └── deploy/.n8n.env                                   │
   └──┬──────────────────────────────────────────────────────┘
      │
      ▼ (HTTPS, Yandex OAuth, операторы команды)
   ┌──────────────┐
   │  Командa     │
   │ • Ivan       │ — kayakmoscow (whitelist)
   │ • маркетолог │ — будет добавлен
   │ • директор   │ — будет добавлен
   │ • Я.модератор│ — добавляется по запросу при ревью
   └──────────────┘
```

---

## 3. Внешние сервисы и где живут учётки

**Yandex (учётка `kayakmoscow@yandex.ru`):**
- Direct API: OAuth-приложение `8de9aec8dbe74ae883b4d72028160d36` на oauth.yandex.ru.
  - Scopes: `direct:api`, `metrika:read`, `metrika:write`.
  - Callback: `https://direct.kayakmoscow.com/oauth/callback`, `https://oauth.yandex.ru/verification_code`.
  - Sandbox активирован, mass-token хранится в самой UI Direct'а.
  - Боевой API: **заявка ещё не подана** на 2026-04-28.
- Метрика, счётчик `49922815`.
- Direct UI: direct.yandex.ru.

**Cloudflare (домен `kayakmoscow.com`):**
- Зона: `c92881d1c3af0e830cb705923cf87f88`.
- API token (DNS-01): хранится в `KayakMoscow_ERP/Docs/credentials.local.md`, также установлен в `/etc/systemd/system/caddy.service.d/cloudflare.conf` как env var `CLOUDFLARE_API_TOKEN`.
- A-записи для нашего сервиса: `direct` и `n8n-ads` → `176.124.208.237`, оба `proxied=false`.

**Timeweb VDS:**
- IP: `176.124.208.237`, root SSH доступ.
- Deploy key добавлен на GitHub (id 149783452).
- Resources: 2×3.3GHz CPU, 4GB RAM, 50GB NVMe + swap 2GB.

**OpenAI:**
- ключ задаётся в `.env` (`OPENAI_API_KEY`); пока не установлен на VDS, поэтому daily_negatives_job не запускается.
- модель: `gpt-4o-mini` (дешёвая, ~$0.15 за 1M input tokens).
- бюджет: до $50/мес.

**Telegram:**
- Bot: `@kayakmoscowads_bot`, токен `8271201222:AAFuqVRsdm-p1llfmmXel86i-JEIFawmrWE`, в `.env` как `TELEGRAM_BOT_TOKEN`.
- Получатели: пока только Ivan `121329929`. Маркетолог + директор продаж — добавятся.

**Tinkoff** (для M5):
- Эквайринг архив за 2024-05-01..2026-04-01 (~2 743 confirmed платежа) лежит в `Archive/Эквайринг Архив/` локально (gitignored).

**Open-Meteo:**
- Бесплатное API без ключа.
- Forecast: `https://api.open-meteo.com/v1/forecast` (до 16 дней).
- Archive: `https://archive-api.open-meteo.com/v1/archive` (с 1940 года).
- Координаты: центр Москвы 55.7558 / 37.6173.

**GitHub:**
- Репо: `rodeokayaker/kayakmoscow-ads` (private).
- Owner: `rodeokayaker`.
- Deploy key с VDS: read-only.

**1С-Битрикс:**
- Сайт `kayakmoscow.ru` крутится на Bitrix CMS (хостинг отдельный, не наш VDS).
- Метрика установлена в шаблон.
- Доступ — у Ivan'a.

---

## 4. Локальная карта (на ноутбуке Ivan'а)

```
/Users/vanya/Documents/
├── KayakMoscow_marketing/    ← маркетинг-стратегия и research
│   ├── Business/
│   ├── Research/             ← кампания 2026, paid platforms, direct automation
│   └── CLAUDE.md             ← project instructions
├── KayakMoscow_ERP/          ← базовый ERP (бронирования, ERP-боты)
│   ├── Docs/credentials.md          ← все секреты (gitignored .local)
│   ├── .env.local                   ← рабочие секреты
│   └── AGENTS.md
├── KayakMoscow_ads/          ← ЭТОТ репо (наш сервис)
│   ├── ads_engine/           ← Python-пакет
│   ├── alembic/              ← миграции БД
│   ├── analysis/
│   │   ├── output/           ← gitignored, CSV-выгрузки калибровки
│   │   └── weather_demand_correlation.md  ← фактический отчёт
│   ├── Archive/              ← gitignored, исходные xlsx-данные
│   │   ├── money_2022..2025.xlsx
│   │   └── Эквайринг Архив/  ← Tinkoff отчёты
│   ├── config/weather_bid_policy.yaml  ← кривая коэффициентов
│   ├── deploy/               ← Dockerfile + compose + Caddy snippet
│   ├── docs/                 ← живые документы (см. § 16)
│   ├── scripts/              ← калибровочные скрипты (одноразовые)
│   ├── tests/                ← 240+ тестов
│   ├── .env.local            ← gitignored, рабочие секреты
│   ├── pyproject.toml
│   └── req.txt               ← gitignored, юр.реквизиты ИП
├── KayakMoscow_research/     ← старый research, не наш
└── KayakMoscow_site/         ← заметки про сайт
```

**Что критично сохранять:**
- `.env.local` файлы (секреты).
- `KayakMoscow_ads/Archive/` (исходные данные для калибровок — потерять можно, можно перевыгрузить из Tinkoff и Excel-таблиц).
- `req.txt` (юр.реквизиты).

Всё остальное в `KayakMoscow_ads/` восстанавливается из git.

---

## 5. Секреты — где живут

**Не в этом файле.** Только указатели:

| Секрет | Где живёт |
|---|---|
| `DIRECT_OAUTH_CLIENT_SECRET` | `KayakMoscow_ERP/.env.local`, `KayakMoscow_ads/.env.local`, VDS `/root/kayak-ads/deploy/.env` |
| `DIRECT_OAUTH_TOKEN` (sandbox) | те же три места |
| `DATABASE_URL` (DB password) | те же |
| `DASHBOARD_SESSION_SECRET` | VDS `.env` (генерируется заново при восстановлении) |
| `TELEGRAM_BOT_TOKEN` | те же |
| `OPENAI_API_KEY` | пока не установлен; ключ создаётся на platform.openai.com |
| `CLOUDFLARE_API_TOKEN` | VDS `/etc/systemd/system/caddy.service.d/cloudflare.conf` + `KayakMoscow_ERP/Docs/credentials.local.md` |
| `KAYAK_DB_PASSWORD` (Postgres) | VDS `/root/kayak/.env` (общий kayak-postgres) |

Бэкап критичных секретов — копия `KayakMoscow_ERP/Docs/credentials.local.md` в 1Password / Bitwarden.

---

## 6. БД `kayak_ads` (Postgres 16, разделяет контейнер `kayak-postgres`)

Таблицы (все с префиксом `ads_`):

### 6.1. `ads_sync_log` (миграция `4aa83d21c30f`)

Аудит всех мутаций во внешние API.

```
id                bigserial PK
created_at        timestamptz default now()
api_env           varchar(16) not null      -- sandbox/prod
service           varchar(64) not null      -- campaigns/ads/bidmodifiers/...
method            varchar(64) not null      -- add/update/get/...
params_hash       varchar(64) not null      -- SHA256 от sorted JSON
request_id        varchar(64)               -- от Direct API
result_code       varchar(32) not null      -- ok/error/timeout
error_code        integer
error_message     varchar(2048)
units_consumed    integer
units_available   integer
duration_ms       integer
params_preview    jsonb                     -- truncated payload
```

### 6.2. `ads_weather_snapshot` (`4aa83d21c30f`)

Почасовой архив погоды для каждой базы.

```
id              bigserial PK
fetched_at      timestamptz
hour_time       timestamp not null          -- на какой час прогноз
location_key    varchar(32) not null        -- strogino/arkhangelskoe/meduza
latitude        float
longitude       float
temperature_c   float
precipitation_mm float
cloud_cover_pct float
weather_index   float
UNIQUE(location_key, hour_time, fetched_at)
INDEX(location_key, hour_time)
```

### 6.3. `ads_bid_experiment_decisions` (`ada573c74e15`)

Журнал hourly-bid решений.

```
id                       bigserial PK
created_at               timestamptz default now()
api_env                  varchar(16)
target_kind              varchar(16)        -- ad_group/campaign
target_id                bigint
decision_hour            timestamp
weekday                  smallint           -- 0=Mon..6=Sun
is_weekend               boolean
today_index              float
next_weekend_index       float
combined_x               float              -- sqrt(today*weekend) по умолч.
matched_lower            float              -- нижняя граница попавшего бина
raw_coefficient_pct      integer            -- из кривой
final_coefficient_pct    integer            -- после caps
capped                   boolean
previous_coefficient_pct integer            -- что было до апдейта
applied                  boolean
skip_reason              varchar(64)        -- below_threshold/api_error:X/...
sync_log_id              bigint             -- FK to ads_sync_log
policy_version           varchar(64)        -- хэш/тег конфига кривой
INDEX(target_kind, target_id, decision_hour)
INDEX(created_at)
```

### 6.4. `ads_negative_candidates` (`2901a31266ee` + `7dba2eceabc7`)

Кандидаты в минус-слова, оцененные LLM. Поля `campaign_id` и `decision` добавлены 2026-05-07 в миграции `7dba2eceabc7`.

```
id                      bigserial PK
created_at              timestamptz default now()
api_env                 varchar(16)
report_period_from      timestamp
report_period_to        timestamp
campaign_id             bigint                  -- из Reports, nullable для старых строк
query_text              varchar(1024) not null
impressions             integer
clicks                  integer
label                   varchar(16)             -- relevant/trash/unclear (LLM)
minus_phrase            varchar(512)            -- предложение LLM (с операторами)
reason                  varchar(512)            -- объяснение LLM
llm_model               varchar(64)
decision                varchar(16) default 'pending'  -- pending/approved/rejected (оператор)
applied                 boolean default false   -- True после реального push'a в Direct
applied_at              timestamptz             -- момент approve в дашборде
applied_to_campaign_id  bigint
sync_log_id             bigint
UNIQUE(api_env, report_period_from, report_period_to, query_text)
INDEX(decision)
```

### 6.5. `ads_runtime_settings` (`bf3e24766039`, добавлена 2026-05-07)

Горячие настройки сервиса (key/value), читаются через `ads_engine.runtime_config.RuntimeConfig` с TTL-кэшем 30 сек. Менять можно из дашборда без рестарта контейнера.

```
key              varchar(64) PK
value            text not null
updated_at       timestamptz default now()
updated_by_login varchar(128)               -- yandex login оператора
```

Известные ключи (см. `ads_engine/runtime_config.py`):
- `hourly_bid.enabled` (bool), `hourly_bid.cron_preset` (`hourly`/`every_30m`/`every_2h`)
- `daily_negatives.enabled`, `daily_negatives.cron_preset` (`daily_03`/`daily_06`/`weekly_mon_03`)
- `daily_digest.enabled`, `daily_digest.cron_preset` (`daily_09`/`daily_18`/`twice_daily`)

Все стартуют выключенными — после деплоя нужно зайти в `/dashboard/settings` и включить.

### 6.6. `ads_campaign_strategy` (`04abb30f16e0`, добавлена 2026-05-07)

Per-campaign конфиг hourly bid loop. Одна строка = одна кампания Direct.

```
campaign_id          bigint PK              -- ID кампании в Direct
name                 varchar(255)           -- человекочитаемое имя
enabled              boolean default false
target_ad_group_ids  jsonb                  -- массив int'ов: к каким ad-group'ам применять
policy_json          jsonb not null         -- combiner + curve (weekday/weekend бины) + caps + apply_threshold
updated_at           timestamptz default now()
updated_by_login     varchar(128)
```

`policy_json` — структура та же, что в `config/weather_bid_policy.yaml`, валидируется через `WeatherBidPolicy.from_dict` при upsert. YAML остаётся как **дефолтная база** при первом seed'инге и для джобов, не привязанных к стратегии (digest).

### 6.7. `alembic_version`

Текущая ревизия миграций. На 2026-05-08: `7dba2eceabc7`. Полная цепочка:
`4aa83d21c30f` → `ada573c74e15` → `2901a31266ee` → `bf3e24766039` → `04abb30f16e0` → `7dba2eceabc7`.

### 6.8. Бэкап БД

Бэкап `kayak-postgres` входит в общий механизм ERP (`KayakMoscow_ERP/Docs/phase0_*` — там описано). Конкретно `kayak_ads`:

```
docker exec kayak-postgres pg_dump -U kayak kayak_ads > kayak_ads_$(date +%Y%m%d).sql
```

Восстановление:

```
docker exec -i kayak-postgres psql -U kayak -d kayak_ads < dump.sql
```

---

## 7. Структура кода (`ads_engine/`)

```
ads_engine/
├── __init__.py                 версия 0.1.0
├── config.py                   pydantic-settings; читает .env / окружение (только секреты + неизменная инфра)
├── runtime_config.py           RuntimeConfig + ключи + cron-пресеты (горячие настройки из БД)
├── auth.py                     OAuth URL builders для Direct (CLI helper)
├── cli.py                      typer; команды: health, auth url, campaigns list, ...
├── scheduler.py                APScheduler entry; soft-toggle через RuntimeConfig + _config_reload каждую минуту
│
├── direct_client/              Yandex Direct API v5/v501 транспорт
│   ├── client.py               DirectClient (httpx + rate limit + Units guard)
│   ├── errors.py               DirectAPIError / DirectAuthError / RateLimitedError / ...
│   └── services/
│       ├── base.py             BaseService
│       ├── campaigns.py        UNIFIED_CAMPAIGN (v501) + helpers стратегий
│       ├── ad_groups.py        ЕПК-группы (v501)
│       ├── ads.py              TextAd
│       ├── bid_modifiers.py    Mobile/Demographic/Regional + WeatherAdjustments (последний не работает в API, см. §12)
│       ├── keywords.py         положительные ключи + минус-фразы
│       └── reports.py          async TSV; SEARCH_QUERY_PERFORMANCE_REPORT (с CampaignId)
│
├── weather/
│   ├── open_meteo.py           OpenMeteoClient (forecast endpoint, теперь и wind_speed_10m)
│   └── index.py                compute_index(): X = 0.5·t + 0.3·d + 0.2·c
│
├── llm/
│   └── openai_client.py        OpenAIChatClient: chat_json (response_format=json_object)
│
├── negatives/
│   ├── classifier.py           LLM-промпт + classify_batch
│   └── pipeline.py             Reports (Query+CampaignId) → filter → batch → LLM → БД
│
├── experiment/
│   ├── policy.py               WeatherBidPolicy (YAML или dict); evaluate → BidDecision
│   ├── forward_index.py        combine_indices: geometric_mean / weighted_mean / single
│   ├── forecast_provider.py    today_index + next_weekend_index из прогноза
│   ├── bid_applier.py          BidApplier: GET MobileAdjustment у AdGroup, ADD/SET, threshold-skip
│   ├── loop.py                 HourlyBidLoop: оркестрация + запись в БД
│   └── strategy_repo.py        get/list/upsert/seed для ads_campaign_strategy
│
├── telegram/
│   ├── client.py               TelegramClient: sendMessage + broadcast
│   └── digest.py               build_daily_digest (HTML)
│
├── db/
│   ├── base.py                 SQLAlchemy 2.0 DeclarativeBase + session_scope
│   └── models/
│       ├── sync_log.py
│       ├── weather.py
│       ├── bid_decision.py
│       ├── negative_candidate.py    (+ campaign_id, decision)
│       ├── runtime_setting.py       NEW
│       └── campaign_strategy.py     NEW
│
└── web/                        FastAPI dashboard
    ├── app.py                  build_app() factory + 7 защищённых ручек
    ├── oauth.py                Yandex OAuth code flow
    ├── security.py             SessionUser + login_required
    ├── templates/              Jinja: base/index/privacy/terms/contacts +
    │                                  dashboard/campaigns/decisions/weather/access_denied +
    │                                  settings/strategy_edit/negatives  ← NEW
    └── static/style.css
```

**Тесты:** `tests/` — 324 passed (на 2026-05-08), все на mock-объектах + один live-тест Open-Meteo, два live-теста Direct sandbox. Запуск:

```
uv run pytest -q                            # unit, ~6 секунд
uv run pytest -m sandbox -q                 # против реальной песочницы (нужен токен)
uv run pytest -m openmeteo -q               # против бесплатного Open-Meteo
```

**Линт:** `uv run ruff check .` (+ `--fix`).

**Один важный конфиг файл:** `config/weather_bid_policy.yaml` — кривая коэффициентов и тип combiner'а. Менять можно без релиза кода (см. § 11).

---

## 8. Контейнеры на VDS

### 8.1. Из общего стека ERP (НЕ наши, но мы их используем)

- `kayak-postgres` (postgres:16-alpine) — БД для всех. У нас тут `kayak_ads`.
- `kayak-directus` (directus/directus:latest) — общий Directus, может расширяться нашими коллекциями `ads_*` (не сделано, M3).
- `kayak-n8n` (n8nio/n8n:latest) — n8n ERP, не наш.
- Caddy (host systemd) — общий reverse proxy. SSL через Cloudflare DNS-01.

### 8.2. Наши

- `kayak-ads-engine` — `kayak-ads-engine:latest`, command `python -m ads_engine.scheduler`.
- `kayak-ads-web` — тот же image, command `uvicorn ads_engine.web.app:app --host 0.0.0.0 --port 8090 --proxy-headers --forwarded-allow-ips '*'`.
- `kayak-ads-n8n` — отдельный n8n для рекламных workflow (использует БД `kayak_ads_n8n` — её ещё нет, поднимется при первом старте).

Все три в Docker сети `kayak-network`. `ads-web` пробрасывает 127.0.0.1:8090, остальные не пробрасывают.

### 8.3. Caddyfile на VDS (`/etc/caddy/Caddyfile`)

Релевантные блоки нашего сервиса:

```
direct.kayakmoscow.com {
    tls { dns cloudflare {env.CLOUDFLARE_API_TOKEN} }
    reverse_proxy localhost:8090
    encode gzip
    header { ... HSTS, X-Frame-Options, etc. ... }
}

n8n-ads.kayakmoscow.com {
    tls { dns cloudflare {env.CLOUDFLARE_API_TOKEN} }
    reverse_proxy localhost:5680
    encode gzip
    header { ... }
}
```

---

## 9. Конфигурация

### 9.1. Переменные окружения (полный список)

Всё в `deploy/.env` на VDS / `.env.local` локально. Шаблон в `deploy/.env.example`.

```
# Direct API
DIRECT_API_ENV=sandbox|prod              # выбор endpoint'a
DIRECT_OAUTH_CLIENT_ID=...               # из oauth.yandex.ru
DIRECT_OAUTH_CLIENT_SECRET=...           # секрет приложения
DIRECT_OAUTH_TOKEN=...                   # debug-токен (короткоживущий)

# Postgres
DATABASE_URL=postgresql+psycopg://kayak:PASS@kayak-postgres:5432/kayak_ads
                                         # на VDS host = имя контейнера
                                         # локально host = localhost (нет такого; используем 127.0.0.1 через ssh-туннель если нужно)

# Directus (общий)
DIRECTUS_BASE_URL=http://kayak-directus:8055
DIRECTUS_TOKEN=                          # пока не используется

# Метрика
METRIKA_COUNTER_ID=49922815
METRIKA_OAUTH_TOKEN=                     # = DIRECT_OAUTH_TOKEN если scope совпадает

# OpenAI
OPENAI_API_KEY=                          # gpt-4o-mini
OPENAI_MODEL=gpt-4o-mini

# Telegram
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_IDS=121329929              # csv

# Open-Meteo (без ключа)
WEATHER_BASE_URL=https://api.open-meteo.com/v1/forecast

# Эксперимент (большая часть переехала в ads_runtime_settings и ads_campaign_strategy)
# Эти env остаются как геокоординаты + путь к дефолтному YAML:
EXPERIMENT_LATITUDE=55.7558              # центр Москвы (как калибровали)
EXPERIMENT_LONGITUDE=37.6173
EXPERIMENT_POLICY_PATH=config/weather_bid_policy.yaml
EXPERIMENT_POLICY_VERSION=v1-2026-04-26  # тег для журнала (per-campaign перезаписывает)
# DEPRECATED (scheduler не читает с 2026-05-07):
# EXPERIMENT_HOURLY_BID_ENABLED  → ads_runtime_settings.hourly_bid.enabled
# EXPERIMENT_TARGET_AD_GROUP_IDS → ads_campaign_strategy.target_ad_group_ids (per-campaign)

# Web dashboard
DASHBOARD_SESSION_SECRET=                # 48 случайных байт через secrets.token_urlsafe
DASHBOARD_ALLOWED_YANDEX_LOGINS=kayakmoscow  # whitelist логинов

# Контакты
CONTACT_EMAIL=vanya.rybnikov@gmail.com
APP_PUBLIC_URL=https://direct.kayakmoscow.com
```

### 9.2. `config/weather_bid_policy.yaml`

Боевой конфиг кривой. Описание полей и текущих значений:

```yaml
version: 1
combiner:
  type: geometric_mean      # sqrt(today × next_weekend)
  # Другие опции: weighted_mean (с today_weight), today_only, weekend_only.

weekend_lookahead_days: 7   # окно поиска ближайших Сб+Вс

curve:
  weekday:                  # понедельник-пятница
    - { lower: 0.85, coefficient_pct: 10 }   # capacity-плато
    - { lower: 0.65, coefficient_pct: 20 }
    - { lower: 0.45, coefficient_pct: 5 }
    - { lower: 0.25, coefficient_pct: -25 }
    - { lower: 0.0,  coefficient_pct: -40 }
  weekend:                  # суббота-воскресенье
    - { lower: 0.85, coefficient_pct: 45 }   # +65% revenue в идеале
    - { lower: 0.65, coefficient_pct: 30 }
    - { lower: 0.45, coefficient_pct: 10 }
    - { lower: 0.25, coefficient_pct: -40 }
    - { lower: 0.0,  coefficient_pct: -60 }

caps:
  min_pct: -100             # жёсткий нижний предел Direct API
  max_pct: 50               # наш собственный (хотя API позволяет +1200)

apply_threshold_pct: 5      # не пушим API-апдейт, если изменение < 5 п.п.
```

Менять кривую = редактировать YAML на VDS (`/root/kayak-ads/config/weather_bid_policy.yaml`) + опционально обновить `EXPERIMENT_POLICY_VERSION` в `.env`. Перезапуск контейнера применит.

---

## 10. Контуры исполнения

### 10.1. Scheduler (`kayak-ads-engine`)

Один blocking process на APScheduler timezone Europe/Moscow. Архитектура с 2026-05-07: **soft-toggle + cron reload**.

- Все три job'a регистрируются всегда (если есть необходимые секреты).
- Внутри каждый job на старте тика читает `ads_runtime_settings.<job>.enabled` через `RuntimeConfig` — если false, no-op (логирует и выходит).
- Отдельный технический job `_config_reload` тикает раз в минуту: если `cron_preset` для какого-то job'a поменялся в БД относительно текущего trigger'a, делает `sched.reschedule_job(...)` — изменения применяются ≤1 минуты.

| Job | Cron-пресет (default) | Условие включения | Что делает |
|---|---|---|---|
| `hourly_bid` | `hourly` (минута :05) | `hourly_bid.enabled=true` в БД + есть `DIRECT_OAUTH_TOKEN` + есть включённые `ads_campaign_strategy` | Итерирует по включённым стратегиям, для каждой: Forecast → per-campaign policy → BidApplier (см. § 11). Per-strategy try/except. |
| `daily_negatives` | `daily_03` | `daily_negatives.enabled=true` + `OPENAI_API_KEY` + `DIRECT_OAUTH_TOKEN` | Reports SEARCH_QUERY (с `CampaignId`) → LLM → `ads_negative_candidates` со `decision=pending` |
| `daily_digest` | `daily_09` | `daily_digest.enabled=true` + `TELEGRAM_BOT_TOKEN` + `TELEGRAM_CHAT_IDS` | Рендер HTML дайджеста + broadcast |
| `_config_reload` | каждую минуту | всегда | сравнить `_active_presets[job_id]` с БД; reschedule при разнице |

Каждая job — try/except в одиночку, не валит соседние. Логи в stdout (`docker logs kayak-ads-engine`).

### 10.2. Web (`kayak-ads-web`)

Uvicorn на порту 8090 за Caddy. Endpoints:

**Публичные:**
- `GET /` → лендинг
- `GET /privacy` → 152-ФЗ политика
- `GET /terms`
- `GET /contacts`
- `GET /healthz` → "ok"
- `GET /robots.txt`
- `GET /static/*` → CSS

**OAuth:**
- `GET /oauth/login` → 303 на oauth.yandex.ru с state
- `GET /oauth/callback?code&state` → exchange → userinfo → whitelist → session → 303 /dashboard
- `GET /logout` → clear session → 303 /

**Защищённые (требуют сессию):**
- `GET /dashboard` → сводка (env, hourly flag из RuntimeConfig, кол-во включённых стратегий, ad-groups, decisions за 24ч, ссылки)
- `GET /dashboard/campaigns` → live `CampaignsService.get(50)` + статус привязанной стратегии в каждой строке
- `GET /dashboard/campaigns/{id}/strategy` → редактор стратегии (multiselect ad-group'ов из Direct, кривая 5+5 бинов, live-превью coefficient)
- `POST /dashboard/campaigns/{id}/strategy` → upsert в `ads_campaign_strategy`, валидация через `WeatherBidPolicy.from_dict`
- `GET /dashboard/decisions[?campaign_id=N]` → 50 последних `BidExperimentDecision` с фильтром по кампании
- `GET /dashboard/weather` → forecast + сырые поля (temp/cloud/precip/wind) + per-campaign превью ставки
- `GET /dashboard/negatives[?decision=&label=]` → кандидаты в минус-слова (default `decision=pending`)
- `POST /dashboard/negatives/{id}/decision` → approve/reject (мутирует `ads_negative_candidates.decision`, push в Direct ещё не реализован)
- `GET /dashboard/settings` → карточки 3 джобов с тогглами и cron-пресетами
- `POST /dashboard/settings` → запись в `ads_runtime_settings` (scheduler подхватит ≤1 минуты)

Сессии: starlette `SessionMiddleware` + itsdangerous, cookie `kma_session`, httponly+samesite=lax+secure, max_age 7 дней.

### 10.3. CLI (`ads ...`)

Запуск внутри контейнера: `docker exec -it kayak-ads-engine ads <cmd>`. На локалке: `uv run ads <cmd>`.

```
ads health                           # проверить токен и Units
ads auth url --client-id ...         # сгенерировать OAuth URL
ads campaigns list [--limit N]       # таблица кампаний
ads experiment run-once [--force]    # один прогон hourly-bid
ads negatives run-once [--days 7]    # один прогон чистки минус-слов
```

---

## 11. Критические инварианты Direct API (guardrails)

Зашиты в коде; нарушать = ломать обучение автостратегий Yandex.

1. **Daily budget**: меняем не чаще раза в 7 дней, ±20%. (Сейчас не меняем вообще.)
2. **Target CPA**: не чаще раза в 3 дня, ±10%. (Не меняем.)
3. **Pause >6 дней**: запрещено (сбросит обучение). Используем `archive` для длительной остановки.
4. **BidModifier**: bounds [-100%, +1200%] от API; наш cap по умолчанию [-100, +50].
5. **Apply threshold**: если новый коэффициент отличается от текущего < 5 п.п., не пушим (минимизация шума автостратегии).
6. **Units quota**: при `available/daily < 10%` клиент сам отказывает в non-critical вызовах (`UnitsExhaustedError`).
7. **5 одновременных запросов** на аккаунт — semaphore в `DirectClient`.
8. **Reports rate limit**: 20 запросов / 10 секунд — sliding window.
9. **Use-Operator-Units header** — НЕ ставим (для прямого рекламодателя ломает с code=58).

---

## 12. Что калибровано и почему

### 12.1. Кривая коэффициентов (см. `analysis/weather_demand_correlation.md`)

Калибровка на 999 днях исторических прогулок (2022-2025) + 2 743 онлайн-платежей Tinkoff (2024-05..2026-04). Главные находки:

- **Pearson(weather_index, payment_amount) = +0.579** на всех днях, **+0.616** для количества платежей. По прогулкам корреляция в 2× ниже — потому что прогулки упираются в capacity (5 групп/день потолок), а платежи — на любую будущую дату.
- **Capacity-плато** на index ≥ 0.85 в будни: revenue 90k vs 89k. Поднимать ставку выше +10% бессмысленно.
- **На сезонных выходных** revenue растёт линейно через все бины (8.2× амплитуда: 15k → 124k ₽). Capacity не упирается. Поднимаем агрессивно (+45% в верхнем бине).

### 12.2. Forward-looking X = √(today × next_weekend_index)

Обнаружено: люди оплачивают в будни на ближайшие выходные. На понедельнике сегодняшняя погода вообще не предсказывает (Pearson +0.19), а прогноз выходных предсказывает (+0.33). Геометрическое среднее обыгрывает обе компоненты по отдельности на 14%.

### 12.3. Формула индекса

```
index = 0.5 · gauss(t, μ=24, σ=5) + 0.3 · dry(p) + 0.2 · clear(c)

gauss(t) = exp(-(t-24)² / 2·5²)             # max в 24°C
dry(p)   = 1 если p=0; 0 если p≥2 мм/ч; линейно между
clear(c) = 1 - c/100                         # доля безоблачности
```

Параметры подобраны эмпирически на основе того, что `≥0.85` совпадает с пиковым спросом в данных. Можно улучшать вторым раундом калибровки.

---

## 13. Известные quirks Direct API (испытано в sandbox)

Полностью описано в `docs/api-findings.md`. Главное:

1. **`AdGroups.add` в sandbox возвращает Id, но объект не персистится.** Воспроизводится для обоих типов кампаний. Полный e2e групп/объявлений возможен только в проде.
2. **`WeatherAdjustments` через API не работает** — `code 3500 "Корректировка данного типа не поддерживается"`. Управление погодными правилами доступно только в UI Direct'а. Архитектурный pivot: используем `MobileAdjustment` на AdGroupId как proxy.
3. **DRAFT-кампании** нельзя suspend/archive — только delete или активировать. Возвращают 8300/8303 как per-item Errors внутри 200-ответа.
4. **Use-Operator-Units header** для прямого рекламодателя ломает с code=58.
5. **`SelectionCriteria.Statuses`**: `ACCEPTED, DRAFT, MODERATION, REJECTED, PREACCEPTED` (без подчёркивания между PRE и ACCEPTED).
6. **Допустимый список Search BiddingStrategy для ЕПК**: `AVERAGE_CPC, AVERAGE_CPA, AVERAGE_CRR, PAY_FOR_CONVERSION, PAY_FOR_CONVERSION_CRR, PAY_FOR_CONVERSION_MULTIPLE_GOALS, AVERAGE_CPA_MULTIPLE_GOALS, WB_MAXIMUM_CLICKS, WB_MAXIMUM_CONVERSION_RATE, HIGHEST_POSITION, MAX_PROFIT, SERVING_OFF, UNKNOWN`. Не `AUTOBUDGET_*` как в legacy.

---

## 14. Восстановление с нуля (runbook)

### Сценарий A: репо есть, VDS упал

```bash
# 1. На новый VDS поставить Docker, Caddy, клонировать ERP-стек (по KayakMoscow_ERP/Docs/).
#    После этого kayak-postgres, kayak-directus, kayak-n8n работают.

# 2. Восстановить БД kayak_ads из дампа (если был):
docker exec -i kayak-postgres psql -U kayak -d postgres -c "CREATE DATABASE kayak_ads OWNER kayak;"
docker exec -i kayak-postgres psql -U kayak -d kayak_ads < /backups/kayak_ads_latest.sql

# Если дампа нет — пустую БД и применить миграции:
cd /root/kayak-ads/deploy
docker compose run --rm ads-engine alembic upgrade head

# 3. Сгенерировать SSH deploy-key, добавить как deploy key в репо
ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N ''
cat /root/.ssh/id_ed25519.pub  # → добавить в settings репо как Deploy Key

# 4. Клонировать
cd /root && git clone git@github.com:rodeokayaker/kayakmoscow-ads.git kayak-ads

# 5. Заполнить /root/kayak-ads/deploy/.env (см. § 9.1)
#    Из бэкапа credentials.local.md или из 1Password.

# 6. Запустить
cd /root/kayak-ads/deploy
docker compose up -d --build

# 7. Patch Caddyfile (skim deploy/Caddyfile.snippet) + reload Caddy

# 8. Cloudflare A-records direct.* и n8n-ads.* (см. § 14.2 ниже)

# 9. Проверка:
curl -I https://direct.kayakmoscow.com/healthz
docker exec kayak-ads-engine ads health
```

### Сценарий B: всё стёрто, кроме Yandex/Cloudflare/GitHub-учёток

Этапы:
1. Завести VDS (Timeweb или другой), Ubuntu, Docker, минимум 4 ГБ RAM.
2. Поднять `kayak-postgres` (по `KayakMoscow_ERP/Docs/`). Секреты — заново сгенерировать, обновить везде.
3. Поднять Caddy на хосте, прописать `CLOUDFLARE_API_TOKEN` в systemd drop-in.
4. SSH deploy-key → добавить как Deploy Key в репо `rodeokayaker/kayakmoscow-ads`.
5. Клонировать `kayak-ads`, заполнить `.env` (см. ниже).
6. Применить Alembic-миграции к свежей `kayak_ads`.
7. Direct API: получить новый OAuth-токен (`ads auth url --client-id ...`, открыть в браузере под `kayakmoscow@yandex.ru`, скопировать токен).
8. Cloudflare DNS:
   ```
   curl -sS -X POST -H "Authorization: Bearer $CF" -H "Content-Type: application/json" \
     "https://api.cloudflare.com/client/v4/zones/c92881d1c3af0e830cb705923cf87f88/dns_records" \
     -d '{"type":"A","name":"direct.kayakmoscow.com","content":"<NEW_VDS_IP>","ttl":1,"proxied":false}'
   ```
9. `docker compose up -d --build`.
10. Smoke: `curl -I https://direct.kayakmoscow.com/`.

### Сценарий C: ноут стёрся, репо живой

```bash
# Поставить uv, Python 3.12.
git clone git@github.com:rodeokayaker/kayakmoscow-ads.git
cd kayakmoscow-ads
uv sync --extra dev
cp .env.example .env.local
# Заполнить .env.local из 1Password или из credentials.local.md

uv run pytest -q       # должно быть 240+ passed
uv run ads health      # проверить sandbox
```

Локальные данные (`Archive/`) — приватны, восстанавливаются из:
- `money_*.xlsx` — у Ivan'a в облаке/на бухгалтерском компе.
- Tinkoff acquiring reports — выгружаются с `business.tinkoff.ru` за нужный период.

---

## 15. Day-2 ops

### 15.1. Деплой обновления

```bash
ssh root@176.124.208.237 "cd /root/kayak-ads && git pull && cd deploy && docker compose build ads-engine && docker compose up -d"
```

`ads-web` и `ads-engine` используют один image — оба обновятся одной командой `up -d`.

### 15.2. Применить новую миграцию

Локально:
```bash
DATABASE_URL="postgresql+psycopg://kayak:x@localhost:5432/kayak_ads" \
  uv run alembic revision --autogenerate -m "название"
```

Применить на VDS:
```bash
DATABASE_URL="postgresql+psycopg://kayak:x@localhost:5432/kayak_ads" \
  uv run alembic upgrade head --sql > /tmp/mig.sql
# Извлечь только новый блок (после COMMIT предыдущей миграции).
scp /tmp/mig.sql root@176.124.208.237:/tmp/
ssh root@176.124.208.237 "docker exec -i kayak-postgres psql -U kayak -d kayak_ads < /tmp/mig.sql"
```

### 15.3. Дебаг

```bash
# Логи
docker logs --tail 100 -f kayak-ads-engine
docker logs --tail 100 -f kayak-ads-web

# Здоровье
docker exec kayak-ads-engine ads health
curl https://direct.kayakmoscow.com/healthz

# БД
docker exec -it kayak-postgres psql -U kayak -d kayak_ads -c '\dt'
docker exec -it kayak-postgres psql -U kayak -d kayak_ads -c \
  'SELECT created_at, target_id, final_coefficient_pct, applied FROM ads_bid_experiment_decisions ORDER BY id DESC LIMIT 10;'

# Telegram digest вручную
docker exec kayak-ads-engine python -c \
  'from ads_engine.scheduler import daily_digest_job; daily_digest_job()'
```

### 15.4. Откат

```bash
ssh root@176.124.208.237 "cd /root/kayak-ads && git log --oneline | head -10"
# выбрать SHA до проблемы
ssh root@176.124.208.237 "cd /root/kayak-ads && git checkout <SHA> && cd deploy && docker compose build && docker compose up -d"
```

При откате назад через миграцию: `alembic downgrade <prev_revision>` (не пробовалось в проде).

### 15.5. Ротация секретов

Если токен/ключ скомпрометирован:
1. Заменить в `.env` на VDS, в `.env.local` на ноуте, в `KayakMoscow_ERP/Docs/credentials.local.md`.
2. `docker compose restart ads-engine ads-web`.
3. Удалить старый токен в Yandex/OpenAI/Telegram настройках.

`DASHBOARD_SESSION_SECRET` — ротация инвалидирует все активные сессии (юзеры заново логинятся).

---

## 16. Документы в `docs/`

| Файл | Что в нём |
|---|---|
| `SYSTEM.md` | этот файл — disaster recovery |
| `architecture.md` | целевая архитектура (часть актуальна, часть была превентивной) |
| `roadmap.md` | 9 милстонов до сентября 2026 |
| `api-findings.md` | sandbox-валидация контрактов Direct API + quirks |
| `experiment-hourly-bid.md` | план эксперимента (test/control SUP-Медуза) |
| `oauth-setup.md` | пошагово: регистрация OAuth-app, sandbox-активация |
| `yandex_application/spec_short.pdf` | спецификация для заявки на прод-доступ Direct API (2 стр., прикладывается к форме) |
| `yandex_application/spec.pdf` | расширенная версия спецификации (3 стр.) |
| `../analysis/weather_demand_correlation.md` | калибровка кривой |

Также в `KayakMoscow_marketing/Research/`:
- `kayak_moscow_advertising_research_2026-04-03.md` — стратегия 2026 сезона.
- `kayak_moscow_paid_platforms_research_2026-04-04.md` — внешние платформы.
- `kayak_moscow_direct_automation_research_2026-04-23.md` — архитектурное исследование автоматизации.

---

## 17. Open issues / known limitations

1. **Прод-доступ к Direct API не получен** (на 2026-05-08). Приложение работает только на sandbox. Спецификация для заявки готова — `docs/yandex_application/spec_short.pdf` (2 стр.); подаётся через UI Direct → Инструменты → Настройки API.
2. **AdGroups в sandbox «фантомные»** — `AdGroups.add` возвращает Id, но `AdGroups.get` их не отдаёт. Подтверждено напрямую API 2026-05-07. Полноценный e2e только в проде.
3. **WeatherAdjustments через API не работает** — `code 3500`. Используем `MobileAdjustment` на AdGroupId как proxy.
4. **OPENAI_API_KEY не задан на VDS**. `daily_negatives_job` пропускается даже при `enabled=true` в runtime config.
5. **Push минус-фразы в Direct не реализован.** Approval flow в `/dashboard/negatives` помечает `decision=approved` в БД, но `Campaigns.update`/`Keywords.add` ещё не вызывает. Отложено до прод-доступа (sandbox AdGroups делают тестирование бессмысленным).
6. **n8n-ads контейнер запущен без workflow'ов**. БД `kayak_ads_n8n` создаётся при первом старте. Workflow'ы под Tinkoff webhook + lead-form pending (M5).
7. **Directus коллекции `ads_*` не созданы**. M3, отложено — UI стратегий теперь есть в нашем дашборде.
8. **Бэкап БД** делается через ERP-механизм, отдельных скриптов не написано.
9. **monitoring/alerting** — только logs+digest. Нет внешнего uptime-монитора.
10. **CI/CD** — нет GitHub Actions. Деплой ручной (`git pull` + `docker compose build` + `up -d`).
11. **Координаты Медузы** в `scripts/calibrate_weather_curve.py` приблизительные (центр Москвы 55.75/37.62) — реальная база не там. Влияние на калибровку малое; уточнить при возможности.

---

## 18. Roadmap указатели

См. `docs/roadmap.md`. Где мы:

- ✅ M1 Sandbox foundation
- ✅ M2 Weather loop + reports (полностью)
- ⏸ M3 Directus config (не начато; UI стратегий теперь в нашем дашборде, M3 фактически закрыт)
- 🟡 M4 Dashboard + OAuth submission — dashboard live + per-campaign UI; **заявка на прод-доступ готова к подаче** (`docs/yandex_application/spec_short.pdf`)
- ✅ M5 Minus-words + approval flow — pipeline ✓, approval UI ✓ (push в Direct отложен до прод-доступа)
- ✅ Runtime UI (2026-05-07) — per-campaign стратегии, тогглы/cron-пресеты, редактор кривой, hot-reload
- ⏳ M6 Production switch — ждёт прод-доступа
- ⏳ M7 Audiences + сезонный режим
- ⏳ M8 VK Ads (июль)
- ⏳ M9 Пост-сезон

Ближайшие шаги, которые двигают проект (приоритет сверху вниз):
1. **Подать заявку на прод-доступ Direct API** через UI Direct'а с приложением `docs/yandex_application/spec_short.pdf`.
2. **Добавить `OPENAI_API_KEY`** в `.env` на VDS.
3. **Whitelist маркетолога и директора продаж** — добавить их Yandex-логины в `DASHBOARD_ALLOWED_YANDEX_LOGINS`.
4. После одобрения прода: настроить per-campaign стратегии в `/dashboard/campaigns/{id}/strategy`, включить `hourly_bid.enabled` в `/dashboard/settings`.
5. Реализовать реальный push минус-фразы в Direct (`Campaigns.update` с `NegativeKeywords` через read-modify-write).
6. M5 Tinkoff webhook + Bitrix форма с yclid → offline conversions в Метрику.

---

## 19. Контакты

- Оператор: ИП Рыбников Иван Григорьевич, ИНН 772861688006.
- Email для запросов 152-ФЗ и тех.поддержки: info@kayakmoscow.ru.
- Личный email Ivan'a: vanya.rybnikov@gmail.com.
- GitHub: rodeokayaker.
- Telegram: 121329929 (Ivan).

---

## 20. Что менять в этом файле

- При добавлении новой таблицы в `kayak_ads` — обновить § 6.
- При добавлении нового сервиса/контейнера — § 8.
- При изменении кривой коэффициентов в YAML (дефолт) — § 9.2; per-campaign кривые редактируются в дашборде, в БД, без правки этого файла.
- При добавлении нового ключа в `RuntimeConfig` — § 6.5.
- При появлении нового endpoint'a в дашборде — § 10.2.
- При появлении нового внешнего сервиса — § 3.
- При смене юр.лица оператора — § 1, § 19, шаблоны privacy/terms.
- Когда подадим/одобрят заявку на прод-доступ — § 17.

Файл живой; не считать его «historical record».
