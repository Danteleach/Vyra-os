#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-artifacts/hardware-report.txt}"
mkdir -p "$(dirname "$OUT")"
{
  echo "Vyra HARDWARE DISCOVERY REPORT"
  echo "Generated: $(date -Is)"
  echo
  echo "== OS =="
  (cat /etc/os-release 2>/dev/null || true)
  echo
  echo "== Kernel =="
  uname -a
  echo
  echo "== CPU =="
  (lscpu 2>/dev/null || true)
  echo
  echo "== Memory =="
  (free -h 2>/dev/null || true)
  echo
  echo "== Block devices =="
  (lsblk -o NAME,MODEL,SIZE,TYPE,TRAN,ROTA,FSTYPE,MOUNTPOINTS 2>/dev/null || true)
  echo
  echo "== PCI devices =="
  (lspci -nn 2>/dev/null || true)
  echo
  echo "== USB devices =="
  (lsusb 2>/dev/null || true)
  echo
  echo "== Network =="
  (nmcli device status 2>/dev/null || true)
  echo
  echo "== Graphics / Vulkan =="
  (glxinfo -B 2>/dev/null || true)
  (vulkaninfo --summary 2>/dev/null || true)
  echo
  echo "== Audio =="
  (wpctl status 2>/dev/null || true)
  echo
  echo "== Battery =="
  for f in /sys/class/power_supply/*/capacity; do
    [ -r "$f" ] && printf '%s: %s%%\n' "$f" "$(cat "$f")"
  done
} > "$OUT"
echo "Hardware report written to: $OUT"
echo "Review for device identifiers before sharing."
