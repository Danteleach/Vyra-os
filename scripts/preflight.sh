#!/usr/bin/env bash
set -euo pipefail
fail=0
for cmd in podman git; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '[PASS] %s found\n' "$cmd"
  else
    printf '[FAIL] %s missing\n' "$cmd"
    fail=1
  fi
done
if [ -f Containerfile ]; then
  grep -q 'quay.io/fedora/fedora-bootc:45' Containerfile \
    && echo '[PASS] Fedora 45 bootc base reference present' \
    || { echo '[FAIL] Expected bootc base reference not found'; fail=1; }
else
  echo '[FAIL] Containerfile missing'
  fail=1
fi
if grep -RniE --exclude=preflight.sh 'wipefs|mkfs\.|parted .*rm|sgdisk .*--zap|dd if=.*of=/dev/' scripts; then
  echo '[WARN] Review potential destructive disk commands above.'
else
  echo '[PASS] No obvious destructive disk-writing commands in scripts'
fi
exit "$fail"
