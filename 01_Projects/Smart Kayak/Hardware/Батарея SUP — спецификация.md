---
type: project-note
status: active
tags: [project, project/smart-kayak]
updated: 2026-05-12
---

# Батарея SUP — спецификация

## BMS
- Модель: **JBD-SP14S004**
- Конфигурация: **7S**
- Ток: **50A**

## Дополнено из концепта SUP

### Конфигурация батареи
- Формат ячеек: **21700**
- Конфигурация: **7S10P**
- Всего ячеек: **70**
- Напряжение: **24.5 В номинал / 29.4 В заряд / 21 В разряд**
- Оценочная ёмкость: **~50 А·ч**
- Энергия: **~1200 Вт·ч**

### Геометрия и интеграция
- Габариты корпуса: **550 × 220 × 30 мм**
- Позиция: вдоль борда, по центру палубы
- Стыковка: кормовым краем надевается на контрол-бокс
- Корпус: **ABS+GF**
- Защита: **IP67 в сборе / IP54 без бокса**
- Интерфейс BMS: **CAN bus**

### Крепление
1. штыревой разъём в контрол-бокс;
2. липучка по нижней плоскости;
3. магнитная защёлка или стропа у носового края.

### Разъём батарея → контрол-бокс
| Пин | Назначение | Диаметр |
|---|---|---|
| B+ | Силовой плюс | ∅8 мм |
| B− | Силовой минус | ∅8 мм |
| CAN-H | Данные BMS | ∅2 мм |
| CAN-L | Данные BMS | ∅2 мм |

Принципиально важно: несимметричное расположение пинов защищает от неверной ориентации батареи.

---
Источник: фиксация от Ивана (2026-04-27) + концепт «[[01_Projects/Smart Kayak/SUP/docs/Электро-САП борд — Техническое описание|Электро-САП борд — Техническое описание]]». 

## Связанные заметки
- [[MOC_Projects]]
- [[01_Projects/Smart Kayak/Project]]
- [[01_Projects/Smart Kayak/Smart Kayak]]
- [[01_Projects/Smart Kayak/Architecture]]
- [[01_Projects/Smart Kayak/Design Language]]
- [[01_Projects/Smart Kayak/Hardware/Flow Straightener (водомёт)]]
- [[01_Projects/Smart Kayak/Kayak/Kayak]]
- [[01_Projects/Smart Kayak/Patent/Патент — Smart Kayak — заявка]]
- [[01_Projects/Smart Kayak/Patent/Патент — Smart Kayak — обозначения]]
- [[01_Projects/Smart Kayak/Patent/Патент — Smart Kayak — формула]]
- [[01_Projects/Smart Kayak/Patent/Патент — Smart Kayak — чертежи]]
- [[01_Projects/Smart Kayak/Patent/Патент — описание Smart Kayak]]
- [[01_Projects/Smart Kayak/SUP/SUP]]
- [[01_Projects/Smart Kayak/SUP/docs/Электро-САП борд — Техническое описание]]
