# Vyra OS — Foundation (Phase 1, 0.1.0-dev)

**Status:** Phase 1 source-complete, 2026-11-24. This is source material, not a built or certified operating system. No ISO exists yet. No hardware is certified yet. See `docs/PHASE_1_REPORT_2026-11-24.md` for what passed, failed, and is blocked.

Vyra OS is being developed as an independently maintained Fedora bootc-based Linux image. This foundation establishes a reproducible build config, hardware discovery (text + JSON + performance class), build scripts, CI checks, branding tokens, and disk-safety guardrails.

## Current scope
- Fedora 45 bootc base image, pinned by tag + digest recorded 2026-11-24 (`sha256:d440aea898005f376bbf0bbe06c216abdba68dcdb6dfa5cb0fa246cd03fa8d8a` — re-verify at build time).
- KDE Plasma desktop foundations and common hardware diagnostic tools.
- Hardware inventory script (text) + machine-readable JSON report with ENTRY / STANDARD / PERFORMANCE classification and storage classification.
- Local Podman build script + bootc-image-builder ISO config/script (Phase 2 gate, not yet run).
- GitHub Actions syntax/build workflow.
- VFM branding tokens (palette + typography, text wordmark only — no invented logo).
- Security and destructive-operation guardrails.
- Application manifest (Phase 1 intent only — later-phase apps are NOT installed).

## Not yet delivered
- A bootable ISO.
- An installer.
- VFM-branded finished desktop shell or Arena.
- HP Victus hardware certification.
- Entry-level hardware certification.
- Full office/creative/gaming application suite.
- Base44 Command Center.

## Build host
Use a supported Fedora Linux build host with:
- Podman
- Git
- Sufficient free storage (recommend 80GB+ for build cache and artifacts)
- Internet access for package and image downloads

This workspace's host (Ubuntu 24.04.5 LTS, 7.7GB RAM) is NOT the recommended host — it is a development VM used for source work and preflight. A Fedora host with more RAM is required for a credible Phase 2 build + QEMU test. See `docs/DEPENDENCIES.md`.

Install Podman using your distribution's official package manager. The exact `image-builder` installation method depends on the host Fedora release; follow the current upstream documentation linked below.

## Build the development container image

```bash
./scripts/build-container.sh
```

This creates `localhost/vyra-os:0.1.0-dev` in local Podman storage. It does **not** create an ISO or write to a physical disk.

## Inspect the image

```bash
podman image inspect localhost/vyra-os:0.1.0-dev
```

## Generate a hardware report on a Linux test machine

```bash
sudo ./scripts/hardware-report.sh
python3 scripts/hardware-report.py artifacts/hardware-report.json
```

The text report is written to `./artifacts/hardware-report.txt` and the machine-readable JSON report (with ENTRY / STANDARD / PERFORMANCE class + storage class) to `./artifacts/hardware-report.json`. Review both before sharing; they may contain device identifiers and system details. A report is discovery only — it is NOT a certification.

## Build the Live ISO (Phase 2 gate — not yet run)

```bash
./scripts/build-iso.sh
```

Uses `quay.io/centos-bootc/bootc-image-builder:latest` with `config/bootc-image-builder.toml`. Writes only to `artifacts/`. Boot test is a separate gate: QEMU/KVM first, then physical HP Victus hardware.

## Next engineering gates
1. Build the container image successfully on a supported Fedora host.
2. Run static checks and inspect the package manifest.
3. Boot a derived test image in QEMU/KVM.
4. Add and validate the ISO boot configuration using current Image Builder documentation.
5. Test on physical HP Victus hardware when available.
6. Test a separate 8GB entry-level system.

## Important storage policy
A 32GB USB is a Live-media target, not a realistic internal-drive target for a full desktop, updates, and a creative/gaming suite. Use a larger SSD for installation. This scaffold does not partition or format disks.

## Upstream references
- bootc: https://bootc-dev.github.io/bootc/
- Fedora bootc ISO guide: https://osbuild.org/docs/developer-guide/projects/image-builder/advanced/bootc/isos/
- Image Builder usage: https://osbuild.org/docs/developer-guide/projects/image-builder/usage/
- Fedora bootc docs: https://docs.fedoraproject.org/
- KDE: https://kde.org/
