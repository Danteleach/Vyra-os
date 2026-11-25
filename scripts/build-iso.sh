#!/usr/bin/env bash
# Vyra ISO build — Phase 2 gate. Requires: podman, a built
# localhost/vyra-os:0.1.0-dev image, and ~20GB free in ./artifacts.
# Writes ONLY to ./artifacts/. Never runs on, or writes to, a physical disk.
#
# Environment adaptations (this sandbox VM, 2026-11-24):
# - podman runs with the same custom flags as the image build:
#   --cgroup-manager cgroupfs, --root ./.vfs, --runroot /tmp/vr,
#   --storage-driver vfs. The Vyra image lives in ./.vfs, so the builder
#   container mounts ./.vfs as /var/lib/containers/storage (NOT the
#   default /var/lib/containers/storage, which is empty here).
# - --network host: container creation fails in this sandbox without it
#   (SIOCSIFFLAGS on the bridge network).
# - No -it: this runs non-interactively (backgrounded).
# - TMPDIR on the big disk: /var/tmp is a 2.0G tmpfs and the image blob
#   is ~5GB (the import failed on this in Phase 1).
# - TLS: the egress proxy MITMs TLS. The builder container (and the
#   osbuild/dnf inside it) needs the proxy CA, so the HOST CA bundle
#   (which already trusts the proxy — verified with curl) is bind-mounted
#   over the container's CA bundle paths. Without this, fetching
#   installer packages from the Fedora mirrors fails with a TLS error.
#   The bundle is the host's public CA set + the proxy CA; no private
#   key is involved.
set -euo pipefail
IMAGE="${Vyra_IMAGE:-localhost/vyra-os:0.1.0-dev}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
command -v podman >/dev/null 2>&1 || { echo "ERROR: Podman is required." >&2; exit 1; }
mkdir -p artifacts .tmp-iso
export TMPDIR="$ROOT/.tmp-iso"
echo "Building ISO from $IMAGE — this downloads the bootc-image-builder container and can take a long time."
podman --cgroup-manager cgroupfs --root "$ROOT/.vfs" --runroot /tmp/vr --storage-driver vfs \
  run --rm --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  --network host \
  -v "$ROOT/artifacts:/output" \
  -v "$ROOT/config/bootc-image-builder.toml:/config.toml:ro" \
  -v "$ROOT/.vfs:/var/lib/containers/storage" \
  -v /etc/ssl/certs/ca-certificates.crt:/etc/pki/tls/certs/ca-bundle.crt:ro \
  -v /etc/ssl/certs/ca-certificates.crt:/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem:ro \
  -v /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type iso --config /config.toml "$IMAGE"
echo
echo "ISO build finished. Check artifacts/ for *.iso and verify its SHA256 before any boot test."
echo "Boot test is a separate gate: QEMU first (no KVM on this host — TCG emulation), then physical HP Victus hardware."
