# Vyra OS — Visual Asset Inventory

**Purpose:** every visual surface the live ISO and installed system need so Vyra OS stops
looking like Fedora and reads as Vyra everywhere — boot, login, desktop, installer, apps.

**Source of truth for style:** Master Directive §12 and `vyra-branding/Vyra-BRANDING.md`.
Palette: Obsidian `#050505`, Carbon `#0F0F0F`, Gold `#DCAE43`, Light Gold `#FFE49A`,
Platinum `#E0E0E0`, Steel `#888888`. Display: Bebas Neue / Antonio. UI: Inter /
Host Grotesk. Mono: JetBrains Mono. Tagline: "Built to Move Culture Forward".
Slogan: "ONE CORE. TWO WORLDS. EVERY DEVICE." **Do not invent a logo** — text
wordmark `Vyra` / `Vyra OS` only, until official VFM logo assets are supplied.

**Status key:** `MISSING` = Fedora default currently showing. `TOKENS` = only the
colour/font tokens exist (in `vyra-branding/`), nothing applies them yet.
`EXISTS` = already in the build.

---

## 1. Boot sequence

| # | Asset | Where it shows | Spec | Status |
|---|-------|----------------|------|--------|
| 1.1 | GRUB background | Boot menu behind "Try Vyra OS" / "Install Vyra OS" | 1920×1080 PNG/JPG, dark Obsidian, subtle gold accent, no text baked in (GRUB draws the menu) | MISSING |
| 1.2 | GRUB theme styling | Menu font, highlight bar, countdown text | GRUB theme: Inter or JetBrains Mono, gold highlight `#DCAE43`, Platinum text | MISSING |
| 1.3 | GRUB entry text | The two menu entries | "Try Vyra OS", "Install Vyra OS" (already set in `installer/iso.yaml`) | EXISTS |
| 1.4 | Plymouth splash background | Boot splash after GRUB | 1920×1080 PNG, Obsidian, centred composition, safe for 4:3 and ultrawide | MISSING |
| 1.5 | Plymouth wordmark | Centred on the splash | Text wordmark "Vyra" in Bebas Neue/Antonio, Platinum, gold underline accent | MISSING |
| 1.6 | Plymouth progress | Spinner / progress dots under the wordmark | Animated dots or thin gold progress bar, 30 fps frame sequence | MISSING |
| 1.7 | LUKS passphrase prompt | Disk-unlock screen (Plymouth) | Same splash background; prompt text: "Enter passphrase to unlock Vyra OS", input field in Carbon with gold focus ring | MISSING |
| 1.8 | Boot animation | The boot-up motion piece (see §7) | 1920×1080, ~4 s, 30 fps, MP4/WebM + Plymouth frame sequence + static fallback frame | MISSING |

## 2. Login — SDDM

| # | Asset | Where it shows | Spec | Status |
|---|-------|----------------|------|--------|
| 2.1 | SDDM background | Login screen | 1920×1080 (also 3840×2160), Obsidian/Carbon gradient with gold accent; distinct from the desktop wallpaper so login reads as its own moment | MISSING |
| 2.2 | SDDM wordmark | Top/centre of login | "Vyra OS" text wordmark, Bebas Neue/Antonio | MISSING |
| 2.3 | User avatar placeholder | Next to the username | Default avatar: gold ring on Carbon, "V" monogram (text, not a logo) | MISSING |
| 2.4 | Clock and date | Login screen | Inter, Platinum; format set by locale | MISSING |
| 2.5 | Login button + session selector | Bottom of login | Gold primary button, Carbon field; session list ("Plasma (Wayland)") in Inter | MISSING |
| 2.6 | Power buttons | Shutdown / restart / suspend | Minimal icons, Steel, gold on hover | MISSING |
| 2.7 | Login copy | Greeting + error text | Greeting: "Welcome back" (or username only). Error: "Incorrect password, try again." | MISSING |

## 3. Desktop — Plasma

### 3a. Wallpaper and lock screen

