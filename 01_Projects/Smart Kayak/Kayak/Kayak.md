---
type: project-subproject
status: active
tags: [smart-kayak, kayak, firmware, motor-control]
updated: 2026-03-06
---

# Kayak

Контроллер SmartKayak, который принимает данные умного весла и преобразует их в команду мотору.

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

## Links

- [[01_Projects/Smart Kayak/Project|Project]]
- [[Architecture]]
