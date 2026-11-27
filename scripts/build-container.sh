#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
Vyra_VERSION="$(cat "$ROOT/VERSION" 2>/dev/null || echo 0.0.0)"
IMAGE="${Vyra_IMAGE:-localhost/vyra-os:${Vyra_VERSION}}"
cd "$ROOT"
command -v podman >/dev/null 2>&1 || {
  echo "ERROR: Podman is required. Install it using your host distribution's official package manager." >&2
  exit 1
}
podman build --pull=always --build-arg "Vyra_VERSION=$Vyra_VERSION" -t "$IMAGE" -f Containerfile .
echo
echo "Built development image: $IMAGE"
echo "This is a container image, not a bootable ISO."
echo "Inspect with: podman image inspect $IMAGE"
echo
echo "NOTE (2026-11-24): in sandboxed VMs without /dev/fuse, the default"
echo "overlay driver fails at container creation (fuse-overlayfs: device"
echo "not found). Fallback that needs no overlay/fuse mount:"
echo "  podman --root \"\$PWD/.vfs\" --runroot /tmp/vr --storage-driver vfs build --pull=always -t \"$IMAGE\" -f Containerfile ."
echo "Runroot must be under 50 characters. VFS is slower and uses more disk."
