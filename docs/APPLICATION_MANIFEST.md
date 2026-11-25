# Vyra Application Manifest — Phase 1 (0.1.0-dev)

Format per Master Directive §8: application, version, licence, install method, storage impact, test status. Versions are resolved at build time from Fedora 45 repos; this manifest records intent + status, not a claim that every app is installed.

## Foundation (in Containerfile — to be verified by image inspect)

| Application | Install method | Status |
|---|---|---|
| KDE Plasma Desktop / Wayland | dnf5 in image | NOT YET BUILT — build pending (see Phase 1 report) |
| SDDM | dnf5 in image | NOT YET BUILT |
| Dolphin / Konsole | dnf5 in image | NOT YET BUILT |
| NetworkManager, PipeWire, BlueZ, firewalld | dnf5 in image | NOT YET BUILT |
| Flatpak, Podman, btrfs-progs, cryptsetup, fwupd | dnf5 in image | NOT YET BUILT |

## Later phases — NOT installed in 0.1, do not claim otherwise

- Office (LibreOffice, Firefox, Thunderbird, Okular): Phase 5 — NOT INSTALLED
- Creative (GIMP, Krita, Inkscape, Kdenlive, Audacity, OBS, Blender, Ardour): Phase 5 — NOT INSTALLED
- Gaming (Steam, Heroic, Lutris, Gamescope, MangoHud, ProtonUp-Qt, Bottles): Phases 4–5 — NOT INSTALLED
- VFM apps (Notes, Calendar, Files, Control, Update, Restore, Shield, Store, Play, Link, Sync, Studio): Phases 3–6 — NOT BUILT
- Arena: Phase 4 — NOT BUILT

## Profiles (§8)

Essential Office / Media / Utilities, Full Creator, Full Gaming, Developer, Advanced 3D — Phase 5. No profile is installable in 0.1. Estimated sizes must be shown before installing a profile; that UI does not exist yet.

## Licences

Fedora packages retain their upstream licences. Original VFM files in this repo are MIT (see LICENSE). No proprietary app, game, ROM, BIOS, or copyrighted media is included.
