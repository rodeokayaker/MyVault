---
type: architecture
status: active
tags: [smart-kayak, architecture]
updated: 2026-05-01
---

# Smart Kayak — Architecture

> [!NOTE] Роль заметки
> Это системная архитектура всей платформы Smart Kayak. Рыночная стратегия, KPI, кастдев и go-to-market должны жить в исследовательских заметках, а не расползаться сюда.

## 1) Смысл системы

Smart Kayak — система усиления гребли: умное весло измеряет движение и нагрузку, каяк вычисляет требуемую поддержку и подаёт тягу на мотор синхронно с фазой гребка.

---

## 2) Основные блоки

- **Smart Paddle (ESP32 + IMU + тензодатчики)**
  - измеряет IMU/ориентацию/усилие на лопастях
  - работает как BLE Server
  - отдаёт телеметрию и принимает команды калибровки

- **Smart Kayak Controller**
  - работает как BLE Client
  - принимает поток телеметрии от весла
  - рассчитывает моторное усилие (прямая логика + предиктивная)
  - управляет ESC/мотором по выбранному режиму мощности

- **Motor subsystem**
  - ESC + электромотор
  - получает управляющий сигнал от Smart Kayak

- **Model Stand (SK_ModelStand)**
  - оффлайн-стенд для воспроизведения CSV-логов
  - тест и настройка алгоритмов без выхода на воду

---

## 3) Каналы данных

### BLE бинарные notify-каналы (весло → каяк)
- **FORCE**: сила на правой/левой лопасти + raw + timestamp
- **IMU**: accel/gyro/mag + quaternion + timestamp
- **ORIENTATION**: quaternion + timestamp
- **Battery Level**: уровень батареи

### BLE JSON-канал (SP_Protocol)
- команды: калибровка, pairing, shutdown, specs
- ответы/статусы/логи/сервисные данные

---

## 4) Логика управления тягой

В контроллере каяка используются:

- **ForceAdapter** — сглаживание/диммирование усилия и защита при смене направления
- **StrokeForceController** — правила включения/выключения предикта, переходы, anti-false-trigger, one-shot логика
- **PredictedPaddle + StrokePredictorGrid** — предсказание силы гребка по ориентации/динамике, чтобы давать упреждающую поддержку

Режимы мотора:
- `OFF`, `LOW`, `MED`, `HIGH`, `DEBUG`

---

## 5) Поток данных (упрощённо)

```text
[Smart Paddle Sensors]
   IMU + Load Cells
          |
          v
 [SmartPaddle Firmware]
   BLE Server + SP_Protocol
          |
          |  BLE (FORCE/IMU/ORIENTATION + JSON)
          v
 [SmartKayak Firmware]
   ForceAdapter + StrokeForceController + Predictor
          |
          v
 [Motor Controller / ESC]
          |
          v
     [Thrust Assist]
```

---

## 6) Что важно для качества

- корректная калибровка IMU и тензодатчиков
- стабильная синхронизация timestamp между каналами
- настройка порогов/конфигов предиктора под реальную технику гребли
- валидация в Model Stand до натурных испытаний

## Связанные заметки
- [[MOC_Projects]]
- [[01_Projects/Smart Kayak/Project]]
- [[01_Projects/Smart Kayak/Практическое исследование — продукт, кастдев, KPI|Практическое исследование — продукт, кастдев, KPI]]
- [[01_Projects/Smart Kayak/Исследование рынков — Smart Kayak vs SUP|Исследование рынков — Smart Kayak vs SUP]]
- [[01_Projects/Smart Kayak/Smart Kayak]]
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
