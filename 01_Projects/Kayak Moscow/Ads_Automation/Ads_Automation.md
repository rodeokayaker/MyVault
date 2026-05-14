---
created: 2026-05-01
updated: 2026-05-14
type: project
project: KayakMoscow
status: active
tags: [kayakmoscow, ads, automation, yandex-direct]
parent: "[[KayakMoscow]]"
repo: rodeokayaker/kayakmoscow-ads
local_path: /Users/vanya/Documents/KayakMoscow_ads
last_commit: 77c309b
---

# Kayak Moscow — Ads Automation

Внутренний сервис для автоматизации рекламы Kayak Moscow в Яндекс Директе. Не SaaS, один аккаунт `kayakmoscow@yandex.ru`. Оператор: ИП Рыбников И.Г. (ИНН 772861688006).

> 🎯 **Точка входа для AI-агента в новой сессии:** [[_AI_BRIEF]].
> 📋 **Roadmap сезона 2026:** [[Roadmap_2026]].
> 🔧 **Disaster recovery:** [[SYSTEM_snapshot_2026-05-14]] (источник правды — `docs/SYSTEM.md` в репо).

## Текущее состояние (2026-05-14)

- ✅ **Прод-доступ Direct API получен** 2026-05-08.
- ✅ **4 кампании созданы в Direct prod** (см. [[Live_Campaigns_2026-05]]):
  - 709824114 — Поиск-Бренд (2026-05-12)
  - 709824286 — Поиск-Generic (2026-05-12)
  - 709893520 — РСЯ-Wide (2026-05-14, ждёт креативы)
  - 709824342 — Погодный-Эксперимент (2026-05-12)
- 🟡 **Ждут модерации Yandex + пополнения баланса + включения через UI.**
- ⏳ После активации — включить `hourly_bid.enabled` в `/dashboard/settings`.

## Goal

Закрыть рутину Direct API руками: погодные ставки, чистка минус-слов, дайджест, реактивация базы — всё через код, с гардрейлами от ломки автостратегий Яндекса.

## Что делает (4 контура)

1. **Hourly bid loop** — каждый час пересчитывает погодный индекс (Open-Meteo) и обновляет `MobileAdjustment` BidModifier'ы у целевых AdGroup'ов. **Per-campaign:** каждая кампания имеет свою кривую в `ads_campaign_strategy`. Forward-looking X = √(today × next_weekend).
2. **Daily negatives pipeline** — раз в сутки тянет SEARCH_QUERY_PERFORMANCE_REPORT за 7 дней (с `CampaignId`), прогоняет через OpenAI gpt-4o-mini, кандидаты в `ads_negative_candidates` со статусом `pending`. Approve/Reject — через дашборд (`/dashboard/negatives`).
3. **Daily Telegram digest** — HTML-сводка в `@kayakmoscowads_bot`, получатели в `TELEGRAM_CHAT_IDS`.
4. **Public dashboard** — `https://direct.kayakmoscow.com` (landing + 152-ФЗ + Yandex OAuth + 8 защищённых страниц).

## Runtime controls (с 2026-05-07)

Все тогглы и расписания — в БД (`ads_runtime_settings`), читаются через `RuntimeConfig` с TTL-кэшем 30 сек. Меняются через `/dashboard/settings`, scheduler подхватывает через `_config_reload` job (каждую минуту). Подробно: [[Runtime_UI_2026-05]].

- `hourly_bid.enabled` + cron preset (`hourly` / `every_30m` / `every_2h`)
- `daily_negatives.enabled` + cron preset (`daily_03` / `daily_06` / `weekly_mon_03`)
- `daily_digest.enabled` + cron preset (`daily_09` / `daily_18` / `twice_daily`)

Старые env-флаги (`EXPERIMENT_HOURLY_BID_ENABLED`, `EXPERIMENT_TARGET_AD_GROUP_IDS`) **больше не читаются scheduler'ом** — управление полностью через UI.

## Стратегии и кампании

Подробно: [[Ads_Strategies_2026]] (5 YAML-пресетов) + [[Live_Campaigns_2026-05]] (3 живые кампании).

