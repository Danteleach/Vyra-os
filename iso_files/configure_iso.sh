#!/usr/bin/bash
# Vyra OS live-ISO payload hook. Runs INSIDE the installer image build
# (privileged podman build, see installer/Containerfile.live): it turns the
# Vyra core image into the live session + Anaconda installer that Titanoboa
# squashes into the ISO.
#
# Ported and trimmed from bearyjd/bazzite-tower installer/src/build.sh
# (which itself ports ublue-os/titanoboa examples/bazzite) and from
# ublue-os/bluefin iso_files/configure_iso_anaconda.sh (Anaconda profile +
# interactive kickstart, at commit d045d24ddd2e483e0ad80f31becf597ae4012433).
# Vyra differences: stock Fedora kernel (already Fedora-signed, so no
# kernel swap), KDE livesys session, Anaconda GTK (anaconda-live; the
# Anaconda WebUI is a stretch goal), Anaconda profile "vyra".
#
# Inputs (files COPYed into the image by installer/Containerfile.live):
#   /tmp/vyra.conf  -> /etc/anaconda/profile.d/vyra.conf
#   /tmp/iso.yaml   -> /usr/lib/bootc-image-builder/iso.yaml
# Environment: INSTALL_IMAGE (default ghcr.io/danteleach/vyra-os:ci) is the
# image the live installer installs.
set -exo pipefail
{ export PS4='+( ${BASH_SOURCE}:${LINENO} ): '; } 2>/dev/null

INSTALL_IMAGE="${INSTALL_IMAGE:-ghcr.io/danteleach/vyra-os:ci}"

# /root is a symlink on bootc images; make sure its target exists.
mkdir -p "$(realpath /root)"
# bwrap (flatpak/dnf scriptlets) needs /proc/sys writable during the build.
mount -o remount,rw /proc/sys || true

# Embed the image to install so the live ISO can install fully offline.
# This is the netinstall=0 / embedded-payload behaviour: Anaconda then
# installs from the live session's container storage
# (ostreecontainer --transport=containers-storage), with no registry pull
# at install time — the install-time pull is what stalled the 0.1.0-dev
# installs (see docs/INSTALL_DEEP_DIVE_2026-11-26.md §2.1).
# NOTE: this nested podman pull writes into /var/lib/containers/storage
# inside the image being built, and needs the privileged build flags
# (--cap-add sys_admin --security-opt label=disable) plus the native
# kernel overlayfs pin in the workflow (bazzite-tower issue #47: the
# runner's fuse-overlayfs rejects the whiteouts the nested pull writes).
podman pull "${INSTALL_IMAGE}"

# Live initramfs: add the dmsquash-live modules so the ISO can mount its
# squashfs as the live root. Without this the ISO boots but finds no root.
dnf install -y dracut-live
kernel="$(ls /usr/lib/modules/ | head -n 1)"
[ -n "$kernel" ] || { echo "ERROR: no kernel found under /usr/lib/modules" >&2; exit 1; }
DRACUT_NO_XATTR=1 dracut -v --force --zstd --reproducible --no-hostonly \
    --add "dmsquash-live dmsquash-live-autooverlay" \
    "/usr/lib/modules/${kernel}/initramfs.img" "${kernel}"

# Live session scripts (KDE). livesys creates the liveuser and configures
# SDDM autologin — standard Fedora live behaviour.
dnf install -y livesys-scripts
sed -i "s/^livesys_session=.*/livesys_session=kde/" /etc/sysconfig/livesys
# Vyra live hostname: livesys sets "localhost-live" at boot (livesys-main);
# point it at vyra-live so the live session reads as Vyra, not Fedora.
sed -i 's/hostnamectl set-hostname "localhost-live"/hostnamectl set-hostname "vyra-live"/' /usr/libexec/livesys/livesys-main
grep -q 'vyra-live' /usr/libexec/livesys/livesys-main
systemctl enable livesys.service livesys-late.service

# Anaconda (GTK first) + block-device support + ISO builder bits + boot splash.
dnf install -y --allowerasing \
    anaconda-live \
    libblockdev-btrfs libblockdev-lvm libblockdev-dm \
    dracut-config-generic dracut-network net-tools \
    grub2-efi-x64-cdboot xorriso isomd5sum plymouth
mkdir -p /var/lib/rpm-state  # Anaconda needs this

# Run 26 fix (installer race, docs/INSTALLER_WEBUI_INVESTIGATION.md):
# webui-desktop waits only 60 s for Anaconda to write
# /run/anaconda/anaconda.conf (get_default_browser); under TCG — and on
# slow hardware — Anaconda's Python startup exceeds that, so webui-desktop
# exits before any browser is launched (installer window never appears,
# runs 24/25). Raise the wait to 600 s.
# CORRECTION 2026-11-27 (run 26 failed on this): the line in the shipped
# anaconda-webui-90-1.fc45 script is INDENTED ("    timeout=60" inside
# get_default_browser), so the original ^timeout=60$ pattern never matched
# and the guard correctly failed the build. Match with optional leading
# whitespace and preserve it; guard matches the same way.
# Guard: fail the build if upstream changes the timeout line.
sed -i 's/^\([[:space:]]*\)timeout=60$/\1timeout=600/' /usr/libexec/anaconda/webui-desktop
grep -q '^[[:space:]]*timeout=600$' /usr/libexec/anaconda/webui-desktop

