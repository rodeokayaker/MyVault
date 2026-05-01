---
created: 2026-03-04
updated: 2026-05-01
type: reference
project: KayakMoscow
status: active
tags: [kayakmoscow, erp, technical, directus, n8n, postgres, docker]
parent: "[[ERP]]"
---

# ERP — техническая документация

**Версия:** 1.2 | **Дата:** Март 2026

## 1. Обзор системы

```
PostgreSQL 16          — база данных (29 таблиц, вся бизнес-логика)
Directus 11.15.4       — веб-интерфейс для администраторов (мобильный доступ)
n8n 2.6.4              — автоматизации (воркфлоу, рассылки, интеграции)
Telegram Bot (через n8n) — быстрые команды для администраторов
Caddy                  — reverse proxy, SSL-сертификаты
Docker Compose         — изоляция окружения на сервере
```

## 2. Сервер

### Характеристики

| Параметр | Значение |
|----------|----------|
| Провайдер | Timeweb |
| IP | `176.124.208.237` |
| ОС | Ubuntu 24.04 LTS |
| Docker | установлен |
| Caddy | кастомная сборка с Cloudflare DNS-plugin |

### Структура директорий

```
/root/
├── kayak/                  ← проект Kayak Moscow
│   ├── docker-compose.yml
│   ├── .env
│   └── schema.sql
│
└── tg-business/            ← другой проект (изолирован, не трогать)
    └── docker-compose.yml
```

### Два изолированных проекта на одном сервере

| Проект | Директория | Docker-сеть | Порты |
|--------|-----------|-------------|-------|
| Kayak Moscow | `/root/kayak/` | `kayak-network` | 5432, 8055, 5679 |
| tg-business | `/root/tg-business/` | `tg-business_default` | 5678 |

## 3. Docker-контейнеры (проект kayak)

| Контейнер | Образ | Порт | Назначение |
|-----------|-------|------|-----------|
| `kayak-postgres` | postgres:16-alpine | 5432 | PostgreSQL |
| `kayak-directus` | directus/directus:latest | 8055 | Админ-панель |
| `kayak-n8n` | n8nio/n8n | 5679→5678 | Автоматизации |

### Управление контейнерами

```bash
ssh root@176.124.208.237
cd /root/kayak

docker compose ps              # статус
docker compose restart         # перезапустить все
docker compose restart directus
docker compose logs -f directus
docker compose logs -f n8n
docker compose down
docker compose up -d
```

## 4. SSL-сертификаты (Caddy + Cloudflare)

**Почему DNS-01:** Timeweb блокирует входящие запросы от Let's Encrypt. Решение — DNS-01 challenge через Cloudflare: Caddy создаёт TXT-запись, LE проверяет. Никакого входящего трафика не нужно.

### Caddyfile (`/etc/caddy/Caddyfile`)

```caddyfile
admin.kayakmoscow.com {
    tls { dns cloudflare {env.CLOUDFLARE_API_TOKEN} }
    encode gzip
    reverse_proxy localhost:8055
}

n8n.kayakmoscow.com {
    tls { dns cloudflare {env.CLOUDFLARE_API_TOKEN} }
    encode gzip
    reverse_proxy localhost:5679
}
```

Cloudflare API Token в `/etc/systemd/system/caddy.service.d/cloudflare.conf`.

### Диагностика Caddy

```bash
systemctl restart caddy
systemctl status caddy
journalctl -u caddy -n 50
/usr/bin/caddy validate --config /etc/caddy/Caddyfile
/usr/bin/caddy list-modules | grep cloudflare
```

## 5. База данных PostgreSQL

### Структура (29 таблиц, 9 модулей)

