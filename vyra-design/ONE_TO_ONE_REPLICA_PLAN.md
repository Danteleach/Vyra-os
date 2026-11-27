# Vyra OS — 1:1 replica plan (mood board, labels 0–5)

Owner direction 2026-11-26 ~21:00 EST: **the system must be a 1:1 replica
of the six labelled mood-board images, or as close as possible. The mood
board is how the OS dynamically changes with device screen size and
functionality.** Reference set: `vyra-design/mood-board/` (labels 0–5,
hash-verified against the 13:34 EST UI/UX set). Interactive replica:
artifact `vyra-os-ui-ux-design` (being updated to the 1:1 screens + the
adaptive device switcher).

This doc maps each labelled screen to its **real** implementation in the
OS. It separates what is already real from what needs a new app, and names
the honest limits. A mockup screen is a design target, not a claim the
feature exists.

## Label 0 — Hero wallpaper (00_hero_wallpaper.jpg)

- **Real today.** The wallpaper package is in the image (01/01b/01c dark,
  02 light). Run 23 showed the art on the desktop — but the LIGHT variant,
  because the session rendered light Breeze instead of BreezeDark.
- **To be 1:1:** fix the dark-scheme application (the BreezeDark /
  look-and-feel defect found in run 23). No new art needed.

## Label 1 — Boot screen, gold ring + V + progress line (01_boot_screen.jpg)

- **Target:** the "One line of gold" boot animation concept (inventory
  §1.6): gold ring draws, V resolves, tagline fades in. Deliverables: hero
  MP4/WebM, Plymouth PNG frame sequence (~120 frames), static fallback.
- **Real today (partial):** Plymouth two-step theme installed, `Theme=vyra`
  set, D1 wordmark logo present. **Run 23: the stock spinner showed, not
  the Vyra theme** — the live ISO's initramfs did not embed/use it.
- **To be 1:1:** fix the initramfs embedding (payload dracut regen must
  pick up the Vyra theme), then build the full frame-sequence animation.
  The still boot screen (label 1) is the first frame to land.

## Label 2 — VYRA STORE (02_vyra_store.jpg)

