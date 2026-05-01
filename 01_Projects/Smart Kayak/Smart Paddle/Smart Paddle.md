---
type: project-subproject
status: active
tags: [smart-kayak, smart-paddle, esp32, ble, sensors]
updated: 2026-05-01
---

# Smart Paddle

Умное весло (SmartPaddle): сенсорный BLE-модуль, который измеряет динамику гребка и передает данные в SmartKayak.

## Goal

Надежный источник качественной телеметрии для расчета моторной поддержки.

## Scope

- аппаратная база: ESP32 (C3/S3), IMU BNO08x, тензодатчики (HX711/ADS1220)
- данные: quaternion/IMU + усилия правой/левой лопасти + timestamp
- BLE: бинарные notify-каналы (`FORCE/IMU/ORIENTATION`) + JSON-канал (`SP_Protocol`)
- сервисные функции: pairing, калибровки, спецификации, power management

## Repositories

- Firmware: https://github.com/rodeokayaker/SmartKayak_PIO_Arduino
- Model stand: https://github.com/rodeokayaker/SK_ModelStand

## Next actions

- [ ] Формализовать процедуру калибровки для полевых запусков
- [ ] Закрыть минимальный набор диагностических метрик BLE-качества
- [ ] Изменить протокол, чтоб данные с IMU датчика сразу передавались по BLE
- [ ] Зафиксировать версионирование протокола `SP_Protocol`
- [ ] 

## Links

- [[01_Projects/Smart Kayak/Project|Project]]
- [[Architecture]]

## Связанные заметки
- [[MOC_Projects]]
- [[01_Projects/Smart Kayak/Project]]
- [[01_Projects/Smart Kayak/Smart Kayak]]
- [[01_Projects/Smart Kayak/Architecture]]
- [[01_Projects/Smart Kayak/Design Language]]
- [[01_Projects/Smart Kayak/Hardware/Flow Straightener (водомёт)]]
- [[01_Projects/Smart Kayak/Hardware/Батарея SUP — спецификация]]
- [[01_Projects/Smart Kayak/Kayak/Kayak]]
- [[01_Projects/Smart Kayak/Patent/Патент — Smart Kayak — заявка]]
- [[01_Projects/Smart Kayak/Patent/Патент — Smart Kayak — обозначения]]
- [[01_Projects/Smart Kayak/Patent/Патент — Smart Kayak — формула]]
- [[01_Projects/Smart Kayak/Patent/Патент — Smart Kayak — чертежи]]
- [[01_Projects/Smart Kayak/Patent/Патент — описание Smart Kayak]]
- [[01_Projects/Smart Kayak/SUP/SUP]]
