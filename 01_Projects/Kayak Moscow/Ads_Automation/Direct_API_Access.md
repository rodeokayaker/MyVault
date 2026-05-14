---
created: 2026-05-14
updated: 2026-05-14
type: reference
project: KayakMoscow
status: reference
tags: [security, oauth, direct-api, access, ai]
parent: "[[Ads_Automation]]"
---

# Direct API Access — как Claude получает доступ

Документ объясняет цепочку доступа от AI-агента (Claude) до Yandex Direct API. Полезен для понимания границ безопасности и процедуры ротации токена.

## TL;DR

Claude **не знает токена напрямую** и не может его регенерировать. Доступ возможен только через:
1. **Shell-доступ к ноуту/VDS пользователя** (через инструменты `Bash` / `ssh`).
2. **Чтение токена средой Python** из `.env` файлов, которые лежат на этих машинах.
3. **HTTPS-запрос с `Authorization: Bearer <token>`** к `api.direct.yandex.com`.

Если потерять `.env` файлы и snapshot'ы — Claude теряет доступ. Если выгнать AI из машины — то же самое.

## Stakeholder-цепочка

```
┌────────────────────────────┐
│ Аккаунт kayakmoscow@yandex.ru │  ← владелец рекламного кабинета
└──────────────┬─────────────┘
               │ создал OAuth-приложение
               ▼
┌────────────────────────────────────────────────┐
│ OAuth-app: 8de9aec8dbe74ae883b4d72028160d36     │
│ host:      oauth.yandex.ru                      │
│ scopes:    direct:api, metrika:read, metrika:write │
│ callback:  https://direct.kayakmoscow.com/oauth/callback │
│            https://oauth.yandex.ru/verification_code     │
│ status:    прод-доступ выдан 2026-05-08         │
└──────────────┬─────────────────────────────────┘
               │ выпустил Bearer-токен (debug, 1 год)
               ▼
┌────────────────────────────────────────────────┐
│ DIRECT_OAUTH_TOKEN (длинная строка)             │
│ срок:    обычно 1 год от выпуска                │
│ scope:   полный доступ к Direct API + Метрика   │
│ единый:  один токен на весь сервис              │
└──────────────┬─────────────────────────────────┘
               │ лежит в .env файлах (см. ниже)
               ▼
┌────────────────────────────────────────────────┐
│ Наш код: httpx.post(                            │
│   "https://api.direct.yandex.com/json/v5/...",  │
│   headers={"Authorization": f"Bearer {token}"}, │
│   json={"method": "...", "params": {...}})      │
└────────────────────────────────────────────────┘
```

## Где живёт токен (3 места)

| Где | Путь | Кто читает | Доступ |
|---|---|---|---|
| Локально на ноуте Ивана | `/Users/vanya/Documents/KayakMoscow_ads/.env.local` | local Python через pydantic-settings | gitignored, chmod 600 |
| Локально (ERP-зеркало) | `/Users/vanya/Documents/KayakMoscow_ERP/.env.local` | тоже самое | gitignored |
| **VDS Timeweb** | `/root/kayak-ads/deploy/.env` | docker-compose → env-vars контейнеров `kayak-ads-engine` и `kayak-ads-web` | chmod 600, root-only |

**Бэкап:** `KayakMoscow_ERP/Docs/credentials.local.md` (gitignored) + копия в 1Password / Bitwarden.

Файл `.env` загружается:
- Локально — `pydantic-settings` ищет `.env.local` затем `.env` в `cwd` при инициализации `Settings()`.
- VDS — `docker-compose.yml` имеет `env_file: .env` → переменные становятся env'ом контейнеров.

## Как Claude технически использует токен

Я выполняю код через инструменты `Bash` / `ssh` через **shell-доступ к машинам пользователя**. Сам токен я **в чистом виде не вижу** (он не печатается на экран); я лишь запускаю код, который его читает из env.

### Сценарий 1: локально на ноуте (Mac)

```bash
# Я запускаю что-то вроде:
.venv/bin/python -c "
from ads_engine.config import get_settings
from ads_engine.direct_client import DirectClient
from ads_engine.direct_client.services import CampaignsService

s = get_settings()          # pydantic-settings → читает .env.local
print(s.direct_api_env)     # 'sandbox' или 'prod'
with DirectClient(base_url=s.direct_base_url, oauth_token=s.direct_oauth_token) as c:
    r = CampaignsService(c).get(field_names=['Id','Name'], limit=5)
    print(r)
"
```

- `get_settings()` лезет в `pydantic_settings.BaseSettings` → читает `.env.local` в `cwd`.
- `s.direct_oauth_token` — строка из env, я её не вижу в выводе если не печатаю явно.
- `DirectClient(...)` инкапсулирует HTTP-вызовы.
- Запрос идёт по HTTPS прямо с моего ноута к `api-sandbox.direct.yandex.com` или `api.direct.yandex.com`.

### Сценарий 2: на VDS через SSH

```bash
# Я выполняю через инструмент Bash:
ssh root@176.124.208.237 "cd /root/kayak-ads && \
  docker compose -f deploy/docker-compose.yml exec -T ads-engine python -c '
    from ads_engine.config import get_settings
    ...
  '"
```

- `ssh` использует **SSH-ключ Ивана**, который лежит в `~/.ssh/` на Mac.
- На VDS я попадаю как `root` — там docker.
- `docker compose exec` запускает Python в контейнере `kayak-ads-engine`, у которого в env уже подгружен `DIRECT_OAUTH_TOKEN` из `deploy/.env`.

Этот путь использую когда нужен **prod-токен** (он только на VDS) и/или **prod-БД** (postgres внутри сети `kayak-network`).

