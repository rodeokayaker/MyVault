---
created: 2026-05-08
updated: 2026-05-08
type: reference
project: KayakMoscow
status: pending-submission
tags: [kayakmoscow, ads, yandex-direct, application, prod-access]
parent: "[[Ads_Automation]]"
---

# Заявка на прод-доступ Direct API — 2026-05

Готовая спецификация и заполненные поля формы Яндекса для перевода приложения с sandbox на прод-доступ Direct API.

## Статус

**На 2026-05-08:** черновик готов, заявка ещё не отправлена. Подаётся через UI Direct → Инструменты → Настройки API → запрос полного доступа.

## Файлы в репо

`docs/yandex_application/`:
- `spec_short.md` / `spec_short.pdf` (2 стр.) — короткая версия для прикрепления к форме.
- `spec.md` / `spec.pdf` (3 стр.) — расширенная версия (если попросят больше деталей).
- `style.css` / `style_short.css` — для пересборки PDF через `pandoc + headless Chrome`.

Пересборка:
```
cd docs/yandex_application
pandoc spec_short.md -f gfm -t html5 --standalone --css style_short.css --embed-resources -o spec_short.html
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu --no-pdf-header-footer --print-to-pdf=spec_short.pdf "file://$PWD/spec_short.html"
```

## Заполнение формы (готовые тексты)

**Название компании:** ИП Рыбников Иван Григорьевич (Kayak Moscow)
**Сайт:** https://kayakmoscow.ru
**Специфика работы:** Рекламодатель (управляю собственной рекламой) — не агентство, не разработчик SDK.
**Язык программирования:** Python 3.12
**Протокол:** JSON
**Версия библиотек:** httpx 0.27, pydantic 2.7, FastAPI 0.115, SQLAlchemy 2.0, APScheduler 3.10
**Логины в Директе:** `kayakmoscow`

**Для чего предназначено** (галочки):
- ✅ Автоматизировать регулярную работу
- ✅ Синхронизировать с данными внутренних систем (погодные данные + платежи Tinkoff для калибровки)

**Основные функции** (галочки):
- ✅ Получение статистики и отчётов
- ✅ Управление кампаниями и объявлениями
- ✅ Управление ставками (биддинг)

**Какие новые возможности:**
> Автоматизация управления сезонными рекламными кампаниями для микробизнеса: погодная корректировка ставок раз в час по прогнозу Open-Meteo (модель откалибрована на 4-летних данных продаж), автоматическая чистка минус-слов через анализ поисковых запросов LLM, ежедневный дайджест статуса кампаний в Telegram. Снижает рутинный труд оператора и помогает удерживать ROI в сезон.

**Схема взаимодействия:** см. `spec_short.pdf` § 3 (таблица методов API + частота).

**Демо-доступ:**
> https://direct.kayakmoscow.com (Yandex OAuth, whitelist). Логин ревьюера добавляется в whitelist по запросу на info@kayakmoscow.ru — в течение часа.

## Используемые методы Direct API

| Метод | Назначение | Частота |
|---|---|---|
| `Campaigns.get` | Список кампаний для UI | по запросу из дашборда |
| `Campaigns.update` | Обновление NegativeKeywords после approval | редко, по нажатию кнопки |
| `AdGroups.get` | Список групп для UI | по запросу из дашборда |
| `BidModifiers.get/add/update` | Корректировки ставок | до 1/час на AdGroup |
| `Reports` (SEARCH_QUERY_PERFORMANCE) | Поисковые запросы для минус-слов | 1 раз в сутки |
| `Keywords` | Минус-фразы на уровне группы (после approval) | редко |

## Что подчёркнуть в заявке (если будут вопросы)

- **Single-tenant.** Один токен, один аккаунт, не SaaS, не агентский.
- **Apply threshold 5 п.п.** + жёсткий cap [-100%, +50%] — не уроним автостратегию.
- **Per-AdGroup rate limit:** не чаще раза в час.
- **Human-in-the-loop** для всех мутаций минус-слов.
- **OAuth-токен** хранится только на нашем VDS (chmod 600), не в репозитории.
- **Передача данных вовне:** OpenAI получает только query-строки без идентификаторов; Telegram — только агрегированную статистику.

## После одобрения — что делать

1. На VDS заменить `DIRECT_OAUTH_TOKEN` на прод-токен, сменить `DIRECT_API_ENV=prod` (или удалить env-переменную, дефолт sandbox → надо проверить).
2. Перейти в `/dashboard/campaigns` — увидеть реальные ad-group'ы (sandbox их не отдавал).
3. Настроить per-campaign стратегии в `/dashboard/campaigns/{id}/strategy`.
4. Включить `hourly_bid.enabled` в `/dashboard/settings`.
5. Включить `daily_negatives.enabled` (и не забыть `OPENAI_API_KEY` в `.env`).
6. Реализовать реальный push минус-фразы в Direct (`Campaigns.update` read-modify-write) — это пункт 5 в [[Ads_Automation#Ближайшие шаги]].

## Связанные

- [[Ads_Automation]] — основной хаб проекта
- [[SYSTEM_snapshot_2026-05-08]] — disaster recovery (на 2026-04-28)
- [[Runtime_UI_2026-05]] — описание дашборда, на который Яндекс будет смотреть
