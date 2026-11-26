# Vyra OS Visual Asset Pack — Batch 01

These assets are generated implementation-ready background artwork inspired by the supplied reference image and the uploaded Vyra Visual Asset Inventory.

## Included
- Desktop wallpaper master (3840×2160), 1920×1080 and 3440×1440 exports
- Light-theme wallpaper master (3840×2160)
- Lock-screen background (3840×2160)
- GRUB background (1920×1080)
- Plymouth splash (1920×1080) with text-only `Vyra` wordmark and tagline
- SDDM login background (3840×2160)
- Four installer slideshow backgrounds (1920×1080)
- Discover banner background (1920×400)
- Contact sheet

## Design constraints
- Palette: Obsidian #050505, Carbon #0F0F0F, Gold #DCAE43, Light Gold #FFE49A, Platinum #E0E0E0, Steel #888888.
- No invented VFM/Vyra logo. Plymouth uses a plain text wordmark only.
- Most backgrounds contain no baked-in UI or instructional text; implementers should render live UI, localization, login controls, and installer copy as native components.
- The artwork is a visual foundation, not a claim that any depicted OS feature is implemented.

## Muse implementation instructions
1. Copy the assets into the appropriate branding/theme directories in the existing Vyra OS repository.
2. Preserve original source files and create a separate asset branch/commit.
3. Do not modify bootloader, partitioning, signing, release, or installer logic as part of this visual asset import.
4. Wire GRUB/Plymouth/SDDM/Plasma/Anaconda assets only after checking the current repository structure and theme integration points.
5. Verify all exports at 16:9, ultrawide, and 4:3-safe crop. Do not stretch assets.
6. For Plymouth, keep progress dots/bar as a separate live-rendered layer; do not flatten progress into the background.
7. Treat the installer slides as backgrounds; overlay text in the installer UI for localization/accessibility.
8. Report exact file paths, integration points, visual QA screenshots, and any missing dependencies.

## Not included in this batch
- Plasma SVG theme package, icon theme, cursor theme, app icons, actual animated Plymouth frame sequence, MP4/WebM boot animation, Android/Linux mobile screenshots, and device mockup photography. These require separate implementation/artwork passes.
