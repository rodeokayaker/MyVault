#!/bin/bash
set -euo pipefail

ts="$(date '+%Y-%m-%d %H:%M:%S %Z')"
host="$(hostname)"

ok() { printf '[OK] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
info() { printf '[INFO] %s\n' "$*"; }

echo "=== PI HEALTHCHECK @ $ts ($host) ==="

# 1) VPN service
if systemctl is-active --quiet awg-quick@awg0; then
  ok "VPN service awg-quick@awg0 active"
else
  warn "VPN service awg-quick@awg0 NOT active"
fi

if systemctl is-enabled --quiet awg-quick@awg0; then
  ok "VPN service awg-quick@awg0 enabled on boot"
else
  warn "VPN service awg-quick@awg0 NOT enabled on boot"
fi

# 2) HID status
if command -v histatus >/dev/null 2>&1; then
  hid_line="$(histatus 2>/dev/null | head -n1 || true)"
  info "HID: ${hid_line:-unknown}"
else
  warn "histatus command not found"
fi

# 3) OpenClaw memory (as vanya)
if id -u vanya >/dev/null 2>&1 && command -v openclaw >/dev/null 2>&1; then
  if sudo -u vanya openclaw memory status --agent main --json >/tmp/openclaw_mem_status.json 2>/dev/null; then
    if grep -q "OpenClawVault" /tmp/openclaw_mem_status.json; then
      ok "OpenClaw memory path includes OpenClawVault"
    else
      warn "OpenClaw memory path missing OpenClawVault"
    fi
  else
    warn "openclaw memory status failed"
  fi
else
  warn "vanya user or openclaw command not available"
fi

# 4) Disk usage
root_use="$(df -h / | awk 'NR==2{print $5}')"
info "Disk / usage: $root_use"

# 5) Temperature
if command -v vcgencmd >/dev/null 2>&1; then
  temp="$(vcgencmd measure_temp 2>/dev/null || true)"
  info "CPU temp: ${temp:-unknown}"
else
  warn "vcgencmd not found"
fi

# 6) Public IP quick check
pub_ip="$(curl -4fsS --max-time 6 ifconfig.me 2>/dev/null || true)"
if [ -n "$pub_ip" ]; then
  info "Public IPv4: $pub_ip"
else
  warn "Public IPv4 check failed"
fi

echo "=== END HEALTHCHECK ==="

