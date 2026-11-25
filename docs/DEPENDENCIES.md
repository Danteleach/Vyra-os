# Vyra Dependencies — Phase 1

## Base image (verified 2026-11-24)

- `quay.io/fedora/fedora-bootc:45`
- Manifest-list digest: `sha256:d440aea898005f376bbf0bbe06c216abdba68dcdb6dfa5cb0fa246cd03fa8d8a`
- amd64 child digest (the pin used in Containerfile): `sha256:49a5a46879e972f231d1045bf12a7801f35d262c4adf4cb2d874436bebbe0ec3`
- Checked: 2026-11-24 11:31 UTC via Quay API (`/api/v1/repository/fedora/fedora-bootc/tag/?specificTag=45`); child digest from `podman image inspect` RepoDigests after a successful tag-only pull.
- Lesson 2026-11-24: podman 4.9.3 fails pulling by manifest-list digest ("can't talk to a V1 container registry", exit 125) but pulls the same image fine by tag. The Containerfile pins the amd64 child digest instead.
- Status: Fedora 45 is current in Nov 2026 upstream activity (fedora-bootc:45 digests updating daily mid-Nov 2026). Fedora 46 was seen emerging 2026-11-09 — 0.1 stays on 45.
- Re-verify the digest at every build; tags move.

## Build host (this run)

- Host in this workspace: Ubuntu 24.04.5 LTS, x86_64, 4 vCPU (AMD EPYC 9D25, host view), 7.7GB RAM, 147GB free on /home.
- This is NOT the recommended host. Recommended: Fedora Linux host, Podman, Git, 80GB+ free storage, internet access.
- Podman was missing at audit start. Install was attempted in this session (see Phase 1 report). Ubuntu podman is usable for a container build but is not a Fedora-host certification.
- QEMU/KVM: not installed at audit start; `qemu-utils` install attempted alongside podman for later QCOW2/ISO inspection. Full QEMU system + KVM is a Phase 2 gate.

## In-image packages (Containerfile)

Foundation desktop + hardware tooling: plasma-desktop, plasma-workspace, plasma-workspace-wayland, sddm, dolphin, konsole, NetworkManager (+wifi/bluetooth), PipeWire + WirePlumber, BlueZ, firewalld, flatpak, podman, btrfs-progs, cryptsetup (LUKS2), fwupd, pciutils, usbutils, lshw, inxi, glx-utils, vulkan-tools, mesa-dri-drivers.

SELinux stays enforcing (bootc base default). Firewall stays enabled. No Secure Boot / TPM feature is disabled by this scaffold.

## ISO tooling (Phase 2 gate, not yet run)

- `quay.io/centos-bootc/bootc-image-builder:latest`
- Config: `config/bootc-image-builder.toml`
- Script: `scripts/build-iso.sh` — writes only to `artifacts/`

## Upstream references

- bootc: https://bootc-dev.github.io/bootc/
- Fedora bootc ISO guide: https://osbuild.org/docs/developer-guide/projects/image-builder/advanced/bootc/isos/
- Image Builder usage: https://osbuild.org/docs/developer-guide/projects/image-builder/usage/
- Fedora docs: https://docs.fedoraproject.org/
- KDE: https://kde.org/
