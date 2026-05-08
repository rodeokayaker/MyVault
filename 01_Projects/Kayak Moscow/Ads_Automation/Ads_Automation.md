---
created: 2026-05-01
updated: 2026-05-08
type: project
project: KayakMoscow
status: active
tags: [kayakmoscow, ads, automation, yandex-direct]
parent: "[[KayakMoscow]]"
repo: rodeokayaker/kayakmoscow-ads
local_path: /Users/vanya/Documents/KayakMoscow_ads
last_commit: 0c94458
---

# Kayak Moscow — Ads Automation

Внутренний сервис для автоматизации рекламы Kayak Moscow в Яндекс Директе. Не SaaS, один аккаунт `kayakmoscow@yandex.ru`. Оператор: ИП Рыбников И.Г. (ИНН 772861688006).

> Полный disaster-recovery документ: [[SYSTEM_snapshot_2026-05-08]] (снапшот `docs/SYSTEM.md` из репо на 2026-05-01).
> Источник правды — `docs/SYSTEM.md` в репо. Этот снапшот — backup на случай потери репо/ноута.

## Goal

Закрыть рутину Direct API руками: погодные ставки, чистка минус-слов, дайджест, реактивация базы — всё через код, с гардрейлами от ломки автостратегий Яндекса.

## Что делает (4 контура)

1. **Hourly bid loop** — каждый час пересчитывает погодный индекс (Open-Meteo) и обновляет `MobileAdjustment` BidModifier'ы у целевых AdGroup'ов. Двухрежимная кривая: будни/выходные. Forward-looking X = √(today × next_weekend). **Per-campaign**: с 2026-05-07 каждая кампания имеет свою стратегию в `ads_campaign_strategy` со своей кривой и target ad-group'ами.
2. **Daily negatives pipeline** — раз в сутки тянет SEARCH_QUERY_PERFORMANCE_REPORT за 7 дней (с `CampaignId`), прогоняет через OpenAI gpt-4o-mini, кандидаты в `ads_negative_candidates` со статусом `pending`. Approve/Reject — через дашборд (`/dashboard/negatives`).
3. **Daily Telegram digest** — HTML-сводка в `@kayakmoscowads_bot`, получатели в `TELEGRAM_CHAT_IDS`.
4. **Public dashboard** — `https://direct.kayakmoscow.com` (landing + 152-ФЗ + Yandex OAuth + защищённые страницы: status, campaigns, **strategy editor**, decisions с фильтром по кампании, weather с per-campaign превью, **negatives approval**, **runtime settings**).

## Runtime controls (с 2026-05-07)

Все тогглы и расписания — в БД (`ads_runtime_settings`), читаются через `RuntimeConfig` с TTL-кэшем 30 сек. Меняются через `/dashboard/settings`, scheduler подхватывает через `_config_reload` job (каждую минуту).

- `hourly_bid.enabled` + cron preset (`hourly` / `every_30m` / `every_2h`)
- `daily_negatives.enabled` + cron preset (`daily_03` / `daily_06` / `weekly_mon_03`)
- `daily_digest.enabled` + cron preset (`daily_09` / `daily_18` / `twice_daily`)

Старые env-флаги (`EXPERIMENT_HOURLY_BID_ENABLED`, `EXPERIMENT_TARGET_AD_GROUP_IDS`) **больше не читаются scheduler'ом** — управление полностью через UI.

## Стек

Python 3.12, httpx, pydantic v2, FastAPI, SQLAlchemy 2.0, Alembic, APScheduler, Jinja2, pytest. Postgres 16 (БД `kayak_ads` в общем `kayak-postgres`). Docker Compose. Caddy reverse-proxy + Cloudflare DNS-01.

## Инфраструктура

- **VDS Timeweb**: `176.124.208.237` (Ubuntu, 4ГБ RAM, 50ГБ NVMe + 2ГБ swap), root SSH.
- **Домены** (Cloudflare zone `c92881d1c3af0e830cb705923cf87f88`):
  - `direct.kayakmoscow.com` → `kayak-ads-web:8090` (FastAPI)
  - `n8n-ads.kayakmoscow.com` → `kayak-ads-n8n:5680`
- **Контейнеры наши**: `kayak-ads-engine` (scheduler), `kayak-ads-web` (uvicorn), `kayak-ads-n8n`. Сеть `kayak-network`.
- **БД**: `kayak_ads` живёт в общем `kayak-postgres` (стек ERP).
- **GitHub**: `rodeokayaker/kayakmoscow-ads` (private), deploy key с VDS.

## Внешние сервисы