| Модуль | Таблицы |
|--------|---------|
| Справочники | `locations`, `routes`, `equipment_types`, `pricing` |
| Расписание | `schedule_templates`, `trips`, `booking_counters` |
| Клиенты | `clients`, `client_tags`, `promo_codes`, `group_discounts`, `subscriptions` |
| Бронирование | `bookings`, `booking_history`, `booking_participants`, `boat_allocations` |
| Инвентарь | `equipment_items`, `equipment_transfers`, `equipment_checkouts`, `equipment_maintenance` |
| Персонал | `staff`, `trip_staff_assignments`, `guide_availability` |
| Финансы | `payments`, `refunds`, `guide_payroll`, `payroll_details`, `expenses` |
| Корпоративы | `corporate_events` |
| Коммуникации | `notifications`, `notification_log` |

### Представления (5 штук)

| View | Назначение |
|------|-----------|
| `v_trip_availability` | Доступные места на будущих сплавах |
| `v_tomorrow_trips` | Завтрашние сплавы с гидами |
| `v_inventory_by_location` | Сводка инвентаря по точкам |
| `v_revenue_by_location` | Выручка по точкам помесячно |
| `v_guide_workload` | Загрузка гидов за период |

### Триггеры

| Триггер | Таблица | Что делает |
|---------|---------|-----------|
| `trg_booking_number` | `bookings` | Генерирует KM-ГГГГ-NNNN (WHEN NULL OR 'PENDING') |
| `trg_update_booked_seats` | `bookings` | Обновляет `trips.booked_seats` |
| `trg_update_client_trips` | `bookings` | Обновляет `clients.total_trips` |
| `trg_promo_used_count` | `bookings` | Обновляет `promo_codes.used_count` |
| `trg_subscription_used` | `bookings` | Обновляет `subscriptions.used_trips` |
| `trg_payments_updated` | `payments` | Обновляет `bookings.status` при оплате |

### Ключевые решения схемы

**Нумерация броней** — `booking_number` имеет `DEFAULT 'PENDING'` (нужно Directus для NOT NULL). Триггер перезаписывает перед INSERT. Атомарный upsert в `booking_counters(year, last_number)`.

**Partial unique index:**
```sql
CREATE UNIQUE INDEX idx_unique_group_trip
  ON trips(route_id, trip_date, start_time)
  WHERE trip_type = 'group';
```

**ISO день недели:** 1=Пн, 7=Вс → `EXTRACT(ISODOW FROM date)`.

### Бэкап и восстановление БД

```bash
# Бэкап
docker exec kayak-postgres pg_dump -U kayak kayak_moscow > backup_$(date +%Y%m%d).sql

# Восстановление
docker exec -i kayak-postgres psql -U kayak -d kayak_moscow < backup_20260301.sql

# Подключиться напрямую
docker exec -it kayak-postgres psql -U kayak -d kayak_moscow
```

## 6. Directus

**URL:** `https://admin.kayakmoscow.com` | **Версия:** 11.15.4

### Что настроено

- 31 коллекция, русские названия, иконки, display templates
- Роли: Администратор (124 permissions CRUD), Заведующий точкой (30 permissions)
- 3 пользователя-администратора
- Язык: ru-RU
- Закладки: Завтра, Ожидают оплаты, Свободные места, Корпоративы, Назначения гидов
- Directus Flow: авто-уведомление при создании брони

### Роли

| Роль | Права |
|------|-------|
| Administrator (встроенная) | Полный доступ, включая настройки |
| Администратор | CRUD на все 31 коллекцию |
| Заведующий точкой | Чтение основного + запись снаряжения. Без финансов и промокодов. |

### Модель прав (Directus 11)

```
Role → directus_access → Policy → directus_permissions
```

`/permissions` принимает поле `policy` (не `role`). Привязка policy к role — через psql в `directus_access` (PATCH /roles → 403).

### Directus Flow — новая бронь

| Параметр | Значение |
|----------|----------|
| Flow ID | `8562b135-ce01-4f55-b9c3-2a3fea950b2a` |
| Trigger | `event` → `items.create` → `bookings` |
| Действие | HTTP POST → WF8 n8n → Telegram клиенту |