| Кампания | Тип API | Преcет (YAML) | Лимит | CPL-таргет | Статус |
|---|---|---|---:|---:|---|
| #1 Поиск-Бренд | UNIFIED_CAMPAIGN | `brand` | 4 900 ₽/нед | 600 ₽ | 🟡 MODERATION |
| #2 Поиск-Generic | UNIFIED_CAMPAIGN | `generic` | 10 500 ₽/нед | 1 000 ₽ | 🟡 MODERATION |
| #3 РСЯ-Wide | UNIFIED_CAMPAIGN (network) | `rsya_wide` | 18 000 ₽/нед | 870 ₽ | 🟡 ждёт креативы |
| #4 Ретаргетинг | UNIFIED_CAMPAIGN | `retargeting` | — | 850 ₽ | ⏳ через UI Direct (нужны Аудитории) |
| #5 ⭐ Погодный-Эксп. | UNIFIED_CAMPAIGN | `weather_experiment` | 4 200 ₽/нед | — | 🟡 MODERATION |
| 3× ТК (Каяки) | Master (вне API) | — | автопилот | — | running |

**Бюджет на сезон: 1.5 млн ₽** (см. [[Roadmap_2026#Бюджет на сезон 1 5 млн ₽]]).

## Стек

Python 3.12, httpx, pydantic v2, FastAPI, SQLAlchemy 2.0, Alembic, APScheduler, Jinja2, pytest. Postgres 16 (БД `kayak_ads` в общем `kayak-postgres`). Docker Compose. Caddy reverse-proxy + Cloudflare DNS-01.

327 passed, 3 deselected. Ruff clean.

## Инфраструктура

- **VDS Timeweb**: `176.124.208.237` (Ubuntu, 4ГБ RAM, 50ГБ NVMe + 2ГБ swap), root SSH.
- **Домены** (Cloudflare zone `c92881d1c3af0e830cb705923cf87f88`):
  - `direct.kayakmoscow.com` → `kayak-ads-web:8090` (FastAPI)
  - `n8n-ads.kayakmoscow.com` → `kayak-ads-n8n:5680`
- **Контейнеры наши**: `kayak-ads-engine` (scheduler), `kayak-ads-web` (uvicorn), `kayak-ads-n8n`. Сеть `kayak-network`.
- **БД**: `kayak_ads` в общем `kayak-postgres` (стек ERP).
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

## Калибровка и аналитика

Подробно: [[Archive_Analysis_2026-05]] + [[Cost_Weather_Correlation_2026-05]].

**Основные находки:**
- Pearson(weather_index, payment_amount) = **+0.579**, по числу платежей **+0.616** (Tinkoff archive 2024-2026).
- Pearson(daily_cost, weather_index) = **+0.287** (Direct cost vs weather, 316 совпавших дней).
- CPL по бинам: bad weather 1 352 ₽ → ideal weather 930 ₽ (разница **31%**).
- Архив 2023-2025: 18 кампаний, 1.05M ₽, 987 конверсий, CPL средний 1 069 ₽.
- Лучший CPL года — июль (855 ₽), пиковые конверсии — август (272).
- Forward-looking X = √(today × next_weekend) обыгрывает компоненты на 14%.
- Формула индекса: `0.5·gauss(t, μ=24, σ=5) + 0.3·dry(p) + 0.2·clear(c)`.
- Боевой default: `config/weather_bid_policy.yaml`; per-campaign — в БД.

## Где живут секреты

Не в Obsidian. Указатели:

| Секрет | Где |
|---|---|
| `DIRECT_OAUTH_*`, `DATABASE_URL`, `TELEGRAM_BOT_TOKEN` | `KayakMoscow_ERP/.env.local` + `KayakMoscow_ads/.env.local` + VDS `/root/kayak-ads/deploy/.env` |
| `DASHBOARD_SESSION_SECRET` | VDS `.env` (генерим заново) |
| `OPENAI_API_KEY` | **пока не задан на VDS** (см. Open issues) |
| `CLOUDFLARE_API_TOKEN` | VDS `/etc/systemd/system/caddy.service.d/cloudflare.conf` + `KayakMoscow_ERP/Docs/credentials.local.md` |
| `KAYAK_DB_PASSWORD` | VDS `/root/kayak/.env` (общий kayak-postgres) |

Бэкап критичных секретов — копия `KayakMoscow_ERP/Docs/credentials.local.md` в 1Password / Bitwarden.

## Roadmap (статус на 2026-05-14)

Полный с этапами и сроками — в [[Roadmap_2026]]. Краткая сводка:

- ✅ M1 Sandbox foundation
- ✅ M2 Weather loop + reports + калибровка
- ⏸ M3 Directus config — закрыт нашим UI (не нужен)
- ✅ M4 Dashboard + OAuth + **прод-доступ Direct API одобрен 2026-05-08**
- ✅ M5 Minus-words pipeline + approval flow
- ✅ Runtime UI + per-campaign стратегии (2026-05-07)
- ✅ M5.1 Анализ архивов + калибровка + 5 YAML-пресетов + декларации кампаний (2026-05-09..12)
- 🟢 M6 Production switch — 3 кампании создал, ждём модерацию (2026-05-12..16)
- ⏳ M6.1 РСЯ + Ретаргетинг через UI Direct
- ⏳ M6.2 Push минус-фраз в Direct
- ⏳ M6.3 Первая ревизия (конец июня)
- ⏳ M7 Audiences + сезонный режим (июль)
- ⏳ M8 VK Ads (июль)
- ⏳ M9 Offline conversions через Tinkoff webhook (сентябрь-октябрь)
- ⏳ M10 Зимний режим (ноябрь+)

## Ближайшие шаги (приоритет сверху вниз)

1. **Дождаться модерации** 3 кампаний в Direct + пополнить баланс ≥10 000 ₽.
2. **Включить кампании** в Direct UI (по умолчанию State=OFF).
3. **В нашем UI:** для каждой из 3 кампаний на `/dashboard/campaigns/{id}/strategy` нажать `enabled=true`. В `/dashboard/settings` включить `hourly_bid.enabled` (после активации в Direct).
4. **Добавить `OPENAI_API_KEY`** в `/root/kayak-ads/deploy/.env` на VDS → перезапустить engine → включить `daily_negatives.enabled`.
5. **Whitelist маркетолога и директора** — добавить их Yandex-логины в `DASHBOARD_ALLOWED_YANDEX_LOGINS`.
6. **Создать РСЯ-Wide (#3) и Ретаргетинг (#4) через UI Direct** (нужны креативы + Аудитории Метрики, API не подходит).
7. **Реализовать push минус-фраз в Direct** (`Campaigns.update` с `NegativeKeywords`, read-modify-write).
8. **M5 Tinkoff webhook + Bitrix форма с yclid** → offline conversions в Метрику.

## Open issues / known limitations

1. ~~Прод-доступ к Direct API не получен~~ — ✅ **одобрено 2026-05-08**.
2. ~~AdGroups в sandbox «фантомные»~~ — больше не релевантно, работаем в prod.
3. **WeatherAdjustments через API не работает** (code 3500). Используем `MobileAdjustment` на AdGroupId как proxy.
4. **`OPENAI_API_KEY` не задан на VDS** → `daily_negatives_job` не запускается даже при `enabled=true`.
5. **Push минус-фразы в Direct не реализован** — approval flow помечает в БД, но `Campaigns.update`/`Keywords.add` ещё не вызывает.
6. **«Товарные кампании» (ТК) не доступны через Direct API** — даже по прямому Id (см. [[_AI_BRIEF#Известные ограничения]]). Управляются только UI Direct'a.
7. n8n-ads контейнер запущен без workflow'ов.
8. Бэкап БД — только через ERP-механизм, отдельных скриптов нет.
9. Нет внешнего uptime-монитора, нет CI/CD (деплой ручной).
10. Координаты Медузы в `scripts/calibrate_weather_curve.py` приблизительные (центр Москвы).
11. **`DailyBudget` несовместим с автостратегиями** Yandex (code 6000) — контроль через `WeeklySpendLimit`.
12. **Title/Title2/Text — узкий whitelist** (Yandex code 5002 на ★ • ✓ → ⭐). Pre-flight `check_unicode()` в скрипте.

## История разработки

Старт **2026-04-24**, активная фаза:

- **2026-04-24:** skeleton + Direct API client (Campaigns/AdGroups/Ads/BidModifiers/Keywords/Reports), Open-Meteo, Alembic.
- **2026-04-25..26:** ruff/quirks fixes, эксперимент-план, калибровка кривой на 4-летних данных, корреляция Tinkoff.
- **2026-04-27:** hourly bid loop, dashboard MVP, deploy на VDS, Yandex OAuth.
- **2026-04-28** (`fd95bcc`): minus-words pipeline, scheduler+telegram digest, `docs/SYSTEM.md` (disaster recovery).
- **2026-05-07** (`93d1c05` + `35bfaf9`): per-campaign стратегии + runtime UI + approval flow.
  - `ads_runtime_settings` + `RuntimeConfig` (TTL 30s).
  - `ads_campaign_strategy` (per-campaign кривая + ad-groups).
  - Soft-toggle scheduler + `_config_reload`.
  - 5 новых страниц дашборда.
  - 84 новых теста (всего 324 passed).
- **2026-05-08** (`0c94458`): спецификация для заявки на прод-доступ Direct API (`docs/yandex_application/spec_short.pdf`, 2 стр.); **прод-доступ одобрен в тот же день**; `DIRECT_API_ENV=prod`.
- **2026-05-09** (`618bef7`): анализ архивных кампаний 2023-2025 (1.05M ₽ расхода, 7 actionable выводов).
- **2026-05-12** (`d132beb` + `1cb558f` + `20114f3` + `5556b91`): UI preset selector, 5 YAML-пресетов кривых (`config/strategies/`), 3 декларации кампаний (`config/campaigns_2026/`), скрипт `create_campaigns_2026.py`, корреляция cost↔weather +0.287, **3 кампании созданы в Direct prod**.
- **2026-05-14** (`77c309b`): unicode pre-flight + auto-retry на code 1000 в скрипте; 4 новых quirk'а в `docs/SYSTEM.md` (DailyBudget/code 5002/code 1000/NegativeKeywords replace); полное обновление Obsidian-документации.

Полный лог — `git log` в репо или § история в [[SYSTEM_snapshot_2026-05-14]].

## Связанные заметки

- [[_AI_BRIEF]] — **точка входа для AI-агента**
- [[Roadmap_2026]] — полный roadmap сезона
- [[Live_Campaigns_2026-05]] — 3 живые кампании (IDs, привязки, чеклист включения)
- [[Ads_Strategies_2026]] — 5 YAML-пресетов кривых
- [[Archive_Analysis_2026-05]] — анализ архивов 2023-2025
- [[Cost_Weather_Correlation_2026-05]] — Pearson cost↔weather
- [[Runtime_UI_2026-05]] — описание дашборда
- [[Direct_API_Access]] — **как Claude получает доступ к Direct API** (security/oauth)
- [[Yandex_Direct_API_Application_2026-05]] — заявка (одобрена)
- [[SYSTEM_snapshot_2026-05-14]] — disaster-recovery (свежий)
- [[SYSTEM_snapshot_2026-05-08]] — предыдущий снапшот (исторический)
- [[SYSTEM_snapshot_2026-05-01]] — самый ранний снапшот
- [[KayakMoscow]] — родительский хаб
- [[Infrastructure_VDS]] — общий стек на этом же VDS
- [[ERP]] — соседний проект
- [[Исследование рекламного продвижения Kayak Moscow на сезон 2026]] — стратегический контекст
- [[Исследование paid-площадок и агрегаторов для Kayak Moscow]] — внешние рекламные каналы
- [[Site]] — Метрика `49922815` стоит в шаблоне Bitrix

## Локально на ноуте

```
/Users/vanya/Documents/KayakMoscow_ads/
├── ads_engine/           Python-пакет (direct_client, weather, llm, negatives,
│                         experiment, telegram, db, web, runtime_config, scheduler)
├── alembic/              миграции БД (7 версий, последняя — 7dba2eceabc7)
├── analysis/             калибровка + weather_demand_correlation.md +
│                         archive_campaigns_analysis_2026-05-09.md +
│                         correlation_cost_weather_2026-05-12.md +
│                         2026_campaigns_proposal.md +
│                         analyze_archive_campaigns.py + correlate_cost_weather.py
├── Archive/              gitignored: money_*.xlsx, Tinkoff отчёты
├── config/
│   ├── weather_bid_policy.yaml     дефолтная кривая
│   ├── strategies/                 5 YAML-пресетов per-campaign кривых
│   │   ├── brand.yaml      conservative ±20%
│   │   ├── generic.yaml    normal ±50%
│   │   ├── rsya_wide.yaml  aggressive ±70%
│   │   ├── retargeting.yaml weighted_mean today=0.3
│   │   └── weather_experiment.yaml very_aggressive ±90%
│   └── campaigns_2026/             3 декларации кампаний (input для скрипта)
│       ├── brand.yaml
│       ├── generic.yaml
│       └── weather_experiment.yaml
├── deploy/               Dockerfile + compose + Caddyfile snippet
├── docs/
│   ├── SYSTEM.md         disaster recovery (обновлён 2026-05-14)
│   ├── architecture.md / roadmap.md / api-findings.md / experiment-hourly-bid.md / oauth-setup.md
│   └── yandex_application/spec_short.pdf  заявка в Direct (одобрена)
├── scripts/
│   ├── create_campaigns_2026.py    создание кампаний через API
│   └── calibrate_weather_curve.py  калибровка
├── tests/                327 passed
└── .env.local            gitignored, рабочие секреты
```

## Контакты

- Оператор: ИП Рыбников Иван Григорьевич, ИНН 772861688006
- 152-ФЗ / тех.поддержка: info@kayakmoscow.ru
- Личный: vanya.rybnikov@gmail.com
- GitHub: rodeokayaker
- Telegram: 121329929
