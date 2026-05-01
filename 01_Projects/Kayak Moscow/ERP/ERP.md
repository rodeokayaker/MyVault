---
created: 2026-02-15
updated: 2026-05-01
type: project
project: KayakMoscow
status: active
tags: [kayakmoscow, erp, directus, n8n, postgres, telegram]
parent: "[[KayakMoscow]]"
---

# ERP

Система автоматизации бизнеса Kayak Moscow — водные прогулки, 3 точки базирования ([[Строгино]], [[Архангельское]], Медуза/Троице-Лыково).

## Стек

```
PostgreSQL 16     — 29 бизнес-таблиц, вся логика на триггерах
Directus 11.15.4  — веб-интерфейс для администраторов
n8n 2.6.4         — 8 воркфлоу автоматизации
Telegram Bot      — команды для администраторов через n8n
Caddy             — reverse proxy + SSL (Cloudflare DNS-01)
Docker Compose    — всё в контейнерах, сервер Timeweb
```

## Доступы

- Directus: `https://admin.kayakmoscow.com`
- n8n: `https://n8n.kayakmoscow.com`
- Сервер: `ssh root@176.124.208.237`
- Все ключи: [[Credentials]]

## Документация

- [[Technical]] — архитектура, сервер, БД, Directus, n8n, известные особенности
- [[User_Guide]] — инструкция для администраторов (ежедневная работа)
- [[Credentials]] — ключи доступа ко всем сервисам

## Что сделано

- [x] Схема БД v1.1 — 29 таблиц, триггеры, views
- [x] Деплой: PostgreSQL + Directus + n8n в Docker
- [x] SSL через Cloudflare DNS-01
- [x] Directus: 31 коллекция, роли, права, закладки, русский язык
- [x] 8 воркфлоу n8n: расписание, гиды, напоминания, Tinkoff, зарплата, бот, уведомления
- [x] Telegram-бот для администраторов
- [x] Directus Flow: авто-уведомление клиенту при создании брони

## Что осталось

- [ ] Корпоративное предложение: согласовать финальную версию; назначить встречу со Стасом
- [ ] Переименовать admin1/2/3 в реальные имена
- [ ] Tinkoff: Terminal Key + Secret, прописать webhook URL
- [ ] Проверить бота в боевом режиме
- [ ] Онлайн-бронирование (отдельная история — сайт)

## Связанные заметки

- [[KayakMoscow]] — родительский хаб
- [[Technical]] · [[User_Guide]] · [[Credentials]] — документация ERP
- [[Infrastructure_VDS]] — общий стек на этом же VDS (Postgres/Directus/n8n/Caddy)
- [[Ads_Automation]] — соседний проект, делит контейнер `kayak-postgres`
- [[Site]] — связанная история про онлайн-бронирование
- [[Корпоративное предложение — KayakMoscow (презентация)]] — B2B-направление
- [[MOC_Projects]]
