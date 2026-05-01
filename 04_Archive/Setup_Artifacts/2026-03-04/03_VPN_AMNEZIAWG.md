---
type: archive
status: archived
tags: [archive]
updated: 2026-05-01
---

# VPN: миграция на AmneziaWG

## Что сделано
- Установлены инструменты AmneziaWG:
  - `awg`
  - `awg-quick`
  - `amneziawg-go`
- Активный конфиг:
  - `/etc/amnezia/amneziawg/awg0.conf`
- Применен конфиг из файла:
  - `amnezia_for_awg.conf`
- Отключен старый автозапуск WireGuard:
  - `wg-quick@wg0` disabled
- Включен автозапуск AmneziaWG:
  - `awg-quick@awg0` enabled

## Команды управления (как и просили)
- Включить VPN:
```bash
vpnon
```
- Выключить VPN:
```bash
vpnoff
```
- Статус:
```bash
vpnstatus
```

## Split tunnel / исключения (в обход VPN)
- Файл доменов:
  - `/etc/amnezia/bypass-domains.txt`
- Включены гос-домены (в т.ч. `mos.ru`, `gosuslugi.ru` и связанные).
- Маршруты исключений добавляются при `vpnon`.

После изменения списка:
```bash
vpnoff
vpnon
```

## Проверка сервиса
```bash
systemctl is-enabled awg-quick@awg0
systemctl is-active awg-quick@awg0
```

## Бэкапы
- Старые скрипты и конфиги сохранены с суффиксами `.bak-*` / `.wg.bak-*`.

## Связанные заметки
- [[MOC_Home]]
