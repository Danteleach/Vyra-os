# Vyra OS mood board — labelled reference set (2026-11-26)

Owner re-uploaded six images, labelled 0–5 for identification, with the
direction: **the system must be a 1:1 replica of the uploaded images, or as
close as possible. The mood board is how the OS should dynamically change
with device screen size and functionality.**

These six files are byte-identical (sha256-verified) to six of the seven
images in the 13:34 EST UI/UX set (`../ui-ux-set/`). The login screen
(`07_login_screen.png`) was NOT re-uploaded; it is still in `ui-ux-set/`.

## Label map (owner's labels 0–5)

| Label | File | Size | What it is |
|---|---|---|---|
| 0 | `00_hero_wallpaper.jpg` | 1376×768 | Hero wallpaper — gold V + "VYRA OS" on flowing gold lines (desktop wallpaper / lock art) |
| 1 | `01_boot_screen.jpg` | 1376×768 | Boot screen — gold ring + V + "VYRA OS" + progress line (Plymouth / boot animation target) |
| 2 | `02_vyra_store.jpg` | 1376×768 | VYRA STORE — app store: Featured "Vyra Creator Studio", Popular Apps, Recommended, My Downloads, Recently Updated, Quick Shortcuts |
| 3 | `03_installer_checklist.jpg` | 714×390 | Installer pre-installation checklist — System Requirements / Disk Space / Network / Digital Signature Passed, Integrity In Progress, Dependency / Boot Config Pending, 65% |
| 4 | `04_vyra_arena.jpg` | 1376×768 | VYRA ARENA — game launcher: Featured "Vanguard: Chronicles" PLAY NOW, My Library / Recent Games, Friends List, Party, Recent Achievements, System Status |
| 5 | `05_mood_board.png` | 1672×941 | Brand showcase poster / mood board — "ONE CORE. TWO WORLDS. EVERY DEVICE." + device matrix (Desktop, Mobile, Gaming, Cloud, VFM Link, VFM Flash) + panels for Desktop, Arena, Mobile, Tablet, VFM Link, VYRA Flash, Security First + brand elements (palette, Bebas Neue / Inter / JetBrains Mono) |

## The adaptive rule (from the mood board, label 5)

The OS shell must **dynamically change with device screen size and
functionality**. The mood board's device matrix is the spec:

- **Desktop** — full VYRA OS DESKTOP: work/create/innovate, full launcher + Store + Arena.
- **Mobile** — VYRA MOBILE: compact shell, "Connect. Go Further.", phone layout.
- **Tablet** — VYRA TABLET: "More. Anywhere.", tablet layout.
- **Gaming (handheld)** — VYRA ARENA: game launcher first, "Play. Compete. Enjoy."
- **Cloud** — cloud session view.
- **VFM Link** — "Sync. Share. Stay Connected." — device sync hub.
- **VFM Flash** — installer / USB flash flow ("Install with Confidence").

Same core, same gold/Obsidian language, layout and feature set adapt to
the device class. This is the "ONE CORE. TWO WORLDS. EVERY DEVICE." rule
made concrete.

## 1:1 replica target

Each labelled screen is the design target for the matching surface in the
real OS. See `ONE_TO_ONE_REPLICA_PLAN.md` for the per-screen mapping to
real implementation (what is already real, what needs a new app, and the
honest limits). The interactive design replica lives in the artifact
`vyra-os-ui-ux-design`.
