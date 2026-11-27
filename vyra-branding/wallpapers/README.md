# Vyra OS Wallpaper Set — 5 designs, dark + light, 4 sizes

Built 2026-11-26. Clean art, no baked-in text (consistent with the Batch 01
pack). Brand tokens: Obsidian #050505, Gold #DCAE43, Light Gold #FFE49A,
Platinum #E0E0E0.

## The 5 designs

| Design | Dark | Light | Notes |
|---|---|---|---|
| **Flow** | gold ribbons + gold dust on Obsidian | gold ribbons on warm off-white | AI master |
| **Summit** | mountain ridge, gold sun, gold mist, stars | pale ridges, gold sun | AI master |
| **Prism** | faceted gold crystals on a dark floor | gold crystals on warm off-white | AI master |
| **Orbit** | gold orbital arcs + particles around a gold glow | gold core + faint arcs on warm off-white | AI master |
| **Ring** | concentric gold rings + faceted gold V | same on warm off-white | drawn in PIL (vector-style, like the logo) |

## Modes

- **Dark** — Obsidian background, gold art. The default desktop look.
- **Light** — warm off-white background (#F3EFE6), gold preserved.
  - Flow / Summit / Prism / Orbit light modes are PIL recolors of the dark
    masters (inverted-luminance remap: bright gold kept and slightly
    deepened; dark background and mid-tone structure remapped to a light
    field so forms stay visible). Ring light is drawn directly in PIL.
  - Honest note: Orbit's light mode is the softest of the five — its
    central glow reads as a warm gold-brown core rather than a bright glow.
    Summit's light mode is pale and sparse by design.

## Sizes (per design, per mode)

| Folder | Size | How made |
|---|---|---|
| `masters/` | 2048x1152 | source masters |
| `3840x2160/` | 3840x2160 (4K) | LANCZOS upscale + light unsharp |
| `1920x1080/` | 1920x1080 (FHD) | LANCZOS downscale |
| `3440x1440/` | 3440x1440 (ultrawide 21:9) | centre-crop to 21:9, then upscale |
| `1080x1920/` | 1080x1920 (portrait / mobile) | centre-crop to 9:16, then upscale |

50 files total: 10 masters + 40 derivatives (~90 MB).

## Honest limits

- Masters are 2048x1152, so the 3840x2160 files are **upscales**, not
  native 4K. They are clean (LANCZOS + unsharp) but a native 4K render
  would be sharper. The 1920x1080 files are native-resolution downscales.
- Ultrawide and portrait are **centre crops** — the edges of the wide
  compositions are trimmed (most noticeable on Summit and Prism).
- These are wallpaper art only. They are not yet wired into the OS
  wallpaper package (that is the Batch 01 Phase A mechanism); wiring the
  new set in is a separate step.

## Files

- `build_wallpaper_set.py` — the builder (masters, Ring drawing, light
  recolor, size derivatives). Re-run it to regenerate; it skips files
  that already exist.
- The original AI generation files (media-generation-*.png + .json
  sidecars) are kept in this folder alongside the clean-named masters.
