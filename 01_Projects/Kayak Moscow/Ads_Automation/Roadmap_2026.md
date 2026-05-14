---
created: 2026-05-14
updated: 2026-05-14
type: roadmap
project: KayakMoscow
status: active
tags: [roadmap, ads, planning, 2026]
parent: "[[Ads_Automation]]"
---

# Roadmap — сезон 2026

Полный roadmap проекта `kayakmoscow-ads` для сезона 2026. Источник правды — этот файл; `docs/roadmap.md` в репо является срезом, может отставать.

## Статус-легенда

- ✅ done
- 🟢 active (в работе)
- 🟡 pending (ждёт внешнее событие)
- ⏳ planned
- ⏸ paused
- ❌ cancelled

## Этапы (milestones)

### ✅ M1 — Sandbox foundation (2026-04-24..26)

- Direct API client (Campaigns/AdGroups/Ads/BidModifiers/Keywords/Reports).
- Open-Meteo + index formula.
- Alembic + SQLAlchemy 2.0 + Postgres.
- Тесты на mock'ах, ruff/mypy конфигурация.

### ✅ M2 — Weather loop + Reports + калибровка (2026-04-26..28)

- HourlyBidLoop с двух-режимной кривой.
- ForwardLookingIndex = √(today × weekend).
- Калибровка: Pearson(revenue, weather) = +0.579.
- SEARCH_QUERY_PERFORMANCE_REPORT парсинг.

### ⏸ M3 — Directus коллекции `ads_*`

**Закрыт через UI наш дашборд** — runtime settings + per-campaign strategies → нет необходимости в Directus как админке.

### ✅ M4 — Dashboard + OAuth + заявка на прод-доступ (2026-04-27..2026-05-08)

- FastAPI dashboard с Yandex OAuth + whitelist (2026-04-27).
- 7 защищённых страниц.
- Спецификация (2 стр. PDF) для заявки в Direct (2026-05-08).
- **Прод-доступ Direct API одобрен 2026-05-08.**
- Переключение `DIRECT_API_ENV=sandbox → prod` 2026-05-08.

### ✅ M5 — Minus-words pipeline + approval flow (2026-04-28..2026-05-07)

- Pipeline Reports → LLM → БД (`ads_negative_candidates`).
- Approval UI на `/dashboard/negatives` (decision: pending/approved/rejected).
- Push минус-фразы в Direct — **отложен** до накопления реальных кандидатов на прод-кампаниях.

### ✅ Runtime UI + per-campaign стратегии (2026-05-07)

- `ads_runtime_settings` + `RuntimeConfig` (TTL 30s).
- `ads_campaign_strategy` (per-campaign кривая + target ad-groups).
- Soft-toggle scheduler + `_config_reload` каждую минуту.
- 5 новых страниц дашборда.
- 84 новых теста (324 всего).

### ✅ M5.1 — Анализ и стратегия сезона 2026 (2026-05-09..12)

- [[Archive_Analysis_2026-05]] — анализ 18 архивных кампаний.
- [[Cost_Weather_Correlation_2026-05]] — Pearson cost↔weather +0.287.
- [[Ads_Strategies_2026]] — 5 YAML-пресетов кривых.
- 3 декларации кампаний в `config/campaigns_2026/`.
- `scripts/create_campaigns_2026.py` — автогенерация кампаний через API.

### 🟢 M6 — Production switch (2026-05-12..16, в процессе)

- ✅ 3 кампании созданы в Direct prod (2026-05-12): brand 709824114, generic 709824286, weather_experiment 709824342.
- 🟡 Модерация Yandex — ждём.
- 🟡 Баланс на счету — пополнить ≥10 000 ₽.
- 🟡 Включение кампаний в Direct UI после модерации.
- 🟡 Включение `hourly_bid.enabled` в `/dashboard/settings`.
- 🟡 Включение `daily_negatives.enabled` (после `OPENAI_API_KEY` в `.env`).
- 🟡 Whitelist маркетолога и директора в `DASHBOARD_ALLOWED_YANDEX_LOGINS`.

### ⏳ M6.1 — РСЯ + Ретаргетинг руками в UI (2026-05-17..23)

