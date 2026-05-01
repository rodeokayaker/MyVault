---
created: 2026-05-01
updated: 2026-05-01
type: project
project: KayakMoscow
status: active
tags: [kayakmoscow, ads, automation, yandex-direct]
parent: "[[KayakMoscow]]"
repo: rodeokayaker/kayakmoscow-ads
local_path: /Users/vanya/Documents/KayakMoscow_ads
---

# Kayak Moscow — Ads Automation

Внутренний сервис для автоматизации рекламы Kayak Moscow в Яндекс Директе. Не SaaS, один аккаунт `kayakmoscow@yandex.ru`. Оператор: ИП Рыбников И.Г. (ИНН 772861688006).

> Полный disaster-recovery документ: [[SYSTEM_snapshot_2026-05-01]] (снапшот `docs/SYSTEM.md` из репо на 2026-05-01).
> Источник правды — `docs/SYSTEM.md` в репо. Этот снапшот — backup на случай потери репо/ноута.

## Goal

Закрыть рутину Direct API руками: погодные ставки, чистка минус-слов, дайджест, реактивация базы — всё через код, с гардрейлами от ломки автостратегий Яндекса.

## Что делает (4 контура)

1. **Hourly bid loop** — каждый час пересчитывает погодный индекс (Open-Meteo) и обновляет `MobileAdjustment` BidModifier'ы у целевых AdGroup'ов. Двухрежимная кривая: будни/выходные. Forward-looking X = √(today × next_weekend).
2. **Daily negatives pipeline** — раз в сутки тянет SEARCH_QUERY_PERFORMANCE_REPORT за 7 дней, прогоняет через OpenAI gpt-4o-mini, кандидаты в минус-слова кладёт в БД (`ads_negative_candidates`).
3. **Daily Telegram digest** — HTML-сводка в `@kayakmoscowads_bot`, получатели в `TELEGRAM_CHAT_IDS`.
4. **Public dashboard** — `https://direct.kayakmoscow.com` (landing + 152-ФЗ + Yandex OAuth + 4 защищённые страницы: status, campaigns, decisions, weather).

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
- 🟡 M4 Dashboard + OAuth submission — dashboard live, **заявка на прод-доступ Direct API ещё не подана**
- 🟡 M5 Minus-words + approval flow — minus-words ✓, approval flow pending
- ⏳ M6 Production switch — ждёт прод-доступа
- ⏳ M7 Audiences + сезонный режим
- ⏳ M8 VK Ads (июль)
- ⏳ M9 Пост-сезон

## Ближайшие шаги (приоритет сверху вниз)

1. Подать **заявку на прод-доступ Direct API** через UI Direct → Инструменты → Настройки API.
2. Добавить `OPENAI_API_KEY` в `.env` на VDS (иначе `daily_negatives_job` пропускается).
3. Whitelist маркетолога и директора продаж — добавить их Yandex-логины в `DASHBOARD_ALLOWED_YANDEX_LOGINS`.
4. После прод-доступа: создать test/control ЕПК, заполнить `EXPERIMENT_TARGET_AD_GROUP_IDS`, включить `EXPERIMENT_HOURLY_BID_ENABLED=true`.
5. Telegram approval flow для `unclear`-кандидатов в минус-слова.
6. M5 Tinkoff webhook + Bitrix форма с yclid → offline conversions в Метрику.

## Open issues / known limitations

1. **Прод-доступ к Direct API не получен** — работаем только в sandbox.
2. **AdGroups в sandbox «фантомные»** — добавляются с Id, но не персистятся. Полный e2e только в проде.
3. **WeatherAdjustments через API не работает** (code 3500). Pivot: используем `MobileAdjustment` на AdGroupId как proxy.
4. `OPENAI_API_KEY` не задан на VDS — daily_negatives_job не запускается.
5. `EXPERIMENT_TARGET_AD_GROUP_IDS` пустой — hourly bid loop простаивает.
6. Telegram approval flow не реализован.
7. n8n-ads контейнер запущен без workflow'ов.
8. Directus коллекции `ads_*` не созданы (M3, отложено).
9. Бэкап БД — только через ERP-механизм, отдельных скриптов нет.
10. Нет внешнего uptime-монитора, нет CI/CD (деплой ручной).
11. Координаты Медузы в `scripts/calibrate_weather_curve.py` приблизительные (центр Москвы).

## История разработки

Старт **2026-04-24**, активная фаза:
- 2026-04-24: skeleton + Direct API client (Campaigns/AdGroups/Ads/BidModifiers/Keywords/Reports), Open-Meteo, Alembic.
- 2026-04-25..26: ruff/quirks fixes, эксперимент-план, калибровка кривой на 4-летних данных, корреляция Tinkoff.
- 2026-04-27: hourly bid loop, dashboard MVP, deploy на VDS, Yandex OAuth.
- 2026-04-28: minus-words pipeline, scheduler+telegram digest, **`docs/SYSTEM.md`** (disaster recovery).

Полный лог — `git log` в репо или § история в [[SYSTEM_snapshot_2026-05-01]].



## Связанные заметки

- [[KayakMoscow]] — родительский хаб
- [[SYSTEM_snapshot_2026-05-01]] — полный disaster-recovery снапшот
- [[Infrastructure_VDS]] — общий стек на этом же VDS (Postgres, Directus, n8n, Caddy)
- [[ERP]] — соседний проект
- [[Исследование рекламного продвижения Kayak Moscow на сезон 2026]] — стратегический контекст
- [[Исследование paid-площадок и агрегаторов для Kayak Moscow]] — внешние рекламные каналы
- [[Site]] — Метрика `49922815` стоит в шаблоне Bitrix

## Локально на ноуте

```
/Users/vanya/Documents/KayakMoscow_ads/
├── ads_engine/           Python-пакет (direct_client, weather, llm, negatives, experiment, telegram, db, web)
├── alembic/              миграции БД
├── analysis/             калибровка + weather_demand_correlation.md
├── Archive/              gitignored: money_*.xlsx, Tinkoff отчёты
├── config/weather_bid_policy.yaml   кривая коэффициентов
├── deploy/               Dockerfile + compose + Caddyfile snippet
├── docs/                 SYSTEM.md, architecture, roadmap, api-findings, experiment, oauth-setup
├── scripts/              калибровочные скрипты
├── tests/                240+ тестов
└── .env.local            gitignored, рабочие секреты
```

## Контакты

- Оператор: ИП Рыбников Иван Григорьевич, ИНН 772861688006
- 152-ФЗ / тех.поддержка: info@kayakmoscow.ru
- Личный: vanya.rybnikov@gmail.com
- GitHub: rodeokayaker
- Telegram: 121329929
