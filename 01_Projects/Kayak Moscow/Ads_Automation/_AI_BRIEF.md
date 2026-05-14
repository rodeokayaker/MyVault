---
created: 2026-05-14
updated: 2026-05-14
type: ai-brief
project: KayakMoscow
status: active
tags: [ai-brief, onboarding, ads, automation]
parent: "[[Ads_Automation]]"
---

# AI Brief — Kayak Moscow Ads Automation

> Файл для быстрого онбординга AI-агента (Claude и др.) в проект. Читай в указанном порядке — после прочтения ты понимаешь систему.

## Что это за проект

Внутренний сервис **ИП Рыбников И.Г.** (ИНН 772861688006) для автоматизации рекламы **Kayak Moscow** (прокат каяков и SUP-досок) в Яндекс Директе. Не SaaS, один аккаунт `kayakmoscow@yandex.ru`. Сезонный бизнес: пик июнь-август, активный сезон май-октябрь.

Сайт: https://kayakmoscow.ru
Базы проката: Серебряный бор, Архангельское, Истра.

## Что делает сервис (4 контура)

1. **Hourly bid loop** — каждый час по погодному прогнозу обновляет `BidModifier`-корректировки ставок per-campaign (своя кривая на каждую кампанию из `ads_campaign_strategy`).
2. **Daily negatives pipeline** — раз в сутки тянет `SEARCH_QUERY_PERFORMANCE_REPORT`, прогоняет через OpenAI gpt-4o-mini, кандидаты в БД на approval-flow.
3. **Daily Telegram digest** — HTML-сводка в Telegram оператору.
4. **Защищённый web-dashboard** — `https://direct.kayakmoscow.com` (Yandex OAuth + whitelist), 8 страниц.

## Текущее состояние (2026-05-14)

- **Прод-доступ Direct API получен** (2026-05-08).
- В Direct **4 живые кампании**:
  - `709824114` — Поиск-Бренд (создана 2026-05-12)
  - `709824286` — Поиск-Generic (создана 2026-05-12)
  - `709893520` — РСЯ-Wide (создана 2026-05-14, ждёт креативы)
  - `709824342` — Погодный-Эксперимент (создана 2026-05-12)
- Дашборд live на `direct.kayakmoscow.com`, OAuth whitelist = `kayakmoscow`.
- Все джобы пока выключены в `ads_runtime_settings` — ждут включения через UI.
- `OPENAI_API_KEY` ещё не задан на VDS → `daily_negatives_job` молчит.

## Порядок чтения файлов

### 1. Контекст и состояние
1. [[Ads_Automation]] — **главный хаб проекта**. Стек, инфраструктура, секреты, roadmap, история.
2. [[Roadmap_2026]] — полный roadmap сезона 2026 с этапами и сроками.
3. [[Live_Campaigns_2026-05]] — что сейчас в Direct (3 кампании, ID, привязки).

### 2. Аналитика и стратегия
4. [[Archive_Analysis_2026-05]] — анализ 18 архивных кампаний 2023-2025 (1.05M ₽ расхода, выводы).
5. [[Cost_Weather_Correlation_2026-05]] — Pearson cost↔weather +0.287, CPL по бинам.
6. [[Ads_Strategies_2026]] — 5 YAML-пресетов кривых (`brand` / `generic` / `rsya_wide` / `retargeting` / `weather_experiment`).

### 3. Техническая платформа
7. [[Runtime_UI_2026-05]] — описание дашборда, runtime settings, страницы.
8. [[Direct_API_Access]] — **как Claude (я) технически имеет доступ к Direct API**, ротация токена, scope'ы, quotas.
9. [[Yandex_Direct_API_Application_2026-05]] — заявка на прод-доступ (одобрена), демо-доступ.
10. [[SYSTEM_snapshot_2026-05-14]] — полный disaster-recovery (источник: `docs/SYSTEM.md` в репо).