### Что я могу сделать

- Запросить любые методы Direct API, к которым выдан scope: `Campaigns.get/add/update`, `AdGroups.*`, `Ads.*`, `Keywords.*`, `BidModifiers.*`, `Reports.*`, `Audiences.*`, `Метрика.*`.
- Создавать кампании, объявления, ключевые слова.
- Менять корректировки ставок.
- Выгружать отчёты.
- Управлять `ads_runtime_settings` / `ads_campaign_strategy` в БД.

### Что я НЕ могу

- **Регенерировать токен** — для этого нужен интерактивный OAuth-flow с подтверждением от Ивана (открыть `oauth.yandex.ru/authorize?...` в браузере под `kayakmoscow@yandex.ru` и нажать «Разрешить»).
- **Управлять «Товарными кампаниями» (ТК)** — Direct API их не отдаёт даже по прямому Id (см. [[_AI_BRIEF#Известные ограничения]]).
- **Менять список scope'ов токена** — задаётся при выпуске.
- **Загрузить токен в repo** — `.env*` files в `.gitignore`, я в принципе не пишу токен куда-либо где он может попасть в git.

## Endpoints + quotas (на 2026-05-14)

Из ответа `/clients/get` нашего prod-аккаунта:

```
{
  "Login": "kayakmoscow",
  "Currency": "RUB",
  "Restrictions": [
    {"Element": "API_POINTS", "Value": 168000},  ← дневная квота API
    {"Element": "STAT_REPORTS_TOTAL_IN_QUEUE", "Value": 5},
    {"Element": "FORECAST_REPORTS_TOTAL_IN_QUEUE", "Value": 5},
    {"Element": "WORDSTAT_REPORTS_TOTAL_IN_QUEUE", "Value": 5},
    {"Element": "VIDEO_DOMAIN_BLACKLIST_SIZE", "Value": 100}
  ]
}
```

| Параметр | Значение | Комментарий |
|---|---:|---|
| Daily API units | **168 000** | большой запас; типичный day usage <100 |
| Одновременных запросов | 5 | защищено semaphore в `DirectClient` |
| Reports rate limit | 20 / 10 сек | sliding window |
| Reports queue | 5 параллельных |
| Endpoint prod | `https://api.direct.yandex.com/json/v5` (or `/v501`) | |
| Endpoint sandbox | `https://api-sandbox.direct.yandex.com/json/v5` | для тестов |
| Auth header | `Authorization: Bearer <token>` | mandatory |
| Accept-Language | `ru` или `en` | определяет язык error messages |

Текущий env (на 2026-05-14): **`DIRECT_API_ENV=prod`** на VDS.

## Что произойдёт при истечении токена

Yandex вернёт `code 53 "Authorization error"`. Тогда:

1. Зайти на `https://oauth.yandex.ru/authorize?response_type=token&client_id=8de9aec8dbe74ae883b4d72028160d36` в браузере под `kayakmoscow@yandex.ru`.
2. Нажать «Разрешить».
3. Скопировать новый токен из URL после редиректа (`#access_token=...`).
4. Заменить значение `DIRECT_OAUTH_TOKEN=...` в:
   - `~/Documents/KayakMoscow_ads/.env.local` (локально)
   - `/root/kayak-ads/deploy/.env` (VDS)
   - `KayakMoscow_ERP/Docs/credentials.local.md` (бэкап)
5. На VDS: `docker compose -f deploy/docker-compose.yml restart ads-engine ads-web`.

Альтернатива — наш собственный OAuth callback на `direct.kayakmoscow.com/oauth/callback` (используется юзерами дашборда для входа). Технически можно через него получить пользовательский токен, но это другой flow — для API-кабинета используем выпущенный debug-токен.

Пошагово эта процедура описана в `docs/oauth-setup.md` в репо.

## Безопасность

- **`.env` файлы chmod 600**, доступны только владельцу процесса (Иван локально / root на VDS).
- **`.gitignore`** содержит `.env*` — токен никогда не попадает в git.
- **Сам токен передаётся только в `Authorization` header**, никогда в URL или query string (не утечёт в логи прокси).
- **Запросы к Yandex идут по HTTPS** (TLS 1.2+).
- **Логи мутаций** пишутся в локальную таблицу `ads_sync_log` — там params_preview обрезается, sensitive поля не хранятся.
- **Дашборд `direct.kayakmoscow.com`** использует Yandex OAuth с whitelist'ом по логинам — пользователи там логинятся своими аккаунтами и видят интерфейс, но не получают доступа к API-токену (он живёт только в backend env).

## Связанные документы

- В репо: `docs/oauth-setup.md` — пошаговая инструкция настройки OAuth с нуля.
- [[Yandex_Direct_API_Application_2026-05]] — заявка на прод-доступ (что Yandex одобрял).
- [[SYSTEM_snapshot_2026-05-14]] § 5 «Секреты — где живут».
- [[_AI_BRIEF]] — общий контекст проекта для AI-сессий.

## Tl;dr для будущей AI-сессии

Если меня (Claude) спросят «как у тебя есть доступ»:

> У меня нет токена. У меня есть **shell-доступ к Mac пользователя и SSH к его VDS**. На обеих машинах в `.env` лежит `DIRECT_OAUTH_TOKEN`, выпущенный для приложения `8de9aec8db…` владельцем аккаунта `kayakmoscow@yandex.ru`. Я запускаю Python, который читает этот токен из окружения и кладёт в `Authorization: Bearer` header при HTTPS-запросах к `api.direct.yandex.com`. Сам токен я не вижу и не печатаю; ротировать его может только Иван через OAuth flow в браузере.
