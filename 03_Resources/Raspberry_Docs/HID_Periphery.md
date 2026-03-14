# HID-периферия: hidon / hidoff / histatus

## Назначение
- `hidon` = периферия включена (Human Interface Devices ON)
- `hidoff` = периферия отключена
- `histatus` = текущий режим и состояние

## Что управляется
- USB клавиатуры/мыши
- Bluetooth клавиатуры/мыши (Bluetooth адаптер не выключается)
- Экран (гашение/включение)
- HDMI-аудио (mute/unmute)

## Установленные команды
- `/usr/local/bin/hidon`
- `/usr/local/bin/hidoff`
- `/usr/local/bin/histatus`

Скрипты сами поднимают `sudo` при запуске от обычного пользователя.

## Как пользоваться
```bash
hidoff
histatus
hidon
histatus
```

## Технически
- Экран: сначала Wayland (`wlr-randr`), затем X11 (`xset`), затем fallback (`setterm`/`vcgencmd`).
- USB HID: отключение/включение через `authorized 0/1` для целевых USB-устройств (стабильнее, чем unbind/bind).
- Bluetooth HID: disconnect/connect по списку устройств HID.
- HDMI audio: mute/unmute sink’ов через `pactl`.

## Файлы состояния
- `/run/hid-control/usb-disabled-parents.list`
- `/run/hid-control/bt-disconnected.list`
- `/run/hid-control/audio-muted.list`
- `/run/hid-control/display.state`
- `/run/hid-control/display.outputs`

## Примечание
- Не-HID служебные USB интерфейсы не трогаются.
- Если после `hidon` конкретная USB-клавиатура не проснулась из-за железа/хаба, обычно помогает одно физическое переподключение; далее работает штатно.

