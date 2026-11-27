#!/usr/bin/env python3
"""Build the VYRA STORE catalogue (JSON + Markdown) from one verified data set.

All Flathub IDs were verified against https://flathub.org/api/v2/appstream/<id>
on 2026-11-26 (105 verified in the first pass; the 7 misses were corrected:
Figma -> digiKam, Endless Sky -> underscore ID, Scratch -> edu.mit.Scratch,
Celestia -> KTouch, HomeBank -> MMEX, 1Password -> vendor RPM, plus the
KDE Partition Manager package name kde-partitionmanager and VirtualBox in
RPM Fusion Free). Fedora RPMs were verified via src.fedoraproject.org.
Ratings and comments are placeholders (null / empty) to be filled by real
Store data later; only catalogue facts are asserted here.
"""
import json, os

OUT = os.path.expanduser("~/workspace/vyra-os/vyra-design")

def app(name, desc, repo, method, app_id, lic, starred, alt=None, proprietary=False):
    return {
        "name": name,
        "description": desc,
        "source_repository": repo,
        "install_method": method,
        "app_id": app_id,
        "license": lic,
        "proprietary": proprietary,
        "open_source_alternative": alt,
        "starred": starred,
        "trust_certificate": starred,
        "rating": None,
        "rating_count": None,
        "featured_comments": [] if starred else None,
        "comments": [],
    }

F = "Flathub"
FLAT = "Flatpak (Flathub)"
OS = lambda lic: f"Open source ({lic})"