| Сервис | Что | Учётка |
|---|---|---|
| Yandex Direct | API v5/v501, OAuth-app `8de9aec8db…` | `kayakmoscow@yandex.ru` |
| Yandex Метрика | счётчик `49922815` | та же |
| Yandex ID | OAuth для входа в dashboard | та же |
| Open-Meteo | прогноз+архив, без ключа | — |
| OpenAI | gpt-4o-mini (~$0.15/1M tok), бюджет $50/мес | platform.openai.com |
| Telegram | `@kayakmoscowads_bot`, ID `8271201222:…` | — |
| Cloudflare | DNS, API token для DNS-01 | — |
| Tinkoff | эквайринг архив 2024-05..2026-04 (для калибровки) | business.tinkoff.ru |
| Bitrix | `kayakmoscow.ru` (CMS, не наш VDS) | у Ivan |

## Калибровка (главное)

- 999 дней прогулок 2022-2025 + 2 743 платежа Tinkoff 2024-05..2026-04.
- Pearson(weather_index, payment_amount) = **+0.579**, по числу платежей **+0.616**.
- На сезонных выходных revenue линейно растёт через все бины (8.2× амплитуда). В будни упирается в capacity-плато при index ≥ 0.85.
- Forward-looking X = √(today × next_weekend) обыгрывает компоненты на 14%.
- Формула индекса: `0.5·gauss(t, μ=24, σ=5) + 0.3·dry(p) + 0.2·clear(c)`.
- Боевой конфиг: `config/weather_bid_policy.yaml` (можно править YAML на VDS без релиза).

Подробно — `analysis/weather_demand_correlation.md` в репо.

## Где живут секреты

Не в Obsidian. Указатели:

| Секрет | Где |
|---|---|
| `DIRECT_OAUTH_*`, `DATABASE_URL`, `TELEGRAM_BOT_TOKEN` | `KayakMoscow_ERP/.env.local` + `KayakMoscow_ads/.env.local` + VDS `/root/kayak-ads/deploy/.env` |
| `DASHBOARD_SESSION_SECRET` | VDS `.env` (генерим заново) |
| `OPENAI_API_KEY` | пока не задан (см. Open issues) |
| `CLOUDFLARE_API_TOKEN` | VDS `/etc/systemd/system/caddy.service.d/cloudflare.conf` + `KayakMoscow_ERP/Docs/credentials.local.md` |
| `KAYAK_DB_PASSWORD` | VDS `/root/kayak/.env` (общий kayak-postgres) |

Бэкап критичных секретов — копия `KayakMoscow_ERP/Docs/credentials.local.md` в 1Password / Bitwarden.

## Roadmap (статус на 2026-05-01)

- ✅ M1 Sandbox foundation
- ✅ M2 Weather loop + reports
- ⏸ M3 Directus config (отложено)
- 🟡 M4 Dashboard + OAuth submission — dashboard live, **заявка на прод-доступ Direct API готова к подаче** (см. [[Yandex_Direct_API_Application_2026-05]])
- ✅ M5 Minus-words + approval flow — pipeline ✓, approval UI ✓ (push в Direct по нажатию Approve — отдельный шаг, отложен до прод-доступа)
- ✅ Runtime UI — per-campaign стратегии, тогглы/cron-пресеты, redactor кривой
- ⏳ M6 Production switch — ждёт прод-доступа
- ⏳ M7 Audiences + сезонный режим
- ⏳ M8 VK Ads (июль)
- ⏳ M9 Пост-сезон

## Ближайшие шаги (приоритет сверху вниз)

