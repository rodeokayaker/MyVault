# OpenClaw: Current Config (2026-03-06)

## Summary
- OpenClaw version: `2026.3.2`
- Main user: `vanya`
- Secondary user: `natalie`
- Gateway mode: local loopback + password auth

## Gateway / Services
- `vanya` gateway:
  - systemd user service: `openclaw-gateway.service`
  - enabled: yes
  - port: `18789`
- `natalie` gateway:
  - systemd user service: `openclaw-gateway.service`
  - enabled: yes
  - port: `18799`

## Agents (vanya)
- `main` -> `openai-codex/gpt-5.3-codex`
- `admin` -> `openai-codex/gpt-5.3-codex`
- `root` -> `openai/gpt-5.1-codex`
- `oaiapi` -> `openai/gpt-5.2`
- `search` -> `perplexity/sonar`

Routing bindings:
- none (empty)
- `/search` is NOT pinned to `search` by routing; use `main` and delegate to `search` when needed.

## Credentials / Secrets
Configured for `vanya` in:
- `/home/vanya/.config/openclaw/env`

Stored there:
- `GITHUB_TOKEN`
- `PERPLEXITY_API_KEY`

Gateway service for `vanya` loads this file via:
- `EnvironmentFile=%h/.config/openclaw/env`

Git credentials for repo access:
- git helper: `store`
- file: `/home/vanya/.git-credentials`

## Perplexity Settings
Configured in OpenClaw config:
- `tools.web.search.provider = perplexity`
- `tools.web.search.perplexity.model = perplexity/sonar`
- `tools.web.search.perplexity.apiKey` is set

Global default model remains:
- `agents.defaults.model.primary = openai-codex/gpt-5.3-codex`

## Memory / Knowledge
- Memory extra path:
  - `/home/vanya/Obsidian/OpenClawVault`
- Index state was refreshed (`dirty=false` after reindex).

## Quick Checks
```bash
# vanya gateway
sudo -u vanya XDG_RUNTIME_DIR=/run/user/1000 systemctl --user status openclaw-gateway
sudo -u vanya openclaw gateway probe --timeout 12000

# natalie gateway
sudo -u natalie XDG_RUNTIME_DIR=/run/user/1002 systemctl --user status openclaw-gateway
sudo -u natalie openclaw --profile natalie gateway probe --url ws://127.0.0.1:18799 --timeout 12000

# agents and models
sudo -u vanya openclaw agents list
sudo -u vanya openclaw models --agent search status

# git/github access test
sudo -u vanya GIT_TERMINAL_PROMPT=0 git ls-remote https://github.com/rodeokayaker/SmartKayak_PIO_Arduino.git | head
```

## Security Notes
- Tokens are stored on disk (env file + git credentials).
- Recommended: rotate PAT tokens periodically.
- Do not copy token values into Obsidian notes.
