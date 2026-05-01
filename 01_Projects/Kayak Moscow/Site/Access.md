---
created: 2026-05-01
updated: 2026-05-01
type: reference
project: KayakMoscow
status: active
tags: [kayakmoscow, site, credentials, secrets]
parent: "[[Site]]"
---

# kayakmoscow.ru — доступы

> Vault локальный, в облако не синхронизируется. Источники: `KayakMoscow_site/dostup.txt`, `KayakMoscow_site/site_passwd`.

## SSH

- Host: `212.57.115.253`
- User: `kayaking`
- Password: `pD2wR0tJ3e`

```
ssh kayaking@212.57.115.253
```

## FTP

- Host: `212.57.115.253`
- User: `kayaking`
- Password: `yB6xC3cE3f`

## ISP Manager (панель хостинга)

- URL: `https://212.57.115.253:1500/ispmgr` (по dostup.txt)
- Альтернативный URL из CLAUDE.md: `https://188.120.226.124:1500/ispmgr`
- Логин/пароль: те же, что у SSH (`kayaking` / `pD2wR0tJ3e`)

## Bitrix admin

- URL: `https://www.kayakmoscow.ru/bitrix/admin/`
- Пароль из `dostup.txt`: `E8c-MFf-mxj-y4A`
- Пароль из `site_passwd`: `tryitnow1`

> Два пароля — расхождение между файлами. Проверить, какой актуален; вероятно один — старый.

## Связанные заметки

- [[Site]] — хаб по сайту
- [[KayakMoscow]] — родительский хаб
- [[Infrastructure_VDS]] — отдельные доступы к VDS (не путать)