CATEGORIES = [
 ("Browsers", [
  app("Firefox", "Fast, private, open-source web browser from Mozilla.", F, FLAT, "org.mozilla.firefox", OS("MPL-2.0"), True),
  app("Chromium", "Open-source web browser that powers Google Chrome.", F, FLAT, "org.chromium.Chromium", OS("BSD-3-Clause"), True),
  app("Brave", "Privacy-first browser with built-in ad and tracker blocking.", F, FLAT, "com.brave.Browser", OS("MPL-2.0"), True),
  app("Google Chrome", "Google's fast, widely used web browser.", "Google Chrome repository", "RPM (Google Chrome repository)", "google-chrome-stable", "Proprietary", True, alt="Chromium", proprietary=True),
  app("Microsoft Edge", "Microsoft's Chromium-based web browser.", "Microsoft repository", "RPM (Microsoft repository)", "microsoft-edge-stable", "Proprietary", True, alt="Firefox", proprietary=True),
  app("LibreWolf", "Privacy-hardened Firefox fork with tracking protection built in.", F, FLAT, "io.gitlab.librewolf-community", OS("MPL-2.0"), True),
  app("Vivaldi", "Highly customizable Chromium-based browser with built-in tools.", "Vivaldi repository", "RPM (Vivaldi repository)", "vivaldi-stable", "Proprietary", True, alt="Chromium", proprietary=True),
  app("Opera", "Fast browser with a built-in VPN, ad blocker, and sidebar apps.", "Opera repository", "RPM (Opera repository)", "opera-stable", "Proprietary", True, alt="Firefox", proprietary=True),
  app("Floorp", "Customizable Firefox-based browser with workspaces and vertical tabs.", F, FLAT, "one.ablaze.floorp", OS("MPL-2.0"), True),
  app("Tor Browser", "Browse anonymously through the Tor network (launcher downloads Tor Browser).", F, FLAT, "org.torproject.torbrowser-launcher", OS("MPL-2.0"), True),
  app("GNOME Web (Epiphany)", "Clean, simple GNOME web browser.", F, FLAT, "org.gnome.Epiphany", OS("GPL-2.0"), False),
  app("Falkon", "Lightweight KDE web browser.", F, FLAT, "org.kde.falkon", OS("GPL-3.0"), False),
 ]),
 ("Communication", [
  app("Thunderbird", "Free, open-source email, calendar, and chat client from Mozilla.", F, FLAT, "org.mozilla.Thunderbird", OS("MPL-2.0"), True),
  app("Discord", "Voice, video, and text chat for communities and gaming.", F, FLAT, "com.discordapp.Discord", "Proprietary", True, alt="Element", proprietary=True),
  app("Telegram", "Fast, cloud-based messaging with channels and groups.", F, FLAT, "org.telegram.desktop", OS("GPL-3.0"), True),
  app("Signal", "Private, end-to-end encrypted messaging.", F, FLAT, "org.signal.Signal", OS("AGPL-3.0"), True),
  app("Element", "Secure, decentralized chat built on the Matrix network.", F, FLAT, "im.riot.Riot", OS("Apache-2.0"), True),
  app("Zoom", "Video meetings, webinars, and screen sharing.", F, FLAT, "us.zoom.Zoom", "Proprietary", True, alt="Jitsi Meet", proprietary=True),
  app("Slack", "Team messaging and collaboration for work.", F, FLAT, "com.slack.Slack", "Proprietary", True, alt="Element", proprietary=True),
  app("ZapZap (WhatsApp)", "WhatsApp desktop client for Linux (unofficial).", F, FLAT, "com.rtosta.zapzap", OS("GPL-3.0"), True),
  app("Jitsi Meet", "Free, secure video conferencing with no account needed.", F, FLAT, "org.jitsi.jitsi-meet", OS("Apache-2.0"), True),
  app("Teams for Linux", "Unofficial Microsoft Teams desktop client.", F, FLAT, "com.github.IsmaelMartinez.teams_for_linux", OS("GPL-3.0"), True),
  app("Pidgin", "Multi-protocol instant messaging client.", F, FLAT, "im.pidgin.Pidgin", OS("GPL-2.0"), False),
  app("Dino", "Modern, privacy-focused XMPP chat client.", F, FLAT, "im.dino.Dino", OS("GPL-3.0"), False),
 ]),
 ("Productivity & Office", [
  app("LibreOffice", "Full office suite: word processor, spreadsheet, and presentations.", F, FLAT, "org.libreoffice.LibreOffice", OS("MPL-2.0"), True),
  app("ONLYOFFICE Desktop Editors", "Office suite with strong Microsoft format compatibility.", F, FLAT, "org.onlyoffice.desktopeditors", OS("AGPL-3.0"), True),
  app("Obsidian", "Markdown-based personal knowledge base and note-taking.", F, FLAT, "md.obsidian.Obsidian", "Proprietary (free for personal use)", True, alt="Joplin", proprietary=True),
  app("Joplin", "Open-source note-taking and to-do app with sync.", F, FLAT, "net.cozic.joplin_desktop", OS("AGPL-3.0"), True),
  app("Logseq", "Privacy-first knowledge graph and outliner.", F, FLAT, "com.logseq.Logseq", OS("AGPL-3.0"), True),
  app("Zotero", "Collect, organize, and cite research sources.", F, FLAT, "org.zotero.Zotero", OS("AGPL-3.0"), True),
  app("Todoist", "Task planner and to-do list with projects and reminders.", F, FLAT, "com.todoist.Todoist", "Proprietary", True, alt="Errands", proprietary=True),
  app("Errands", "Simple, elegant task manager.", F, FLAT, "io.github.mrvladus.List", OS("GPL-3.0"), True),
  app("GNOME Calendar", "Clean calendar to manage your schedule.", F, FLAT, "org.gnome.Calendar", OS("GPL-3.0"), True),
  app("Okular", "View and annotate PDFs and other documents.", F, FLAT, "org.kde.okular", OS("GPL-2.0"), True),
  app("Standard Notes", "Simple, private, encrypted notes.", F, FLAT, "org.standardnotes.standardnotes", OS("AGPL-3.0"), False),
  app("Kontact", "KDE's all-in-one email, calendar, and contacts suite.", F, FLAT, "org.kde.kontact", OS("GPL-2.0"), False),
 ]),
 ("Media & Entertainment", [
  app("VLC", "The open-source media player that plays almost anything.", F, FLAT, "org.videolan.VLC", OS("GPL-2.0"), True),
  app("Spotify", "Stream millions of songs and podcasts.", F, FLAT, "com.spotify.Client", "Proprietary", True, alt="Spot", proprietary=True),
  app("FreeTube", "Watch YouTube privately, without tracking or ads.", F, FLAT, "io.freetubeapp.FreeTube", OS("AGPL-3.0"), True),
  app("Stremio", "One hub for movies, shows, and streaming add-ons.", F, FLAT, "com.stremio.Stremio", OS("GPL-2.0"), True),
  app("Kodi", "Open-source home theater and media center.", F, FLAT, "tv.kodi.Kodi", OS("GPL-2.0"), True),
  app("mpv", "Minimal, powerful, open-source media player.", F, FLAT, "io.mpv.Mpv", OS("GPL-2.0"), True),
  app("Audacious", "Lightweight audio player for your music library.", F, FLAT, "org.atheme.audacious", OS("BSD-2-Clause"), True),
  app("Elisa", "Elegant KDE music player with online radio.", F, FLAT, "org.kde.elisa", OS("LGPL-3.0"), True),
  app("Lollypop", "Modern GNOME music player and collection manager.", F, FLAT, "org.gnome.Lollypop", OS("GPL-3.0"), True),
  app("Rhythmbox", "Classic GNOME music player and library organizer.", F, FLAT, "org.gnome.Rhythmbox3", OS("GPL-2.0"), True),
  app("Haruna", "Qt-based video player with YouTube support.", F, FLAT, "org.kde.haruna", OS("GPL-3.0"), False),
  app("HandBrake", "Open-source video transcoder for any format.", F, FLAT, "fr.handbrake.ghb", OS("GPL-2.0"), False),
 ]),
 ("Graphics & Design", [
  app("GIMP", "High-end image editing and manipulation.", F, FLAT, "org.gimp.GIMP", OS("GPL-3.0"), True),
  app("Inkscape", "Professional vector graphics editor.", F, FLAT, "org.inkscape.Inkscape", OS("GPL-3.0"), True),
  app("Krita", "Digital painting and illustration studio.", F, FLAT, "org.kde.krita", OS("GPL-3.0"), True),
  app("Blender", "Free and open-source 3D creation suite.", F, FLAT, "org.blender.Blender", OS("GPL-3.0"), True),
  app("darktable", "Organize and develop RAW photos.", F, FLAT, "org.darktable.Darktable", OS("GPL-3.0"), True),
  app("RawTherapee", "Advanced RAW photo development.", F, FLAT, "com.rawtherapee.RawTherapee", OS("GPL-3.0"), True),
  app("Kdenlive", "Open-source, full-featured video editor.", F, FLAT, "org.kde.kdenlive", OS("GPL-3.0"), True),
  app("OBS Studio", "Record and live-stream video.", F, FLAT, "com.obsproject.Studio", OS("GPL-2.0"), True),
  app("digiKam", "Photo management and editing for large collections.", F, FLAT, "org.kde.digikam", OS("GPL-2.0"), True),
  app("Scribus", "Open-source desktop publishing and page layout.", F, FLAT, "net.scribus.Scribus", OS("GPL-2.0"), True),
  app("Pinta", "Simple image editor and digital painting.", F, FLAT, "com.github.PintaProject.Pinta", OS("MIT"), False),
  app("MyPaint", "Painting program for digital artists.", F, FLAT, "org.mypaint.MyPaint", OS("GPL-2.0"), False),
 ]),
 ("Development", [
  app("Visual Studio Code", "Microsoft's popular code editor.", F, FLAT, "com.visualstudio.code", "Proprietary", True, alt="VSCodium", proprietary=True),
  app("VSCodium", "VS Code without Microsoft telemetry.", F, FLAT, "com.vscodium.codium", OS("MIT"), True),
  app("PyCharm Community", "Python IDE for professional development.", F, FLAT, "com.jetbrains.PyCharm-Community", OS("Apache-2.0"), True),
  app("IntelliJ IDEA Community", "Java and Kotlin IDE.", F, FLAT, "com.jetbrains.IntelliJ-IDEA-Community", OS("Apache-2.0"), True),
  app("Android Studio", "Official IDE for Android app development.", F, FLAT, "com.google.AndroidStudio", "Proprietary (free)", True, alt="IntelliJ IDEA Community", proprietary=True),
  app("Eclipse", "Extensible IDE for Java and more.", F, FLAT, "org.eclipse.Java", OS("EPL-2.0"), True),
  app("Sublime Text", "Fast, sophisticated text editor for code and prose.", F, FLAT, "com.sublimetext.three", "Proprietary", True, alt="VSCodium", proprietary=True),
  app("GitKraken", "Visual Git client with repo management and issue tracking.", F, FLAT, "com.axosoft.GitKraken", "Proprietary", True, alt="Git Cola", proprietary=True),
  app("Podman Desktop", "Manage containers with Podman from a single UI.", F, FLAT, "io.podman_desktop.PodmanDesktop", OS("Apache-2.0"), True),
  app("Neovim", "Modern Vim fork focused on extensibility.", F, FLAT, "io.neovim.nvim", OS("Apache-2.0"), True),
  app("Postman", "API development and testing environment.", F, FLAT, "com.getpostman.Postman", "Proprietary", False, alt="Bruno", proprietary=True),
  app("DBeaver Community", "Free universal database tool.", F, FLAT, "io.dbeaver.DBeaverCommunity", OS("Apache-2.0"), False),
 ]),
 ("Games", [
  app("Steam", "The largest PC game store and launcher.", F, FLAT, "com.valvesoftware.Steam", "Proprietary", True, alt="Heroic Games Launcher", proprietary=True),
  app("Heroic Games Launcher", "Play Epic, GOG, and Amazon games on Linux.", F, FLAT, "com.heroicgameslauncher.hgl", OS("GPL-3.0"), True),
  app("Lutris", "Open gaming platform for Linux.", F, FLAT, "net.lutris.Lutris", OS("GPL-3.0"), True),
  app("RetroArch", "Frontend for emulators and classic games.", F, FLAT, "org.libretro.RetroArch", OS("GPL-3.0"), True),
  app("Prism Launcher", "Custom Minecraft launcher for mods and instances.", F, FLAT, "org.prismlauncher.PrismLauncher", OS("GPL-3.0"), True),
  app("0 A.D.", "Free, open-source real-time strategy game.", F, FLAT, "com.play0ad.zeroad", OS("GPL-2.0"), True),
  app("SuperTuxKart", "3D open-source kart racing game.", F, FLAT, "net.supertuxkart.SuperTuxKart", OS("GPL-3.0"), True),
  app("OpenTTD", "Open-source transport simulation game.", F, FLAT, "org.openttd.OpenTTD", OS("GPL-2.0"), True),
  app("Luanti (formerly Minetest)", "Open voxel sandbox and multiplayer game platform.", F, FLAT, "net.minetest.Minetest", OS("LGPL-2.1"), True),
  app("GZDoom", "Modern engine for classic Doom.", F, FLAT, "org.zdoom.GZDoom", OS("GPL-3.0"), True),
  app("Endless Sky", "Space exploration and combat game.", F, FLAT, "io.github.endless_sky.endless_sky", OS("GPL-3.0"), False),
  app("Battle for Wesnoth", "Turn-based strategy game in a fantasy world.", F, FLAT, "org.wesnoth.Wesnoth", OS("GPL-2.0"), False),
 ]),
 ("Utilities & System", [
  app("GNOME Disks", "Manage disks, partitions, and SMART health.", "Fedora", "RPM (Fedora)", "gnome-disk-utility", OS("GPL-2.0"), True),
  app("GParted", "Graphical partition editor.", "Fedora", "RPM (Fedora)", "gparted", OS("GPL-2.0"), True),
  app("Timeshift", "System snapshots and restore points.", "Fedora", "RPM (Fedora)", "timeshift", OS("GPL-3.0"), True),
  app("KDE Partition Manager", "Manage disks and partitions (KDE).", "Fedora", "RPM (Fedora)", "kde-partitionmanager", OS("GPL-3.0"), True),
  app("BleachBit", "Free up space and protect privacy.", F, FLAT, "org.bleachbit.BleachBit", OS("GPL-3.0"), True),
  app("File Roller", "Open, create, and modify compressed archives.", F, FLAT, "org.gnome.FileRoller", OS("GPL-2.0"), True),
  app("GNOME System Monitor", "See processes and resource usage.", "Fedora", "RPM (Fedora)", "gnome-system-monitor", OS("GPL-2.0"), True),
  app("Mission Center", "Modern system resource monitor.", F, FLAT, "io.missioncenter.MissionCenter", OS("GPL-3.0"), True),
  app("Flatseal", "Manage Flatpak app permissions.", F, FLAT, "com.github.tchx84.Flatseal", OS("GPL-3.0"), True),
  app("VirtualBox", "Run virtual machines on your desktop.", "RPM Fusion Free", "RPM (RPM Fusion Free)", "VirtualBox", "Proprietary (free for personal use)", True, alt="GNOME Boxes", proprietary=True),
  app("Warehouse", "Manage all your Flatpaks in one place.", F, FLAT, "io.github.flattool.Warehouse", OS("GPL-3.0"), False),
  app("Bottles", "Run Windows software with Wine.", F, FLAT, "com.usebottles.bottles", OS("GPL-3.0"), False),
 ]),
 ("Education & Science", [
  app("Stellarium", "Desktop planetarium: explore the night sky.", F, FLAT, "org.stellarium.Stellarium", OS("GPL-2.0"), True),
  app("KStars", "Desktop planetarium with astrophotography tools.", F, FLAT, "org.kde.kstars", OS("GPL-2.0"), True),
  app("GeoGebra", "Dynamic mathematics: geometry, algebra, and graphing.", F, FLAT, "org.geogebra.GeoGebra", "Proprietary (free for non-commercial use)", True, alt="Kig", proprietary=True),
  app("Anki", "Powerful, intelligent flash cards for learning.", F, FLAT, "net.ankiweb.Anki", OS("AGPL-3.0"), True),
  app("Scratch", "Create stories, games, and animations with blocks (community build).", F, FLAT, "edu.mit.Scratch", OS("BSD-3-Clause"), True),
  app("Tux Paint", "Drawing program for children.", F, FLAT, "org.tuxpaint.Tuxpaint", OS("GPL-2.0"), True),
  app("GCompris", "Educational games for children aged 2-10.", F, FLAT, "org.kde.gcompris", OS("GPL-3.0"), True),
  app("Marble", "Virtual globe and world atlas.", F, FLAT, "org.kde.marble", OS("LGPL-2.1"), True),
  app("Kalzium", "Periodic table of elements.", F, FLAT, "org.kde.kalzium", OS("GPL-2.0"), True),
  app("Cantor", "Frontend for mathematical software.", F, FLAT, "org.kde.cantor", OS("GPL-2.0"), True),
  app("GNU Octave", "Scientific programming language for numerical computing.", F, FLAT, "org.octave.Octave", OS("GPL-3.0"), False),
  app("KTouch", "Touch typing tutor.", F, FLAT, "org.kde.ktouch", OS("GPL-2.0"), False),
 ]),
 ("Finance & Organization", [
  app("GnuCash", "Manage finances, accounts, and investments.", F, FLAT, "org.gnucash.GnuCash", OS("GPL-3.0"), True),
  app("KMyMoney", "Personal finance with double-entry bookkeeping.", F, FLAT, "org.kde.kmymoney", OS("GPL-2.0"), True),
  app("Skrooge", "Personal finance manager for home use.", F, FLAT, "org.kde.skrooge", OS("GPL-2.0"), True),
  app("Denaro", "Simple personal finance manager.", F, FLAT, "org.nickvision.money", OS("GPL-3.0"), True),
  app("Money Manager Ex (MMEX)", "Organize finances and track cash flow.", F, FLAT, "org.moneymanagerex.MMEX", OS("GPL-2.0"), True),
  app("KeePassXC", "Secure, offline password manager.", F, FLAT, "org.keepassxc.KeePassXC", OS("GPL-3.0"), True),
  app("Bitwarden", "Secure password manager that syncs everywhere.", F, FLAT, "com.bitwarden.desktop", OS("GPL-3.0"), True),
  app("1Password", "Password manager and secure vault.", "1Password repository", "RPM (1Password repository)", "1password", "Proprietary", True, alt="KeePassXC", proprietary=True),
  app("GNOME Contacts", "Manage your contacts.", F, FLAT, "org.gnome.Contacts", OS("GPL-2.0"), True),
  app("GNOME Calculator", "Calculator for arithmetic, scientific, and financial math.", F, FLAT, "org.gnome.Calculator", OS("GPL-3.0"), True),
  app("GNOME Clocks", "World clocks, alarms, and timers.", F, FLAT, "org.gnome.clocks", OS("GPL-2.0"), False),
  app("GNOME Weather", "Weather conditions and forecast.", F, FLAT, "org.gnome.Weather", OS("GPL-2.0"), False),
 ]),
]

