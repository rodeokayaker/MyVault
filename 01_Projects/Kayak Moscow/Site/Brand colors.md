---
created: 2026-06-10
updated: 2026-06-10
type: reference
project: KayakMoscow
tags: [kayakmoscow, brand, design]
parent: "[[Site]]"
---

# Бренд-цвета KayakMoscow

## Основные цвета

| Назначение | HEX | RGB | Где используется на сайте |
|---|---|---|---|
| **Тёмный бренд-цвет** | `#14343B` | 20, 52, 59 | `favicon.ico` (выкатан 2026-06-10) |
| **Красный** | `#EA0440` | 234, 4, 64 | `local/templates/kayak-moscow/img/logo-red.png` — `og:image` для соцсетей |

Тёмный — петрольный / тёмно-бирюзовый. Красный — насыщенный, ближе к малиновому-розовому.

## Превью

<div style="display:flex;gap:10px;margin:20px 0">
  <div style="background:#14343B;color:#fff;padding:30px;border-radius:8px;font-family:monospace">#14343B</div>
  <div style="background:#EA0440;color:#fff;padding:30px;border-radius:8px;font-family:monospace">#EA0440</div>
</div>

## Исходники логотипа

В OneDrive: `~/Library/CloudStorage/OneDrive-Личная/Документы/kayakmoscow/logo/New/`

- **`PDF/Ресурс 1.pdf`** — горизонтальный лого (иконка-каяк + текст KAYAKMOSCOW), векторный. Использован для inline SVG в шапке/футере сайта (2026-06-10).
- **`SVG/Ресурс 3.svg`** — только иконка-каяк (ромб + V), без текста. Использован для favicon в тёмном цвете.
- **`All/Png/horizontally_white.png`** — белый PNG горизонтального лого, 1200×901 (после trim 1048×157).
- **`All/Png/horizontally_black.png`** — чёрный вариант.
- **`All/Png/vertical_black.png`** — вертикальный лого (иконка сверху + KAYAK MOSCOW в 2 строки), 1200×901. Использован для `bitrix/images/logo1.jpg` в JSON-LD Schema.org (2026-06-10).
- **`PDF/Logobook_Kayak.moskow.pdf`** — общий бренд-бук.

## История применений

- **2026-06-10**: favicon из SVG-иконки в `#14343B`. Бэкап: `favicon.ico.bak-20260610`.
- **2026-06-10**: `logo-red.png` перекрашен в точный `#EA0440` (был тот же оттенок, но с другими пропорциями). Бэкап: `.bak-20260610`.
- **2026-06-10**: `bitrix/images/logo1.jpg` (Schema.org logo) заменён на квадратный вертикальный лого 600×600. Бэкап: `.bak-20260610`.
- **2026-06-10**: SVG-логотип в шапке/футере (`header.php`, `footer.php`, `<symbol id="logo">`) заменён на новый горизонтальный из PDF. CSS-высоты пересчитаны под aspect 6.67:1. Бэкапы: `.bak-20260610-2005`.

## Линки

- [[Site]] — хаб сайта
- [[Apex-домен недоступен у части пользователей (2026-06-08)]]
