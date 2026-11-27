# VYRA STORE — Preloaded App Catalogue

Version 1.0 — 2026-11-26. Built for Vyra OS (Fedora 45 bootc / KDE Plasma).

**120 apps across 10 categories** (12 per category). The **top 10 apps in each category are starred (★)** — they get a special star, a **trust certificate**, and **featured ratings/comments**. The other 2 apps per category get ratings and a comment section only. Ratings and comments are **placeholders** (shown as `—` below) to be filled by real Store data later; only the catalogue facts (name, source, install method, license) were verified.

## Repositories

The Store is backed by **10 repositories**. The 120 apps in this catalogue draw from 8 of them; the other 2 (Fedora Updates and RPM Fusion Nonfree) are enabled as part of the standard Fedora third-party set for updates and codecs.

| # | Repository | What it supplies here | Apps |
|---|---|---|---|
| 1 | **Flathub** | Flatpak desktop apps (the primary source) | 109 |
| 2 | **Fedora** | RPM system tools | 5 |
| 3 | **Fedora Updates** | Fedora package updates (enabled; no catalogue app is sourced here) | 0 |
| 4 | **RPM Fusion Free** | VirtualBox (akmod build) | 1 |
| 5 | **RPM Fusion Nonfree** | Enabled for codecs/drivers (no catalogue app is sourced here) | 0 |
| 6 | **Google Chrome repository** | Google Chrome (vendor RPM) | 1 |
| 7 | **Microsoft repository** | Microsoft Edge (vendor RPM) | 1 |
| 8 | **Vivaldi repository** | Vivaldi (vendor RPM) | 1 |
| 9 | **Opera repository** | Opera (vendor RPM) | 1 |
| 10 | **1Password repository** | 1Password (vendor RPM) | 1 |

Install methods used: **Flatpak (Flathub)** for desktop apps (preferred), **RPM (Fedora)** for system tools, **RPM (RPM Fusion Free)** for VirtualBox, and **RPM (vendor repository)** for the four big proprietary browsers and 1Password. Vendor repositories are the app maker's own signed RPM repo; the Store adds them only for that app.

## How duplicates were removed

One entry per app. Where the same app exists in more than one repository, it is listed **once** with the preferred source (Flathub Flatpak for desktop apps, Fedora RPM for system tools). Near-duplicates resolved:

- **Luanti / Minetest** — the same program, renamed in 2024. Listed once as "Luanti (formerly Minetest)".
- **GNOME Web / Epiphany** — the same program (Epiphany is the codename). Listed once as "GNOME Web (Epiphany)".
- **Element / Riot** — the same program, renamed (Riot → Element). Listed once as "Element"; its Flathub ID (`im.riot.Riot`) still carries the old name.
- **Google Chrome / Chromium** and **VS Code / VSCodium** — the same codebase, but distinct installable products (the proprietary build vs the open build). Both are listed, with the open build named as the alternative.
- **Errands / GNOME Endeavour** — the same task-app lineage. Only Errands is listed, to avoid two entries for one task manager.
- **Okular / Evince, GNOME Calculator / KCalc** — only one PDF viewer and one calculator are listed.

Apps considered but **not included** because they are not installable on Fedora / Flathub (with the alternative offered instead):

- **Microsoft Office** (no Linux version) → LibreOffice / ONLYOFFICE.
- **Netflix** (no Linux app) → Stremio / Kodi, or the browser.
- **Notion** (no Linux app) → Joplin / Logseq / Obsidian.
- **Figma** (no official Linux app; the community Flathub package `io.github.Figma_Linux.figma_linux` was archived in Dec 2024 and returns 404) → digiKam / Inkscape; Penpot (web) is the design-tool alternative.
- **Celestia** (no Flathub package) → KTouch (Education) was added in its place; Stellarium / KStars cover the astronomy slot.
- **HomeBank** (no Flathub package) → Money Manager Ex (MMEX).
- **Adobe Photoshop / Illustrator** (no Linux version) → GIMP / Krita / Inkscape.
- **Microsoft Teams** (no official Linux app) → Teams for Linux (unofficial client, listed).
- **WhatsApp** (no official Linux app) → ZapZap (unofficial client, listed).

