#!/usr/bin/env bash
# Vyra ISO build — Fedora host variant (Phase 2).
# Run this ON a Fedora machine (Fedora 42 or newer recommended).
# Requires: podman, git, ~20GB free disk, internet.
# Writes ONLY to ./artifacts/ in this repo. Never runs on, or writes to,
# a physical disk (the ISO is a file; installing it is a separate, manual step).
#
# Why a separate script from scripts/build-iso.sh: that one is adapted to the
# sandbox VM (custom podman storage in ./.vfs, host networking, TMPDIR, and
# CA-bundle mounts for the MITM egress proxy). A real Fedora host needs none
# of that — plain rootful podman and the default storage location.
# This script uses `sudo podman` throughout so the image lands in
# /var/lib/containers/storage, which the builder container mounts.
set -euo pipefail
IMAGE="${Vyra_IMAGE:-localhost/vyra-os:0.1.0-dev}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
command -v podman >/dev/null 2>&1 || { echo "ERROR: install podman first: sudo dnf install -y podman git" >&2; exit 1; }
mkdir -p artifacts certs
# Empty CA placeholder: the Containerfile bind-mounts certs/hatch-egress-ca.crt
# in each dnf RUN, so the file must exist. On a normal host there is no MITM
# proxy, so it stays EMPTY and scripts/sandbox-ca.sh skips trusting it.
# (On the sandbox VM this file holds the real egress CA — never commit it;
# certs/ is gitignored.)
touch certs/hatch-egress-ca.crt
if ! sudo podman image exists "$IMAGE"; then
  echo "Building $IMAGE (this downloads the Fedora base and installs ~813 packages; it takes a while)..."
  sudo podman build -t "$IMAGE" -f Containerfile .
else
  echo "Image $IMAGE already present, reusing it."
fi
echo "Building ISO from $IMAGE — this downloads the bootc-image-builder container and can take a long time."
sudo podman run --rm --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v "$ROOT/artifacts:/output" \
  -v "$ROOT/config/bootc-image-builder.toml:/config.toml:ro" \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type iso --config /config.toml "$IMAGE"
echo
echo "ISO build finished. Check artifacts/ for *.iso and verify its SHA256:"
echo "  sha256sum artifacts/*.iso"
echo "The ISO file will be owned by root (the builder runs privileged);"
echo "copy or read it with sudo if needed."
echo "Next: boot-test it (QEMU/KVM on this host is fastest), or get it to"
echo "Coby for the QEMU boot test — see docs/FEDORA_HOST_SETUP.md."
