---
type: project
status: active
tags: [raspberry, infra, openclaw]
updated: 2026-03-04
---


# Raspberry Operations

## Scope
Operational setup and maintenance for OpenClaw, Obsidian, VPN and HID control on Raspberry Pi.

## Key links
- [[MOC_Home]]
- [[MOC_Projects]]
- [[MOC_Resources]]
- [[03_Resources/Raspberry_Docs/RUNBOOK]]
- [[03_Resources/Raspberry_Docs/OpenClaw]]
- [[03_Resources/Raspberry_Docs/Obsidian]]
- [[03_Resources/Raspberry_Docs/VPN_AmneziaWG]]
- [[03_Resources/Raspberry_Docs/HID_Periphery]]

## Operations
- VPN control: `vpnon`, `vpnoff`, `vpnstatus`
- HID control: `hidoff`, `hidon`, `histatus`
- Healthcheck: `/usr/local/bin/pi-healthcheck`

## Next actions
- [ ] Add Telegram alerts for healthcheck WARN
- [ ] Add git backup for vault
