# Vyra OS — Batch 01 Visual Assets: Wiring Plan

**Status:** RESEARCH + PLAN ONLY. Nothing in this plan has been implemented.
No build file was modified while writing it. No build was started. No push was made.

**Branch:** `visual-assets-batch-01` (local + GitHub; from `main` `3f81989d`).
Assets are in `vyra-branding/batch-01/` (13 PNGs + pack README, uploaded via
browser, commit `9cf6369`; mapping README via snapshot-push, commit `103c35c0`).
Original ZIP preserved at `workspace/user/files/`.

**Directive:** Batch 01 Visual Asset Implementation Directive, 2026-11-26
(Boot, Login, Desktop, Installer branding — upgrade, not rebuild).
**Reference:** `../Vyra-VISUAL-ASSET-INVENTORY.md` (~45 assets),
`vyra-branding/batch-01/README.md` (asset map + flags),
`workspace/user/files/1212_1_ciyq.png` (brand board).

**Owner instruction folded in (2026-11-26 11:10 EST):** anything not yet
designed gets a visually stunning design cohesive to the asset pack, and only
HD derivatives are allowed — 1920×1080 minimum, no stretching, no invented
logo, text wordmark only. Every derivative this plan recommends is marked
**PROPOSED** (to be generated and reviewed). No derivative is presented as an
existing file.

## How to read this plan

- **EXISTING** — a file that is already in `vyra-branding/batch-01/`.
- **PROPOSED** — a file that does not exist yet and must be generated
  (an HD derivative of pack art, or a small config/CSS file written at
  implementation time). Never treat a PROPOSED file as already on disk.
- **TBD / UNVERIFIED** — a mechanism or fact this research could not confirm
  from a real source. The plan says so plainly instead of asserting it.
- **BLOCKED** — cannot be wired with the current pipeline at all (§1 GRUB).
- Every mechanism below names its source. Where the source is the project's
  own files, the path is given. Where it is upstream, the document and the
  exact finding are cited in §14 Sources.

## Ground rules (apply to every surface)

1. **Two images, two layers.** The *core* image (`Containerfile`) is the
   installed OS. The *payload* image (`installer/Containerfile.live` +
   `iso_files/configure_iso.sh`) is the live session + installer. Anything
   the installed desktop needs goes in the core image; anything only the
   live session / installer needs goes in the payload. A file placed only
   in the payload never reaches an installed system.
2. **`/usr/share/vyra/branding/` is the source of truth.** The core
   Containerfile already COPYs `vyra-branding/` there. Wired assets are
   COPIED from that tree into their canonical runtime homes at build time;
   the `batch-01/` directory itself is never a runtime path. Originals are
   never edited, moved, or deleted.
3. **No invented logo.** Text wordmark only (`Vyra` / `Vyra OS`). Raster
   derivatives that carry the wordmark are crops of supplied art, not new
   logos. (Separate deferred owner task, 2026-11-26 11:17 EST: a cohesive
   Vyra logo for the GitHub profile picture, *after* Batch 01 — it is not
   part of this plan and must not be used as an OS asset until the owner
   approves it for that purpose.)
4. **Fonts are a known gap, not a Batch 01 deliverable.** Bebas Neue /
   Antonio / Inter / Host Grotesk / JetBrains Mono are NOT installed in the
   image (inventory 3.20 MISSING) and no font files were supplied in the
   pack. Any text rendered natively by the system (SDDM clock/labels,
   installer copy, Plasma UI) will use Fedora's fallback fonts until a font
   pass ships them. Raster derivatives (PNG crops) are unaffected — their
   typography is baked into the image. Do not claim a surface "uses Bebas
   Neue" until the fonts are installed.
5. **Live session ≠ installed system for login.** `livesys` sets SDDM
   autologin for the live session, so the SDDM screen is bypassed on the
   live ISO and only appears on an installed system (or on logout). The
   lock screen (kscreenlocker) is a different surface from SDDM and *does*
   appear in the live session.
6. **Nothing is "integrated" until it is seen in the actual system**
   (directive §5). File presence in the image is not a pass.

## Build-order map (what changes where)

| Step | Layer / file | Surfaces |
|---|---|---|
| 1 | Core `Containerfile` (+ files under `vyra-branding/`) | Wallpaper package, look-and-feel package, `kdeglobals` + `kscreenlockerrc` defaults, Plymouth theme + default, SDDM theme fork + selection, os-release NAME override, `plasma-discover` package (Phase E, decision — §6) |
| 2 | Payload `iso_files/configure_iso.sh` (after `dnf install anaconda-live`) | Anaconda pixmaps + custom CSS (§5) |
| 3 | Payload `iso_files/vyra.conf` (`[User Interface]`) | Anaconda `custom_stylesheet` (§5) |
| 4 | No change | `.github/workflows/build.yml` (Titanoboa inputs are only `image-ref` + `iso-dest`; nothing new is needed), `installer/iso.yaml` (GRUB entries already correct), bootloader / partitioning / signing (untouched) |
| 5 | Blocked, no change possible in-pipeline | GRUB background (§1) |

Order inside the payload matters for exactly one thing: the Plymouth theme
and its default must exist **before** the `dracut` regen in
`configure_iso.sh` (§2). Everything else is order-independent.

---

## §1 — GRUB background — BLOCKED, cannot be wired in this pipeline

**Asset:** `04_grub_background_1920x1080.png` (EXISTING, inventory 1.1).
**Verdict: there is no mechanism.** A GRUB background cannot be put into a
Titanoboa-built ISO from the image, from `iso.yaml`, or from any file the
image provides.

**Mechanism verified from the real source.** Titanoboa at the pinned commit
(`ublue-os/titanoboa@5c457c3d0518bd17e754be0fd98a60d29d26abb4`, the pin in
`.github/workflows/build.yml`) builds the ISO with `build_iso.sh` (95 lines,
fetched from the repo at that SHA via the GitHub connector). The script:

- reads only two keys from `/usr/lib/bootc-image-builder/iso.yaml`
  (`label`, `grub2.timeout` / `grub2.default` / `grub2.entries[]`);
- copies only the kernel, the initramfs, the GRUB modules
  (`/usr/lib/grub/i386-pc`, `arm64-efi`) and the EFI directory into the ISO;
- generates `grub.cfg` as fixed text:

```
set timeout=<from iso.yaml>
set default="<from iso.yaml>"
set menu_auto_hide=false
function load_video { insmod all_video; }
load_video
set gfxpayload=keep
insmod gzio
insmod part_gpt
insmod chain
search --no-floppy --set=root -l '<label>'
menuentry '<name>' { linux <line>; initrd <line>; }
```

