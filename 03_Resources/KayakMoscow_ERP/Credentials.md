---
type: resource
tags: [kayak, erp, credentials, secrets]
updated: 2026-03-04
project: "[[01_Projects/KayakMoscow_ERP/Project]]"
---

# Kayak Moscow — Ключи доступа

> [!danger] Чувствительные данные
> Не передавать посторонним, не хранить в публичных репозиториях.

→ [[Technical]] | [[User_Guide]] | [[01_Projects/KayakMoscow_ERP/Project]]

---

## Сервер (VPS)

| Параметр | Значение |
|----------|----------|
| IP | `176.124.208.237` |
| Провайдер | Timeweb |
| ОС | Ubuntu 24.04 |
| Пользователь | `root` |
| Доступ | SSH-ключ (пароль отключён) |

```bash
ssh root@176.124.208.237
```

---

## Directus

**URL:** https://admin.kayakmoscow.com

### Суперадмин (технический)

| Поле | Значение |
|------|----------|
| Email | `admin@kayakmoscow.com` |
| Пароль | `AwFO1AXuqDErbX9Fv81o` |
| Роль | Administrator (встроенная) |

### Аккаунты администраторов

| Email | Пароль | Роль |
|-------|--------|------|
| `admin1@kayakmoscow.com` | `Admin1_2025!` | Администратор |
| `admin2@kayakmoscow.com` | `Admin2_2025!` | Администратор |
| `admin3@kayakmoscow.com` | `Admin3_2025!` | Администратор |

> Пароли временные — сменить при первом входе.

---

## n8n

**URL:** https://n8n.kayakmoscow.com

| Поле | Значение |
|------|----------|
| Логин | `admin` |
| Пароль | `h63gjorknudyKu0Z28Rc` |
| API Key | `n8n_api_kayak_m0sc0w_2026_setup` |

---

## PostgreSQL

**Доступ только с сервера** (порт не открыт наружу)

| Параметр | Значение |
|----------|----------|
| Host | `localhost` / `kayak-postgres` (внутри Docker) |
| Port | `5432` |
| Пользователь | `kayak` |
| Пароль | `yZLaQXbJG6zgpNM9bBQTeRVlKzHe` |
| БД бизнес-логики | `kayak_moscow` |
| БД n8n | `kayak_n8n` |

```bash
docker exec -it kayak-postgres psql -U kayak -d kayak_moscow
```

---

## Cloudflare

| Параметр | Значение |
|----------|----------|
| Домен | `kayakmoscow.com` |
| API Token (DNS-challenge) | `xL_NlXhilyd6PdjyFraBRbbq0RqUpSK868oI0ehj` |

Токен используется Caddy для SSL через DNS-01.

---

## Telegram Bot

| Параметр | Значение |
|----------|----------|
| Имя | Kayak Moscow Admin |
| Токен | `8758244289:AAEsUjBOEsQFGjFuHW3cyruc6dyqUGzyzgg` |
| Webhook URL | `https://n8n.kayakmoscow.com/webhook/8758244289/webhook` |

---

## Directus — внутренние ID

### Роли

| Роль | ID |
|------|----|
| Администратор | `a09e2bb4-6ab9-47e0-9947-35d0dad41011` |
| Заведующий точкой | `d373ef9e-7217-423f-911d-79be9795e3e5` |

### Политики прав

| Политика | ID |
|----------|----|
| Администратор — полный доступ | `afcb866e-8bca-4152-9fb9-75a1d3349d76` |
| Заведующий точкой — доступ | `265cce69-1e92-4c75-8e57-c04b62f8b5e2` |

### Directus Flow

| | ID |
|--|---|
| Flow (новая бронь) | `8562b135-ce01-4f55-b9c3-2a3fea950b2a` |
| Operation (HTTP request) | `bd3c324e-c96b-493f-a1a5-f3f7cb520c21` |

---

## n8n — воркфлоу

| ID | Название |
|----|---------:|
| `FNLkTldmUYYCTnJy` | 1. Генерация слотов |
| `MDzxZKx8D1pXlflM` | 2. Рассылка номера гида |
| `AHXWy4CNDUJuArR6` | 3. Напоминания клиентам |
| `4Rix8Rc7Ybvty6o9` | 4. Tinkoff webhook |
| `2HE1SYT7MRwSWTtE` | 5. Расчёт зарплаты |
| `74HpmvzPrHqOpyUY` | 6. Отмена по погоде |
| `a172huRxsYB4b8ec` | 7. Telegram Bot |
| `YcRDoLUMT4BivJ1s` | 8. Уведомление о новой брони |

---

## Переменные окружения на сервере

Файл: `/root/kayak/.env`

```env
DB_PASSWORD=yZLaQXbJG6zgpNM9bBQTeRVlKzHe
DIRECTUS_SECRET=yNiDgzvMehMTu7iYFduf0VKitJNF5hDgZLRm
DIRECTUS_ADMIN_EMAIL=admin@kayakmoscow.com
DIRECTUS_ADMIN_PASSWORD=AwFO1AXuqDErbX9Fv81o
N8N_USER=admin
N8N_PASSWORD=h63gjorknudyKu0Z28Rc
N8N_HOST=n8n.kayakmoscow.com
```

Cloudflare токен: `/etc/systemd/system/caddy.service.d/cloudflare.conf`

```ini
[Service]
Environment=CLOUDFLARE_API_TOKEN=xL_NlXhilyd6PdjyFraBRbbq0RqUpSK868oI0ehj
```

---

## DNS-записи (Cloudflare)

| Запись | Тип | Значение | Проксирование |
|--------|-----|----------|---------------|
| `admin.kayakmoscow.com` | A | `176.124.208.237` | Выключено (серый) |
| `n8n.kayakmoscow.com` | A | `176.124.208.237` | Выключено (серый) |

Трафик идёт напрямую — Caddy сам терминирует TLS.
