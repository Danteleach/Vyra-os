# Vyra OS — 3-Part Split across 2 GitHub Repos (v2)

Status: **design decided by the owner, 2026-11-24**. Not yet built. All sizes below
are estimates until the first ISO exists (Phase 2 is blocked on the Fedora host).
Supersedes the v1 design (single repo, 5.7 GB total).

## Goal

Ship Vyra OS as three parts across **two GitHub repos**, using the full size
budget for flagship features:

- **Total compressed: 3.8–4.0 GB. Fill the budget.** A build that lands well under
  is a signal to add flagship content, not a win.
- **Total uncompressed: ~10 GB.** Current system measures ~5 GB uncompressed
  (rootfs 4.97 GB; the owner works from ~5.9 GB), so the upgrade packs add
  roughly **~4–5 GB of new uncompressed content**.
- Assumed compression ratio ~2.5:1 (squashfs xz for the ISO, zstd for packs).
  Fedora live media lands in the same range; verify at first build.
- **Part 1 alone is a complete, working OS**: it boots, installs, and runs.
- **Parts 2 and 3 are upgrades**, applied on top of the running system, in
  sequence (Stability → Performance → Aesthetics).
- A **walkthrough guide for new users** ships with the release
  (`docs/WALKTHROUGH.md`, draft written; final version lives in Repo 2).

## The two repos

| Repo | Holds | Release assets |
| --- | --- | --- |
| `vyra-os` (Repo 1) | OS source, Containerfile, core image, build scripts | `vyra-os-0.1.0-core.iso` |
| `vyra-os-packs` (Repo 2) | Upgrade packs, pack tool, walkthrough guide | `vyra-os-0.1.0-performance.vyrapack`, `vyra-os-0.1.0-aesthetics.vyrapack`, `SHA256SUMS`, `vyra-os-0.1.0-manifest.json`, `WALKTHROUGH.md` |

Repo names are proposed; the owner creates the repos. GitHub caps each release
asset at 2 GiB, with no cap on release total or bandwidth, so every file below
stays under 2 GiB. Stable download URLs follow GitHub's pattern:
`https://github.com/<owner>/<repo>/releases/download/<tag>/<asset>`.
Repo 1's release notes link to Repo 2 for the packs and the walkthrough.

## Size budget (compressed)

| Part | File | Budget | Uncompressed (est.) |
| --- | --- | --- | --- |
| 1 — Stability | `vyra-os-0.1.0-core.iso` (Repo 1) | ≤ 1.9 GB | ~5 GB |
| 2 — Performance | `vyra-os-0.1.0-performance.vyrapack` (Repo 2) | ≤ 1.1 GB | ~2.5 GB |
| 3 — Aesthetics | `vyra-os-0.1.0-aesthetics.vyrapack` (Repo 2) | ≤ 1.0 GB | ~2 GB |
| **Total** | | **≤ 4.0 GB** | **~10 GB** |

If a part comes in over budget, the lever is trimming or deferring content to a
later version — never splitting Part 1 (it must stay a single bootable file).