There is no `background_image`, no `insmod png`/`jpeg`, no theme, no font
and no colour directive anywhere in the script, and no step that copies any
other file from the image into the ISO's `/boot/grub2`. The FOSDEM
container-native ISO contract talk (O. Budai, "Building ISOs from OCI
containers") confirms the same boundary: `iso.yaml` supports exactly `label`
and `grub2` (default / timeout / entries with name+linux+initrd) — nothing
else. The generated menu therefore renders as text on a black background,
exactly as the 2026-11-26 boot test photographed it.

**What that means for 04.** The file stays in the pack as supplied art. It
cannot be the GRUB background. Its art is still usable as *source* for HD
derivatives elsewhere (Plymouth logo crop §2, SDDM derivative §3), because
the derivative rule allows HD derivatives of pack art.

**Options (owner decision — no default taken):**

- **(a) Defer — recommended.** Ship Batch 01 with a text GRUB menu. The
  menu is on screen for 10 seconds; everything after it is branded. Zero
  pipeline risk.
- **(b) Fork Titanoboa.** Add background support to `build_iso.sh`: copy a
  splash image into the ISO, emit `insmod png`, `background_image
  /boot/grub2/vyra-splash.png` (and optionally a `grub2-theme` + font) in
  the generated `grub.cfg`, and pin the workflow at the fork. Cost: the
  project then owns a fork of its ISO builder (upstream fixes must be
  rebased by hand); the change is small (~10 lines + the image) but it is
  a build-tool fork, not a branding tweak. Needs an explicit owner call.
- **(c) Post-process the finished ISO** (unpack, rewrite `grub.cfg`,
  re-pack). Not recommended: it breaks the reproducible CI pipeline and
  the checksum chain, and has to be redone on every build.

**Exact target paths:** none — there is no path a GRUB background could be
placed at that the pipeline would use.
**Config changes:** none.
**How to verify in QEMU:** boot the ISO, screenshot the GRUB menu. Expected
result under option (a): text menu, no background — that is the *correct*
outcome for this plan, not a failure. Under (b): the 04 art (or a
derivative) visible behind "Try Vyra OS" / "Install Vyra OS".

---

## §2 — Plymouth theme — two-step (primary), script (full-fidelity alternative)

**Asset:** `05_plymouth_splash_1920x1080.png` (EXISTING, inventory 1.4/1.5 —
verified clean: "Vyra" wordmark + gold underline + tagline, clear space
below for live progress). **Progress dots/bar must stay a separate
live-rendered layer, never flattened into the background** — both options
below satisfy that; the 05 file is never edited.

### Mechanism (verified)

A Plymouth theme is a directory under `/usr/share/plymouth/themes/<name>/`
containing a `<name>.plymouth` data file (`[Plymouth Theme]` section with
`Name`, `Description`, `ModuleName`, plus a per-plugin section), and is
activated with `plymouth-set-default-theme <name>`, after which the
initramfs must be rebuilt (`dracut -f`) — RHEL 7 Desktop Migration and
Administration Guide §10.3, "Plymouth". The theme lives in the initramfs:
dracut's plymouth module embeds the default theme recorded in
`/etc/plymouth/plymouthd.conf` (written by `plymouth-set-default-theme`).

**The dracut ordering problem in `configure_iso.sh` is real and has a
clean fix.** The script currently runs its `dracut` regen *before* the
`dnf install ... plymouth` line. If Plymouth were not installed when
dracut runs, the regenerated initramfs would contain no splash at all.
(The 2026-11-26 boot test *did* show a Plymouth splash with three dots,
which implies Plymouth was already present at dracut time — almost
certainly shipped in the `fedora-bootc:45` base image — but that is
inference, not proof; see the verification step below.) The fix does not
require reordering `configure_iso.sh`: put the theme files, the
`plymouth-set-default-theme vyra` call, and an explicit `dnf install -y
plymouth` (belt-and-braces) in the **core** `Containerfile`, so that by the
time the payload's existing `dracut` regen runs, the theme and its default
are already in place and get embedded. Fallback if the `lsinitrd` gate
below fails: add a second `dracut` run in `configure_iso.sh` *after* the
Plymouth install. Do not change the existing dracut flags — the live boot
works today with them (the Margine handbook's `--add ostree` note applies
to the *installed* system's initramfs on bootc, not to this live
`dmsquash-live` regen).

### Primary recommendation: two-step theme (no custom code)

The `two-step` splash plugin renders a solid background colour, a centred
logo image, and a live progress animation (throbber / progress bar) that is
driven by real boot progress — the progress layer is the plugin's own
rendering, not part of any image. It also has a **built-in LUKS password
prompt** (dialog), which matters for encrypted installs (inventory 1.7).
Per-plugin options are documented in the RHEL guide (Procedure 10.4/10.5:
copy an existing theme, set `ImageDir`, `BackgroundStartColor` /
`BackgroundEndColor`, add a `logo.png`) and in the Manjaro
`manjaro.plymouth` example (progress-bar colours, dialog alignment,
`UseProgressBar`, `MessageBelowAnimation`).

**PROPOSED derivative (to be generated, HD, from 05):**
`logo.png` — a transparent-background crop of the central "Vyra" wordmark
with its gold underline, taken from `05_plymouth_splash_1920x1080.png`
(never a re-draw; never a new logo). Target size ~900×360 px (the
wordmark band of the 1920×1080 splash, cropped — no stretching, no
upscaling). The tagline is *not* in the logo file: two-step draws the logo
and the progress animation only; the tagline stays in the full splash art
for the script-theme alternative below.

**Exact target paths (core image):**

```
/usr/share/plymouth/themes/vyra/vyra.plymouth
/usr/share/plymouth/themes/vyra/logo.png            (PROPOSED derivative)
/etc/plymouth/plymouthd.conf                        (written by plymouth-set-default-theme)
```

**Exact config (`vyra.plymouth`) — PROPOSED file, write at implementation:**

```ini
[Plymouth Theme]
Name=Vyra
Description=Vyra OS boot splash — Obsidian background, gold wordmark, live progress
ModuleName=two-step

[two-step]
ImageDir=/usr/share/plymouth/themes/vyra
HorizontalAlignment=.5
VerticalAlignment=.5
Transition=none
TransitionDuration=0.0
BackgroundStartColor=0x050505
BackgroundEndColor=0x050505
ProgressBarBackgroundColor=0x606060
ProgressBarForegroundColor=0xDCAE43
DialogHorizontalAlignment=.5
DialogVerticalAlignment=.682
Font=Inter 12
TitleFont=Inter Bold 30
```

(Colours: Obsidian `#050505`, Gold `#DCAE43`. `Font`/`TitleFont` name
Inter, but see the fonts gap in Ground Rules §4 — until Inter is
installed these fall back to the system font, which only affects the
LUKS/dialog text, not the logo.)

**Build steps (core `Containerfile`):**

```dockerfile
# after: COPY vyra-branding /usr/share/vyra/branding
RUN dnf5 install -y plymouth \
    && mkdir -p /usr/share/plymouth/themes/vyra \
    && cp /usr/share/vyra/branding/batch-01/vyra.plymouth /usr/share/plymouth/themes/vyra/vyra.plymouth \
    && cp /usr/share/vyra/branding/batch-01/vyra-plymouth-logo.png /usr/share/plymouth/themes/vyra/logo.png \
    && plymouth-set-default-theme vyra \
    && dnf5 clean all
```

(Exact source filenames for the two new files are the implementer's
choice; keep them under `vyra-branding/` so they travel with the pack.
Note the core `Containerfile` currently has no `plymouth` install — the
`dnf5 install -y plymouth` line is the belt-and-braces part; if Plymouth
is already in the base image it is a no-op.)

**Verification:** in the payload build, `lsinitrd
/usr/lib/modules/*/initramfs.img | grep vyra` must list the theme files;
`plymouth-set-default-theme --list` must include `vyra`. In QEMU: the
boot splash shows the Obsidian background + gold Vyra wordmark + live
progress animation underneath; screenshot it (the boot test's
Plymouth-screen shot is the reference point). For LUKS: install with
encryption in QEMU and confirm the passphrase dialog renders on the
splash (two-step's built-in dialog).

### Full-fidelity alternative: script theme (only if the full splash must show)

A `script`-plugin theme draws the 05 PNG full-screen as a background
sprite and renders progress dots as live sprites in the script
(`Plymouth.SetBootProgressFunction` / progress callbacks) — the dots are
still live, never baked in. This shows the tagline and the full
composition, which two-step cannot (two-step has no full-screen background
image — only a solid colour + centred logo).

Costs, all verified from the Margine handbook §5.6 (a bootc project that
ships a script theme): needs the extra package `plymouth-plugin-script`
(`dnf -y install plymouth-plugin-script` — Bluefin ships Plymouth core
but *not* the script plugin); needs a hand-written `vyra.script` (custom
code, must be tested at every resolution); and — the sharp edge — **a
script theme has NO built-in LUKS prompt**: the plugin advertises the
display-password hook but the theme must implement it itself with
`Plymouth.SetDisplayPasswordFunction` and render its own dialog, or an
encrypted install appears to hang on the splash (verified in Plymouth
24.004.60 source by the Margine author). Recommendation: take the
two-step route for Batch 01; revisit the script theme only if the owner
judges the full splash indispensable.

---

## §3 — SDDM login background — fork the Fedora theme, use a clean derivative

**Asset:** `06_sddm_login_background_3840x2160.png` (EXISTING, inventory
2.1) — **FLAGGED, do not wire as-is.** The image has "Vyra OS" /
"Welcome back" and a rounded-card outline **baked in**. SDDM renders its
own username, password field, clock and session selector natively on top
of the background; using 06 as the background would double the text and
the card. Per the batch-01 README and the owner's derivative rule, 06 is
kept as a **design mockup only**.

**Recommended implementation asset (PROPOSED HD derivative):** a clean
SDDM background generated from the pack's clean art — the `03` lock-screen
art (already the darker, blurrier composition, so native white/platinum
controls stay legible) or a darkened `01` master — 3840×2160 (same as 06),
**no baked-in text, no card outline**. The derivative is what gets wired;
06 is never shipped as a background.

### Mechanism (verified)

Fedora KDE's default SDDM theme is `01-breeze-fedora`, shipped as
`/usr/share/sddm/themes/01-breeze-fedora/` (theme files: `Main.qml`,
`Login.qml`, `Background.qml`, `theme.conf`, `metadata.desktop`,
`preview.png` — confirmed by the Fedora Discussion thread on changing the
SDDM background, which lists that exact tree, and by the
`codingarret.dev` Bazzite guide, which forks that exact directory).
The background image is a theme setting, not a global one:

- `theme.conf` in the theme directory holds
  `[General] background=<path> type=image` (EndeavourOS example shows
  exactly this);
- an override file `theme.conf.user` in the same directory overrides
  `theme.conf` without editing the packaged file (ArchWiki SDDM,
  "Customizing a theme"; the Fedora openQA suite edits
  `/usr/share/sddm/themes/01-breeze-fedora/theme.conf.user` the same way);
- the active theme is selected in `/etc/sddm.conf.d/*.conf`:
  `[Theme] Current=<name>` (SDDM reads `/etc/sddm.conf.d/` drop-ins;
  system defaults live in `/usr/lib/sddm/sddm.conf.d/default.conf`).

The clean way to ship a branded login on an image-based OS is to **fork
the theme at build time** (copy the directory, rename it, point its
background at the Vyra art) rather than editing the packaged Fedora
theme in place — the fork survives package updates and never touches a
file another package owns. (The bind-mount / `/var/lib/sddm/themes`
workarounds in the Fedora Discussion thread exist for *mutable* atomic
desktops where `/usr` is read-only at runtime; Vyra bakes the theme into
the image at build time, so no runtime workaround is needed.)

**Exact target paths (core image):**

```
/usr/share/sddm/themes/vyra/                 (forked from 01-breeze-fedora)
/usr/share/sddm/themes/vyra/metadata.desktop  (Name=Vyra)
/usr/share/sddm/themes/vyra/theme.conf.user   (PROPOSED file, overrides background)
/etc/sddm.conf.d/10-theme.conf               (PROPOSED file, selects the theme)
```

**Exact config — `theme.conf.user` (PROPOSED):**

```ini
[General]
background=/usr/share/vyra/branding/sddm-background.png
type=image
```

**Exact config — `/etc/sddm.conf.d/10-theme.conf` (PROPOSED):**

```ini
[Theme]
Current=vyra
```

**Build steps (core `Containerfile`):**

```dockerfile
RUN cp -r /usr/share/sddm/themes/01-breeze-fedora /usr/share/sddm/themes/vyra \
    && sed -i 's/^Name=.*/Name=Vyra/' /usr/share/sddm/themes/vyra/metadata.desktop \
    && cp /usr/share/vyra/branding/batch-01/vyra-sddm-background.png \
          /usr/share/vyra/branding/sddm-background.png \
    && printf '[General]\nbackground=/usr/share/vyra/branding/sddm-background.png\ntype=image\n' \
          > /usr/share/sddm/themes/vyra/theme.conf.user \
    && printf '[Theme]\nCurrent=vyra\n' > /etc/sddm.conf.d/10-theme.conf
```

(The `vyra-sddm-background.png` source is the PROPOSED derivative from
03/01 art, generated into `vyra-branding/batch-01/` first. The runtime
path `/usr/share/vyra/branding/sddm-background.png` keeps all branding
under the one branding directory. If the fork must differ from Breeze
further — e.g. gold primary button, Carbon fields, inventory 2.5 — that is
`Main.qml`/`Login.qml` work and a separate, larger theme pass; Batch 01
changes the background only, which is what the pack supplies.)

**Known gotcha (verify at test time, do not pre-fix):** a 2024-10-20 note
on the Breeze-fork guide reports `Theme has an unknown property
"fontSize"` on newer SDDM with older Breeze QML, fixed by replacing
`fontSize` → `font.pointSize` and `iconSource` → `icon.name` in
`Main.qml`. Fedora 45 ships matched SDDM + Breeze versions, so this is
expected *not* to occur — but if the SDDM screen shows that error, that
is the documented fix.

**Verification:** SDDM is bypassed by autologin in the live session, so
verify two ways: (1) in the live session, run
`sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/vyra` and
screenshot the greeter (ArchWiki's documented preview command); (2) on
an installed system (qcow2 or a QEMU install), reboot to the login
screen, screenshot it, log in as the created user, and confirm the clock,
password field and session selector are readable and functional over the
derivative background.

---

## §4 — Plasma wallpaper + lock screen — wallpaper package + look-and-feel defaults

**Assets:** `01_desktop_wallpaper_master_3840x2160.png`,
`01b_desktop_wallpaper_1920x1080.png`,
`01c_desktop_wallpaper_ultrawide_3440x1440.png`,
`02_light_wallpaper_master_3840x2160.png`,
`03_lock_screen_background_3840x2160.png` (all EXISTING, inventory
3.1/3.2/3.3). Covers the live user *and* installed users with one
mechanism: both are brand-new users whose first login applies the system
defaults.

### Mechanism (verified)

**Wallpaper package.** A wallpaper is a KPackage plugin under
`/usr/share/wallpapers/<Id>/`: `metadata.json` (`KPlugin` with `Id` /
`Name`) plus `contents/images/<WxH>.png` — the image plugin picks the
file whose resolution best matches the screen — and
`contents/images_dark/<WxH>.png`, used when the colour scheme is dark
(both conventions evidenced in the KDE bug 527150 report, which shows
the lock screen loading
`.../Mountain/contents/images_dark/5120x2880.png`, and in the
nix-community/stylix KDE module, which builds exactly this layout and
writes `contents/screenshot.png` thumbnails with ImageMagick).

**Default wallpaper.** A look-and-feel (global theme) package may specify
its default wallpaper in `contents/defaults` as:

```ini
[Wallpaper]
Image=<wallpaper kplugin Id>
```

— KDE bug 477338 ("The default wallpaper setting of a look-and-feel
package has no effect", Fedora reporter: "We use this in Fedora to set
our default wallpaper"). **That bug is FIXED** — Alessandro Astone,
" This works in Beta 1", Version Fixed In 5.90.0 (Plasma 6.0) — so on
Plasma 6.8 the mechanism works. Fedora itself sets its default wallpaper
this way. The look-and-feel is selected system-wide in `kdeglobals`
(`[KDE] LookAndFeelPackage=<id>` — the key as used by nix-community/stylix,
which sets it immutably). Files under `/etc/xdg/` are the system-wide
KConfig defaults, so a default written there applies to every new user —
the live user created by `livesys` and every user created by the
installer.

**Lock screen.** Independent of the desktop wallpaper. Its image is
stored in `kscreenlockerrc` under the nested group
`[Greeter][Wallpaper][org.kde.image][General]`, key `Image` (multiple
independent sources: Garuda Linux migration notes, the
shalva97/kde-configuration-files reference, the submerge theme's
`kwriteconfig6` commands). The value is a direct file path or `file://`
URL. KDE bug 527150 (lock screen falling back to the default wallpaper
on one screen in 6.8.0) found that a **direct image file URL works
reliably** while a wallpaper-*package* directory path was the flaky case;
the bug is fixed in 6.8.2 and Fedora 45 ships Plasma 6.8.3, but the
direct-file form is still the safer choice — use it.

### Exact target paths (core image)

```
/usr/share/wallpapers/Vyra/metadata.json
/usr/share/wallpapers/Vyra/contents/images/3840x2160.png        (from 02, light)
/usr/share/wallpapers/Vyra/contents/images_dark/3840x2160.png   (from 01, dark master)
/usr/share/wallpapers/Vyra/contents/images_dark/1920x1080.png   (from 01b)
/usr/share/wallpapers/Vyra/contents/images_dark/3440x1440.png   (from 01c)
/usr/share/wallpapers/Vyra/contents/screenshot.png              (PROPOSED 400×250 thumbnail from 01b)
/usr/share/plasma/look-and-feel/org.vyra.desktop/metadata.json  (PROPOSED)
/usr/share/plasma/look-and-feel/org.vyra.desktop/contents/defaults (PROPOSED)
/etc/xdg/kdeglobals                                             (PROPOSED, [KDE] LookAndFeelPackage)
/etc/xdg/kscreenlockerrc                                        (PROPOSED, lock-screen image)
/usr/share/vyra/branding/lock-screen-background.png             (from 03)
```

**Light-variant note:** only one light master exists (02, 3840×2160).
The image plugin downscales it on smaller / ultrawide light-mode
screens, which is acceptable. PROPOSED optional derivatives: light
1920×1080 and 3440×1440 exports from 02 — generate them only if the
owner wants pixel-exact light variants; do not block Batch 01 on them.

**Exact config — `metadata.json` (wallpaper, PROPOSED):**

```json
{
  "KPlugin": {
    "Id": "Vyra",
    "Name": "Vyra",
    "Description": "Vyra OS default wallpaper",
    "ServiceTypes": ["Plasma/Wallpaper"]
  }
}
```

(Mirror the format of an installed Fedora wallpaper package, e.g.
`/usr/share/wallpapers/Next/metadata.json`, at implementation time —
that file is the in-image reference for the exact keys.)

**Exact config — `org.vyra.desktop/contents/defaults` (PROPOSED):**

```ini
[Wallpaper]
Image=Vyra
```

**Exact config — `/etc/xdg/kdeglobals` addition (PROPOSED):**

```ini
[KDE]
LookAndFeelPackage=org.vyra.desktop
```

**Exact config — `/etc/xdg/kscreenlockerrc` (PROPOSED):**

```ini
[Greeter]
WallpaperPlugin=org.kde.image

[Greeter][Wallpaper][org.kde.image][General]
Image=file:///usr/share/vyra/branding/lock-screen-background.png
```

**Build steps (core `Containerfile`):** install the wallpaper package
files, the `org.vyra.desktop` look-and-feel package, and the two
`/etc/xdg` defaults from `vyra-branding/` (write them as source files in
the repo, e.g. `vyra-branding/plasma/org.vyra.desktop/...`,
`vyra-branding/xdg/kdeglobals`, `vyra-branding/xdg/kscreenlockerrc`,
and COPY them into place — do not generate config with shell heredocs
in the Containerfile where a versioned source file will do).

**Fallbacks (only if the QEMU test shows the defaults did not apply):**

1. Ship a default `plasma-org.kde.plasma.desktop-appletsrc` under
   `/etc/xdg/` with
   `[Containments][1][Wallpaper][org.kde.image][General]
   Image=file:///usr/share/wallpapers/Vyra/contents/images_dark/3840x2160.png`
   — the per-desktop wallpaper entry. (Bor's KConfig docs warn this "does
   not take effect reliably" because containment IDs are generated, so it
   is a fallback, not the primary.)
2. A guarded first-login autostart entry that runs
   `plasma-apply-wallpaperimage <file>` only when no wallpaper is set
   yet. Imperative and last-resort; prefer the declarative routes above.

**Verification (QEMU, live ISO):** the live desktop screenshot must show
the 01 art (dark default) — compare against the 2026-11-26 boot test,
which showed the Fedora gears wallpaper; lock the screen (or wait out the
~5-minute idle lock seen in the boot test) and screenshot the lock screen
showing the 03 art; switch the colour scheme to light in System Settings
and confirm the 02 art appears. The 1920×1080 and 3440×1440 variants
cannot be screenshot-verified in the 1280×800 QEMU window — verify by
file presence + the plugin's resolution selection, and mark that as
partial verification, not a pass at those resolutions.

---

## §5 — Anaconda installer — pixmaps + CSS + os-release (NO slideshow)

**Assets:** `07_installer_slide_desktop_1920x1080.png`,
`08_installer_slide_gaming_1920x1080.png`,
`09_installer_slide_customization_1920x1080.png`,
`10_installer_slide_culture_1920x1080.png` (all EXISTING, inventory 4.5).
**Say it plainly: Anaconda GTK has no slideshow feature.** The Red Hat
"Customizing Anaconda" documentation lists everything that can be
customised — boot menu, graphical-interface logo/backgrounds/product name,
and add-on spokes/screens — and a rotating install slideshow is not among
them. There is no hook, config key, or directory that would display
slides 07–10 in sequence while packages install. Any plan that claims the
slides will "play" during install is inventing a feature.

### What CAN be shown (verified)

The customisable graphical elements live in
`/usr/share/anaconda/pixmaps/` — `sidebar-bg.png`, `sidebar-logo.png`,
`topbar-bg.png`, `right-arrow-icon.png`, the password-show icons — and
`/usr/share/anaconda/anaconda-gtk.css` wires them to the UI
(`.logo-sidebar` → `sidebar-bg.png`, `.logo` → `sidebar-logo.png`,
`.product-logo` placeholder, `AnacondaSpokeWindow #nav-box` →
`topbar-bg.png`). The RHEL docs note the PNG backgrounds "do not scale,
they are always displayed in their true dimensions" — so derivatives must
be produced at the pixmaps' real dimensions (measure them at
implementation; see below), not at 1920×1080.

The profile can also point at a product-specific stylesheet: the
`[User Interface]` section of the Anaconda default configuration
(`data/anaconda.conf`, Anaconda main branch) documents
`custom_stylesheet` — "The path to a custom stylesheet." — and Fedora
Workstation's own profile (`data/profile.d/fedora-workstation.conf`,
same branch) uses exactly this:
`custom_stylesheet = /usr/share/anaconda/pixmaps/workstation/fedora-workstation.css`.

**Product name — the inventory is wrong here, and the correction matters.**
Inventory 4.1 says the product name is "Anaconda `productName` in
`iso_files/vyra.conf`". There is **no** `productName`/`product_name`
option in the Anaconda configuration (checked against the full default
`data/anaconda.conf`). The product name is read from the installation
environment's os-release — `pyanaconda/core/product.py`,
`get_product_values()`: "NAME, VERSION_ID and VARIANT provide the
product name, version and variant. ID provides the short name." So the
installer says "Vyra OS" if and only if os-release says so (inventory
5.1). The wiring is therefore an os-release override in the **core**
image, not a `vyra.conf` line:

- `/usr/lib/os-release`: set `NAME="Vyra OS"`,
  `PRETTY_NAME="Vyra OS 0.1"` (and a Vyra-appropriate `VERSION_ID`).
- **Keep `ID=fedora` for now.** The Vyra Anaconda profile
  (`iso_files/vyra.conf`) matches on `os_id = fedora`; changing `ID` to
  `vyra` would require changing `os_id` in the profile *and* re-checking
  every piece of Fedora tooling that keys off `ID`. Keep
  `ID_LIKE=fedora`. Changing `ID` is a separate identity decision with
  wider blast radius — it is not a Batch 01 visual change.

### What the slides become

The four slides are near-identical backgrounds whose distinction lives in
overlaid text (batch-01 README flag) — and installer text must be
rendered natively, never baked into images. So the slides' *art* is the
input to PROPOSED HD derivatives at pixmap size; the slides themselves
have no display path during install:

- **PROPOSED** `sidebar-bg.png` — vertical gold-on-Obsidian band derived
  from the slide art (crop the flowing gold linework into a vertical
  strip; measure the shipped `sidebar-bg.png` dimensions in the payload
  build first — TBD until measured).
- **PROPOSED** `sidebar-logo.png` — the "Vyra OS" text wordmark as a
  transparent PNG, cropped from the 05 splash / brand board (never a
  re-drawn logo).
- **PROPOSED** `topbar-bg.png` — horizontal gold band derivative from
  the slide art.
- **PROPOSED** `vyra.css` — a small custom stylesheet
  (`/usr/share/anaconda/pixmaps/vyra/vyra.css`) setting the product
  colours, e.g. `@define-color product_bg_color #050505;` with gold
  accents, following the Fedora Workstation CSS pattern.

**Exact target paths (payload image — the anaconda package is installed
only there, by `configure_iso.sh`):**

```
/usr/share/anaconda/pixmaps/sidebar-bg.png    (PROPOSED derivative, replaces file)
/usr/share/anaconda/pixmaps/sidebar-logo.png  (PROPOSED derivative, replaces file)
/usr/share/anaconda/pixmaps/topbar-bg.png     (PROPOSED derivative, replaces file)
/usr/share/anaconda/pixmaps/vyra/vyra.css     (PROPOSED file)
```

**Exact config — `iso_files/vyra.conf` addition (PROPOSED):**

```ini
[User Interface]
custom_stylesheet = /usr/share/anaconda/pixmaps/vyra/vyra.css
```

**Build steps (payload `iso_files/configure_iso.sh`, after the
`dnf install -y anaconda-live ...` line):**

```bash
# Vyra installer branding — replace the Anaconda GTK pixmaps with
# derivatives of the Batch 01 slide art, and point the Vyra profile
# at the Vyra stylesheet (vyra.conf [User Interface]).
cp /usr/share/vyra/branding/batch-01/vyra-sidebar-bg.png   /usr/share/anaconda/pixmaps/sidebar-bg.png
cp /usr/share/vyra/branding/batch-01/vyra-sidebar-logo.png /usr/share/anaconda/pixmaps/sidebar-logo.png
cp /usr/share/vyra/branding/batch-01/vyra-topbar-bg.png    /usr/share/anaconda/pixmaps/topbar-bg.png
mkdir -p /usr/share/anaconda/pixmaps/vyra
cp /usr/share/vyra/branding/batch-01/vyra.css /usr/share/anaconda/pixmaps/vyra/vyra.css
```

(The source filenames above are the implementer's choice; keep the
derivatives under `vyra-branding/batch-01/` with the rest of the pack.
The pixmap files belong to the `anaconda` RPM — replacing them at build
time is a build-time overlay in the payload image only; it never touches
the installed system, which comes from the embedded core image.)

### TBD — which installer UI actually runs (blocks visual verification)

The payload installs `anaconda-live` and the boot test saw
`anaconda --liveinst --graphical` running, but the installer *window*
never appeared in two attempts (boot test verdict 2026-11-26 10:19 EST:
installer GUI FAIL), and a `webui-desktop` process was seen in one
attempt and absent in the next. **Whether the live ISO launches the GTK
UI or the WebUI is unresolved.** The pixmaps/CSS mechanism in this
section applies to the GTK UI only. If the live installer turns out to
be the WebUI, these files are simply unused and WebUI branding needs
separate research. Do not claim Phase D "verified" until the installer
window appears in QEMU; file presence in the payload is the only check
available until the GUI issue is resolved (retest on real hardware/KVM
first, per the boot-test record).

**Verification (once the window appears):** launch the installer from
the live desktop, screenshot the hub and one spoke — the sidebar must
show the gold band + Vyra wordmark, the top bar the gold band, and the
window title / product name must read "Vyra OS" (os-release). The
slides 07–10 are verified as *not shown* — that is the expected outcome,
not a defect.

---

## §6 — Discover banner — no local banner plug-in; featured-list control exists

**Asset:** `11_discover_banner_1920x400.png` (EXISTING, inventory 6.3).
**Verdict: the banner image itself has no plug-in point in Discover's
front page.** Discover's home page is built from AppStream data: app
cards, screenshots, ratings, "Most Popular" / "Editor's Choice" lists.
There is no local banner file, theme key, or config that puts a
1920×400 image across the top of Discover.

### What DOES exist (verified)

The KDE/discover README ("Vendor Customization", current master):

> "Want to change the apps featured in the Editor's Choice section? Add a
> configuration file named `/usr/share/discover/featuredurlrc` that points
> to a JSON file patterned off the default one present at
> https://autoconfig.kde.org/discover/featured-5.9.json"

```ini
[Software]
FeaturedListingURL="https://your-url-here/file.json"
```

That mechanism controls **which apps** appear in Editor's Choice — a JSON
list of application IDs, rendered by Discover with their AppStream
screenshots. It does not display a banner image. (The Debian bug 851617
thread confirms the same direction: Discover's featured list is
"downloaded from KDE" rather than computed locally.)

**Exact target path (core image):**

```
/usr/share/discover/featuredurlrc   (PROPOSED file)
```

### Dependencies that decide Phase E

1. **`plasma-discover` is not installed.** The core `Containerfile`
   installs `plasma-desktop`, `plasma-workspace`, `plasma-workspace-wayland`,
   `sddm`, `dolphin`, `konsole` — no Discover package, and it is not a
   dependency of any of them. Phase E therefore requires adding the
   package to the core image (a deliberate package addition, not a
   visual tweak) — owner decision. Until then there is no Discover to
   brand. (Verify at build time: `rpm -q plasma-discover`.)
2. **The featured JSON needs a home.** The `FeaturedListingURL` in the
   README example is an `https://` URL. Whether a local `file://` URL
   works is **TBD/unverified** — do not assume it. The realistic options
   are (a) host the JSON somewhere Vyra-controlled (VFM site, or a file
   in one of the Vyra repos served over HTTPS), or (b) defer the
   featured-list control and ship only the package. Either way the JSON
   lists app IDs; the banner art is not part of it.
3. **What 11 becomes.** The banner art is not wasted: it is the source
   for a future AppStream pass (a Vyra AppStream component whose
   screenshots use the banner art) and for the featured apps' presentation
   once Vyra ships its own apps. For Batch 01, record 11 as **not
   integrable as a banner** and keep the file in the pack.

**Verification (once Discover is installed):** open Discover in the live
session, screenshot the home page; if a Vyra `featuredurlrc` is shipped
and its JSON is reachable, confirm the Editor's Choice section reflects
the Vyra list. If no JSON is hosted, the only honest check is file
presence of `featuredurlrc` — a partial check, not a visual pass.

---

## HD derivatives register (all PROPOSED — none exists yet)

| # | Derivative | Source art | Runtime home | Used by |
|---|---|---|---|---|
| D1 | `vyra-plymouth-logo.png` (~900×360, transparent, wordmark + gold underline crop) | 05 | `/usr/share/plymouth/themes/vyra/logo.png` | §2 |
| D2 | `vyra-sddm-background.png` (3840×2160, no text, no card; from 03 or darkened 01) | 03 / 01 | `/usr/share/vyra/branding/sddm-background.png` | §3 |
| D3 | `screenshot.png` (400×250 thumbnail) | 01b | `/usr/share/wallpapers/Vyra/contents/screenshot.png` | §4 |
| D4 | Light 1920×1080 + 3440×1440 exports (optional) | 02 | `/usr/share/wallpapers/Vyra/contents/images/` | §4 |
| D5 | `vyra-sidebar-bg.png` (vertical band, at shipped pixmap size — measure first) | 07–10 art | `/usr/share/anaconda/pixmaps/sidebar-bg.png` | §5 |
| D6 | `vyra-sidebar-logo.png` (transparent wordmark) | 05 / brand board | `/usr/share/anaconda/pixmaps/sidebar-logo.png` | §5 |
| D7 | `vyra-topbar-bg.png` (horizontal gold band, at shipped pixmap size) | 07–10 art | `/usr/share/anaconda/pixmaps/topbar-bg.png` | §5 |
| D8 | `vyra.css` (Obsidian/gold GTK stylesheet) | — (written) | `/usr/share/anaconda/pixmaps/vyra/vyra.css` | §5 |

Plus small written (not image) PROPOSED files: `vyra.plymouth`,
`theme.conf.user`, `/etc/sddm.conf.d/10-theme.conf`,
`org.vyra.desktop` (metadata.json + contents/defaults),
`/etc/xdg/kdeglobals` addition, `/etc/xdg/kscreenlockerrc`,
`/usr/share/discover/featuredurlrc`, `vyra.conf` `[User Interface]`
addition. All are text; all go through snapshot-push as usual.

## If the PNGs lived in a separate assets repo instead

Main plan above assumes the main-repo layout (PNGs COPYed from
`vyra-branding/batch-01/`). If the owner moves the PNGs to a separate
assets repo (authorised: up to 4 repos, 2026-11-26), the wiring changes
in exactly one place — **acquisition**, not the runtime paths:

- The core `Containerfile` would fetch the pack at build time instead of
  `COPY vyra-branding/`: e.g. an `ADD` of a pinned archive URL, or a
  `curl` of the raw files at a pinned commit SHA, into
  `/usr/share/vyra/branding/` — same destination tree, same filenames.
  Pin by commit SHA or tag, never by branch (reproducibility).
- The payload needs no extra fetch: it inherits the core image's
  `/usr/share/vyra/branding/` and copies from there, exactly as in §5.
- Trade-offs: the main repo stays text-only (snapshot-push friendly) and
  the assets repo holds the binaries (browser upload, as decided
  2026-11-26 11:10 EST); but the build now needs network at image-build
  time (CI has it; the sandbox needs the CA dance), and an unpinned or
  moved asset breaks the build. Keep the runtime paths in §§2–6 identical
  either way — only the `COPY` line changes.

## TBD / decisions needed (do not proceed past these silently)

| # | Item | Status / next step |
|---|---|---|
| T1 | GRUB background (04) | BLOCKED in-pipeline (§1). Owner call: (a) defer, or (b) fork Titanoboa. |
| T2 | Anaconda UI: GTK vs WebUI on the live ISO | UNVERIFIED. Resolve from the installer-GUI investigation; if WebUI, §5's pixmaps/CSS don't apply and WebUI branding needs new research. Blocks Phase D visual verification. |
| T3 | Installer window never appears (boot test 10:19 EST) | Open issue. Blocks visual verification of §5 and of any installer work. Retest on real hardware/KVM before calling it an image defect. |
| T4 | Product name via os-release NAME | Mechanism VERIFIED (product.py); the NAME/PRETTY_NAME override itself is a small core-image change, listed in §5. Keep `ID=fedora` (decision recorded); changing `ID` is separate. |
| T5 | Discover: install `plasma-discover`? Host the featured JSON? | Owner decisions (§6). Until decided, Phase E is package-add + file-presence only. |
| T6 | Featured JSON: does `file://` work for `FeaturedListingURL`? | UNVERIFIED. Assume https until tested. |
| T7 | Plymouth: is `two-step.so` in the `plymouth` package? Is Plymouth already in the base image at payload dracut time? | Verify at build: `rpm -q plymouth`, `rpm -ql plymouth \| grep two-step`, `lsinitrd … \| grep vyra`. |
| T8 | SDDM theme dir name | Expected `01-breeze-fedora` (two independent sources). Confirm at build: `ls /usr/share/sddm/themes/`. |
| T9 | Anaconda pixmap dimensions (sidebar-bg / topbar-bg / sidebar-logo) | TBD until measured in the payload build: `file /usr/share/anaconda/pixmaps/*.png`. Derivatives D5–D7 must be produced at those sizes. |
| T10 | Fonts (Bebas Neue/Antonio/Inter/JetBrains Mono) | NOT installed, NOT supplied. Native UI text falls back. Raster derivatives unaffected. Font pass is a separate supply/install task. |
| T11 | 1080p/ultrawide light wallpaper variants | Optional PROPOSED derivatives (D4). Plugin downscales the 4K master acceptably without them. |
| T12 | `org.vyra.desktop` look-and-feel + `LookAndFeelPackage` key | Mechanism VERIFIED (bug 477338 fixed in 6.0; stylix uses the key). Still needs the QEMU check that a fresh live user actually lands on the Vyra wallpaper. |

## Verification checklist (QEMU boot test, run #11 ISO flow)

Use the existing harness (`run-live-iso-vm*.sh`, `qmp.py`, screenshots
under `first-run/` with a `batch01-` prefix). ~20 min TCG to desktop is
normal for this setup.

| # | Check | Pass looks like |
|---|---|---|
| V1 | GRUB menu screenshot | Text menu, "Try Vyra OS" / "Install Vyra OS" — **no background is the correct result** under option (a) (§1) |
| V2 | Plymouth splash screenshot | Obsidian background, gold Vyra wordmark, live progress animation underneath (not a static image of dots) |
| V3 | `lsinitrd` on the ISO's `initrd.img` | Theme files under `usr/share/plymouth/themes/vyra/` present |
| V4 | Live desktop screenshot | 01 art as the wallpaper (replacing the Fedora gears seen 2026-11-26) |
| V5 | Lock screen screenshot (idle ~5 min, or lock manually) | 03 art behind the clock / password prompt |
| V6 | Light colour scheme (System Settings) | 02 art as the wallpaper |
| V7 | `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/vyra` | Greeter over the D2 derivative, no doubled text, no card outline |
| V8 | Installed-system boot (qcow2 / QEMU install) | SDDM login over the D2 derivative; login works; clock/session selector readable |
| V9 | Installer window (blocked on T3) | Hub + spoke show gold sidebar band + Vyra wordmark + "Vyra OS" product name; slides 07–10 correctly *not* shown |
| V10 | Discover home page (blocked on T5) | Editor's Choice reflects the Vyra JSON if hosted; otherwise file presence only |
| V11 | `rpm -q plasma-discover plymouth` + theme/pixmap file lists | Versions and file placements as specified in §§2–6 |

## Sources

- **Titanoboa `build_iso.sh` @ `5c457c3d0518bd17e754be0fd98a60d29d26abb4`**
  (ublue-os/titanoboa, fetched via GitHub connector at the workflow pin):
  grub.cfg generation, ISO layout. The whole GRUB conclusion rests on
  this file (95 lines).
- **Container-native ISO contract** — O. Budai, "Building ISOs from OCI
  containers", FOSDEM 2026: `iso.yaml` supports only `label` + `grub2`
  (default / timeout / entries). Corroborates §1.
- **RHEL 7 Desktop Migration and Administration Guide §10.3 "Plymouth"**
  (docs.redhat.com): theme file format, `plymouth-set-default-theme`,
  `dracut -f` rebuild, two-step options, `logo.png` + `ImageDir`.
- **Margine handbook, "Shipping desktop opinion as data" §5.6**
  (margine.dev): script-theme layout, `plymouth-plugin-script`,
  `plymouth-set-default-theme` + `dracut --force --no-hostonly --add
  ostree`, and the script-theme LUKS-prompt lesson
  (`SetDisplayPasswordFunction` required; two-step/details have a
  built-in prompt).
- **Manjaro `manjaro.plymouth`** (gitlab.manjaro.org): two-step option
  set in the wild (progress-bar colours, dialog alignment,
  `UseProgressBar`, `MessageBelowAnimation`).
- **ArchWiki, "SDDM"**: `theme.conf.user` override
  (`[General] background=...`), `sddm-greeter-qt6 --test-mode --theme`.
- **codingarret.dev, "Customizing a SDDM theme"** (Bazzite): Fedora's
  default theme is `01-breeze-fedora`; fork-by-copy + rename in
  `metadata.desktop` + edit `theme.conf` background; the `fontSize` →
  `font.pointSize` gotcha.
- **Fedora Discussion, "Cannot Change SDDM Login Screen Background
  Image"**: `01-breeze-fedora` tree listing; `/var/lib/sddm/themes` +
  `ThemeDir=` workaround for atomic desktops (not needed here — Vyra
  bakes the theme in at build time).
- **KDE bug 477338** (bugs.kde.org, via kde-bugs-dist): look-and-feel
  `contents/defaults` `[Wallpaper] Image=<kplugin>`; RESOLVED FIXED,
  Version Fixed In 5.90.0 ("This works in Beta 1") — mechanism works on
  Plasma 6.8.
- **nix-community/stylix, `modules/kde/hm.nix`**: wallpaper-package +
  look-and-feel-package layout (`metadata.json`, `contents/defaults`,
  `contents/images[_dark]`, `contents/screenshot.png`),
  `kdeglobals [KDE] LookAndFeelPackage`.
- **KDE bug 527150** (bugs.kde.org, via kde-bugs-dist): lock-screen
  wallpaper fallback on one screen in 6.8.0; direct image file URL works
  reliably; fixed in 6.8.2 (Fedora 45 ships Plasma 6.8.3).
- **Garuda Linux migration notes; shalva97/kde-configuration-files;
  flyingf15h/submerge**: `kscreenlockerrc` format —
  `[Greeter][Wallpaper][org.kde.image][General] Image=...`,
  `WallpaperPlugin=org.kde.image`.
- **Red Hat, "Customizing Anaconda" (RHEL 8/9/10)**: pixmaps directory
  (`sidebar-bg.png`, `sidebar-logo.png`, `topbar-bg.png`),
  `anaconda-gtk.css` classes, "PNG backgrounds do not scale".
- **Anaconda source, main branch** (rhinstaller/anaconda, fetched via
  GitHub connector): `data/anaconda.conf` (`[User Interface]
  custom_stylesheet`); `data/profile.d/fedora-workstation.conf`
  (`custom_stylesheet = .../pixmaps/workstation/fedora-workstation.css`);
  `pyanaconda/core/product.py` (`get_product_values()` reads product
  name/version/variant from os-release NAME/VERSION_ID/VARIANT/ID).
- **Anaconda configuration-files docs** (anaconda-installer.readthedocs.io)
  + Fedora Change "Replace Anaconda product configuration files with
  profiles": profiles replaced product configs (Fedora 35+); profile
  detection by `os-release` ID/VARIANT_ID.
- **KDE/discover README** (current master): vendor customisation —
  `/usr/share/discover/featuredurlrc`, `[Software]
  FeaturedListingURL="..."`, patterned off
  `https://autoconfig.kde.org/discover/featured-5.9.json`.
- **Project files read for this plan:** `Containerfile`,
  `installer/Containerfile.live`, `iso_files/configure_iso.sh`,
  `iso_files/vyra.conf`, `installer/iso.yaml`,
  `.github/workflows/build.yml`, `vyra-branding/batch-01/README.md`,
  `vyra-branding/Vyra-VISUAL-ASSET-INVENTORY.md`,
  `first-run/WALKTHROUGH.md` (boot-test record, 2026-11-26 10:19 EST).
- **Could not verify in this sandbox:** the core image's installed
  package/file list — `podman run` is blocked here (crun/netavark
  "Operation not permitted" in this VM), so SDDM theme dir contents,
  Plymouth presence, `plasma-discover` absence, wallpaper-package
  formats and Anaconda pixmap dimensions are all marked for the
  build-time checks listed in §12 (T7–T9). Nothing in this plan depends
  on an unverified claim without saying so.
