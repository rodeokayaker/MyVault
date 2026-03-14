# OpenClaw на Raspberry Pi

## Что настроено
- OpenClaw установлен на Raspberry Pi.
- Для агента `main` подключено локальное хранилище заметок Obsidian через memory index.
- У агента `main` в конфиге задан дополнительный путь памяти:
  - `/home/vanya/Obsidian/OpenClawVault`
- Индексация памяти по этому пути работает.

## Ключевые пути
- Vault Obsidian:
  - `/home/vanya/Obsidian/OpenClawVault`
- OpenClaw memory path в конфиге:
  - `agents.defaults.memorySearch.extraPaths`

## Полезные команды
- Проверить состояние памяти агента:
```bash
openclaw memory status --agent main --json
```

- Принудительно переиндексировать память:
```bash
openclaw memory index --agent main --force
```

- Поиск по памяти:
```bash
openclaw memory search --agent main --query "ключевая фраза"
```

- Проверить валидность конфига:
```bash
openclaw config validate
```

## Важно
- Если добавляешь новый каталог заметок, добавляй его в `agents.defaults.memorySearch.extraPaths` и запускай переиндексацию.
- Если в `memorySearch.remote.apiKey` стоит невалидный ключ, будут ошибки удаленного memory API (401). Для локальной памяти это не требуется.

