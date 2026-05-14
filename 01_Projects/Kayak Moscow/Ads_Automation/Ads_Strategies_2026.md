---
created: 2026-05-14
updated: 2026-05-14
type: reference
project: KayakMoscow
status: active
tags: [strategies, ads, yaml, weather, bidding]
parent: "[[Ads_Automation]]"
---

# Ads Strategies 2026 — YAML-пресеты

5 YAML-пресетов погодных кривых под разные кампании. Хранятся в репо: `config/strategies/*.yaml`. Подключаются к кампаниям через `ads_campaign_strategy.policy_json`.

## Структура пресета

```yaml
version: 1
combiner:
  type: geometric_mean    # или weighted_mean / today_only / weekend_only
  today_weight: 0.5       # только для weighted_mean
weekend_lookahead_days: 7
curve:
  weekday:
    - { lower: 0.85, coefficient_pct: 10 }
    - { lower: 0.65, coefficient_pct: 20 }
    - { lower: 0.45, coefficient_pct: 5 }
    - { lower: 0.25, coefficient_pct: -25 }
    - { lower: 0.0,  coefficient_pct: -40 }
  weekend: [...]   # та же структура
caps:
  min_pct: -100
  max_pct: 50
apply_threshold_pct: 5    # минимум п.п. для отправки в Direct
```

`combined_x = √(today × weekend)` (geometric_mean) → ищется первый бин снизу-вверх с `lower ≤ x` → возвращает `coefficient_pct`, ограниченный `caps`.

## Пресеты

| Файл | Профиль | Амплитуда (wd) | Амплитуда (we) | Под кампанию | CPL-таргет |
|---|---|:---:|:---:|---|---:|
| `brand.yaml` | conservative | -10..+10 | -10..+15 | #1 Поиск-Бренд | 600 ₽ |
| `generic.yaml` | normal (откалиброванный) | -40..+20 | -60..+45 | #2 Поиск-Generic | 1 000 ₽ |
| `rsya_wide.yaml` | aggressive | -60..+30 | -70..+50 | #3 РСЯ-Wide | 870 ₽ |
| `retargeting.yaml` | conservative-warm (weighted_mean today=0.3) | -20..+15 | -25..+20 | #4 Ретаргетинг | 850 ₽ |
| `weather_experiment.yaml` | very_aggressive | -80..+50 | -90..+50 | #5 Погодный-Эксп. | — (test) |

## Детальные кривые

### `brand.yaml` — conservative

Бренд работает в любую погоду — узкая амплитуда.

| X bin | weekday % | weekend % |
|---|---:|---:|
| ≥0.85 | +10 | +15 |
| 0.65-0.85 | +5 | +10 |
| 0.45-0.65 | 0 | +5 |
| 0.25-0.45 | -5 | -5 |
| <0.25 | -10 | -10 |

caps: [-20, +20], threshold 5 п.п.

### `generic.yaml` — normal (откалиброванный)

Реплика дефолтного `weather_bid_policy.yaml`.

| X bin | weekday % | weekend % |
|---|---:|---:|
| ≥0.85 | +10 | +45 |
| 0.65-0.85 | +20 | +30 |
| 0.45-0.65 | +5 | +10 |
| 0.25-0.45 | -25 | -40 |
| <0.25 | -40 | -60 |

caps: [-100, +50], threshold 5 п.п.

### `rsya_wide.yaml` — aggressive

РСЯ сильнее зависит от погоды (импульсивные клики).

| X bin | weekday % | weekend % |
|---|---:|---:|
| ≥0.85 | +25 | +50 |
| 0.65-0.85 | +30 | +35 |
| 0.45-0.65 | +10 | +15 |
| 0.25-0.45 | -35 | -50 |
| <0.25 | -60 | -70 |

caps: [-100, +50], threshold **3 п.п.** (часто меняем).

### `retargeting.yaml` — conservative-warm

Тёплая аудитория решает не по сегодняшней погоде. **`weighted_mean today=0.3`** — больше веса прогнозу выходных. `weekend_lookahead_days: 14`.

| X bin | weekday % | weekend % |
|---|---:|---:|
| ≥0.85 | +15 | +20 |
| 0.65-0.85 | +10 | +15 |
| 0.45-0.65 | 0 | +5 |
| 0.25-0.45 | -10 | -15 |
| <0.25 | -20 | -25 |

caps: [-30, +25], threshold 5 п.п.

### `weather_experiment.yaml` — very_aggressive

Максимальная амплитуда — тестируем эффект на узкой кампании #5.

