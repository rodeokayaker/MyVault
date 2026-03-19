---
type: project
status: active
tags: [smart-kayak, kayak, sup, smart-paddle, ble, motor-control]
updated: 2026-03-13
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

## Repositories

- Firmware: https://github.com/rodeokayaker/SmartKayak_PIO_Arduino
- Model stand: https://github.com/rodeokayaker/SK_ModelStand

## Design direction

- См. [[01_Projects/Smart Kayak/Design Language|Design Language]].
- В дизайне воплощать **лёгкость**: Smart Kayak должен ощущаться как **кроссовок** — лёгкий, быстрый, современный и естественный.
- Ориентир для визуального языка: как в хороших беговых кроссовках — ощущение лёгкости в форме, цветах и общих пропорциях.
- Дизайн должен считываться не как «тяжёлая техника», а как лёгкий спортивный продукт.

## Next actions

- [x] Патент: подготовлен заявочный комплект (см. [[01_Projects/Smart Kayak/Patent/Патент — Smart Kayak — заявка|заявка]] и финальный DOCX).
- [x] [[Flow Straightener (водомёт)]]: смоделировать выпрямитель потока (+5 см) и посадку под подшипник; отдать Максу в печать.
- [ ] Формализовать roadmap по трекам `Kayak` / `Smart Paddle` / `SUP`
- [ ] Определить KPI для water-тестов (стабильность, задержка, энергопотребление)
- [ ] Подготовить тестовую матрицу стенд -> вода

## Links
- [[MOC_Projects]]