| # | Asset | Where it shows | Spec | Status |
|---|-------|----------------|------|--------|
| 3.1 | Default wallpaper | Desktop background | 3840×2160 master, plus 1920×1080 and 3440×1440 ultrawide exports; Obsidian/Carbon with gold light work, cinematic, minimal — the Vyra hero image | MISSING |
| 3.2 | Light variant wallpaper | Desktop (light theme users) | Same composition re-lit in Platinum/Light Gold | MISSING |
| 3.3 | Lock screen background | Screen lock | 1920×1080, darker/blurred version of the wallpaper so the clock stays legible | MISSING |

### 3b. Plasma theme, panels, menus

| # | Asset | Where it shows | Spec | Status |
|---|-------|----------------|------|--------|
| 3.4 | Plasma theme (shell) | Panels, widgets, popups | Dark theme: Carbon panels `#0F0F0F`, Platinum text, gold accents on active items; rounded corners, subtle shadow | MISSING |
| 3.5 | Taskbar / panel | Bottom panel | Carbon, translucent; launcher icon, pinned apps, system tray, clock | MISSING |
| 3.6 | Application Launcher | Start menu | Vyra-styled menu: search field on top, favourites, categories; gold highlight on hover/selection | MISSING |
| 3.7 | System tray + clock | Panel right side | Network, volume, battery, notifications icons; clock in Inter, Platinum | MISSING |
| 3.8 | Widget styling | Desktop widgets (clock, notes, etc.) | Carbon cards, gold accent lines, Inter text | MISSING |
| 3.9 | Window decorations | Title bars | Dark title bar, Platinum title text, min/max/close buttons (gold close on hover), thin border, soft shadow | MISSING |
| 3.10 | KWin effects | Window open/close, workspace switch | Subtle fade/scale only — fast, no heavy blur | MISSING |

### 3c. Icons

| # | Asset | Where it shows | Spec | Status |
|---|-------|----------------|------|--------|
| 3.11 | Icon theme (base) | Everywhere | SVG, Breeze-derived custom set re-coloured to the Vyra palette (gold folders, Carbon panels); sizes 16/22/32/48/64/128/256 | MISSING |
| 3.12 | App icons | Launcher, taskbar, Discover | Dolphin, Konsole, Firefox, Settings, Discover, Kate, and every preinstalled app — consistent stroke/colour treatment | MISSING |
| 3.13 | Folder + file icons | Dolphin, desktop | Gold-tinted folders; distinct icons for documents, images, video, audio, archives | MISSING |
| 3.14 | Status + action icons | Toolbars, dialogs, tray | Network, volume, battery, Bluetooth, notifications; save/open/close/search icons in one visual language | MISSING |
| 3.15 | Mimetype icons | File manager | One icon per common type (text, image, video, audio, PDF, archive) | MISSING |

### 3d. Cursors, controls, fonts

| # | Asset | Where it shows | Spec | Status |
|---|-------|----------------|------|--------|
| 3.16 | Cursor theme | Pointer, text, resize, wait, hand | Dark cursor with gold accent on the pointer; standard hotspots | MISSING |
| 3.17 | Buttons | Dialogs, Settings, installer | Primary: gold fill, Obsidian text. Secondary: Carbon fill, Platinum text, Steel border. Disabled: Steel at 40% | MISSING |
| 3.18 | Toggles, sliders, checkboxes, radios | Settings, dialogs | Gold "on" state, Carbon track, Platinum labels | MISSING |
| 3.19 | Progress bars + scrollbars | Installs, downloads, lists | Thin gold progress fill on Carbon track; slim scrollbar, gold thumb on hover | MISSING |
| 3.20 | Fonts (installed + defaults) | Everywhere | Bebas Neue + Antonio (display), Inter + Host Grotesk (UI), JetBrains Mono (terminal/code) — shipped in the image, set as Plasma defaults | MISSING |
| 3.21 | Notifications + OSD | Toast banners, volume/brightness overlays | Carbon card, gold left-edge accent, app icon, Inter text; OSD: centred pill, gold fill level | MISSING |

## 4. Installer — Anaconda

