---
type: project
status: in-progress
tags: [smart-kayak, kayak, sup, smart-paddle, ble, motor-control]
updated: 2026-05-01
---

# Smart Kayak

Система интеллектуального усиления гребли: умное весло передает телеметрию, контроллер рассчитывает фазу/усилие гребка и подает поддержку на мотор.

## Goal

Сделать устойчивую, безопасную и продуктовую платформу assist-системы для каяка и SUP.

## Scope

- Smart Paddle: сенсоры + BLE-протокол + калибровки
- Kayak controller: алгоритмы дозирования тяги и safety-логика
- SUP product line: модульная интеграция в электро-SUP платформу
- Model stand: оффлайн-валидация алгоритмов по логам

## Subprojects

- [[Kayak]]
- [[Smart Paddle]]
- [[SUP]]

## Architecture

- [[Architecture]]

## Research

- [[01_Projects/Smart Kayak/Исследование рынков — Smart Kayak vs SUP|Исследование рынков — Smart Kayak vs SUP]]
- [[01_Projects/Smart Kayak/Практическое исследование — продукт, кастдев, KPI|Практическое исследование — продукт, кастдев, KPI]]

## Repositories

- Firmware: https://github.com/rodeokayaker/SmartKayak_PIO_Arduino
- Model stand: https://github.com/rodeokayaker/SK_ModelStand

## Design direction

- См. [[01_Projects/Smart Kayak/Design Language|Design Language]].
- В дизайне воплощать **лёгкость**: Smart Kayak должен ощущаться как **кроссовок** — лёгкий, быстрый, современный и естественный.
- Ориентир для визуального языка: как в хороших беговых кроссовках — ощущение лёгкости в форме, цветах и общих пропорциях.
- Дизайн должен считываться не как «тяжёлая техника», а как лёгкий спортивный продукт.

## Next actions

- [x] Патент: собрана расширенная версия заявки с примерами реализации, включая варианты SUP/каяк, с магнитометром и без, с мотором и без, а также аналитический режим (см. [[01_Projects/Smart Kayak/Patent/Патент — Smart Kayak — заявка|заявка]]).
- [x] Заявка принята и зарегистрирована в ФИПС: рег. № `2026109935`, дата регистрации `06.04.2026`, входящий № `W26021775`.
- [x] [[01_Projects/Smart Kayak/Hardware/Flow Straightener (водомёт)|Flow Straightener (водомёт)]]: смоделировать выпрямитель потока (+5 см) и посадку под подшипник; отдать Максу в печать.
- [x] После регистрации заявки: добавить регистрационный номер, дату регистрации и подтверждающие документы в патентный раздел Obsidian.
- [x] Перед подачей патента: проверить единообразие терминов, убрать излишне жёсткую привязку к конкретной элементной базе в описании примеров и финально вычитать формулу на предмет заужения.
- [ ] Формализовать roadmap по трекам `Kayak` / `Smart Paddle` / `SUP`
- [ ] Определить KPI для water-тестов (стабильность, задержка, энергопотребление)
- [ ] Подготовить тестовую матрицу стенд -> вода

## Links
- [[MOC_Projects]]

## Связанные заметки
- [[MOC_Projects]]
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
- [[01_Projects/Smart Kayak/SUP/docs/Электро-САП борд — Техническое описание]]
