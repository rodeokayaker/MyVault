---
type: project-subproject
status: active
tags: [smart-kayak, smart-paddle, firmware, sensors, ble]
updated: 2026-05-13
---

# Smart Paddle

Подпроект умного весла: сенсорный и коммуникационный слой платформы Smart Kayak.

## Goal

Стабильно измерять движение и усилие гребка, передавать телеметрию в контроллер и поддерживать калибровку без хрупкой магии.

## Scope

- IMU / ориентация / инерциальные данные
- тензодатчики / force sensing
- BLE server и телеметрические каналы
- команды калибровки, pairing, shutdown, specs
- качество сигналов для assist-логики и анализа техники

## Docs

- [[01_Projects/Smart Kayak/Architecture|Architecture]]
- [[01_Projects/Smart Kayak/Project|Project]]
- [[01_Projects/Smart Kayak/Smart Paddle/Smart Paddle — sensors and calibration|Smart Paddle — sensors and calibration]]
- [[01_Projects/Smart Kayak/Smart Paddle/Smart Paddle — BLE protocol|Smart Paddle — BLE protocol]]

## Next actions

- [ ] Добить процедуры калибровки и критерии качества в [[01_Projects/Smart Kayak/Smart Paddle/Smart Paddle — sensors and calibration|Smart Paddle — sensors and calibration]]
- [ ] Добить формат каналов и контракт полей в [[01_Projects/Smart Kayak/Smart Paddle/Smart Paddle — BLE protocol|Smart Paddle — BLE protocol]]
- [ ] Связать Smart Paddle-логирование с требованиями model stand и water logs

## Links

- [[01_Projects/Smart Kayak/Project|Project]]
- [[01_Projects/Smart Kayak/Architecture|Architecture]]
- [[01_Projects/Smart Kayak/Kayak/Kayak|Kayak]]
- [[01_Projects/Smart Kayak/Smart Kayak|Smart Kayak]]

## Связанные заметки
- [[MOC_Projects]]
- [[01_Projects/Smart Kayak/Smart Kayak]]
- [[01_Projects/Smart Kayak/Project]]
- [[01_Projects/Smart Kayak/Architecture]]
- [[01_Projects/Smart Kayak/SUP/SUP]]
