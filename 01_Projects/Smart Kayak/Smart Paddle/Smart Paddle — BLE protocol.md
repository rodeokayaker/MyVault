---
type: project-note
status: active
tags: [smart-kayak, smart-paddle, ble, protocol, telemetry]
updated: 2026-05-13
---

# Smart Paddle — BLE protocol

## Суть

Эта заметка про коммуникационный слой Smart Paddle: какие каналы телеметрии идут в каяк и какие сервисные команды поддерживаются.

## Телеметрические каналы

### BLE notify-каналы
- `FORCE` — сила на правой/левой лопасти + raw + timestamp
- `IMU` — accel / gyro / mag + quaternion + timestamp
- `ORIENTATION` — quaternion + timestamp
- `Battery Level` — уровень батареи

### JSON / service protocol
- калибровка
- pairing
- shutdown
- specs
- ответы / статусы / логи / сервисные данные

## Практический смысл

Это не просто транспорт. Формат каналов определяет, насколько чисто kayak-контроллер может считать фазу гребка, насколько удобно логировать данные и насколько реально поддерживать сервисные операции без поломки UX.

## Что стоит вынести дальше

- [ ] Описать контракт полей по каждому каналу
- [ ] Зафиксировать частоты, задержки и ожидаемые диапазоны
- [ ] Отделить production-протокол от debug/diagnostic уровня
- [ ] Связать протокол с требованиями model stand и water logs

## Links

- [[01_Projects/Smart Kayak/Smart Paddle/Smart Paddle|Smart Paddle]]
- [[01_Projects/Smart Kayak/Architecture|Architecture]]
- [[01_Projects/Smart Kayak/Kayak/Kayak|Kayak]]
