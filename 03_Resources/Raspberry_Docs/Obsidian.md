# Obsidian на Raspberry Pi

## Vault
- Основной vault:
  - `/home/vanya/Obsidian/OpenClawVault`
- На Mac клон:
  - `/Users/vanya/Documents/Obsidian/MainVault`

## Что настроено
- Obsidian установлен глобально как AppImage:
  - `/opt/obsidian/Obsidian-arm64.AppImage`
- Команда запуска:
  - `/usr/local/bin/obsidian`
- Desktop entry:
  - `/usr/share/applications/obsidian.desktop`
- Синхронизация vault через Syncthing (Raspberry <-> Mac).
- `.obsidian/` исключен из синхронизации (разные настройки на устройствах).

## Как запускать Obsidian
В графической сессии Raspberry:
```bash
obsidian
```

## Важно
- У Obsidian нет текстового интерфейса.
- По SSH без GUI окно не откроется.
- Markdown-файлы можно редактировать в терминале.

## Syncthing (ручной режим)
На Raspberry:
```bash
vaultsync-on
vaultsync-off
```

На Mac:
```bash
/opt/homebrew/opt/syncthing/bin/syncthing serve --no-browser --no-restart --home="$HOME/Library/Application Support/Syncthing"
```

Примечание:
- Автозапуск Syncthing не включен.
- Периодическая синхронизация идет пока Syncthing запущен (watcher + rescan).

## Интеграция с OpenClaw
- Индексация памяти читает vault:
  - `/home/vanya/Obsidian/OpenClawVault`
- После массовых изменений:
```bash
sudo -u vanya openclaw memory index --agent main --force
```