Verification notes (2026-11-26): every Flathub ID was checked against the Flathub API (`/api/v2/appstream/<id>`) and returns a real app record. Fedora RPMs were checked against the Fedora package source API; KDE Partition Manager's Fedora package name is `kde-partitionmanager`, and VirtualBox is in **RPM Fusion Free** (not Nonfree). Vendor repositories re-verified 2026-11-26 (evening, fresh web check): Google Chrome — `https://dl.google.com/linux/chrome/rpm/stable/` (`google-chrome-stable`, also via Fedora's `fedora-workstation-repositories`); Microsoft Edge — `https://packages.microsoft.com/yumrepos/edge/config.repo` (`microsoft-edge-stable`; note Microsoft's own config.repo sets `gpgcheck=0`, so the Store should import Microsoft's key and enable checking rather than using that file unchanged); Vivaldi — `https://repo.vivaldi.com/stable/vivaldi-fedora.repo` (`vivaldi-stable`, baseurl `repo.vivaldi.com/archive/rpm/`); Opera — `https://rpm.opera.com/rpm` (`opera-stable`, key `https://rpm.opera.com/rpmrepo.key`); 1Password — `https://downloads.1password.com/linux/rpm/stable/` per 1Password's own support page (`dnf install 1password`). Scratch's Flathub package (`edu.mit.Scratch`) is an unverified community build on an older version (3.10.1); it is still installable. The Tor Browser entry installs via the Tor Browser Launcher, which downloads Tor Browser.

## Browsers (12 apps, 10 starred)

| # | App | Description | Source | Install | License | ★ | Open-source alternative | Rating |
|---|---|---|---|---|---|---|---|---|
| 1 | Firefox | Fast, private, open-source web browser from Mozilla. | Flathub | Flatpak (Flathub) | Open source (MPL-2.0) | ★ | — | — |
| 2 | Chromium | Open-source web browser that powers Google Chrome. | Flathub | Flatpak (Flathub) | Open source (BSD-3-Clause) | ★ | — | — |
| 3 | Brave | Privacy-first browser with built-in ad and tracker blocking. | Flathub | Flatpak (Flathub) | Open source (MPL-2.0) | ★ | — | — |
| 4 | Google Chrome | Google's fast, widely used web browser. | Google Chrome repository | RPM (Google Chrome repository) | Proprietary | ★ | Chromium | — |
| 5 | Microsoft Edge | Microsoft's Chromium-based web browser. | Microsoft repository | RPM (Microsoft repository) | Proprietary | ★ | Firefox | — |
| 6 | LibreWolf | Privacy-hardened Firefox fork with tracking protection built in. | Flathub | Flatpak (Flathub) | Open source (MPL-2.0) | ★ | — | — |
| 7 | Vivaldi | Highly customizable Chromium-based browser with built-in tools. | Vivaldi repository | RPM (Vivaldi repository) | Proprietary | ★ | Chromium | — |
| 8 | Opera | Fast browser with a built-in VPN, ad blocker, and sidebar apps. | Opera repository | RPM (Opera repository) | Proprietary | ★ | Firefox | — |
| 9 | Floorp | Customizable Firefox-based browser with workspaces and vertical tabs. | Flathub | Flatpak (Flathub) | Open source (MPL-2.0) | ★ | — | — |
| 10 | Tor Browser | Browse anonymously through the Tor network (launcher downloads Tor Browser). | Flathub | Flatpak (Flathub) | Open source (MPL-2.0) | ★ | — | — |
| 11 | GNOME Web (Epiphany) | Clean, simple GNOME web browser. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) |  | — | — |
| 12 | Falkon | Lightweight KDE web browser. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) |  | — | — |

Starred (★) apps in Browsers get the trust certificate and featured ratings/comments; the other 2 get ratings and a comment section only.

## Communication (12 apps, 10 starred)

| # | App | Description | Source | Install | License | ★ | Open-source alternative | Rating |
|---|---|---|---|---|---|---|---|---|
| 1 | Thunderbird | Free, open-source email, calendar, and chat client from Mozilla. | Flathub | Flatpak (Flathub) | Open source (MPL-2.0) | ★ | — | — |
| 2 | Discord | Voice, video, and text chat for communities and gaming. | Flathub | Flatpak (Flathub) | Proprietary | ★ | Element | — |
| 3 | Telegram | Fast, cloud-based messaging with channels and groups. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 4 | Signal | Private, end-to-end encrypted messaging. | Flathub | Flatpak (Flathub) | Open source (AGPL-3.0) | ★ | — | — |
| 5 | Element | Secure, decentralized chat built on the Matrix network. | Flathub | Flatpak (Flathub) | Open source (Apache-2.0) | ★ | — | — |
| 6 | Zoom | Video meetings, webinars, and screen sharing. | Flathub | Flatpak (Flathub) | Proprietary | ★ | Jitsi Meet | — |
| 7 | Slack | Team messaging and collaboration for work. | Flathub | Flatpak (Flathub) | Proprietary | ★ | Element | — |
| 8 | ZapZap (WhatsApp) | WhatsApp desktop client for Linux (unofficial). | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 9 | Jitsi Meet | Free, secure video conferencing with no account needed. | Flathub | Flatpak (Flathub) | Open source (Apache-2.0) | ★ | — | — |
| 10 | Teams for Linux | Unofficial Microsoft Teams desktop client. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 11 | Pidgin | Multi-protocol instant messaging client. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) |  | — | — |
| 12 | Dino | Modern, privacy-focused XMPP chat client. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) |  | — | — |