> [!warning] Нюанс
> API создаёт flow с `trigger: 'hook'`, движок ожидает `'event'`. После создания:
> ```sql
> UPDATE directus_flows SET trigger = 'event' WHERE trigger = 'hook';
> ```
> + перезапуск Directus.

> [!note] Формат headers в operation
> Массив: `[{"header": "Content-Type", "value": "application/json"}]`, не словарь.

## 7. n8n

**URL:** `https://n8n.kayakmoscow.com` | **Версия:** 2.6.4

### Воркфлоу (все активны)

| № | ID | Название | Триггер |
|---|----|----------|---------|
| 1 | `FNLkTldmUYYCTnJy` | Генерация слотов расписания | Cron пн 9:00 |
| 2 | `MDzxZKx8D1pXlflM` | Рассылка номера гида | Cron 18:00 |
| 3 | `AHXWy4CNDUJuArR6` | Напоминание клиентам | Cron 20:00 |
| 4 | `4Rix8Rc7Ybvty6o9` | Webhook Tinkoff | Webhook POST |
| 5 | `2HE1SYT7MRwSWTtE` | Расчёт зарплаты | Cron 1-е и 16-е |
| 6 | `74HpmvzPrHqOpyUY` | Отмена по погоде | Ручной (неактивен) |
| 7 | `a172huRxsYB4b8ec` | Telegram Bot | Webhook (Telegram) |
| 8 | `YcRDoLUMT4BivJ1s` | Уведомление о новой брони | Webhook (Directus) |

### Webhook URL

| | URL |
|--|-----|
| Tinkoff | `.../webhook/4Rix8Rc7Ybvty6o9/webhook tinkoff/tinkoff-payment` |
| Telegram Bot | `.../webhook/a172huRxsYB4b8ec/webhook/tg-bot` |
| Новая бронь | `.../webhook/YcRDoLUMT4BivJ1s/webhook/new-booking` |

База n8n: `n8n_api_kayak_m0sc0w_2026_setup` (API key).

> [!warning] Нюансы при настройке n8n через API
> - **Set node v3.4** через API возвращает `{}` — использовать Code node
> - **Connections** — по именам нод, не по ID (`n1`, `n2`)
> - **Кириллица в именах нод** ломает webhook URL — только латиница для webhook-нод
> - **responseMode: responseNode** — если нода до Respond может упасть, ставить `onError: continueRegularOutput`

## 8. Telegram-бот

| Параметр | Значение |
|----------|----------|
| Токен | `8758244289:AAEsUjBOEsQFGjFuHW3cyruc6dyqUGzyzgg` |
| Webhook | `https://n8n.kayakmoscow.com/webhook/8758244289/webhook` |
| Воркфлоу | WF7 `a172huRxsYB4b8ec` |

Используется Webhook-нод (не TelegramTrigger) — URL стабильный.

## 9. История изменений

| Дата | Событие |
|------|---------|
| Февраль 2026 | Схема БД v1.0 |
| Март 2026 | Схема v1.1: исправлено 9 проблем |
| Март 2026 | Деплой: PostgreSQL + Directus + n8n, SSL |
| Март 2026 | Полная настройка Directus (коллекции, роли, пользователи) |
| Март 2026 | 8 воркфлоу n8n |
| Март 2026 | Directus Flow: авто-уведомление при создании брони |

## 10. Известные ограничения

- **n8n отдельная БД `kayak_n8n`** — иначе загрязняет Directus своими таблицами
- **PATCH /roles → 403** — привязка policy к role только через psql в `directus_access`
- **Caddy — кастомная сборка**, не из apt. Бинарник: `/usr/bin/caddy`
- **Directus Flow trigger** создаётся как `hook`, нужно исправить на `event` в БД
- **Set node v3.4** через API не работает → Code node

## Связанные заметки

- [[ERP]] — карточка проекта
- [[Credentials]] · [[User_Guide]] — документация ERP
- [[KayakMoscow]] — родительский хаб
- [[Infrastructure_VDS]] — карта VDS (общий стек)
- [[Ads_Automation]] — соседний проект на той же инфраструктуре