# ---- sanity checks ----
total = sum(len(apps) for _, apps in CATEGORIES)
starred = sum(1 for _, apps in CATEGORIES for a in apps if a["starred"])
names = [a["name"].lower() for _, apps in CATEGORIES for a in apps]
assert total == 120, f"total {total} != 120"
assert starred == 100, f"starred {starred} != 100"
assert len(names) == len(set(names)), "duplicate app names!"
for cat, apps in CATEGORIES:
    assert len(apps) == 12, f"{cat}: {len(apps)} apps"
    assert sum(1 for a in apps if a["starred"]) == 10, f"{cat}: starred != 10"

catalogue = {
    "catalogue": "VYRA STORE",
    "version": "1.0",
    "date": "2026-11-26",
    "description": "Preloaded app catalogue for Vyra OS. 120 apps across 10 categories. The top 10 apps in each category are starred: they get a special star, a trust certificate, and featured ratings/comments. All other apps get ratings and a comment section only. Ratings and comments are placeholders (null / empty) to be filled by real Store data later.",
    "total_apps": total,
    "starred_apps": starred,
    "categories": [
        {"name": cat, "app_count": len(apps), "starred_count": sum(1 for a in apps if a["starred"]), "apps": apps}
        for cat, apps in CATEGORIES
    ],
}

