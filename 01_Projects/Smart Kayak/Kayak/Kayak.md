---
type: project-subproject
status: active
tags: [smart-kayak, kayak, firmware, motor-control]
updated: 2026-05-01
---

# Kayak

Подпроект каяка: контроллер Smart Kayak, который принимает данные умного весла и преобразует их в команду мотору.

> [!NOTE] Роль заметки
> Эта заметка — index и рабочая рамка kayak-направления. Подробные силовые и железные спецификации лучше постепенно выносить в отдельные hardware-заметки, чтобы `Kayak.md` не превращался в склад всего сразу.

## Goal

Стабильное, безопасное и предсказуемое управление тягой в реальном времени.

## Scope

- BLE-клиент к SmartPaddle
- режимы мощности: `OFF/LOW/MED/HIGH/DEBUG`
- ForceAdapter + StrokeForceController
- предиктивный режим: `PredictedPaddle + StrokePredictorGrid`
- логирование телеметрии для анализа и тюнинга

## Next actions

- [ ] Зафиксировать критерии включения/выключения предиктивного режима
- [ ] Вынести safety-ограничения в явный checklist перед water-тестами
- [ ] Согласовать формат логов для стенда и воды

## Hardware

- Фактическая силовая сборка и параметры водомёта вынесены в: [[01_Projects/Smart Kayak/Hardware/Kayak — силовая конфигурация|Kayak — силовая конфигурация]]
- Это лучше держать отдельно, чтобы `Kayak.md` оставался управляемой index-заметкой, а не смешивал control logic с hardware-реестром.
## Links

- [[01_Projects/Smart Kayak/Project|Project]]
- [[01_Projects/Smart Kayak/Architecture|Architecture]]
- [[01_Projects/Smart Kayak/Hardware/Kayak — силовая конфигурация|Kayak — силовая конфигурация]]
- [[01_Projects/Smart Kayak/Практическое исследование — продукт, кастдев, KPI|Практическое исследование — продукт, кастдев, KPI]]
- [[01_Projects/Smart Kayak/Исследование рынков — Smart Kayak vs SUP|Исследование рынков — Smart Kayak vs SUP]]

## Связанные заметки
- [[MOC_Projects]]
- [[01_Projects/Smart Kayak/Project]]
- [[01_Projects/Smart Kayak/Smart Kayak]]
- [[01_Projects/Smart Kayak/Architecture]]
- [[01_Projects/Smart Kayak/Design Language]]
- [[01_Projects/Smart Kayak/Hardware/Flow Straightener (водомёт)]]
- [[01_Projects/Smart Kayak/Hardware/Батарея SUP — спецификация]]
- [[01_Projects/Smart Kayak/Patent/Патент — Smart Kayak — заявка]]
- [[01_Projects/Smart Kayak/Patent/Патент — Smart Kayak — обозначения]]
- [[01_Projects/Smart Kayak/Patent/Патент — Smart Kayak — формула]]
- [[01_Projects/Smart Kayak/Patent/Патент — Smart Kayak — чертежи]]
- [[01_Projects/Smart Kayak/Patent/Патент — описание Smart Kayak]]
- [[01_Projects/Smart Kayak/SUP/SUP]]
- [[01_Projects/Smart Kayak/SUP/docs/Электро-САП борд — Техническое описание]]
