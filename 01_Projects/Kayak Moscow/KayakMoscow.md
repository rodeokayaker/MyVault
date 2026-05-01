---
created: 2026-03-11
updated: 2026-05-01
type: hub
project: KayakMoscow
status: active
tags: [kayakmoscow, hub]
---

# KayakMoscow

Бизнес-хаб: каякинг, SUP-прогулки, корпоративные мероприятия в Москве и ближнем Подмосковье. Все рабочие материалы по проекту собираются здесь.

## Сайт

- [[Site]] — хаб по `kayakmoscow.ru` (стек, доступы, бэкап, текущие приоритеты)
- [[Access]] — все креды (SSH, FTP, ISP Manager, Bitrix admin)
- [[Аудит сайта kayakmoscow.ru (2026-04-20)]] — UX, конверсия, контент, техническое SEO
- [[Анализ конкурентов (2026-04-21)]] — `akulovmsk.ru` и `baydaroshnaya.ru`
- [[SEO роудмэп (апрель 2026)]] — что сделано, P0/P1/P2/P3
- [[SEO семантическое ядро и тексты (2026-04-20)]] — кластеры запросов и готовые title/description
- [[SEO-аудит kayakmoscow.ru (исходник 2026-03-16)]] — стартовая точка
- [[SEO-аудит kayakmoscow.ru (проверка актуальности)]] — что уже исправлено

## Маркетинг

- [[Исследование рекламного продвижения Kayak Moscow на сезон 2026]] — медиамикс, CRM, реактивация базы, погодные сценарии
- [[Исследование paid-площадок и агрегаторов для Kayak Moscow]] — KudaGo, Tripster, Sputnik8, Afisha Eventmarket, Timepad
- [[Корпоративное предложение — KayakMoscow (презентация)]] — структура коммерческого офера для event-агентств
- [[Лидлист — event-агентства Москва_МО (корпоратив на каяках)]] — 20 агентств с приоритизацией A/B/C

## Автоматизация рекламы

- [[Ads_Automation]] — Direct API, погодные ставки, минус-слова, dashboard `direct.kayakmoscow.com`
- [[SYSTEM_snapshot_2026-05-01]] — disaster-recovery снапшот репо `rodeokayaker/kayakmoscow-ads`

## Инфраструктура

- [[Infrastructure_VDS]] — Timeweb VDS `176.124.208.237`: Postgres, Directus, n8n, Caddy. Не путать с хостингом сайта `kayakmoscow.ru`.
- Соседний проект: [[ERP]] — общий стек `kayak-postgres`/`kayak-directus`/Caddy

## Локации

- [[Строгино]] — основная база
- [[Архангельское]]
- [[СберСити]]

## TODO (ближайшее)

- [ ] SEO/техничка: убрать редирект-цепочку и `:443` в Location. Сейчас: `https://kayakmoscow.ru/` → `http://www.kayakmoscow.ru/` → `https://www.kayakmoscow.ru:443/` → `200`. Цель: один 301 на `https://www.kayakmoscow.ru/`.
- [ ] Создать `/events/korporativ/`, `/events/den-rozhdeniya/`, `/events/timbilding/`, `/arenda/` (см. [[SEO роудмэп (апрель 2026)]]).
- [ ] Подать заявку на прод-доступ Direct API через UI Direct → Инструменты → Настройки API.
- [ ] Добавить `OPENAI_API_KEY` в `.env` на VDS, иначе `daily_negatives_job` пропускается.

## Связанные заметки

- [[Созвон со Стасом — чеклист (2026-03-11)]] — обсуждения по локациям
- [[ERP]] — соседний проект, общая инфра
