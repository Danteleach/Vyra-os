# Vyra OS foundation — development image, Phase 1 (0.1.0-dev)
# Base pinned by tag + per-arch digest, re-verified 2026-11-27
# (the 2026-11-24 pin expired: Quay rebuilt the image and the old digest
#  went "manifest unknown", which failed the first CI run in seconds;
#  the 2026-11-25 pin expired the same way 2026-11-26 and failed run #10
#  in 30s; the 2026-11-26 pin expired the same way 2026-11-27 and would
#  have failed run #26 — Quay garbage-collects unreferenced digests
#  within ~a day):
#   quay.io/fedora/fedora-bootc:45
#   manifest-list digest sha256:28d699682aa6f6b48c96864032717c596020d5d9890f83f488454e0d72f955b7
#   (Quay API, checked Fri 2026-11-27, 4 children)
#   amd64 child digest sha256:30c120e9b7ad3d7c94ae9ead413025f316775adf94f8d5fb3f9a62f808f0763a
#   (from the Quay registry API manifest list, verified resolving)
# LESSON 2026-11-24: podman 4.9.3 in this environment FAILS pulling by the
# manifest-list digest ("can't talk to a V1 container registry", exit 125),
# but pulls the same image fine by tag, and the amd64 child digest is the
# single-arch manifest. So the pin below uses the amd64 child digest.
# Re-verify digests at build time — Fedora 45 tags move with updates.
# Fedora 46 was seen emerging 2026-11-09 in upstream renovate activity;
# 0.1 stays on 45 for stability. Do not move to 46 without a Phase decision.
FROM quay.io/fedora/fedora-bootc:45@sha256:30c120e9b7ad3d7c94ae9ead413025f316775adf94f8d5fb3f9a62f808f0763a

LABEL org.opencontainers.image.title="Vyra OS"
LABEL org.opencontainers.image.description="Vyra bootc-based Linux foundation"
LABEL org.opencontainers.image.vendor="VFM Studios"
LABEL org.opencontainers.image.version="0.1.0-dev"
LABEL io.vyra.base="quay.io/fedora/fedora-bootc:45"
LABEL io.vyra.base-digest="sha256:30c120e9b7ad3d7c94ae9ead413025f316775adf94f8d5fb3f9a62f808f0763a"
LABEL io.vyra.base-manifest-list-digest="sha256:28d699682aa6f6b48c96864032717c596020d5d9890f83f488454e0d72f955b7"
LABEL io.vyra.base-digest-checked="2026-11-27"

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
    sddm-breeze \
    dolphin \
    konsole \
    plasma-discover \
    kf6-kconfig \
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

# Phase A (Batch 01) — Desktop identity: Vyra wallpaper package,
# org.vyra.desktop look-and-feel, system-wide defaults + lock screen.
# Sources live under vyra-branding/ (COPYed above to /usr/share/vyra/branding);
# the PNGs are the Batch 01 pack files, never edited in place.
RUN install -d -m 0755 /usr/share/wallpapers/Vyra/contents/images \
        /usr/share/wallpapers/Vyra/contents/images_dark \
    && cp /usr/share/vyra/branding/batch-01/02_light_wallpaper_master_3840x2160.png \
        /usr/share/wallpapers/Vyra/contents/images/3840x2160.png \
    && cp /usr/share/vyra/branding/batch-01/01_desktop_wallpaper_master_3840x2160.png \
        /usr/share/wallpapers/Vyra/contents/images_dark/3840x2160.png \
    && cp /usr/share/vyra/branding/batch-01/01b_desktop_wallpaper_1920x1080.png \
        /usr/share/wallpapers/Vyra/contents/images_dark/1920x1080.png \
    && cp /usr/share/vyra/branding/batch-01/01c_desktop_wallpaper_ultrawide_3440x1440.png \
        /usr/share/wallpapers/Vyra/contents/images_dark/3440x1440.png \
    && cp /usr/share/vyra/branding/batch-01/screenshot.png \
        /usr/share/wallpapers/Vyra/contents/screenshot.png \
    && cp /usr/share/vyra/branding/batch-01/03_lock_screen_background_3840x2160.png \
        /usr/share/vyra/branding/lock-screen-background.png \
    && cp /usr/share/vyra/branding/plasma/wallpapers/Vyra/metadata.json \
        /usr/share/wallpapers/Vyra/metadata.json \
    && mkdir -p /usr/share/plasma/look-and-feel \
    && cp -r /usr/share/vyra/branding/plasma/look-and-feel/org.vyra.desktop \
        /usr/share/plasma/look-and-feel/org.vyra.desktop \
    && mkdir -p /etc/xdg \
    && cp /usr/share/vyra/branding/xdg/kscreenlockerrc /etc/xdg/kscreenlockerrc \
    && (grep -q '^LookAndFeelPackage=' /etc/xdg/kdeglobals 2>/dev/null \
        || printf '[KDE]\nLookAndFeelPackage=org.vyra.desktop\n' >> /etc/xdg/kdeglobals)

