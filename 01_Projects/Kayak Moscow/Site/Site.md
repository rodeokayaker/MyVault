---
created: 2026-05-01
updated: 2026-06-08
type: hub
project: KayakMoscow
status: active
tags: [kayakmoscow, site, bitrix]
parent: "[[KayakMoscow]]"
---

# kayakmoscow.ru — сайт

Хаб по сайту [kayakmoscow.ru](https://www.kayakmoscow.ru). Это рабочий каталог `/Users/vanya/Documents/KayakMoscow_site/` — административная папка для правок на проде, не код-репозиторий.

## Стек и инфраструктура

- **CMS:** 1С-Битрикс
- **Хостинг:** shared hosting под управлением ISP Manager
- **Сервер:** IP `212.57.115.253`, SSH-пользователь `kayaking`
- **Канонический URL:** `https://www.kayakmoscow.ru/` (без `www` уходит через лишний редирект)
- **Bitrix admin:** `https://www.kayakmoscow.ru/bitrix/admin/`
- **ISP Manager:** `https://188.120.226.124:1500/ispmgr`

> Не путать с инфраструктурой n8n/Directus — она на отдельном Timeweb VDS, см. [[Infrastructure_VDS]].

## Доступы

Все креды (SSH, FTP, ISP Manager, Bitrix admin) — в [[Access]]. Источники в рабочем каталоге: `KayakMoscow_site/dostup.txt`, `KayakMoscow_site/site_passwd`.

## Бэкап

В `/Users/vanya/Documents/KayakMoscow_site/backup/` лежит точечный снапшот живого сайта:
- `kayakmoscow_db_*.sql.gz` — дамп MySQL (~1.7 МБ)
- `kayakmoscow_files_*.tar.gz` + part-файлы — полная Bitrix-инсталляция (~2.5 ГБ)

Чтобы восстановить: распаковать tar в webroot и залить SQL в БД, прописанную в `/bitrix/.settings.php` или `/bitrix/php_interface/dbconn.php`.

## Документы

- [[Аудит сайта kayakmoscow.ru (2026-04-20)]] — UX, продажи, контент, конверсия, техническое SEO
- [[Анализ конкурентов (2026-04-21)]] — сравнение с `akulovmsk.ru` и `baydaroshnaya.ru`
- [[SEO роудмэп (апрель 2026)]] — что сделано, P0/P1/P2/P3 задачи
- [[SEO семантическое ядро и тексты (2026-04-20)]] — кластеры запросов и готовые title/description/SEO-тексты по страницам
- [[SEO-аудит kayakmoscow.ru (исходник 2026-03-16)]] — стартовая точка
- [[SEO-аудит kayakmoscow.ru (проверка актуальности)]]
- [[Apex-домен недоступен у части пользователей (2026-06-08)]] — диагноз DPI-блокировки apex у пользователя, что выкатил (JSON-LD logo, HSTS через ISPmanager), готовый текст тикета хостеру
- [[Brand colors]] — бренд-цвета (#14343B тёмный, #EA0440 красный) + пути к векторным исходникам логотипа

## Аналитика

В рабочем каталоге `Yandex Analytics/`:
- `Поисковые запросы-2025-05-01-2026-04-20.csv` — поисковые запросы за год (источник для семантики)
- `www.kayakmoscow.ru_*.xlsx` / `*.csv` — выгрузки Метрики

Скриншоты Метрики: `Screenshots/2026-04-20 16.11.*.jpg`. Логотипы и брендинг — `logo MAX/`.

## Текущие приоритеты (на 2026-05-01)

Из [[SEO роудмэп (апрель 2026)]] техническая база закрыта. Следующий рычаг роста — **количество страниц**:

- **P0:** добавить `/privacy/` в sitemap; добить редирект-цепочку до одного 301; проверить `noindex` на `/calendar/detail.php`
- **P1:** создать страницы `/events/korporativ/`, `/events/den-rozhdeniya/`, `/events/timbilding/`, `/arenda/`; разметка `BreadcrumbList` и `TouristTrip`
- **P2:** локационные посадочные ([[Строгино]], Серебряный Бор, [[Архангельское]], Живописный мост); блог из 5 статей; «байдарки» в title `/calendar/`

Главный вывод [[Анализ конкурентов (2026-04-21)|конкурентного анализа]]: у Акуловых 127 страниц, у БайдароШной 57, у нас ~18. Каждая новая страница — отдельная точка входа из поиска.

## Связанные заметки

- [[KayakMoscow]] — родительский хаб
- [[Access]] — доступы к серверу и админке
- [[Исследование рекламного продвижения Kayak Moscow на сезон 2026]] — место сайта в общем медиамиксе
- [[Ads_Automation]] — Yandex Метрика счётчик `49922815` стоит в шаблоне Bitrix