1. **Подать заявку на прод-доступ Direct API** через UI Direct → Инструменты → Настройки API. Спека готова: `docs/yandex_application/spec_short.pdf` (2 стр.) — см. [[Yandex_Direct_API_Application_2026-05]].
2. Добавить `OPENAI_API_KEY` в `.env` на VDS (иначе `daily_negatives_job` молча скипается даже при включённом тоггле).
3. Whitelist маркетолога и директора продаж — добавить их Yandex-логины в `DASHBOARD_ALLOWED_YANDEX_LOGINS`.
4. После прод-доступа: настроить per-campaign стратегии в `/dashboard/campaigns/{id}/strategy` (выбор ad-group'ов + кривая), включить `hourly_bid.enabled` в `/dashboard/settings`.
5. Реализовать реальный push минус-фразы в Direct (`Campaigns.update` с `NegativeKeywords`) — read-modify-write. Сейчас approve = только пометка в БД.
6. M5 Tinkoff webhook + Bitrix форма с yclid → offline conversions в Метрику.
7. ~~Обновить `docs/SYSTEM.md`~~ — сделано 2026-05-08.

## Open issues / known limitations

1. **Прод-доступ к Direct API не получен** — работаем только в sandbox.
2. **AdGroups в sandbox «фантомные»** — добавляются с Id, но `AdGroups.get` их не возвращает. Подтверждено напрямую API 2026-05-07. Полноценный e2e только в проде.
3. **WeatherAdjustments через API не работает** (code 3500). Pivot: используем `MobileAdjustment` на AdGroupId как proxy.
4. `OPENAI_API_KEY` не задан на VDS — `daily_negatives_job` не запускается даже при `enabled=true` в runtime config.
5. **Push минус-фразы в Direct не реализован** — approval flow помечает в БД, но `Campaigns.update`/`Keywords.add` ещё не вызывает. Отложено до прод-доступа.
6. n8n-ads контейнер запущен без workflow'ов.
7. Directus коллекции `ads_*` не созданы (M3, отложено).
8. Бэкап БД — только через ERP-механизм, отдельных скриптов нет.
9. Нет внешнего uptime-монитора, нет CI/CD (деплой ручной).
10. Координаты Медузы в `scripts/calibrate_weather_curve.py` приблизительные (центр Москвы).
11. ~~`docs/SYSTEM.md` отстаёт от реальности~~ — обновлён 2026-05-08, см. [[SYSTEM_snapshot_2026-05-08]].

## История разработки

Старт **2026-04-24**, активная фаза:
- 2026-04-24: skeleton + Direct API client (Campaigns/AdGroups/Ads/BidModifiers/Keywords/Reports), Open-Meteo, Alembic.
- 2026-04-25..26: ruff/quirks fixes, эксперимент-план, калибровка кривой на 4-летних данных, корреляция Tinkoff.
- 2026-04-27: hourly bid loop, dashboard MVP, deploy на VDS, Yandex OAuth.
- 2026-04-28: minus-words pipeline, scheduler+telegram digest, **`docs/SYSTEM.md`** (disaster recovery).
- 2026-05-07 (`93d1c05` + `35bfaf9`): **per-campaign стратегии + runtime UI + approval flow** — 7 этапов за день.
  - `ads_runtime_settings` + `RuntimeConfig` сервис с TTL-кэшем 30s.
  - `ads_campaign_strategy` (per-campaign кривая + target ad-groups).
  - Рефактор scheduler'а: soft-toggle, `_config_reload` job каждую минуту.
  - 5 новых страниц в дашборде: settings, strategy editor, weather с превью, decisions с фильтром, negatives approval.
  - `ads_negative_candidates`: добавлены `campaign_id` и `decision`.
  - OpenMeteoForecast: добавлен `wind_speed_ms`.
  - 84 новых теста (всего 324 passed).
  - Деплой на VDS прошёл, 3 миграции применились на postgres.
- 2026-05-08 (`0c94458`): спецификация для заявки на прод-доступ Direct API (`docs/yandex_application/spec_short.pdf`, 2 стр.).

Полный лог — `git log` в репо или § история в [[SYSTEM_snapshot_2026-05-08]].



## Связанные заметки

- [[KayakMoscow]] — родительский хаб
- [[SYSTEM_snapshot_2026-05-08]] — полный disaster-recovery снапшот (на 2026-04-28; устарел на 2 коммита)
- [[Yandex_Direct_API_Application_2026-05]] — спецификация и статус заявки на прод-доступ
- [[Runtime_UI_2026-05]] — описание новых страниц дашборда и схемы runtime-настроек
- [[Infrastructure_VDS]] — общий стек на этом же VDS (Postgres, Directus, n8n, Caddy)
- [[ERP]] — соседний проект
- [[Исследование рекламного продвижения Kayak Moscow на сезон 2026]] — стратегический контекст
- [[Исследование paid-площадок и агрегаторов для Kayak Moscow]] — внешние рекламные каналы
- [[Site]] — Метрика `49922815` стоит в шаблоне Bitrix

## Локально на ноуте

```
/Users/vanya/Documents/KayakMoscow_ads/
├── ads_engine/           Python-пакет (direct_client, weather, llm, negatives, experiment, telegram, db, web, runtime_config, scheduler)
├── alembic/              миграции БД (7 версий, последняя — 7dba2eceabc7)
├── analysis/             калибровка + weather_demand_correlation.md
├── Archive/              gitignored: money_*.xlsx, Tinkoff отчёты
├── config/weather_bid_policy.yaml   дефолтная кривая (база для seed'a per-campaign стратегий)
├── deploy/               Dockerfile + compose + Caddyfile snippet
├── docs/
│   ├── SYSTEM.md         disaster recovery (2026-04-28, отстаёт)
│   ├── architecture.md / roadmap.md / api-findings.md / experiment-hourly-bid.md / oauth-setup.md
│   └── yandex_application/spec_short.pdf  заявка в Direct (2 стр.)
├── scripts/              калибровочные скрипты
├── tests/                324 passed
└── .env.local            gitignored, рабочие секреты
```

## Контакты

- Оператор: ИП Рыбников Иван Григорьевич, ИНН 772861688006
- 152-ФЗ / тех.поддержка: info@kayakmoscow.ru
- Личный: vanya.rybnikov@gmail.com
- GitHub: rodeokayaker
- Telegram: 121329929