Starred (★) apps in Communication get the trust certificate and featured ratings/comments; the other 2 get ratings and a comment section only.

## Productivity & Office (12 apps, 10 starred)

| # | App | Description | Source | Install | License | ★ | Open-source alternative | Rating |
|---|---|---|---|---|---|---|---|---|
| 1 | LibreOffice | Full office suite: word processor, spreadsheet, and presentations. | Flathub | Flatpak (Flathub) | Open source (MPL-2.0) | ★ | — | — |
| 2 | ONLYOFFICE Desktop Editors | Office suite with strong Microsoft format compatibility. | Flathub | Flatpak (Flathub) | Open source (AGPL-3.0) | ★ | — | — |
| 3 | Obsidian | Markdown-based personal knowledge base and note-taking. | Flathub | Flatpak (Flathub) | Proprietary (free for personal use) | ★ | Joplin | — |
| 4 | Joplin | Open-source note-taking and to-do app with sync. | Flathub | Flatpak (Flathub) | Open source (AGPL-3.0) | ★ | — | — |
| 5 | Logseq | Privacy-first knowledge graph and outliner. | Flathub | Flatpak (Flathub) | Open source (AGPL-3.0) | ★ | — | — |
| 6 | Zotero | Collect, organize, and cite research sources. | Flathub | Flatpak (Flathub) | Open source (AGPL-3.0) | ★ | — | — |
| 7 | Todoist | Task planner and to-do list with projects and reminders. | Flathub | Flatpak (Flathub) | Proprietary | ★ | Errands | — |
| 8 | Errands | Simple, elegant task manager. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 9 | GNOME Calendar | Clean calendar to manage your schedule. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 10 | Okular | View and annotate PDFs and other documents. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 11 | Standard Notes | Simple, private, encrypted notes. | Flathub | Flatpak (Flathub) | Open source (AGPL-3.0) |  | — | — |
| 12 | Kontact | KDE's all-in-one email, calendar, and contacts suite. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) |  | — | — |

Starred (★) apps in Productivity & Office get the trust certificate and featured ratings/comments; the other 2 get ratings and a comment section only.

## Media & Entertainment (12 apps, 10 starred)

| # | App | Description | Source | Install | License | ★ | Open-source alternative | Rating |
|---|---|---|---|---|---|---|---|---|
| 1 | VLC | The open-source media player that plays almost anything. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 2 | Spotify | Stream millions of songs and podcasts. | Flathub | Flatpak (Flathub) | Proprietary | ★ | Spot | — |
| 3 | FreeTube | Watch YouTube privately, without tracking or ads. | Flathub | Flatpak (Flathub) | Open source (AGPL-3.0) | ★ | — | — |
| 4 | Stremio | One hub for movies, shows, and streaming add-ons. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 5 | Kodi | Open-source home theater and media center. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 6 | mpv | Minimal, powerful, open-source media player. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 7 | Audacious | Lightweight audio player for your music library. | Flathub | Flatpak (Flathub) | Open source (BSD-2-Clause) | ★ | — | — |
| 8 | Elisa | Elegant KDE music player with online radio. | Flathub | Flatpak (Flathub) | Open source (LGPL-3.0) | ★ | — | — |
| 9 | Lollypop | Modern GNOME music player and collection manager. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 10 | Rhythmbox | Classic GNOME music player and library organizer. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 11 | Haruna | Qt-based video player with YouTube support. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) |  | — | — |
| 12 | HandBrake | Open-source video transcoder for any format. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) |  | — | — |

Starred (★) apps in Media & Entertainment get the trust certificate and featured ratings/comments; the other 2 get ratings and a comment section only.

## Graphics & Design (12 apps, 10 starred)