# Phase A2 — Dark colour scheme (BreezeDark) as the system default, so the
# desktop reads dark/Carbon instead of light Breeze. Interim until the full
# Vyra Plasma theme (inventory §3.4) lands.
# CORRECTION 2026-11-26 (Phase A4): the original RUN set `--key Name
# BreezeDark`, but `Name` is NOT the colour-scheme key — the key Plasma
# reads is `ColorScheme` under [General] (verified against the shipped
# Breeze Dark look-and-feel defaults in plasma-workspace 6.8.1:
#   [kdeglobals][General] ColorScheme=BreezeDark
# Setting Name alone never switched the scheme, which is why runs 23/24
# rendered a LIGHT desktop + the light wallpaper despite this RUN
# reporting success. This RUN now sets ColorScheme (and the breeze-dark
# icon theme). The look-and-feel defaults file sets the same values, so
# applying org.vyra.desktop also keeps the session dark.
RUN kwriteconfig6 --file /etc/xdg/kdeglobals --group General --key ColorScheme BreezeDark 2>/dev/null \
    && kwriteconfig6 --file /etc/xdg/kdeglobals --group Icons --key Theme breeze-dark 2>/dev/null; \
    grep -q '^ColorScheme=BreezeDark' /etc/xdg/kdeglobals && echo 'dark colour scheme: BreezeDark set' || echo 'WARNING: BreezeDark colour scheme NOT set'