# Phase D (Batch 01) — Vyra installer branding (Obsidian + gold). Fedora 45's
# Anaconda has no sidebar/topbar pixmaps (flat @anaconda_bg_color), so the
# theme is the logo + custom stylesheet, pointed at by the Vyra profile
# (vyra.conf [User Interface]). Sources are the Batch 01 pack files
# inherited from the core image's /usr/share/vyra/branding/ tree.
# Phase A4: the installer logo is now the Vyra gold V mark (vyra-mark.png,
# the transparent 512px icon from vyra-branding/icons/), and the desktop
# "Install Vyra OS" icon is the Vyra logo (Icon=vyra) instead of the
# Fedora AnacondaInstaller "f". The D1 wordmark (vyra-logo.png) is still
# copied for the Plymouth boot logo and kept here as a brand asset.
cp /usr/share/vyra/branding/batch-01/vyra-plymouth-logo.png /usr/share/anaconda/pixmaps/vyra-logo.png
cp /usr/share/vyra/branding/icons/vyra-512.png /usr/share/anaconda/pixmaps/vyra-mark.png
mkdir -p /usr/share/anaconda/pixmaps/vyra
cp /usr/share/vyra/branding/batch-01/vyra.css /usr/share/anaconda/pixmaps/vyra/vyra.css
# "Install Vyra OS" desktop label (was "Install to Hard Drive") and Vyra
# logo icon (was the Fedora AnacondaInstaller "f").
sed -i 's/^Name=Install to Hard Drive$/Name=Install Vyra OS/' /usr/share/applications/liveinst.desktop
sed -i 's/^Icon=.*/Icon=vyra/' /usr/share/applications/liveinst.desktop
grep -q '^Name=Install Vyra OS$' /usr/share/applications/liveinst.desktop
grep -q '^Icon=vyra$' /usr/share/applications/liveinst.desktop

# Anaconda profile "vyra" (Bluefin pattern). The core image sets
# os-release ID=vyra, so the profile matches on os_id=vyra (vyra.conf).
mkdir -p /etc/anaconda/profile.d
cp /tmp/vyra.conf /etc/anaconda/profile.d/vyra.conf

# Interactive kickstart: install the embedded image from the live
# session's container storage (offline), then repoint the installed
# deployment's origin at the registry for future updates.
cat >>/usr/share/anaconda/interactive-defaults.ks <<EOF

ostreecontainer --url=${INSTALL_IMAGE} --transport=containers-storage --no-signature-verification
%post
# Repoint the installed deployment at the registry for future updates.
# (Margine: the only %post allowed to fail — a failed repoint must not
# fail an otherwise good offline install.)
bootc switch --mutate-in-place --transport registry ${INSTALL_IMAGE} || echo "WARNING: bootc switch repoint failed; run it manually after first boot"
%end
EOF

# EFI layout Titanoboa's build_iso.sh expects: /boot/efi/EFI/$VENDOR
# (shim + grub2 binaries, copied from the image's /usr/lib/efi tree).
mkdir -p /boot/efi
cp -av /usr/lib/efi/*/*/EFI /boot/efi/ || true
cp -v /boot/efi/EFI/fedora/grubx64.efi /boot/efi/EFI/BOOT/fbx64.efi || true

# UTC clock for the live session.
systemd-firstboot --timezone UTC || true

# The live root is a small tmpfs overlay; ostree install needs room in /var/tmp.
rm -rf /var/tmp || :
mkdir -p /var/tmp
cat >/etc/systemd/system/var-tmp.mount <<'EOF'
[Unit]
Description=Larger tmpfs for /var/tmp on the live system
[Mount]
What=tmpfs
Where=/var/tmp
Type=tmpfs
Options=size=50%,nr_inodes=1m
[Install]
WantedBy=local-fs.target
EOF
systemctl enable var-tmp.mount

# "Install Vyra OS" GRUB entry: boots the live desktop with
# vyra.start-installer=1 on the kernel line; this autostart file launches
# the installer when (and only when) that flag is present. On a normal
# "Try Vyra OS" boot the script exits immediately and nothing starts.
mkdir -p /usr/share/vyra
cat >/usr/share/vyra/vyra-start-installer.sh <<'EOS'
#!/bin/sh
# Launched from the KDE autostart dir; starts the installer only on the
# "Install Vyra OS" GRUB entry (vyra.start-installer=1 on the kernel line).
if grep -q 'vyra.start-installer=1' /proc/cmdline 2>/dev/null; then
    exec liveinst
fi
EOS
chmod 0755 /usr/share/vyra/vyra-start-installer.sh
mkdir -p /etc/xdg/autostart
cat >/etc/xdg/autostart/vyra-start-installer.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Vyra Installer Autostart
Exec=/usr/share/vyra/vyra-start-installer.sh
OnlyShowIn=KDE;
NoDisplay=true
EOF

# The ISO config Titanoboa requires at this exact path (it exits 1 without it).
mkdir -p /usr/lib/bootc-image-builder
cp /tmp/iso.yaml /usr/lib/bootc-image-builder/iso.yaml

dnf clean all || true