| # | Asset | Where it shows | Spec | Status |
|---|-------|----------------|------|--------|
| 4.1 | Product name | Installer title bar, every screen | "Vyra OS" (Anaconda `productName` in `iso_files/vyra.conf`) | MISSING |
| 4.2 | Welcome Center copy | First screen after "Install to Hard Drive" | Headline + body, see §5 copy list; replaces "Welcome to Fedora Linux!" | MISSING |
| 4.3 | Install icon | Desktop icon + Welcome Center button | Vyra install glyph: gold "V" monogram or download arrow in the Vyra style (text/monogram only) | MISSING |
| 4.4 | Installer sidebar/banner | Left edge of installer windows | Vertical gold-on-Obsidian band with "Vyra OS" wordmark | MISSING |
| 4.5 | Install slideshow (3–5 slides) | Shown while packages install | 1920×1080 images + one-line copy each: (1) the desktop, (2) Game Space, (3) customisation, (4) "Built to Move Culture Forward" | MISSING |
| 4.6 | Completion screen copy | Install finished | "Vyra OS is installed. Restart to start using it." + restart button | MISSING |

## 5. Identity text — copy to be filled in

These are strings, not images. **Status 2026-11-26 (commit 9d4dc1c0): most are now
implemented** — the system identity (NAME/PRETTY_NAME/ID), the live hostname,
and the installer label are Vyra; the Welcome Center headline/button/body
follow automatically from os-release NAME (verified against the
`fedora-welcome` source). Still pending: HOME_URL/BUG_REPORT_URL (needs the
owner's VFM/Vyra support URL — do not invent one), and the tagline/slogan
placements (no config surface; the UI/UX design defines the About screen).

| # | String | Where it shows | Current text | Vyra text (to decide) |
|---|--------|----------------|--------------|----------------------|
| 5.1 | `NAME` / `PRETTY_NAME` | `/etc/os-release`, Settings → About, `hostnamectl` | Fedora Linux / Fedora Linux 45 | Vyra OS / Vyra OS 0.1 — DONE (Containerfile Phase D) |
| 5.2 | `ID` / `ID_LIKE` | os-release, tooling | `fedora` | `vyra` / `ID_LIKE=fedora` — DONE (Containerfile Phase D + vyra.conf os_id=vyra). NOTE: fedora-release owns os-release; a future dnf update could overwrite it — durable fix is a vyra-release package. |
| 5.3 | `HOME_URL` / `BUG_REPORT_URL` | About, crash dialogs | fedoraproject.org | VFM / Vyra support URL — PENDING, owner to supply (do not invent). |
| 5.4 | Welcome Center headline | Desktop first-run window | "Welcome to Fedora Linux!" | "Welcome to Vyra OS!" — DONE automatically (fedora-welcome reads os-release NAME). |
| 5.5 | Welcome Center body | Same window | "Pressing the icon below will begin installing Fedora Linux…" | "…installing Vyra OS…" — DONE automatically (same source). |
| 5.6 | Installer button | Welcome Center + desktop icon | "Install to Hard Drive" | "Install Vyra OS" — DONE (configure_iso.sh renames liveinst.desktop; the Welcome Center button is "Install Vyra OS…" automatically from NAME). |
| 5.7 | Live user / hostname | Login prompt, terminal | `liveuser` / `localhost-live` | Keep `liveuser`, hostname `vyra-live` — DONE (configure_iso.sh patches livesys-main; livesys sets the hostname at boot). |
| 5.8 | Boot log name | `dmesg`, journal | Fedora Linux 45 | Vyra OS — DONE (follows from 5.1). |
| 5.9 | Tagline placement | About screen, Welcome Center footer | — | "Built to Move Culture Forward" — PENDING (no config surface; UI/UX design defines the About screen). |
| 5.10 | Slogan placement | About screen, installer completion | — | "ONE CORE. TWO WORLDS. EVERY DEVICE." — PENDING (same as 5.9). |
| 5.11 | GRUB timeout text | Boot menu countdown | "The highlighted entry will be executed automatically in Ns" | Keep (generic). |

## 6. App defaults

| # | Asset | Where it shows | Spec | Status |
|---|-------|----------------|------|--------|
| 6.1 | Firefox start page | New tab / first launch | Vyra start page (dark, wordmark, search, links to VFM) or plain dark blank tab — decide | MISSING |
| 6.2 | Dolphin + Konsole theme | File manager, terminal | Dark theme, JetBrains Mono in Konsole, gold prompt accent | MISSING |
| 6.3 | Discover banner | App store front page | Vyra banner art, 1920×400, gold on Obsidian | MISSING |
| 6.4 | Default apps list | Launcher favourites | Decide the pinned set (Dolphin, Konsole, Firefox, Settings, Discover, + Vyra apps later) | MISSING |

## 7. Boot animation — concept + deliverables

**Concept: "One line of gold."** Simple, short, impressive — no spinning logos, no
particle storms.

Storyboard (~4 seconds, 30 fps, 1920×1080, Obsidian background throughout):
1. **0.0–1.2 s** — a single thin gold line draws itself across the centre of the
   screen, left to right, and resolves into the text wordmark **"Vyra"** (Bebas
   Neue, Platinum, with the gold line settling as an underline).
2. **1.2–2.2 s** — a thin gold ring expands once from behind the wordmark and
   fades, like a ripple. The wordmark stays.
3. **2.2–3.2 s** — the tagline **"Built to Move Culture Forward"** fades in
   below in Inter, Steel→Platinum.
4. **3.2–4.0 s** — hold on the finished frame; Plymouth progress dots fade in
   underneath; cut to the login/desktop.

**Deliverables:**
| # | Asset | Spec | Status |
|---|-------|------|--------|
| 7.1 | Animation video (hero) | 1920×1080 MP4 + WebM, ~4 s, 30 fps — for the website, trailer, and sharing | MISSING |
| 7.2 | Plymouth frame sequence | Same animation as numbered PNG frames (120 frames) for the boot splash | MISSING |
| 7.3 | Static fallback frame | Last frame as a still (1920×1080 PNG) — used when animation can't play (GRUB, slow hardware) | MISSING |
| 7.4 | Loop version | 4 s seamless loop for demo/showreel use | MISSING |

## 8. What needs no new art (copy only)

- Language, keyboard, timezone, and user-creation screens — text only, Vyra
  product name flows in from §4.1/§5.1.
- Error dialogs (wrong password, no network, install failure) — copy only,
  styled by the theme in §3d.
- Help / About dialogs inside apps — copy only.

---

## Build order (recommended)

1. **Identity text (§5)** — cheapest, biggest effect: the system stops saying
   "Fedora" everywhere in one change set.
2. **Wallpaper + SDDM + Plymouth stills (§1.4–1.5, §2.1, §3.1)** — the three
   images a user actually sees first.
3. **Boot animation (§7)** — the motion piece; built from the same wordmark art.
4. **Plasma theme + icons + controls (§3b–3d)** — the full desktop skin.
5. **Installer (§4)** — product name, Welcome copy, slideshow.
6. **App defaults (§6)** — start page, banners, pinned apps.

- **Dark colour scheme (interim, inventory §3.4)**: BreezeDark set as the system default via kwriteconfig6 (kf6-kconfig) in the Containerfile (Phase A2), so the desktop reads dark/Carbon instead of light Breeze until the full Vyra Plasma theme lands.
- **Welcome Center Fedora logo icon + installer icon**: the welcome window's icon (`fedora-logo-icon`) and the installer icon (`org.fedoraproject.AnacondaInstaller`) are still Fedora's — they need Vyra icon art (inventory 4.3). The welcome text itself is Vyra automatically (it reads os-release NAME).

## Count

- ~45 assets total: 8 boot, 7 login, 21 desktop (3 wallpaper/lock + 7 theme/panels
  + 5 icons + 6 cursors/controls/fonts/notifications), 6 installer, 11 copy
  strings, 4 app defaults, 4 animation deliverables.
- Identity text (§5) is now mostly implemented (2026-11-26, commit 9d4dc1c0);
  wallpaper/SDDM/Plymouth are wired in Batch 01. The rest (Plasma theme,
  icons, cursors, fonts, boot animation, installer slideshow, app defaults)
  is still Fedora-default and needs design/art.