# Phase A3 (Wallpaper set) — Install the 5 new Vyra wallpaper designs
# (Flow, Summit, Prism, Orbit, Ring) as selectable KDE wallpaper packages,
# each with dark + light variants in 3 sizes, plus the VYRA STORE catalogue
# data. Sources live under vyra-branding/wallpapers/ and vyra-branding/store/
# (COPYed above). The Batch 01 hero (Vyra) stays the default wallpaper;
# these are additional choices. The catalogue JSON is installed at
# /usr/share/vyra/store/catalogue.json for the future Store app to read.
RUN for spec in flow:Flow summit:Summit prism:Prism orbit:Orbit ring:Ring; do \
        stem=${spec%%:*}; name=${spec##*:}; \
        install -d -m 0755 /usr/share/wallpapers/Vyra-${name}/contents/images \
            /usr/share/wallpapers/Vyra-${name}/contents/images_dark; \
        for size in 3840x2160 1920x1080 3440x1440; do \
            cp /usr/share/vyra/branding/wallpapers/${stem}-dark-${size}.png \
                /usr/share/wallpapers/Vyra-${name}/contents/images_dark/${size}.png; \
            cp /usr/share/vyra/branding/wallpapers/${stem}-light-${size}.png \
                /usr/share/wallpapers/Vyra-${name}/contents/images/${size}.png; \
        done; \
        cp /usr/share/vyra/branding/wallpapers/${stem}-dark-1920x1080.png \
            /usr/share/wallpapers/Vyra-${name}/contents/screenshot.png; \
        cp /usr/share/vyra/branding/plasma/wallpapers/Vyra-${name}/metadata.json \
            /usr/share/wallpapers/Vyra-${name}/metadata.json; \
    done \
    && install -d -m 0755 /usr/share/vyra/store \
    && cp /usr/share/vyra/branding/store/catalogue.json /usr/share/vyra/store/catalogue.json \
    && ls -d /usr/share/wallpapers/Vyra-* \
    && test -s /usr/share/vyra/store/catalogue.json \
    && echo 'wallpaper packages + store catalogue installed'

# Phase A4 (UI identity) — Vyra logo home button, black wallpaper default,
# Fedora logo replacement, floating glass dock.
# Owner direction 2026-11-26: (1) the Vyra logo as the home/start button
# (like the Windows Start button) and in the installer, (2) the black
# hero wallpaper as the default, (3) Fedora logos replaced with the Vyra
# logo, (4) a floating glassmorphism dock (macOS / elementary style),
# (5) HarmonyOS elegance throughout.
#
# How each piece is wired (all verified against Fedora 45 / Plasma 6.8
# before writing — see vyra-branding/icons/README.md and
# vyra-design/VYRA_UI_IDENTITY_DESIGN.md):
# - Home button: the look-and-feel layout.js
#   (org.vyra.desktop/contents/layouts/org.kde.plasma.desktop-layout.js,
#   copied by Phase A's cp -r) creates the dock and sets the Kickoff
#   applet's icon to "vyra" (writeConfig("icon","vyra") in [General]).
#   The "vyra" icon is installed below into the hicolor theme.
# - Black wallpaper default: the look-and-feel defaults now set
#   ColorScheme=BreezeDark (the correct key — see Phase A2 correction),
#   so the Vyra wallpaper package picks its images_dark/ (black hero)
#   variant; the layout.js ALSO pins the desktop wallpaper to the black
#   hero file by direct path, so either layer alone is enough.
# - Fedora logos: the Vyra icon is installed under every Fedora icon
#   name (fedora-logo-icon, org.fedoraproject.AnacondaInstaller,
#   start-here, anaconda), the Fedora SVG/PNG files are removed or
#   overwritten, and the pixmaps logos are overwritten with the V mark.
#   The installer .desktop icon is set to vyra by configure_iso.sh.
# - Floating glass dock: the layout.js builds a single centered bottom
#   panel with floating=true, lengthMode=fit, opacity=translucent.
#   KWin's blur (on by default) frosts the wallpaper behind it.
# - The layout.js + defaults flow through Phase A's existing cp -r of
#   the look-and-feel dir; this RUN only installs the icons and
#   replaces the Fedora logo files.
RUN for size in 16 22 24 32 36 48 64 96 128 256 512; do \
        install -d -m 0755 "/usr/share/icons/hicolor/${size}x${size}/apps"; \
        cp "/usr/share/vyra/branding/icons/vyra-${size}.png" \
            "/usr/share/icons/hicolor/${size}x${size}/apps/vyra.png"; \
        cp "/usr/share/vyra/branding/icons/vyra-${size}.png" \
            "/usr/share/icons/hicolor/${size}x${size}/apps/fedora-logo-icon.png"; \
        cp "/usr/share/vyra/branding/icons/vyra-${size}.png" \
            "/usr/share/icons/hicolor/${size}x${size}/apps/start-here.png"; \
    done \
    && cp /usr/share/vyra/branding/icons/vyra-48.png \
        /usr/share/icons/hicolor/48x48/apps/org.fedoraproject.AnacondaInstaller.png \
    && cp /usr/share/vyra/branding/icons/vyra-256.png \
        /usr/share/icons/hicolor/256x256/apps/org.fedoraproject.AnacondaInstaller.png \
    && cp /usr/share/vyra/branding/icons/vyra-256.png \
        /usr/share/icons/hicolor/256x256/apps/anaconda.png \
    && rm -f /usr/share/icons/hicolor/scalable/apps/start-here.svg \
        /usr/share/icons/hicolor/scalable/places/start-here.svg \
        /usr/share/icons/hicolor/48x48/apps/org.fedoraproject.AnacondaInstaller.svg \
        /usr/share/icons/hicolor/symbolic/apps/org.fedoraproject.AnacondaInstaller-symbolic.svg \
    && cp /usr/share/vyra/branding/icons/vyra-512.png /usr/share/pixmaps/fedora-logo.png \
    && cp /usr/share/vyra/branding/icons/vyra-256.png /usr/share/pixmaps/fedora-logo-small.png \
    && cp /usr/share/vyra/branding/icons/vyra-256.png /usr/share/anaconda/pixmaps/sidebar-logo.png \
    && (gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true) \
    && test -s /usr/share/icons/hicolor/48x48/apps/vyra.png \
    && test -s /usr/share/icons/hicolor/48x48/apps/fedora-logo-icon.png \
    && test -s /usr/share/icons/hicolor/48x48/apps/org.fedoraproject.AnacondaInstaller.png \
    && test -s /usr/share/icons/hicolor/48x48/apps/start-here.png \
    && echo 'Vyra icons installed; Fedora logos replaced'

# Phase B (Batch 01) — Plymouth boot splash: Vyra two-step theme.
# The theme + default live in the CORE image so the payload's dracut regen
# (configure_iso.sh) embeds them in the live initramfs. The logo is the D1
# wordmark crop (vyra-plymouth-logo.png); the theme file is vyra.plymouth.
# Run 26 (docs/PLYMOUTH_INVESTIGATION.md Option 1): the theme is completed —
# watermark.png (copy of the D1 wordmark; the two-step plugin loads its logo
# as watermark.png, not logo.png), 1x1 transparent dialog images
# (box/entry/lock/bullet.png), and Cantarell fonts (Inter is not installed).
RUN --mount=type=bind,source=certs/hatch-egress-ca.crt,target=/tmp/hatch-egress-ca.crt,ro \
    --mount=type=bind,source=scripts/sandbox-ca.sh,target=/tmp/sandbox-ca.sh,ro \
    sh /tmp/sandbox-ca.sh trust \
    && dnf5 install -y plymouth plymouth-plugin-two-step plymouth-plugin-label \
    && mkdir -p /usr/share/plymouth/themes/vyra \
    && cp /usr/share/vyra/branding/batch-01/vyra.plymouth /usr/share/plymouth/themes/vyra/vyra.plymouth \
    && cp /usr/share/vyra/branding/batch-01/vyra-plymouth-logo.png /usr/share/plymouth/themes/vyra/logo.png \
    && cp /usr/share/vyra/branding/batch-01/vyra-watermark.png /usr/share/plymouth/themes/vyra/watermark.png \
    && cp /usr/share/vyra/branding/batch-01/box.png /usr/share/plymouth/themes/vyra/box.png \
    && cp /usr/share/vyra/branding/batch-01/entry.png /usr/share/plymouth/themes/vyra/entry.png \
    && cp /usr/share/vyra/branding/batch-01/lock.png /usr/share/plymouth/themes/vyra/lock.png \
    && cp /usr/share/vyra/branding/batch-01/bullet.png /usr/share/plymouth/themes/vyra/bullet.png \
    && plymouth-set-default-theme vyra \
    && dnf5 clean all \
    && sh /tmp/sandbox-ca.sh remove

# Phase C (Batch 01) — SDDM login: fork the Fedora Breeze theme as "vyra",
# point its background at the clean D2 derivative (06 stays a mockup — it has
# baked-in text/card), and select the theme. The background file is copied
# to /usr/share/vyra/branding/sddm-background.png (the theme.conf.user path).
RUN cp -r /usr/share/sddm/themes/01-breeze-fedora /usr/share/sddm/themes/vyra \
    && sed -i 's/^Name=.*/Name=Vyra/' /usr/share/sddm/themes/vyra/metadata.desktop \
    && cp /usr/share/vyra/branding/batch-01/vyra-sddm-background.png \
        /usr/share/vyra/branding/sddm-background.png \
    && cp /usr/share/vyra/branding/sddm/theme.conf.user \
        /usr/share/sddm/themes/vyra/theme.conf.user \
    && mkdir -p /etc/sddm.conf.d \
    && cp /usr/share/vyra/branding/sddm/10-theme.conf /etc/sddm.conf.d/10-theme.conf

# Run 26 fixes — startup races found in the run-25 boot test.
# - plasmashell (docs/PLASMASHELL_RACE_INVESTIGATION.md F1+F2): the shell's
#   load gate waits on a single-shot async D-Bus reply from
#   kactivitymanagerd with no retry; order the daemon before the shell
#   (After=+Wants=) and raise the shell's start timeout 40 s -> 120 s.
# - krunner (docs/KRUNNER_INVESTIGATION.md Option 1): the shipped unit's
#   5 s start timeout kills D-Bus activation under TCG; raise it to 60 s.
#   The NoDisplay desktop file silences the cosmetic xdg-desktop-portal
#   lookup warning (KDE bug 512650); it does not fix Alt+F2 by itself.
# Drop-ins are Vyra-owned /etc files (three-way merged across bootc
# updates); the desktop file ships under /usr/share/applications.
RUN mkdir -p /etc/systemd/user/plasma-plasmashell.service.d \
        /etc/systemd/user/plasma-krunner.service.d \
    && cp /usr/share/vyra/branding/systemd/plasma-plasmashell.service.d/vyra-fix.conf \
        /etc/systemd/user/plasma-plasmashell.service.d/vyra-fix.conf \
    && cp /usr/share/vyra/branding/systemd/plasma-krunner.service.d/vyra-timeout.conf \
        /etc/systemd/user/plasma-krunner.service.d/vyra-timeout.conf \
    && cp /usr/share/vyra/branding/applications/org.kde.krunner.desktop \
        /usr/share/applications/org.kde.krunner.desktop \
    && test -s /etc/systemd/user/plasma-plasmashell.service.d/vyra-fix.conf \
    && test -s /etc/systemd/user/plasma-krunner.service.d/vyra-timeout.conf \
    && test -s /usr/share/applications/org.kde.krunner.desktop \
    && echo 'run-26 systemd drop-ins + krunner desktop file installed'

# Phase D (Batch 01) — Product identity: the installer reads its product
# name from os-release (Anaconda product.py), not from vyra.conf.
# ID is now vyra (ID_LIKE=fedora kept so Fedora tooling still works) and
# vyra.conf os_id matches it. VERSION_ID=45 stays — dnf's $releasever
# depends on it. NOTE: /usr/lib/os-release is owned by fedora-release, so a
# future dnf update of that package could overwrite these values; a durable
# fix is a vyra-release package (future work).
RUN sed -i 's/^NAME=.*/NAME="Vyra OS"/; s/^PRETTY_NAME=.*/PRETTY_NAME="Vyra OS 0.1"/; s/^ID=.*/ID=vyra/' /usr/lib/os-release \
    && (grep -q '^ID_LIKE=' /usr/lib/os-release || printf 'ID_LIKE="fedora"\n' >> /usr/lib/os-release) \
    && grep -q '^NAME="Vyra OS"' /usr/lib/os-release \
    && grep -q '^PRETTY_NAME="Vyra OS 0.1"' /usr/lib/os-release \
    && grep -q '^ID=vyra$' /usr/lib/os-release \
    && grep -q '^ID_LIKE="fedora"' /usr/lib/os-release

# Phase E (Batch 01) — Discover featured list: point Editor's Choice at the
# Vyra-hosted JSON (repo file, branch URL; re-pin to main/a tag at release).
# The banner PNG has no plug-in in Discover; the JSON is the control.
RUN mkdir -p /usr/share/discover \
    && cp /usr/share/vyra/branding/discover/featuredurlrc /usr/share/discover/featuredurlrc

# Hardware discovery (host-side script, also shipped in-image for first-boot use).
COPY scripts/hardware-report.sh /usr/share/vyra/hardware-report.sh
COPY scripts/hardware-report.py /usr/share/vyra/hardware-report.py
RUN chmod 0755 /usr/share/vyra/hardware-report.sh /usr/share/vyra/hardware-report.py

# This is a development foundation. The graphical login/session configuration,
# bootable ISO composition, installer, Arena, and production branding are
# separate gates (Phases 2-4, 7). This image alone is NOT a bootable ISO.
