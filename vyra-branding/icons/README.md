# Vyra icons — gold V mark

Source: the draft Vyra logo mark, `~/workspace/vyra-os/vyra-logo/vyra-logo-mark-1024.png`
(gold faceted V on Obsidian #050505, 1024x1024). The owner directed this mark
to be used in the OS UI (home/start button, installer, icon replacements)
2026-11-26. It is the ONLY logo used — no new logo was invented.

## Transparency (important)

The source mark is **RGB with a solid Obsidian background — it has no
transparency**, despite the task note saying it did. `build_icons.py`
derives transparency from luminance (ramp: luminance <= 10 transparent,
>= 110 opaque, linear between — the same technique as the Batch 01 D1
wordmark crop). The bright gold V is fully opaque, the anti-aliased edges
stay smooth, and the faint gold ring/lines stay subtle instead of
becoming a black box. Verified by compositing on Obsidian and on light
grey: the V reads cleanly on both, at 512px and at 48px.

## Files

- `vyra-logo-mark-1024-transparent.png` — transparent master (1024x1024 RGBA).
- `vyra-<size>.png` — the V mark at 16, 22, 24, 32, 36, 48, 64, 96, 128,
  256, 512 (LANCZOS downscale from the transparent master).
- `build_icons.py` — regenerates everything from the source mark.

## How they are installed (Containerfile Phase A4)

The `vyra-<size>.png` set is installed into the hicolor icon theme at
`/usr/share/icons/hicolor/<size>x<size>/apps/` under these names:

| Icon name | Where it shows |
|---|---|
| `vyra` | The Vyra logo itself; the Kickoff home/start button (layout.js sets the Kickoff `icon` to `vyra`) and the installer icon (`liveinst.desktop` Icon=vyra). |
| `fedora-logo-icon` | The Welcome Center icon (fedora-welcome uses `iconName: 'fedora-logo-icon'`). Fedora ships this name as 0-byte placeholder files — the Vyra PNGs replace them so the logo actually renders. |
| `org.fedoraproject.AnacondaInstaller` | The Anaconda installer icon (the blue Fedora "f" seen in the Welcome Center Install button and the desktop "Install Vyra OS" icon). Replaces the Fedora SVG + symbolic SVG. |
| `start-here` | The Application Launcher button fallback icon (Fedora's `start-here.svg` in hicolor/scalable). The fixed-size Vyra PNGs override it; the Fedora scalable SVG is removed. |
| `anaconda` | The Anaconda app icon (256x256 `anaconda.png`). |

The pixmaps Fedora logos (`/usr/share/pixmaps/fedora-logo.png`,
`fedora-logo-small.png`, `/usr/share/anaconda/pixmaps/sidebar-logo.png`)
are also overwritten with the Vyra mark (512px transparent).

After installing, the icon cache is refreshed (best effort) so the new
icons resolve immediately.
