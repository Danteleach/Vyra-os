# Vyra OS — Visual Asset Pack, Batch 01

**Source:** `Vyra_OS_Visual_Asset_Pack_Batch_01_2_uvip.zip`
(sha256 `1588bec938b20846006d40c517636a29b8494bfc4af20b1cccd1d4e1ab4910a1`,
3,959,862 bytes, 15 files, integrity verified 2026-11-26).
Original ZIP preserved at `workspace/user/files/`; working copy at
`workspace/vyra-os/batch-01-staging/`. Do not delete the originals.

**Branch:** `visual-assets-batch-01` (local working branch).
**Directive:** Batch 01 Visual Asset Implementation Directive, 2026-11-26
(Boot, Login, Desktop and Installer branding — upgrade, not rebuild).
**Reference:** `../Vyra-VISUAL-ASSET-INVENTORY.md` (~45 assets) and the
supplied Vyra brand board (`workspace/user/files/1212_1_ciyq.png`).

## Asset map

| File | Size | Inventory | Phase | Integration point (target) |
|---|---|---|---|---|
| `01_desktop_wallpaper_master_3840x2160.png` | 3840×2160 | 3.1 default wallpaper | A | `/usr/share/wallpapers/Vyra/` + Plasma default (mechanism TBD — see below) |
| `01b_desktop_wallpaper_1920x1080.png` | 1920×1080 | 3.1 | A | same, 1080p export |
| `01c_desktop_wallpaper_ultrawide_3440x1440.png` | 3440×1440 | 3.1 | A | same, ultrawide export |
| `02_light_wallpaper_master_3840x2160.png` | 3840×2160 | 3.2 light wallpaper | A | same, light-theme variant |
| `03_lock_screen_background_3840x2160.png` | 3840×2160 | 3.3 lock screen | A | screen-locker background (kscreenlockerrc) |
| `04_grub_background_1920x1080.png` | 1920×1080 | 1.1 GRUB background | B | GRUB menu background — Titanoboa `iso.yaml` has no background field; mechanism TBD (research Titanoboa `build_iso.sh`) |
| `05_plymouth_splash_1920x1080.png` | 1920×1080 | 1.4/1.5 Plymouth splash + wordmark | B | Plymouth theme `/usr/share/plymouth/themes/vyra/` + default-theme set + dracut regen (must run before the initramfs build in `iso_files/configure_iso.sh`; progress dots stay a separate live layer) |
| `06_sddm_login_background_3840x2160.png` | 3840×2160 | 2.1 SDDM background | C | **FLAGGED — see below** |
| `07_installer_slide_desktop_1920x1080.png` | 1920×1080 | 4.5 installer slideshow | D | Installer background — Anaconda GTK has no slideshow; integration point TBD (research: sidebar/banner vs progress-screen art) |
| `08_installer_slide_gaming_1920x1080.png` | 1920×1080 | 4.5 | D | same |
| `09_installer_slide_customization_1920x1080.png` | 1920×1080 | 4.5 | D | same |
| `10_installer_slide_culture_1920x1080.png` | 1920×1080 | 4.5 | D | same |
| `11_discover_banner_1920x400.png` | 1920×400 | 6.3 Discover banner | E | Discover front-page banner — mechanism TBD (Discover featured art comes from AppStream, not a local file; research) |
| `00_contact_sheet.jpg` | 1280×2340 | — | — | Reference only, not shipped in the image |
| `README_MUSE_HANDOFF.md` | — | — | — | Pack notes, preserved as supplied |

## Flags (do not wire blindly)

- **06 SDDM has baked-in UI text.** The image contains a centred rounded
  card with "Vyra OS" and "Welcome back" baked in. Used as a plain SDDM
  background, the native SDDM controls (username, password field, clock)
  would render on top of that text and duplicate it. Do not use 06 as the
  SDDM background as-is. Recommended: use the clean art (01 wallpaper or
  03 lock screen) for SDDM and keep 06 as a design mockup, or build an
  SDDM theme whose controls sit inside the baked card (fragile across
  resolutions — needs owner sign-off). Awaiting decision.
- **05 Plymouth is clean.** "Vyra" wordmark + gold underline + tagline
  "Built to Move Culture Forward", centred, clear space below for live
  progress dots. Matches inventory 1.4–1.6.
- **07–10 slides are near-identical backgrounds.** They differ only
  subtly; the slide distinction lives in the overlaid installer text,
  which must be rendered natively, not baked in.
- **Not in this batch** (per pack README): Plasma SVG theme, icon theme,
  cursor theme, app icons, animated Plymouth frame sequence, MP4/WebM boot
  animation, mobile screenshots, device mockups. Separate passes.

## Push constraint

The GitHub connector's snapshot push handles UTF-8 text files only — no
binary contents, no branch creation through it. The 13 PNGs in this
directory cannot be pushed with `push-files`. Upload route for the images
(browser web-UI upload to `Danteleach/Vyra-os`, owner upload, or a
separate assets repo — owner authorised up to 4 repos) is still to decide.
Text files (Containerfile, theme configs, `vyra.conf`, `configure_iso.sh`,
docs) go through snapshot-push as usual; workflow files go through the
web UI by the owner.

## Verification done so far

- ZIP integrity: `unzip -t` — no errors. All 13 PNG dimensions match
  their filenames (`file` output). Contact sheet + Plymouth + SDDM
  inspected at full size.
- Nothing is integrated yet. No asset is claimed as integrated until it
  is tested in the actual system (directive §5).
