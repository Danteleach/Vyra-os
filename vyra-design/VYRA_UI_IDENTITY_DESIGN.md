# Vyra OS UI identity — design note (Phase A4)

Owner direction 2026-11-26 (five changes, one cohesive update):
1. Vyra logo in the installation interface and as the desktop home/start
   button (like the Windows Start button).
2. The new Vyra OS black wallpaper as the default.
3. Fedora logos replaced with the Vyra logo.
4. A floating dock with glassmorphism (macOS / elementary OS style).
5. HarmonyOS elegance retained throughout.

## HarmonyOS elegance — how it is applied here

HarmonyOS's design language is clean, minimal, refined: soft curves,
generous spacing, a single harmonious surface, restrained accent colour,
nothing shouting. That is the filter every choice below passed through.

- **One dock, not three islands.** macOS and elementary OS use a single
  centered dock; HarmonyOS uses a single clean bottom bar. Vyra uses
  ONE floating dock (not the win12kde three-island split). Everything
  the user needs — home button, apps, tray, clock — lives in that one
  harmonious element. No second bar, no extra panel, no clutter.
- **Generous spacing.** The dock is 60px tall (roomy, not cramped),
  icons are 48px with breathing room, icon spacing is relaxed. The
  dock is only as wide as its content (`lengthMode=fit`), so it reads
  as a deliberate object floating on the wallpaper, not a bar that
  spans the screen.
- **Soft curves.** The floating panel + Breeze dark theme draw a
  translucent rounded rectangle. No sharp corners, no hard edges.
  The gold V is itself a soft, geometric mark — no harsh angles.
- **Restrained gold.** Gold (#DCAE43) appears in exactly two places:
  the Vyra V logo and the wallpaper's flowing lines. It is an accent,
  not a theme. Panels, windows, and text stay Obsidian / Carbon /
  Platinum. Nothing else is gold.
- **Only the essentials are pinned.** Dolphin, Firefox, Konsole,
  Discover. Four apps. The Store (Discover) is pinned because the
  owner wants the VYRA STORE prominent, but the dock does not try to
  be an app launcher grid — the Kickoff menu is for that.
- **Quiet status area.** The clock shows time with the date below it,
  24-hour, short date. No seconds, no extra widgets, no weather island.
  The tray icons are scaled to the dock height so they read as one row.
- **Black wallpaper as the default.** The Obsidian hero with gold
  flowing lines is the calm, dark canvas the glass dock floats on.
  The dock's frosted translucency only reads as glass against a dark,
  rich wallpaper — which is why the black default matters, not just
  for branding but for the glass effect itself.

## The five changes, concretely

| # | Change | Implementation |
|---|---|---|
| 1 | Logo as home/start button + in installer | Kickoff `icon=vyra` (layout.js); installer `.logo` = V mark (vyra.css + configure_iso.sh); `liveinst.desktop` Icon=vyra. |
| 2 | Black wallpaper default | Look-and-feel defaults set `ColorScheme=BreezeDark` (correct key — see below) so the Vyra package picks `images_dark/` (black hero); layout.js also pins the desktop wallpaper to the black hero file. |
| 3 | Fedora logos replaced | Vyra icon installed as `vyra`, `fedora-logo-icon`, `org.fedoraproject.AnacondaInstaller`, `start-here`, `anaconda` (hicolor); Fedora SVG/PNG files removed or overwritten; pixmaps logos overwritten. |
| 4 | Floating glass dock | Single centered bottom panel, `floating=true`, `lengthMode=fit`, `opacity=translucent`, height 60. KWin blur frosts it. |
| 5 | HarmonyOS elegance | The principles above; see the layout.js and this note. |

## The dark-scheme root cause (found while doing this work)

Runs 23/24 rendered a LIGHT desktop + light wallpaper even though
Phase A2 "set BreezeDark". The cause: Phase A2 set `--key Name
BreezeDark`, but `Name` is not the colour-scheme key. The key Plasma
reads is **`ColorScheme`** under `[General]` in kdeglobals — verified
against the shipped Breeze Dark look-and-feel defaults in
plasma-workspace 6.8.1 (`[kdeglobals][General] ColorScheme=BreezeDark`).
Phase A2 is corrected in place, and the look-and-feel defaults file now
carries the same BreezeDark sections, so applying org.vyra.desktop also
keeps the session dark. This is the fix for the run-23/24 defect (2).

## What the boot test must confirm (not claimed yet)

- The dock actually renders floating, centered, translucent/frosted
  (KWin blur on). If it renders solid, blur is the first suspect.
- The layout.js runs at first login (fresh live session). If the stock
  full-width panel appears instead, the layout did not run and a
  default `plasma-org.kde.plasma.desktop-appletsrc` fallback is needed.
- The Kickoff button shows the gold V (not a missing-icon placeholder).
- The desktop is dark (BreezeDark) with the black hero wallpaper.
- The Welcome Center shows the Vyra V (not the Fedora "f" or nothing).
- The "Install Vyra OS" desktop icon shows the Vyra V.
- No Fedora "f" remains visible anywhere in the UI.

## Conflicts with Batch 01 wiring (resolved)

- **vyra.css `.logo`**: Batch 01 pointed it at the D1 wordmark
  (`vyra-logo.png`). Phase A4 repoints it at the V mark
  (`vyra-mark.png`). The D1 wordmark is NOT deleted — it stays as the
  Plymouth boot logo and is still copied into the installer pixmaps
  as a brand asset. No Batch 01 file was removed, only the CSS
  pointer changed.
- **Phase A2 `Name` key**: corrected in place to `ColorScheme` (see
  above). This is a bug fix to an existing RUN, not new work; the new
  work lives in Phase A4.
- **Wallpaper package**: the Vyra package still has both `images/`
  (light 02) and `images_dark/` (black 01). Nothing about the package
  changed. The black default comes from the (now correct) dark colour
  scheme + the layout.js explicit path, not from deleting the light
  variant — the light wallpaper remains a user choice.
- **liveinst.desktop**: configure_iso.sh already sed-ed the Name;
  Phase A4 adds an Icon sed in the same place. No conflict.