**Live-ISO tension (2026-11-26, owner to re-decide — NOT re-decided here):**
Part 1 is now a **live ISO** (Titanoboa; see `docs/INSTALL_DEEP_DIVE_2026-11-26.md`
and the run #9 section of `docs/PHASE_2_REPORT_2026-11-24.md`), not the
anaconda installer ISO this budget was written for. A live ISO embeds the
squashfs of the whole image (~5 GB uncompressed → roughly 2 GB compressed)
**plus**, in embedded/offline mode, the install payload again in the
image's container storage — Bluefin's live ISOs are ~5 GB. The ≤1.9 GB
Part 1 budget is therefore **not achievable for a live ISO** as written,
and the 3.8–4.0 GB total and the 2 GiB-per-file GitHub release cap are in
tension with it too (a live ISO cannot be a release asset; distribution is
artifacts with 7-day expiry, or Internet Archive for public release).
Do NOT re-budget here: measure the first live-ISO build (run #9), then the
owner re-decides the Part 1 budget — either raising it, or slimming the
core image hard first (the split design's slim-core work). Keep the 3-part
split for *content*; the numbers follow the measurement.

## The three parts

### Part 1 — STABILITY (required, standalone)

File: `vyra-os-0.1.0-core.iso` — the Titanoboa live ISO (replaces the
bootc-image-builder Anaconda installer ISO, retired 2026-11-26 — see
`docs/INSTALL_DEEP_DIVE_2026-11-26.md`). Boots to a live Plasma desktop
to try before installing; the installer runs from the desktop.

Contents (0.1): kernel, systemd, NetworkManager, PipeWire/WirePlumber, BlueZ,
SELinux enforcing, firewalld, cryptsetup/LUKS, Btrfs, bootc, Podman, Flatpak,
Plasma desktop (plasma-desktop, kwin, sddm, dolphin, konsole), Mesa + open GPU
firmware (AMD/Intel/NVIDIA firmware blobs — needed to boot on the Victus),
core fonts, fwupd, and the **Vyra Pack tool** (see below).

Guarantee: boots on the target hardware, installs, desktop + networking work,
updates and rolls back. Plain default look — full Vyra visuals are Part 3.

### Part 2 — PERFORMANCE (upgrade; the flagship pack)

File: `vyra-os-0.1.0-performance.vyrapack` — zstd tarball, applied post-install.

Contents (0.1): `tuned`, `tuned-ppd`, `zram-generator`, `irqbalance`,
CPU governor / I/O scheduler configs, kernel-tools.
Flagship additions (ArcaneOS-inspired, see below; land as they are built,
starting in the Arena phase): GameMode, MangoHud FPS overlay, Gamescope,
Vyra Game Space / Arena Hub (game launcher + per-game performance profiles),
and the proprietary NVIDIA driver (RPM Fusion; proprietary, so it stays
opt-in in this pack, never in core).

### Part 3 — AESTHETICS (upgrade)

File: `vyra-os-0.1.0-aesthetics.vyrapack` — zstd tarball, applied post-install.

Contents (0.1): `plasma-lookandfeel-fedora`, `f45-backgrounds-kde`,
`desktop-backgrounds-kde`, `breeze-icon-theme`, `breeze-gtk`,
`ocean-sound-theme`, extra fonts (Cantarell, Hack, Adobe mappings, URW base35,
Noto Serif/Emoji).
Flagship additions: the real Vyra art — custom 4K wallpapers, SDDM theme,
Plymouth boot theme, Bebas Neue / Antonio display fonts, golden-hour skybox
assets, and the Vyra customization hub (themes, accents, icon styles, sounds).

Note: for 0.1, Parts 2 and 3 are mostly the performance/aesthetics pieces that
are already installed in the monolithic 0.1.0-dev image, moved out of the core
image into packs. The core gets slimmer; the packs restore the full experience
and then grow with the flagship features above.

## Flagship inspiration: ArcaneOS

"ArcaneOS" names two different projects; Vyra takes high-level inspiration
from both, as design ideas only. Clean-room rule stands: no ArcaneOS code,
assets, or branding are copied.

**Flux ArcaneOS** (Ubuntu 24-based node OS, 2025): a hardened OS whose whole
point is proving what it is — Secure Boot under a controlled platform key,
TPM2-sealed LUKS disk, dm-verity verified root filesystem, a System
Attestation Service that validates OS integrity after install, automatic
updates and self-healing, and a live image installer with a graphical
interface and a cryptographic chain of trust. Independent audit found zero
critical vulnerabilities.
Vyra's take: **Vyra Verified Boot** — Secure Boot + TPM2-sealed LUKS +
measured boot with a visible integrity check in the welcome app; **self-healing**
via bootc rollback (a failed new deployment boots back to the last good one
automatically); **staged automatic updates** the user approves; encrypted
per-app storage for containers. This builds on what the Vyra directive already
requires (Secure Boot, TPM, LUKS2) and turns it into a headline feature.

**ArcaneOS Android ROM** (Pixel Experience-based, 2021–22): bloat-free and
fast by design, with a Game Mode and FPS overlay, deep UI customization
(redesigned panels, themed icons, color accents, wallpaper collection), a
dedicated customization app, and performance work aimed at lower CPU usage
and faster app launching.
Vyra's take: **Vyra Game Space** (launcher + performance mode + FPS overlay
+ per-game profiles) as the Arena headline; **bloat-free tuning** (lean
services in game mode, app-launch optimization); and the **Vyra customization
hub** (themes, accents, icons, wallpapers, sounds in one place).

## Pack format and the apply mechanism

Each `.vyrapack` is a tarball containing:

- `vyra-pack.json` — manifest: `{ id, version, requires, next: { url, sha256 } }`.
  `next` points at the following part, which is how the chain works.
- `payload/` — RPMs (or a local dnf repo dir) and config/theme files.
- `Containerfile.pack` — builds the derived image locally, e.g.
  `FROM localhost/vyra-os:0.1.0-core`, then installs the payload.

Apply flow (Vyra Pack tool, shipped in Part 1):

1. Download the pack (or use a locally downloaded file), verify SHA256 from the
   manifest. Refuse to apply on mismatch.
2. `podman build` the derived image from the local base image already on disk
   (no registry needed, no re-download of the base).
3. `bootc switch` to the derived image, reboot. Rollback available if it fails.
4. Read the pack manifest's `next` entry and offer to download the next part.

Why derived images and not a file-drop or `dnf install`: on a bootc system
`/usr` is read-only at runtime, so the supported upgrade path is a new image.
Part 3's manifest has no `next` — it is the end of the chain. A user can also
download any part manually from the release pages; the tool only automates the
sequence. Skipping Part 2 is supported: Part 3's Containerfile builds from
whichever base is present (core or performance).

## Walkthrough guide for new users

`docs/WALKTHROUGH.md` (draft in this repo; ships in Repo 2, linked from Repo 1):
what Vyra OS is, what you need, the three parts explained, download links,
checksum verification, making a bootable USB, booting and installing, first
boot, applying Part 2 then Part 3, and rollback/recovery if something fails.
Written for a first-time user; no unexplained jargon.

## Build pipeline changes (not yet done)

- `Containerfile` splits into a slim core plus pack definitions. The current
  monolithic 0.1.0-dev image stays as the "everything" reference build.
- New `scripts/build-packs.sh`: builds both pack tarballs + manifests + SHA256SUMS
  from the same source tree, enforces the per-part budgets.
- New `scripts/vyra-pack`: the on-system tool (download, verify, build, switch).
- `scripts/build-iso-fedora.sh` gains a pack step after the ISO build.
- The GitHub workflow's `iso-build` job gains release-upload steps for both
  repos (or releases are published manually from the Fedora host).
- Two repos to create: `vyra-os` and `vyra-os-packs` (owner creates them;
  distribution home — the build itself still runs on the Fedora host or CI).

## Verification criteria (before calling this done)

- Part 1 ISO boots in QEMU and installs; the installed system works with no
  other part present.
- Part 2 applies via the Pack tool, system still boots, `bootc rollback` works.
- Part 3 applies the same way.
- Measured sizes: each asset < 2 GiB, total compressed 3.8–4.0 GB,
  uncompressed total ~10 GB.
- SHA256 of every downloaded part matches the published sums.
- Walkthrough followed end-to-end by a first-time user with no help.

## Open points

- Exact ISO/pack sizes: unknown until the first build. Compression ratio
  ~2.5:1 is an assumption to confirm.
- Live ISO size (2026-11-26): measure at run #9 before re-budgeting Part 1
  (see the live-ISO tension note under "Size budget" above). `erofs`
  compression is worth testing for faster boot at similar size.
- NVIDIA driver: proprietary; stays an opt-in Part 2 item, never in core.
- Later versions may publish the derived images to GHCR instead of tarballs;
  the pack format stays the same, only the fetch step changes.
