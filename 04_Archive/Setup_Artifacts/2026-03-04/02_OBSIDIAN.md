# Obsidian на Raspberry Pi

## Что сделано
- Подготовлен vault:
  - `/home/vanya/Obsidian/OpenClawVault`
- В vault созданы стартовые файлы (`README.md`, `00-Inbox.md`).
- Obsidian установлен глобально как AppImage:
  - `/opt/obsidian/Obsidian-arm64.AppImage`
- Добавлен запуск через команду:
  - `/usr/local/bin/obsidian`
- Добавлен desktop-файл:
  - `/usr/share/applications/obsidian.desktop`

## Как запускать
- В графической сессии Raspberry:
```bash
obsidian
```

## Важно
- Obsidian не имеет текстового режима.
- По SSH без GUI окно не откроется (нужна локальная desktop-сессия, VNC, RDP и т.п.).
- Сами заметки (`.md`) можно редактировать в терминале обычными редакторами.

## Интеграция с OpenClaw
- OpenClaw читает этот vault через memory index.
- После массовых изменений заметок полезно делать:
```bash
openclaw memory index --agent main --force
```

