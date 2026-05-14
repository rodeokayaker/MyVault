---
created: 2026-05-08
updated: 2026-05-08
type: reference
project: KayakMoscow
status: active
tags: [kayakmoscow, ads, ui, dashboard, runtime]
parent: "[[Ads_Automation]]"
last_commit: 0c94458
---

# Runtime UI и per-campaign стратегии

Описание новых страниц дашборда (`https://direct.kayakmoscow.com`) и схемы runtime-настроек, появившихся 2026-05-07 в коммите `93d1c05`.

## Идея

Раньше всё управлялось через env-переменные (`EXPERIMENT_HOURLY_BID_ENABLED`, `EXPERIMENT_TARGET_AD_GROUP_IDS`) — менять = редактировать `.env` на VDS и рестартить контейнер. Теперь все тогглы и расписания — в БД, scheduler читает их через `RuntimeConfig` с TTL-кэшем 30 сек, изменения в UI применяются на ближайшем тике (≤ 1 минуты через `_config_reload` job).

## Таблицы БД (новые)

- **`ads_runtime_settings`** — key/value store горячих настроек. PK `key`, value `Text`, audit `updated_at` + `updated_by_login`.
  - Ключи: `hourly_bid.enabled`, `hourly_bid.cron_preset`, `daily_negatives.enabled`, `daily_negatives.cron_preset`, `daily_digest.enabled`, `daily_digest.cron_preset`.
- **`ads_campaign_strategy`** — per-campaign конфиг hourly bid loop.
  - PK `campaign_id` (BigInt), `name`, `enabled`, `target_ad_group_ids` (JSON-массив), `policy_json` (JSON: combiner + curve + caps + apply_threshold), `updated_at`, `updated_by_login`.
- **`ads_negative_candidates`** — добавлены поля `campaign_id` (nullable) и `decision` (`pending`/`approved`/`rejected`).

## Cron-пресеты

| Job | Пресет | APScheduler kwargs |
|---|---|---|
| `hourly_bid` | `hourly` | `minute=5` |
|  | `every_30m` | `minute='5,35'` |
|  | `every_2h` | `hour='*/2', minute=5` |
| `daily_negatives` | `daily_03` | `hour=3, minute=0` |
|  | `daily_06` | `hour=6, minute=0` |
|  | `weekly_mon_03` | `day_of_week='mon', hour=3, minute=0` |
| `daily_digest` | `daily_09` | `hour=9, minute=0` |
|  | `daily_18` | `hour=18, minute=0` |
|  | `twice_daily` | `hour='9,18', minute=0` |

Все стартуют выключенными — после деплоя нужно зайти в UI и включить вручную.

## Страницы дашборда

| Путь | Что |
|---|---|
| `/dashboard` | Главная: окружение (env, hourly loop on/off, кол-во включённых стратегий, ad-groups), решения за 24 часа, навигация |
| `/dashboard/settings` | Карточки 3 джобов: тоггл + dropdown пресета. POST → `ads_runtime_settings`, scheduler подхватит ≤1 мин |
| `/dashboard/campaigns` | Список из Direct + статус привязанной стратегии (включена/выключена/нет) + ссылка «Настроить →» |
| `/dashboard/campaigns/{id}/strategy` | Редактор стратегии: имя, enabled, multiselect ad-group'ов из Direct, 5+5 бинов кривой (будни/выходные), live-превью текущего coefficient |
| `/dashboard/weather` | Индекс + сырые поля (температура, осадки, облачность, ветер) + per-campaign превью ставки на следующий тик |
| `/dashboard/decisions` | Журнал решений + фильтр по `campaign_id` |
| `/dashboard/negatives` | Approval flow: фильтры (decision/label) + кнопки Approve / Reject. Approve = `decision=approved` в БД, push в Direct ещё не реализован |

**Добавлено 2026-05-12:** На странице `/dashboard/campaigns/{id}/strategy?preset=NAME` — дропдаун выбора YAML-пресета (`brand` / `generic` / `rsya_wide` / `retargeting` / `weather_experiment`). Подставляет кривую в форму без сохранения — посмотреть и сохранить руками. См. [[Ads_Strategies_2026]].

## Что осознанно НЕ сделано

- Реальный push минус-фразы в Direct (`Campaigns.update` с `NegativeKeywords`) — отложено до прод-доступа, в sandbox AdGroups «фантомные» и тестировать невозможно.
- История изменений `ads_runtime_settings` — храним только текущее значение + `updated_by_login` (по решению Ивана).
- Свободный cron-выражение и редактор YAML — только пресеты, чтобы не сломать в 3 ночи.
- Bulk-actions для approval (по одному).
- Multi-роли (admin/viewer) — whitelist остаётся плоским.

## Тесты

84 новых теста, всего 324 passed (`pytest`):
- `test_runtime_config.py` (32) — TTL-кэш, get/set, парсинг bool/enum, cron-пресеты.
- `test_campaign_strategy.py` (10) — модель, repo (get/list/upsert/seed), policy roundtrip.
- `test_scheduler.py` (13) — `decide_cron_changes`, action-функции с тогглами.
- `test_web_settings.py` (8) — UI настроек.
- `test_web_strategy.py` (6) — UI стратегий.
- `test_web_weather_decisions.py` (4) — погода + фильтр decisions.
- `test_web_negatives.py` (10) — approval flow.
- `test_weather_open_meteo.py` (+1) — `wind_speed_ms`.

## Деплой 2026-05-07

```bash
ssh root@176.124.208.237
cd /root/kayak-ads
git pull   # → 35bfaf9
docker compose -f deploy/docker-compose.yml build ads-engine
docker compose -f deploy/docker-compose.yml run --rm ads-engine alembic upgrade head
docker compose -f deploy/docker-compose.yml up -d --force-recreate ads-engine ads-web
```

3 миграции применились: `bf3e24766039` → `04abb30f16e0` → `7dba2eceabc7`.

После деплоя в логах scheduler видно:
```
registered hourly_bid with preset=hourly
registered daily_negatives with preset=daily_03
registered daily_digest with preset=daily_09
registered _config_reload (every minute)
Scheduler started
```

## Связанные

- [[Ads_Automation]] — основной хаб
- [[Yandex_Direct_API_Application_2026-05]] — заявка на прод-доступ
- [[SYSTEM_snapshot_2026-05-08]] — свежий disaster-recovery снапшот