| # | App | Description | Source | Install | License | ★ | Open-source alternative | Rating |
|---|---|---|---|---|---|---|---|---|
| 1 | GIMP | High-end image editing and manipulation. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 2 | Inkscape | Professional vector graphics editor. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 3 | Krita | Digital painting and illustration studio. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 4 | Blender | Free and open-source 3D creation suite. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 5 | darktable | Organize and develop RAW photos. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 6 | RawTherapee | Advanced RAW photo development. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 7 | Kdenlive | Open-source, full-featured video editor. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 8 | OBS Studio | Record and live-stream video. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 9 | digiKam | Photo management and editing for large collections. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 10 | Scribus | Open-source desktop publishing and page layout. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 11 | Pinta | Simple image editor and digital painting. | Flathub | Flatpak (Flathub) | Open source (MIT) |  | — | — |
| 12 | MyPaint | Painting program for digital artists. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) |  | — | — |

Starred (★) apps in Graphics & Design get the trust certificate and featured ratings/comments; the other 2 get ratings and a comment section only.

## Development (12 apps, 10 starred)

| # | App | Description | Source | Install | License | ★ | Open-source alternative | Rating |
|---|---|---|---|---|---|---|---|---|
| 1 | Visual Studio Code | Microsoft's popular code editor. | Flathub | Flatpak (Flathub) | Proprietary | ★ | VSCodium | — |
| 2 | VSCodium | VS Code without Microsoft telemetry. | Flathub | Flatpak (Flathub) | Open source (MIT) | ★ | — | — |
| 3 | PyCharm Community | Python IDE for professional development. | Flathub | Flatpak (Flathub) | Open source (Apache-2.0) | ★ | — | — |
| 4 | IntelliJ IDEA Community | Java and Kotlin IDE. | Flathub | Flatpak (Flathub) | Open source (Apache-2.0) | ★ | — | — |
| 5 | Android Studio | Official IDE for Android app development. | Flathub | Flatpak (Flathub) | Proprietary (free) | ★ | IntelliJ IDEA Community | — |
| 6 | Eclipse | Extensible IDE for Java and more. | Flathub | Flatpak (Flathub) | Open source (EPL-2.0) | ★ | — | — |
| 7 | Sublime Text | Fast, sophisticated text editor for code and prose. | Flathub | Flatpak (Flathub) | Proprietary | ★ | VSCodium | — |
| 8 | GitKraken | Visual Git client with repo management and issue tracking. | Flathub | Flatpak (Flathub) | Proprietary | ★ | Git Cola | — |
| 9 | Podman Desktop | Manage containers with Podman from a single UI. | Flathub | Flatpak (Flathub) | Open source (Apache-2.0) | ★ | — | — |
| 10 | Neovim | Modern Vim fork focused on extensibility. | Flathub | Flatpak (Flathub) | Open source (Apache-2.0) | ★ | — | — |
| 11 | Postman | API development and testing environment. | Flathub | Flatpak (Flathub) | Proprietary |  | Bruno | — |
| 12 | DBeaver Community | Free universal database tool. | Flathub | Flatpak (Flathub) | Open source (Apache-2.0) |  | — | — |

Starred (★) apps in Development get the trust certificate and featured ratings/comments; the other 2 get ratings and a comment section only.

## Games (12 apps, 10 starred)

| # | App | Description | Source | Install | License | ★ | Open-source alternative | Rating |
|---|---|---|---|---|---|---|---|---|
| 1 | Steam | The largest PC game store and launcher. | Flathub | Flatpak (Flathub) | Proprietary | ★ | Heroic Games Launcher | — |
| 2 | Heroic Games Launcher | Play Epic, GOG, and Amazon games on Linux. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 3 | Lutris | Open gaming platform for Linux. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 4 | RetroArch | Frontend for emulators and classic games. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 5 | Prism Launcher | Custom Minecraft launcher for mods and instances. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 6 | 0 A.D. | Free, open-source real-time strategy game. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 7 | SuperTuxKart | 3D open-source kart racing game. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 8 | OpenTTD | Open-source transport simulation game. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 9 | Luanti (formerly Minetest) | Open voxel sandbox and multiplayer game platform. | Flathub | Flatpak (Flathub) | Open source (LGPL-2.1) | ★ | — | — |
| 10 | GZDoom | Modern engine for classic Doom. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 11 | Endless Sky | Space exploration and combat game. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) |  | — | — |
| 12 | Battle for Wesnoth | Turn-based strategy game in a fantasy world. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) |  | — | — |

Starred (★) apps in Games get the trust certificate and featured ratings/comments; the other 2 get ratings and a comment section only.

## Utilities & System (12 apps, 10 starred)