| X bin | weekday % | weekend % |
|---|---:|---:|
| ≥0.85 | +50 | +50 |
| 0.65-0.85 | +35 | +40 |
| 0.45-0.65 | +10 | +15 |
| 0.25-0.45 | -50 | -60 |
| <0.25 | -80 | -90 |

caps: [-100, +50], threshold **2 п.п.** (ловим каждое движение).

## Калибровка

Подобраны на основе:
- **Калибровка `analysis/weather_demand_correlation.md`** (4 года продаж + 2 743 Tinkoff платежа) → Pearson(revenue, weather) = +0.579.
- **Корреляция `analysis/correlation_cost_weather_2026-05-12.md`** (316 совпадающих дней Direct cost ↔ weather) → Pearson(cost, weather) = +0.287.
- **Бинная аналитика CPL** ([[Cost_Weather_Correlation_2026-05]]):
  - bad weather (X < 0.45): CPL ~1 352 ₽
  - ideal weather (X ≥ 0.85): CPL ~930 ₽
  - **разница 31%** — окно для нашей корректировки.

После 30 дней живых данных по #5 пересобрать кривые на per-campaign срезе.

## Декларации кампаний

В репо: `config/campaigns_2026/*.yaml` — input для `scripts/create_campaigns_2026.py`. Каждая декларация:

```yaml
key: brand
strategy_yaml: brand   # ссылка на config/strategies/brand.yaml

campaign:
  name: "[2026] Поиск-Бренд"
  start_date: 2026-05-16
  strategy:
    type: WB_MAXIMUM_CLICKS
    weekly_spend_rubles: 4900
    bid_ceiling_rubles: 25
    network: SERVING_OFF
  # daily_budget_rubles: 700   ← НЕ работает с автостратегиями (Yandex code 6000)

ad_group:
  name: "AG-1 / Бренд"
  region_ids: [1]   # 1 = Москва+МО, 213 = только Москва
  negative_keywords: [...]

ads:
  - title: ...    # ≤56 символов, латиница/кириллица/цифры/пунктуация (Yandex code 5002 на ★ • ✓)
    title2: ...   # ≤30
    text: ...     # ≤81
    href: ...     # с utm_source/campaign/medium

keywords: [...]
```

3 декларации в репо:
- `config/campaigns_2026/brand.yaml`
- `config/campaigns_2026/generic.yaml`
- `config/campaigns_2026/weather_experiment.yaml`

РСЯ-Wide (#3) и Ретаргетинг (#4) — **не автоматизируются** (нужны креативы + Аудитории Метрики, через UI Direct'a).

## Запуск создания

```bash
# Dry-run (валидация + предпросмотр)
.venv/bin/python scripts/create_campaigns_2026.py --all

# Apply через VDS (там prod-токен)
ssh root@176.124.208.237 'docker compose -f /root/kayak-ads/deploy/docker-compose.yml \
  exec -T ads-engine python /app/scripts/create_campaigns_2026.py --only brand --apply'
```

Скрипт делает:
1. Pre-flight: unicode-проверка + структура (`check_unicode()`).
2. `Campaigns.add` → получаем `campaign_id`.
3. `AdGroups.add` с `NegativeKeywords` → `ad_group_id`.
4. `Ads.add_text_ads` со списком текстов.
5. `Keywords.add` со списком ключей.
6. `ads_campaign_strategy.upsert` с подключённым YAML-пресетом (`enabled=false`).

Auto-retry на `code 1000` (с backoff 3→6→12 сек) на каждом шаге.

## Что подключено к каким кампаниям (на 2026-05-14)

| Direct campaign_id | preset | Live (Direct) | Enabled (наш UI) |
|---:|---|:---:|:---:|
| 709824114 (Бренд) | `brand` | MODERATION | false |
| 709824286 (Generic) | `generic` | MODERATION | false |
| 709824342 (Эксперимент) | `weather_experiment` | MODERATION | false |

## Как поменять кривую

1. Через UI: `/dashboard/campaigns/{id}/strategy?preset=brand` подставит pre-fill из YAML; правишь поля бинов; «Сохранить».
2. Через файл: правишь `config/strategies/<preset>.yaml` → коммит → push → редеплой → переподключить пресет в UI (для существующих кампаний — не подхватится автоматически, нужно вручную).

## Связанные

- [[Ads_Automation]] — главный хаб
- [[Live_Campaigns_2026-05]] — что сейчас в Direct
- [[Cost_Weather_Correlation_2026-05]] — на чём калибровали
- [[Archive_Analysis_2026-05]] — почему такие пресеты
- [[Roadmap_2026]] — план сезона
