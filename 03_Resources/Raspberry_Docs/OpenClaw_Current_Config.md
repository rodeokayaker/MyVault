---
type: resource
status: active
tags: [resource, resource/raspberry-docs]
updated: 2026-05-01
---

# OpenClaw: Current Config (2026-05-01)

## Obsidian
- Main Mac vault: `/Users/vanya/Documents/Obsidian/MainVault`
- Raspberry docs folder in the vault:
  - `03_Resources/Raspberry_Docs`
- Existing Raspberry notes in the vault:
  - `OpenClaw.md`
  - `OpenClaw_Current_Config.md`
  - `Obsidian.md`
  - `Syncthing_Obsidian_Sync.md`

## Summary
- Raspberry users with OpenClaw:
  - `vanya`
  - `natalie`
- Both users now resolve `openclaw` to user-local `2026.4.21`
- Both configs validate successfully
- Shared wrapper in `/usr/local/bin/openclaw` routes:
  - `vanya` -> `/home/vanya/.npm-global/bin/openclaw`
  - `natalie` -> `/home/natalie/.npm-global/bin/openclaw`
  - everyone else -> `/usr/bin/openclaw`

## Gateway / Services
- `vanya`
  - user service: `/home/vanya/.config/systemd/user/openclaw-gateway.service`
  - port: `18789`
  - current service version: `2026.4.21`
  - last restart confirmed: `2026-05-01 08:32:19 MSK`
  - user drop-in: `/home/vanya/.config/systemd/user/openclaw-gateway.service.d/10-env.conf`
- `natalie`
  - user service: `/home/natalie/.config/systemd/user/openclaw-gateway.service`
  - port: `18799`
  - current service version: `2026.4.21`
  - last restart confirmed: `2026-04-30 15:31:54 MSK`
  - user drop-in: `/home/natalie/.config/systemd/user/openclaw-gateway.service.d/10-env.conf`

## CLI / Shell State
- `vanya`
  - `which openclaw` from shell resolves to `/usr/local/bin/openclaw`
  - wrapper forwards to `/home/vanya/.npm-global/bin/openclaw`
  - `openclaw --version` -> `2026.4.21`
  - `openclaw config validate` -> valid
  - `~/.profile` now prepends `~/.npm-global/bin`
- `natalie`
  - `which openclaw` from shell resolves to `/usr/local/bin/openclaw`
  - wrapper forwards to `/home/natalie/.npm-global/bin/openclaw`
  - `openclaw --version` -> `2026.4.21`
  - `openclaw config validate` -> valid

## Environment / Secrets Layout
- `vanya`
  - main env file: `/home/vanya/.config/openclaw/env`
  - contains keys for:
    - `GITHUB_TOKEN`
    - `PERPLEXITY_API_KEY`
    - `DEEPSEEK_API_KEY`
    - `OPENAI_API_KEY`
    - `GAMMA_API_KEY`
    - `GEMINI_API_KEY`
    - `PANDOC_PATH`
  - service-side extra env file:
    - `/home/vanya/.openclaw/gateway.systemd.env`
  - after cleanup this extra file keeps only:
    - `YANDEX_DIRECT_OAUTH_TOKEN`
    - `YANDEX_DIRECT_CLIENT_ID`
    - `YANDEX_DIRECT_LOGIN`
  - duplicate `OPENAI_API_KEY` was removed from `gateway.systemd.env`
- `natalie`
  - main env file: `/home/natalie/.config/openclaw/env`
  - contains keys for:
    - `GITHUB_TOKEN`
    - `PERPLEXITY_API_KEY`
    - `DEEPSEEK_API_KEY`
    - `OPENAI_API_KEY`
    - `PPLX_API_KEY`
    - `PANDOC_PATH`
    - `GAMMA_API_KEY`
  - service drop-in loads:
    - `EnvironmentFile=-/home/natalie/.config/openclaw/env`

## Models / Routing
- `vanya`
  - default primary model remains `openai-codex/gpt-5.4`
  - `main` still uses `openai-codex/gpt-5.4`
  - current config is the newer `2026.4.x` schema
- `natalie`
  - gateway is also on `2026.4.21`
  - Telegram / multi-account setup remains active under this newer schema

## Memory / Obsidian Integration
- Raspberry-side vault used by OpenClaw memory:
  - `/home/vanya/Obsidian/OpenClawVault`
- Config key:
  - `agents.defaults.memorySearch.extraPaths`
- Current local memory DB for `vanya/main`:
  - `/home/vanya/.openclaw/memory/main.sqlite`
  - current observed size: about `27 MB`
- `vanya/main` session store still exists and was not wiped:
  - `~/.openclaw/agents/main/sessions/sessions.json`
  - current transcript count observed: `52` `.jsonl` files

## Incident Note: 2026-04-23
- The "agents forgot themselves" incident on `vanya` did not look like a full state wipe.
- The main cause was version split-brain:
  - shell CLI was still hitting old `2026.3.13`
  - gateway had already moved to `2026.4.21`
  - both were touching the same `~/.openclaw` state
- Symptom:
  - old CLI saw the new config as invalid
  - the running gateway used the newer schema
- During that period:
  - `~/.openclaw/memory/main.sqlite` was recreated on `2026-04-23`
  - `~/.openclaw/workspace/IDENTITY.md` for `main` was rewritten later the same day
- Important conclusion:
  - most agent directories, identities, auth files, and transcript files were still present
  - the problem was primarily incompatible runtime/config state, not total deletion of all agent data

## Current State After Cleanup
- `vanya` split-brain was cleaned up:
  - shell and service now both use `2026.4.21`
  - config validates from shell
  - gateway restarted cleanly after cleanup
- `natalie` shell routing was also cleaned up earlier:
  - shell and service both use `2026.4.21`

## Safe Checks
```bash
# vanya
sudo -u vanya -H sh -c 'which openclaw && openclaw --version && openclaw config validate'
sudo -u vanya -H env XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus systemctl --user status openclaw-gateway.service

# natalie
sudo -u natalie -H sh -c 'which openclaw && openclaw --version && openclaw config validate'
sudo -u natalie -H env XDG_RUNTIME_DIR=/run/user/1002 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1002/bus systemctl --user status openclaw-gateway.service

# vanya memory
sudo -u vanya openclaw memory status --agent main --json
sudo -u vanya openclaw memory index --agent main --force
```

## Notes
- Backup / rollback artifacts from earlier repairs still exist in `~/.openclaw`.
- They do not currently break the setup, but they can be cleaned later if needed.
- Do not put raw token values into Obsidian notes.

## Связанные заметки
- [[MOC_Resources]]
- [[03_Resources/Raspberry_Docs/HID_Periphery]]
- [[03_Resources/Raspberry_Docs/Obsidian]]
- [[03_Resources/Raspberry_Docs/OpenClaw]]
- [[03_Resources/Raspberry_Docs/RUNBOOK]]
- [[03_Resources/Raspberry_Docs/Raspberry_Setup_Index]]
- [[03_Resources/Raspberry_Docs/Syncthing_Obsidian_Sync]]
- [[03_Resources/Raspberry_Docs/VPN_AmneziaWG]]
