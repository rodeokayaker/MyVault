# Raspberry Setup Index

## Основные документы
- [[OpenClaw]]
- [[OpenClaw_Current_Config]]
- [[Obsidian]]
- [[VPN_AmneziaWG]]
- [[HID_Periphery]]
- [[Syncthing_Obsidian_Sync]]
- [[RUNBOOK]]

## Ключевые пути
- Vault: `/home/vanya/Obsidian/OpenClawVault`
- OpenClaw docs: `/home/vanya/Obsidian/OpenClawVault/03_Resources/Raspberry_Docs`
- VPN config: `/etc/amnezia/amneziawg/awg0.conf`
- VPN bypass list: `/etc/amnezia/bypass-domains.txt`

## Быстрые команды
```bash
# VPN
vpnon
vpnoff
vpnstatus

# HID
hidoff
hidon
histatus

# Obsidian sync (Raspberry)
vaultsync-on
vaultsync-off

# OpenClaw memory
sudo -u vanya openclaw memory index --agent main --force
sudo -u vanya openclaw memory status --agent main --json | head -n 40
```