- **Does NOT exist as a real app.** What is real: `plasma-discover`
  (KDE's store) is installed, and a featured JSON is configured — but
  Discover cannot be skinned into this layout (Featured carousel, app
  cards, My Downloads panel, Quick Shortcuts).
- **To be 1:1:** build a Vyra Store app (Qt/QML) with the mockup's layout.
  It can read the same featured JSON and the system package/app data.
- **Preloaded catalogue (owner requirement, 2026-11-26 ~21:15 EST):** the
  Store ships preloaded with a **minimum of 100 of the top apps**, drawn
  from the **top 10 repositories or open-source alternatives**, so apps
  install instantly / quickly. **Duplicates are removed** across sources
  (one entry per app, preferred source noted). Apps are shown inside
  **custom OS windows designed for the Vyra system** (the Store's own
  windows, not a generic package-manager view). The **top 10 apps in EACH
  category** get a **special star**, a **trust certificate**, and
  **featured ratings and comments**. **All other apps get a ratings and
  comment section only** (no star, no trust certificate, no featured
  ratings/comments). Catalogue COMPLETE 2026-11-26 ~21:21 EST — see
  `workspace/vyra-os/vyra-design/vyra-store-catalogue.md` (and `.json` +
  `build_catalogue.py`): 120 apps, 10 categories × 12, 100 starred (top 10
  per category), 101 open source / 19 proprietary (each with a named
  open-source alternative), 10 repos (Flathub 109, Fedora RPM 5, RPM Fusion
  Free 1, vendor repos 4, Fedora Updates + RPM Fusion Nonfree 0).
  Ratings/comments are placeholders (null/empty), not fabricated. The
  Store screen in the replica is being updated to show this real
  catalogue (starred apps with star + trust certificate + featured
  ratings/comments; the rest with ratings + comment section only).
- **Honest limit:** the apps in the mockup (Vyra Core Studio, Voxel
  Editor, VFM Link, Aero Browser, Gold Wave, Codeforge, Sonic Studio,
  Soundcraft, Vigilant Security, Nova Player, and the featured "Vyra
  Creator Studio") are **concept titles — they do not exist**. The Store
  shell can be built 1:1; its catalogue is placeholder until real apps
  exist. "My Downloads 73%" is a concept state.

## Label 3 — Installer pre-installation checklist (03_installer_checklist.jpg)

- **Does NOT exist.** Anaconda (GTK `liveinst`) has no pre-installation
  checklist screen. The mockup is a custom pre-installer: System
  Requirements / Disk Space / Network / Digital Signature Passed,
  Integrity In Progress, Dependency / Boot Config Pending, 65%.
- **To be 1:1:** build a custom pre-flight app that runs before `liveinst`
  (checks system requirements, disk space, network, signature, file
  integrity, dependencies, boot config) and hands off to Anaconda. This
  is a new piece of installer UI, not a theme tweak.
- **Stage tracker (owner requirement, 2026-11-26 ~21:05 EST):** EVERY
  installation stage must be part of the GUI and easily trackable from
  stage to stage WITH A PERCENTAGE, so the user can follow the
  installation stage by stage with a percentage during the installation
  phase itself. (Owner correction: this is for the installation phase,
  not the testing phase — it is a permanent part of the installer
  experience, not a test aid.) The installer UI shows the full stage
  list, each stage with its own status (Pending / In Progress / Passed /
  Failed) and percentage, plus an overall progress percentage. Full stage
  list: (pre-install) 1 System Requirements Check, 2 Disk Space
  Verification, 3 Network Connectivity, 4 Digital Signature Verification,
  5 Integrity of Installation Files, 6 Dependency Resolution, 7 Boot
  Configuration Check; (install) 8 Partitioning & Formatting, 9 Installing
  Packages, 10 Configuring Bootloader, 11 Writing System Configuration,
  12 Finalizing & Cleanup, 13 Reboot / Complete. The pre-flight app tracks
  stages 1–7; the install tracker must also surface Anaconda's stages
  8–13 (it reads Anaconda's progress and mirrors it in the same list, so
  the user never loses sight of the install once `liveinst` takes over).
- **Honest limit:** Anaconda's own screens cannot be reshaped into this
  checklist; the checklist is a separate app in front of it. The 65% /
  "Verifying system integrity" states are concept until the checks are
  wired to real verifiers.

## Label 4 — VYRA ARENA (04_vyra_arena.jpg)

- **Does NOT exist as a real app.** The mockup is a game launcher:
  Featured "Vanguard: Chronicles" PLAY NOW, My Library / Recent Games,
  Friends List (Online: 12), Party, Recent Achievements, System Status.
- **To be 1:1:** build a Vyra Arena app (Qt/QML) with the mockup's layout.
  Library can list installed games; the rest needs content and services.
- **Honest limit:** the games shown (Vanguard: Chronicles, Cyber Arena,
  Shadow of the Eclipse, Wasteland Legends, Skyward) are **concept titles
  — they do not exist**. Friends / Party / Achievements are online
  features needing a backend; the launcher shell can be built 1:1, but
  friends, party, and achievements are placeholder until a service exists.

## Label 5 — Mood board / adaptive device rule (05_mood_board.png)

- **The rule:** one core, layout and feature set adapt to device class.
  Desktop = full VYRA OS DESKTOP. Mobile = VYRA MOBILE compact shell.
  Tablet = VYRA TABLET. Handheld = VYRA ARENA first. Cloud = cloud
  session view. VFM Link = device sync hub. VFM Flash = USB installer flow.
- **Real today:** the brand tokens, the slogan, and the device list are
  in the design system. The adaptive behaviour is NOT implemented.
- **To be 1:1:** the Vyra apps (Store, Arena, desktop shell) must be
  built responsive — layouts that reflow by screen size and device class
  (the mood board's matrix is the spec). KDE Plasma desktop does not
  natively do phone/tablet/handheld adaptive shells; the Vyra apps carry
  the responsive layouts themselves. VFM Link (sync) and VFM Flash (USB
  installer) are separate features to build.
- **Honest limit:** "ONE CORE. TWO WORLDS. EVERY DEVICE." is the goal,
  not the current state. The 0.1 base is desktop x86-64 only; mobile /
  tablet / handheld are design targets until a build for those form
  factors exists.

## Login screen (07, not re-uploaded — still in the set)

- **Real today (partial):** SDDM forked to the `vyra` theme with the D2
  background; run 23 test-mode showed it legible. Gap: no "Vyra OS"
  wordmark on the greeter, stock avatar. The 07 mockup's card layout is
  the target for the greeter's brand plate.

## Order of work

1. Interactive 1:1 replica in the design artifact (in progress) — locks
   the look on every screen + device class before real code is written.
2. Fix the two run 23 defects that block the replica on the real desktop:
   Plymouth theme in the initramfs (label 1) and the dark scheme /
   look-and-feel (label 0).
3. Build the Vyra Store and Vyra Arena apps (labels 2 and 4) as Qt/QML
   with responsive layouts (label 5), catalogue/library as placeholder
   until real apps and games exist.
4. Build the installer pre-flight checklist app (label 3) in front of
   Anaconda.
5. VFM Link and VFM Flash (label 5) as their own features.