### 4. Соседние проекты
- [[KayakMoscow]] — родительский хаб бизнеса.
- [[Infrastructure_VDS]] — общая инфраструктура (Postgres, Directus, Caddy, n8n).
- [[ERP]] — соседний проект (общий стек, бронирования).

## Где живёт код

- Репо: `rodeokayaker/kayakmoscow-ads` (private).
- Локально: `/Users/vanya/Documents/KayakMoscow_ads/`.
- VDS: `root@176.124.208.237:/root/kayak-ads/`.
- Текущий HEAD: `77c309b` (на 2026-05-14).

## Где живут секреты

**Не в Obsidian.** Указатели — см. [[Ads_Automation#Где живут секреты]]. Бэкап — `KayakMoscow_ERP/Docs/credentials.local.md` + 1Password.

## Ключевые ID и URLs

| Что | Где | ID/URL |
|---|---|---|
| Direct OAuth app | `8de9aec8dbe74ae883b4d72028160d36` | oauth.yandex.ru |
| Метрика счётчик | `49922815` | metrika.yandex.ru |
| Cloudflare zone | `c92881d1c3af0e830cb705923cf87f88` | — |
| VDS | Timeweb | `176.124.208.237` |
| Дашборд | live | https://direct.kayakmoscow.com |
| Telegram bot | `@kayakmoscowads_bot` | id 8271201222 |

## Ближайшие шаги (приоритет)

1. **Дождаться модерации** 3 кампаний в Direct, пополнить баланс ≥10k ₽, включить в UI.
2. **Включить hourly_bid.enabled** в `/dashboard/settings` после активации кампаний.
3. **Положить OPENAI_API_KEY** в `/root/kayak-ads/deploy/.env` → включить `daily_negatives.enabled`.
4. Whitelist маркетолога/директора в `DASHBOARD_ALLOWED_YANDEX_LOGINS`.
5. Подготовить РСЯ-Wide (#3) и Ретаргетинг (#4) **через UI Direct'a** — креативы и аудитории Метрики через API не делаются.
6. Реализовать реальный push минус-фраз в Direct (`Campaigns.update` с `NegativeKeywords`, read-modify-write).
7. M5 Tinkoff webhook + Bitrix форма с yclid → offline conversions в Метрику.

## Известные ограничения

1. **«Товарные кампании» (ТК) не доступны через Direct API** — даже по прямому Id. Управляются только UI Direct'a. У нас 3 активные ТК автопилотятся Yandex AI, мы их не трогаем.
2. **`SEARCH_QUERY_PERFORMANCE_REPORT` для архивных кампаний пустой** — Yandex retention.
3. **`DailyBudget` несовместим с автостратегиями** (`AVERAGE_CPC`, `WB_MAXIMUM_CLICKS` и т.п.) — контроль только через `WeeklySpendLimit`.
4. **В text fields объявлений запрещены unicode-символы** (`★ • ✓ → ⭐`) — Yandex code 5002.
5. **`AdGroups.update` для `NegativeKeywords` — replace, не append** (нужен read-modify-write).

## Полезные команды

```bash
# Локально
.venv/bin/python -m pytest -q          # 327 passed, 3 deselected
.venv/bin/python -m ruff check .       # All checks passed
.venv/bin/python scripts/create_campaigns_2026.py --all     # dry-run кампаний

# VDS — deploy
ssh root@176.124.208.237 'cd /root/kayak-ads && git pull && \
  docker compose -f deploy/docker-compose.yml build ads-engine && \
  docker compose -f deploy/docker-compose.yml up -d --force-recreate ads-engine ads-web'

# VDS — проверка
ssh root@176.124.208.237 'docker compose -f /root/kayak-ads/deploy/docker-compose.yml ps'
ssh root@176.124.208.237 'docker logs --tail 30 kayak-ads-engine'

# Dashboard URL
https://direct.kayakmoscow.com/dashboard
```

## Контакты

- Оператор: ИП Рыбников Иван Григорьевич, ИНН 772861688006
- Email: info@kayakmoscow.ru, vanya.rybnikov@gmail.com
- Telegram: 121329929
- GitHub: rodeokayaker
