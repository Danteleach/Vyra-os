# Vyra OS foundation — development image, Phase 1 (0.1.0-dev)
# Base pinned by tag + per-arch digest, re-verified 2026-11-25
# (the 2026-11-24 pin expired: Quay rebuilt the image and the old digest
#  went "manifest unknown", which failed the first CI run in seconds):
#   quay.io/fedora/fedora-bootc:45
#   manifest-list digest sha256:2342f957281b061919c48a12227f9cd04f2d9825d17629fd914083aaa672002c
#   (Quay API, last modified Wed, 25 Nov 2026 12:01:14 UTC, 4 children)
#   amd64 child digest sha256:bf0f127b2fb2432bb48bf730406ec94fbf8943ab987cfdadca2de6d84426bbc9
#   (from `podman manifest inspect` on the tag, verified resolving)
# LESSON 2026-11-24: podman 4.9.3 in this environment FAILS pulling by the
# manifest-list digest ("can't talk to a V1 container registry", exit 125),
# but pulls the same image fine by tag, and the amd64 child digest is the
# single-arch manifest. So the pin below uses the amd64 child digest.
# Re-verify digests at build time — Fedora 45 tags move with updates.
# Fedora 46 was seen emerging 2026-11-09 in upstream renovate activity;
# 0.1 stays on 45 for stability. Do not move to 46 without a Phase decision.
FROM quay.io/fedora/fedora-bootc:45@sha256:bf0f127b2fb2432bb48bf730406ec94fbf8943ab987cfdadca2de6d84426bbc9

LABEL org.opencontainers.image.title="Vyra OS"
LABEL org.opencontainers.image.description="Vyra bootc-based Linux foundation"
LABEL org.opencontainers.image.vendor="VFM Studios"
LABEL org.opencontainers.image.version="0.1.0-dev"
LABEL io.vyra.base="quay.io/fedora/fedora-bootc:45"
LABEL io.vyra.base-digest="sha256:bf0f127b2fb2432bb48bf730406ec94fbf8943ab987cfdadca2de6d84426bbc9"
LABEL io.vyra.base-manifest-list-digest="sha256:2342f957281b061919c48a12227f9cd04f2d9825d17629fd914083aaa672002c"
LABEL io.vyra.base-digest-checked="2026-11-25"

# Build-host TLS workaround (this sandbox VM only): the egress proxy MITMs
# TLS with "Hatch Sandbox Egress CA", which the Fedora image does not trust,
# so dnf fails with "self-signed certificate in certificate chain".
# NOTE: this CA is per-VM and CHANGES on VM replacement — after any restart,
# re-extract it from /run/hatch/cell-anchors/hatch-egress-ca.pem into
# certs/hatch-egress-ca.crt (certificate only, never a private key) and
# verify the fingerprint matches the live CA before rebuilding. A stale
# cert fails dnf with the same TLS error (attempt 9, 2026-11-24).
# The trust step is scripts/sandbox-ca.sh (bind-mounted): it trusts the CA
# only if the mounted file is non-empty. On a normal host / CI the mount
# source is an empty placeholder file (see .github/workflows/build.yml),
# so the script skips trusting and dnf just works. Either way the CA is
# removed again in the same RUN, so no layer ever keeps the sandbox CA.
# The install is split into three RUNs (not one) because the vfs storage
# driver failed twice (attempts 6 and 10) storing one huge dnf layer:
# "storing layer … to file: io: read/write on closed pipe", exit 125.
# Smaller layers are the workaround; each RUN repeats the CA trust dance
# and removes the CA again, so no layer ever keeps the sandbox CA.
RUN --mount=type=bind,source=certs/hatch-egress-ca.crt,target=/tmp/hatch-egress-ca.crt,ro \
    --mount=type=bind,source=scripts/sandbox-ca.sh,target=/tmp/sandbox-ca.sh,ro \
    sh /tmp/sandbox-ca.sh trust \
    && dnf5 install -y \
    plasma-desktop \
    plasma-workspace \
    plasma-workspace-wayland \
    sddm \
    dolphin \
    konsole \
    && dnf5 clean all \
    && sh /tmp/sandbox-ca.sh remove
RUN --mount=type=bind,source=certs/hatch-egress-ca.crt,target=/tmp/hatch-egress-ca.crt,ro \
    --mount=type=bind,source=scripts/sandbox-ca.sh,target=/tmp/sandbox-ca.sh,ro \
    sh /tmp/sandbox-ca.sh trust \
    && dnf5 install -y \
    NetworkManager \
    NetworkManager-wifi \
    NetworkManager-bluetooth \
    pipewire \
    pipewire-alsa \
    pipewire-pulseaudio \
    wireplumber \
    bluez \
    firewalld \
    flatpak \
    podman \
    btrfs-progs \
    cryptsetup \
    fwupd \
    && dnf5 clean all \
    && sh /tmp/sandbox-ca.sh remove
RUN --mount=type=bind,source=certs/hatch-egress-ca.crt,target=/tmp/hatch-egress-ca.crt,ro \
    --mount=type=bind,source=scripts/sandbox-ca.sh,target=/tmp/sandbox-ca.sh,ro \
    sh /tmp/sandbox-ca.sh trust \
    && dnf5 install -y \
    pciutils \
    usbutils \
    lshw \
    inxi \
    glx-utils \
    vulkan-tools \
    mesa-dri-drivers \
    && dnf5 clean all \
    && sh /tmp/sandbox-ca.sh remove

# Keep NetworkManager enabled. Do not disable SELinux or firewall defaults.
RUN systemctl enable NetworkManager.service \
    && systemctl enable bluetooth.service \
    && systemctl enable firewalld.service

# VFM release identity and branding tokens (text wordmark only — no invented logo).
# Official VFM logo assets were not on disk at Phase 1 audit (2026-11-20);
# do not invent a logo file here. Branding files are copied from vyra-branding/.
COPY vyra-branding /usr/share/vyra/branding
RUN install -d -m 0755 /usr/share/vyra \
    && printf '%s\n' 'Vyra OS 0.1.0-dev' > /usr/share/vyra/release \
    && printf '%s\n' 'ONE CORE. TWO WORLDS. EVERY DEVICE.' > /usr/share/vyra/slogan \
    && printf '%s\n' 'Built to Move Culture Forward' > /usr/share/vyra/tagline

# Hardware discovery (host-side script, also shipped in-image for first-boot use).
COPY scripts/hardware-report.sh /usr/share/vyra/hardware-report.sh
COPY scripts/hardware-report.py /usr/share/vyra/hardware-report.py
RUN chmod 0755 /usr/share/vyra/hardware-report.sh /usr/share/vyra/hardware-report.py

# This is a development foundation. The graphical login/session configuration,
# bootable ISO composition, installer, Arena, and production branding are
# separate gates (Phases 2-4, 7). This image alone is NOT a bootable ISO.