json_path = os.path.join(OUT, "vyra-store-catalogue.json")
with open(json_path, "w") as f:
    json.dump(catalogue, f, indent=2, ensure_ascii=False)
    f.write("\n")
print("wrote", json_path, f"({total} apps, {starred} starred)")

# ---- Markdown ----
lines = []
lines.append("# VYRA STORE — Preloaded App Catalogue")
lines.append("")
lines.append("Version 1.0 — 2026-11-26. Built for Vyra OS (Fedora 45 bootc / KDE Plasma).")
lines.append("")
lines.append("**120 apps across 10 categories** (12 per category). The **top 10 apps in each category are starred (★)** — they get a special star, a **trust certificate**, and **featured ratings/comments**. The other 2 apps per category get ratings and a comment section only. Ratings and comments are **placeholders** (shown as `—` below) to be filled by real Store data later; only the catalogue facts (name, source, install method, license) were verified.")
lines.append("")
lines.append("## Repositories")
lines.append("")
lines.append("The Store is backed by **10 repositories**. The 120 apps in this catalogue draw from 8 of them; the other 2 (Fedora Updates and RPM Fusion Nonfree) are enabled as part of the standard Fedora third-party set for updates and codecs.")
lines.append("")
lines.append("| # | Repository | What it supplies here | Apps |")
lines.append("|---|---|---|---|")
lines.append("| 1 | **Flathub** | Flatpak desktop apps (the primary source) | 109 |")
lines.append("| 2 | **Fedora** | RPM system tools | 5 |")
lines.append("| 3 | **Fedora Updates** | Fedora package updates (enabled; no catalogue app is sourced here) | 0 |")
lines.append("| 4 | **RPM Fusion Free** | VirtualBox (akmod build) | 1 |")
lines.append("| 5 | **RPM Fusion Nonfree** | Enabled for codecs/drivers (no catalogue app is sourced here) | 0 |")
lines.append("| 6 | **Google Chrome repository** | Google Chrome (vendor RPM) | 1 |")
lines.append("| 7 | **Microsoft repository** | Microsoft Edge (vendor RPM) | 1 |")
lines.append("| 8 | **Vivaldi repository** | Vivaldi (vendor RPM) | 1 |")
lines.append("| 9 | **Opera repository** | Opera (vendor RPM) | 1 |")
lines.append("| 10 | **1Password repository** | 1Password (vendor RPM) | 1 |")
lines.append("")
lines.append("Install methods used: **Flatpak (Flathub)** for desktop apps (preferred), **RPM (Fedora)** for system tools, **RPM (RPM Fusion Free)** for VirtualBox, and **RPM (vendor repository)** for the four big proprietary browsers and 1Password. Vendor repositories are the app maker's own signed RPM repo; the Store adds them only for that app.")
lines.append("")
lines.append("## How duplicates were removed")
lines.append("")
lines.append("One entry per app. Where the same app exists in more than one repository, it is listed **once** with the preferred source (Flathub Flatpak for desktop apps, Fedora RPM for system tools). Near-duplicates resolved:")
lines.append("")
lines.append("- **Luanti / Minetest** — the same program, renamed in 2024. Listed once as \"Luanti (formerly Minetest)\".")
lines.append("- **GNOME Web / Epiphany** — the same program (Epiphany is the codename). Listed once as \"GNOME Web (Epiphany)\".")
lines.append("- **Element / Riot** — the same program, renamed (Riot → Element). Listed once as \"Element\"; its Flathub ID (`im.riot.Riot`) still carries the old name.")
lines.append("- **Google Chrome / Chromium** and **VS Code / VSCodium** — the same codebase, but distinct installable products (the proprietary build vs the open build). Both are listed, with the open build named as the alternative.")
lines.append("- **Errands / GNOME Endeavour** — the same task-app lineage. Only Errands is listed, to avoid two entries for one task manager.")
lines.append("- **Okular / Evince, GNOME Calculator / KCalc** — only one PDF viewer and one calculator are listed.")
lines.append("")
lines.append("Apps considered but **not included** because they are not installable on Fedora / Flathub (with the alternative offered instead):")
lines.append("")
lines.append("- **Microsoft Office** (no Linux version) → LibreOffice / ONLYOFFICE.")
lines.append("- **Netflix** (no Linux app) → Stremio / Kodi, or the browser.")
lines.append("- **Notion** (no Linux app) → Joplin / Logseq / Obsidian.")
lines.append("- **Figma** (no official Linux app; the community Flathub package `io.github.Figma_Linux.figma_linux` was archived in Dec 2024 and returns 404) → digiKam / Inkscape; Penpot (web) is the design-tool alternative.")
lines.append("- **Celestia** (no Flathub package) → KTouch (Education) was added in its place; Stellarium / KStars cover the astronomy slot.")
lines.append("- **HomeBank** (no Flathub package) → Money Manager Ex (MMEX).")
lines.append("- **Adobe Photoshop / Illustrator** (no Linux version) → GIMP / Krita / Inkscape.")
lines.append("- **Microsoft Teams** (no official Linux app) → Teams for Linux (unofficial client, listed).")
lines.append("- **WhatsApp** (no official Linux app) → ZapZap (unofficial client, listed).")
lines.append("")
lines.append("Verification notes (2026-11-26): every Flathub ID was checked against the Flathub API (`/api/v2/appstream/<id>`) and returns a real app record. Fedora RPMs were checked against the Fedora package source API; KDE Partition Manager's Fedora package name is `kde-partitionmanager`, and VirtualBox is in **RPM Fusion Free** (not Nonfree). Scratch's Flathub package (`edu.mit.Scratch`) is an unverified community build on an older version (3.10.1); it is still installable. The Tor Browser entry installs via the Tor Browser Launcher, which downloads Tor Browser.")
lines.append("")
for cat, apps in CATEGORIES:
    lines.append(f"## {cat} ({len(apps)} apps, {sum(1 for a in apps if a['starred'])} starred)")
    lines.append("")
    lines.append("| # | App | Description | Source | Install | License | ★ | Open-source alternative | Rating |")
    lines.append("|---|---|---|---|---|---|---|---|---|")
    for i, a in enumerate(apps, 1):
        star = "★" if a["starred"] else ""
        alt = a["open_source_alternative"] or "—"
        lines.append(f"| {i} | {a['name']} | {a['description']} | {a['source_repository']} | {a['install_method']} | {a['license']} | {star} | {alt} | — |")
    lines.append("")
    lines.append(f"Starred (★) apps in {cat} get the trust certificate and featured ratings/comments; the other 2 get ratings and a comment section only.")
    lines.append("")

md_path = os.path.join(OUT, "vyra-store-catalogue.md")
with open(md_path, "w") as f:
    f.write("\n".join(lines))
print("wrote", md_path)