| # | App | Description | Source | Install | License | ★ | Open-source alternative | Rating |
|---|---|---|---|---|---|---|---|---|
| 1 | GNOME Disks | Manage disks, partitions, and SMART health. | Fedora | RPM (Fedora) | Open source (GPL-2.0) | ★ | — | — |
| 2 | GParted | Graphical partition editor. | Fedora | RPM (Fedora) | Open source (GPL-2.0) | ★ | — | — |
| 3 | Timeshift | System snapshots and restore points. | Fedora | RPM (Fedora) | Open source (GPL-3.0) | ★ | — | — |
| 4 | KDE Partition Manager | Manage disks and partitions (KDE). | Fedora | RPM (Fedora) | Open source (GPL-3.0) | ★ | — | — |
| 5 | BleachBit | Free up space and protect privacy. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 6 | File Roller | Open, create, and modify compressed archives. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 7 | GNOME System Monitor | See processes and resource usage. | Fedora | RPM (Fedora) | Open source (GPL-2.0) | ★ | — | — |
| 8 | Mission Center | Modern system resource monitor. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 9 | Flatseal | Manage Flatpak app permissions. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 10 | VirtualBox | Run virtual machines on your desktop. | RPM Fusion Free | RPM (RPM Fusion Free) | Proprietary (free for personal use) | ★ | GNOME Boxes | — |
| 11 | Warehouse | Manage all your Flatpaks in one place. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) |  | — | — |
| 12 | Bottles | Run Windows software with Wine. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) |  | — | — |

Starred (★) apps in Utilities & System get the trust certificate and featured ratings/comments; the other 2 get ratings and a comment section only.

## Education & Science (12 apps, 10 starred)

| # | App | Description | Source | Install | License | ★ | Open-source alternative | Rating |
|---|---|---|---|---|---|---|---|---|
| 1 | Stellarium | Desktop planetarium: explore the night sky. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 2 | KStars | Desktop planetarium with astrophotography tools. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 3 | GeoGebra | Dynamic mathematics: geometry, algebra, and graphing. | Flathub | Flatpak (Flathub) | Proprietary (free for non-commercial use) | ★ | Kig | — |
| 4 | Anki | Powerful, intelligent flash cards for learning. | Flathub | Flatpak (Flathub) | Open source (AGPL-3.0) | ★ | — | — |
| 5 | Scratch | Create stories, games, and animations with blocks (community build). | Flathub | Flatpak (Flathub) | Open source (BSD-3-Clause) | ★ | — | — |
| 6 | Tux Paint | Drawing program for children. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 7 | GCompris | Educational games for children aged 2-10. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 8 | Marble | Virtual globe and world atlas. | Flathub | Flatpak (Flathub) | Open source (LGPL-2.1) | ★ | — | — |
| 9 | Kalzium | Periodic table of elements. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 10 | Cantor | Frontend for mathematical software. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 11 | GNU Octave | Scientific programming language for numerical computing. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) |  | — | — |
| 12 | KTouch | Touch typing tutor. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) |  | — | — |

Starred (★) apps in Education & Science get the trust certificate and featured ratings/comments; the other 2 get ratings and a comment section only.

## Finance & Organization (12 apps, 10 starred)

| # | App | Description | Source | Install | License | ★ | Open-source alternative | Rating |
|---|---|---|---|---|---|---|---|---|
| 1 | GnuCash | Manage finances, accounts, and investments. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 2 | KMyMoney | Personal finance with double-entry bookkeeping. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 3 | Skrooge | Personal finance manager for home use. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 4 | Denaro | Simple personal finance manager. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 5 | Money Manager Ex (MMEX) | Organize finances and track cash flow. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 6 | KeePassXC | Secure, offline password manager. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 7 | Bitwarden | Secure password manager that syncs everywhere. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 8 | 1Password | Password manager and secure vault. | 1Password repository | RPM (1Password repository) | Proprietary | ★ | KeePassXC | — |
| 9 | GNOME Contacts | Manage your contacts. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) | ★ | — | — |
| 10 | GNOME Calculator | Calculator for arithmetic, scientific, and financial math. | Flathub | Flatpak (Flathub) | Open source (GPL-3.0) | ★ | — | — |
| 11 | GNOME Clocks | World clocks, alarms, and timers. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) |  | — | — |
| 12 | GNOME Weather | Weather conditions and forecast. | Flathub | Flatpak (Flathub) | Open source (GPL-2.0) |  | — | — |

Starred (★) apps in Finance & Organization get the trust certificate and featured ratings/comments; the other 2 get ratings and a comment section only.