- **Только через UI Direct'a** — креативы (баннеры/видео) и аудитории Метрики через API не делаются.
- РСЯ-Wide (#3) — креативы 2-3 баннера + 1 видео ≤15 сек.
- Ретаргетинг (#4) — настроить аудитории Метрики: «без брони 14 дней» / «hot pricing» / look-alike к платившим.
- После создания — подключить в наш дашборд через `/dashboard/campaigns/{id}/strategy` (preset rsya_wide / retargeting).

### ⏳ M6.2 — Push минус-фраз в Direct (после ≥2 недель работы)

- Реализовать `Campaigns.update` с `NegativeKeywords` (read-modify-write).
- Обновить approval-handler в дашборде — после Approve действительно пушить в Direct.
- Тестирование на 1 кампании.

### ⏳ M6.3 — Первая ревизия (конец июня)

- Первая ревизия через 4 недели после старта.
- Анализ CPL, конверсий, корреляции с погодой.
- Пересборка `Ads_Strategies_2026` на per-campaign данных.

### ⏳ M7 — Audiences + сезонный режим (июль 2026)

- Расширенные сегменты Метрики (новые vs возвращающиеся).
- Сезонный «турбо-режим» для пиковых выходных по прогнозу.
- Look-alike по Tinkoff платежам через Аудитории Yandex.

### ⏳ M8 — VK Ads (июль 2026)

- Параллельный канал на VK Ads (структура повторяет Direct).
- Тестовая кампания на 50k ₽/месяц.
- Сравнение CPL с Direct.

### ⏳ M9 — Пост-сезон + offline conversions (сентябрь-октябрь 2026)

- Tinkoff webhook → Bitrix форма с yclid → offline conversions в Метрику.
- Полный merge: Direct cost ↔ Tinkoff revenue per-campaign.
- Финальный отчёт сезона.

### ⏳ M10 — Зимний режим (ноябрь 2026 — апрель 2027)

- Зимняя кампания (Истра / лыжные прогулки) — повторить эксперимент 2023-2024.
- Минимальный поддерживающий бюджет (≤10k ₽/мес).
- Подготовка к сезону 2027.

## Бюджет на сезон (1.5 млн ₽)

| Месяц | Доля | ₽ | Что активно |
|---|---:|---:|---|
| апрель | 8% | 120 k | Бренд + малый РСЯ (pre-season) |
| май | 12% | 180 k | Полный запуск |
| июнь | 15% | 225 k | Подключение ретаргетинга |
| **июль** | **20%** | **300 k** | Лучший CPL года (855 ₽) |
| **август** | **22%** | **330 k** | Пиковые конверсии |
| сентябрь | 17% | 255 k | Хвост сезона |
| октябрь | 6% | 90 k | Только ретаргетинг + микро-РСЯ |

Подробно: [[Archive_Analysis_2026-05#9 Что взять в работу для сезона 2026]].

## KPI (еженедельно)

- CPL по каждой кампании vs target (см. [[Ads_Strategies_2026]]).
- Доля mobile (норма: spend 50-60%, conv 60-70%).
- CTR: поиск ≥4%, РСЯ ≥0.8%, ретаргетинг ≥1.5%.
- Pearson(daily_cost, weather_index) — после 30 дней.
- Pending negatives — чистить раз в 2-3 дня через approval.

## Зависимости (внешние блокеры)

1. **Модерация Direct** — обычно 1-3 часа, до суток.
2. **OPENAI_API_KEY** на VDS — нужен для daily_negatives.
3. **Баланс Direct** — пополнить с РКО.
4. **Аудитории Метрики** — настроить через UI Метрики для ретаргетинга.
5. **Креативы для РСЯ** — баннеры/видео от маркетолога.

## Risk register

- **CPC ×5 в 2025 vs 2023** → бюджет 1.5 млн может закончиться раньше плана. Мониторить weekly.
- **ТК-каннибализация** → наша Generic-поисковая конкурирует с архивной ТК. Через 2 недели проверить в Метрике; победитель остаётся.
- **Слабая корреляция Direct cost ↔ weather** (+0.287) → ожидать −5..−10% CPL у эксперимента, не больше.
- **VDS падение** → нет HA, нет внешнего uptime-монитора. Disaster recovery — [[SYSTEM_snapshot_2026-05-14]].
- **Yandex меняет правила** → подписка на их changelog не настроена.
