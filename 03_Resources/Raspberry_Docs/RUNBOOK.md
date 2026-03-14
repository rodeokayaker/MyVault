# RUNBOOK (Raspberry + OpenClaw)

## 1) Базовая проверка после перезагрузки
```bash
systemctl is-active awg-quick@awg0
vpnstatus
histatus
sudo -u vanya openclaw memory status --agent main --json | head -n 40
```

Ожидаемо:
- `awg-quick@awg0` = `active`
- `vpnstatus` показывает `ВКЛЮЧЕН`
- `histatus` обычно `HID ON`

## 2) Частые команды

### VPN
```bash
vpnon
vpnoff
vpnstatus
```

Изменил `/etc/amnezia/bypass-domains.txt`:
```bash
vpnoff && vpnon
```

### HID периферия
```bash
hidoff
hidon
histatus
```

### Obsidian sync
```bash
vaultsync-on
vaultsync-off
```

### OpenClaw память
```bash
sudo -u vanya openclaw memory index --agent main --force
sudo -u vanya openclaw memory search --agent main --query "test"
```

## 3) Если что-то сломалось

### VPN не поднимается
```bash
systemctl status awg-quick@awg0 --no-pager -l
journalctl -u awg-quick@awg0 -n 120 --no-pager
```

### Исключения (mos.ru/gosuslugi) не обходят VPN
```bash
sudo cat /etc/amnezia/bypass-domains.txt
vpnoff && vpnon
getent ahostsv4 mos.ru | head -n1 | awk {print } | xargs -I{} ip route get {}
```

### Экран/клава/мышь ведут себя странно
```bash
hidon
histatus
```

Если USB-клава не проснулась:
- переподключить USB-кабель 1 раз, затем снова `hidon`.

### OpenClaw не видит новые заметки
```bash
sudo -u vanya openclaw memory index --agent main --force
sudo -u vanya openclaw memory status --agent main --json | grep -n OpenClawVault
```

### Obsidian не синхронизируется
```bash
vaultsync-off
vaultsync-on
sudo -u vanya syncthing cli --home=/home/vanya/.config/syncthing show connections
```

## 4) Полезные пути
- OpenClaw docs: `01_OPENCLAW.md`
- Obsidian docs: `02_OBSIDIAN.md`
- VPN docs: `03_VPN_AMNEZIAWG.md`
- HID docs: `04_HID_PERIPHERY.md`
- Vault: `/home/vanya/Obsidian/OpenClawVault`
- VPN config: `/etc/amnezia/amneziawg/awg0.conf`
- VPN bypass list: `/etc/amnezia/bypass-domains.txt`

## 5) Автоконтроль (healthcheck)
- Скрипт:
  - `/usr/local/bin/pi-healthcheck`
- Cron:
  - `/etc/cron.d/pi-healthcheck`
- Лог:
  - `/var/log/pi-healthcheck.log`

Проверить вручную:
```bash
sudo /usr/local/bin/pi-healthcheck
```

Смотреть последние записи:
```bash
sudo tail -n 100 /var/log/pi-healthcheck.log
```
