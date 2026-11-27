# Vyra OS — Plymouth Theme Investigation

**Date:** 2026-11-27
**Scope:** Why the Vyra Plymouth theme never renders at boot (runs 23/24/25).
**Method:** Research + documentation only. No code changes, no pushes, no VM, no builds.
**Status:** Root cause narrowed to a theme-load failure with three concrete theme
defects found. The exact fatal defect is NOT proven from static evidence — it
needs the Plymouth debug log from a boot (see §8).

## 1. Verdict

**The working hypothesis from the boot tests is REFUTED: the initramfs DOES
contain the Vyra theme.** The theme, its config, the two-step plugin, and all
of the plugin's libraries are embedded in the run-25 ISO's initramfs
(proven by direct inspection, §2). The problem is not that dracut failed to
embed the theme — it is that **plymouthd falls back to the text theme at boot
because the Vyra theme fails to LOAD** (the boot screen is the text theme's
"3 box countdown", §5).

Three concrete defects were found in the Vyra theme itself, measured against
Fedora's reference two-step theme (`plymouth-theme-charge`):

1. **Missing `watermark.png`** — the two-step plugin's logo file. The Vyra
   theme ships only `logo.png`. The plugin loads `watermark.png`, not
   `logo.png`, so the wordmark could never display even if the theme loaded.
2. **Missing dialog images `box.png`, `entry.png`, `lock.png`** — the
   reference two-step theme ships all three (plus `bullet.png`). The Vyra
   theme ships none of them.
3. **Fonts `Inter 12` / `Inter Bold 30` are not installed anywhere** — not in
   the image, not in the initramfs. The working themes either ship no `Font`
   key (charge) or name an installed font (spinner: Cantarell).

The recommended fix (Option 1, §7) addresses all three at once — all changes
are theme files only — and the next boot test should capture the Plymouth
debug log so that if it still fails, the exact reason is on record.
**The fix approach needs the owner's approval before it is implemented.**
No fix has been applied and no build has been started.

## 2. The decisive check: the run-25 initramfs DOES contain the theme

The run-25 ISO (`~/workspace/vyra-os/live-iso-run25/Vyra-OS-Live.iso`,
3,243,835,392 bytes, sha256 `67058d09…addab`, verified) was inspected
directly. Its initramfs (`/IMAGES/PXEBOOT/INITRD.IMG`, 273,512,613 bytes)
is an uncompressed early-microcode cpio (17,410,800 bytes) followed by a
zstd-compressed cpio (decompressed 335,644,672 bytes, 5,683 entries).
Method: `pycdlib` to extract the file from the ISO (no xorriso/isoinfo on
this VM), `zstandard` to decompress, a small newc-cpio parser to list
entries. All steps ran locally; no VM, no boot.

**Plymouth entries in the initramfs: 46.** The decisive ones:

| Entry | Size | Note |
|---|---|---|
| `etc/plymouth/plymouthd.conf` | 92 B | `[Daemon] Theme=vyra` |
| `usr/share/plymouth/themes/vyra/vyra.plymouth` | 495 B | Theme file, `ModuleName=two-step` |
| `usr/share/plymouth/themes/vyra/logo.png` | 17,351 B | D1 wordmark (same size as the source file) |
| `usr/lib64/plymouth/two-step.so` | 77,688 B | The theme's plugin |
| `usr/lib64/plymouth/label-freetype.so` | 24,016 B | Label plugin |
| `usr/lib64/plymouth/details.so`, `text.so` | — | Fallback themes |
| `usr/lib64/plymouth/renderers/drm.so`, `frame-buffer.so` | — | Renderers |
| `usr/lib64/libply.so.5`, `libply-splash-core.so.5`, `libply-splash-graphics.so.5` | — | All three libraries `two-step.so` needs (`readelf -d` NEEDED) |
| `usr/lib64/libpng16.so.16`, `libfreetype.so.6`, `libdrm.so.2` | — | Image/font/DRM support |
| `usr/share/fonts/Plymouth.ttf`, `Plymouth-monospace.ttf` | — | Default-font symlinks (DejaVu substitute, see §4) |
| `usr/bin/plymouth`, `usr/bin/plymouthd` | — | Daemon + client |
| `usr/share/plymouth/plymouthd.defaults` | 225 B | `[Daemon] Theme=bgrt` (distro default) |
| `usr/share/plymouth/themes/details/`, `text/` | — | Fallback themes only |

**Not present (and expected to be absent):**
`usr/share/plymouth/themes/default.plymouth` — the symlink. In Plymouth
26.x `plymouth-set-default-theme` **removes** this symlink when setting a
theme and does not recreate it (see §3); its absence is the new normal,
not a defect.

**Conclusion:** dracut embedded everything the theme needs. The old
"initramfs did not embed/use it" explanation is wrong and should be
retired from the record.

## 3. How dracut's Plymouth module works (dracut 111, Fedora 45)

Fedora 45 ships **dracut 111-5.fc45** and **Plymouth 26.134.222-6.fc45**
(verified against `dl.fedoraproject.org`; the Plymouth version is 26.x,
not the old 0.9.x line). Dracut's Plymouth module is `45plymouth` in
dracut-ng (renumbered from `50plymouth` in older dracut). Its `install()`
hands off to the Plymouth-shipped script
`/usr/libexec/plymouth/plymouth-populate-initrd` (from the
`plymouth-scripts` subpackage — read in full from the Fedora RPM for this
investigation). The script's logic, in order:

1. **Theme selection:** `PLYMOUTH_THEME_NAME=$(plymouth-set-default-theme)`
   (no args). That script's `get_default_theme()` reads `Theme` from
   `/etc/plymouth/plymouthd.conf` first, and falls back to
   `/usr/share/plymouth/plymouthd.defaults` only if the conf value is empty
   or the theme file is unreadable. With `Theme=vyra` in the conf, the
   theme is `vyra`.
2. **Theme directory:** `set_theme_dir()` resolves it from the conf
   (`ThemeDir`, unset here) to `/usr/share/plymouth/themes/vyra`.
3. **Plugin:** `ModuleName` is read from `vyra.plymouth` → `two-step`;
   `two-step.so` is installed, plus the `drm.so` and `frame-buffer.so`
   renderers.
4. **Theme files:** `inst_recur` copies the **whole** theme directory
   (`vyra.plymouth` + `logo.png`) and the `ImageDir` (same directory here).
5. **Fonts:** `Font`/`TitleFont` are resolved with `fc-match` in the build
   image and the matched files are installed. `Inter` is not installed, so
   `fc-match` substitutes the default font (DejaVu) — that is what lands
   in the initramfs as `Plymouth.ttf` / `Plymouth-monospace.ttf`. The
   theme file itself still says `Inter 12`.
6. **Fallbacks:** the `text` and `details` themes + plugins are always
   installed, as are `label-freetype.so`, the Plymouth systemd units, and
   `plymouthd.defaults`.
7. **Symlink:** the `default.plymouth` symlink is copied **only if it
   exists** on the build host. It does not exist (the 26.x set-default
   script removes it), so it is not in the initramfs. Expected.

Every one of these steps is confirmed by the §2 listing. The populate
step worked exactly as designed.

## 4. The build-pipeline trace (core → payload → ISO)

| Step | Where | What happens to Plymouth |
|---|---|---|
| Core image, Phase B | `Vyra-Foundation/Containerfile`, Phase B RUN | Installs `plymouth`, `plymouth-plugin-two-step`, `plymouth-plugin-label`; copies `vyra.plymouth` + D1 `logo.png` into `/usr/share/plymouth/themes/vyra/`; runs `plymouth-set-default-theme vyra` (writes `Theme=vyra` to `/etc/plymouth/plymouthd.conf`, removes the legacy `default.plymouth` symlink). |
| Payload image | `installer/Containerfile.live` → `iso_files/configure_iso.sh` (lines 43–50) | Installs `dracut-live`, then regenerates the initramfs: `DRACUT_NO_XATTR=1 dracut -v --force --zstd --reproducible --no-hostonly --add "dmsquash-live dmsquash-live-autooverlay" /usr/lib/modules/<kernel>/initramfs.img <kernel>`. This runs **after** the core image set `Theme=vyra`, so the theme and the default are both in place when dracut's Plymouth module runs. (The later `dnf install … plymouth` in the same script is a no-op — Plymouth is already installed.) |
| ISO | Titanoboa `build_iso.sh` line 45, pinned `5c457c3d…` | `cp -av /rootfs/usr/lib/modules/*/initramfs.img /work/iso-root/images/pxeboot/initrd.img` — Titanoboa **copies the payload image's initramfs verbatim**. It does not regenerate it. So the initramfs on the ISO is exactly the one `configure_iso.sh` built. |
| Boot | GRUB entry from `installer/iso.yaml` | Kernel line: `quiet rhgb root=live:CDLABEL=Vyra-OS-Live enforcing=0 rd.live.image`. `rhgb` **is** present, so Plymouth is told to show the graphical splash. No `plymouth.theme=` override. `plymouth-start.service` runs `plymouthd --mode=boot` with no `--theme` override. |

**No step in this chain can lose the theme.** The theme is set before
dracut runs, dracut embeds it (§2 proves it), Titanoboa copies the
initramfs verbatim, and the kernel command line asks for the graphical
splash. The failure is at **run time, inside plymouthd**, not in the
build pipeline.

## 5. What the boot actually shows — and what it means

The run-24 Plymouth screenshot (`first-run/run24-02-plymouth.png`) is a
flat **#2e3436** background (measured with PIL at six sample points; the
colour covers 1,023,874 of 1,024,000 pixels) with exactly three small
dots in a row (one white, two grey). The WALKTHROUGH records it as
byte-identical to run 11's splash — and run 11's image had **no Vyra
theme at all**.

Identification: this is the **text theme** — Plymouth's hardcoded
fallback. Evidence:

- `plymouthd` (26.134.222, strings from the Fedora binary) contains the
  literal fallback path `/usr/share/plymouth/themes/text/text.plymouth`
  and the log strings `Loading boot splash theme '%s'`,
  `Loading built-in theme`, `Theme %s not found`. The text theme is the
  daemon's built-in fallback when the configured theme cannot be loaded.
- `text.plymouth` describes itself as *"Text mode theme with a 3 box
  countdown"* — three boxes, matching the three dots exactly.
- The Vyra theme's background would be Obsidian **#050505** (its
  `BackgroundStartColor`/`BackgroundEndColor`). The screen is #2e3436.
  The Vyra theme is definitively not rendering.
- The spinner theme is ruled out: its `.plymouth` file sets
  `BackgroundStartColor=0x000000` (black), and its throbber frames are
  32×32 white arc segments, not three dots. (The spinner and bgrt themes
  are both two-step themes sharing the spinner image dir; neither is in
  the initramfs anyway — only `details`, `text`, and `vyra` are.)

**So the sequence at boot is: plymouthd reads `Theme=vyra`, attempts to
load the Vyra theme, the load fails, and it falls back to the text
theme.** The config is right and the files are present; the load itself
is what fails. (One caveat: the #2e3436 background is attributed to the
text plugin by the 3-box match and the fallback path, not by reading the
text plugin's source — the colour itself was measured, the attribution
is the inference.)

## 6. The three theme defects (Vyra vs the reference two-step theme)

Fedora's reference two-step theme is `plymouth-theme-charge`
(26.134.222). Its files: `box.png`, `bullet.png`, `charge.plymouth`,
`entry.png`, `lock.png`. Its `.plymouth` file specifies **no `Font` key**
and **no logo image file** — the two-step plugin renders its progress
bar and background from colours alone.

The Vyra theme (`vyra.plymouth` + `logo.png`) differs in three ways:

### Defect 1 — No `watermark.png` (the plugin's logo file)

`two-step.so` (strings, Fedora binary) loads its logo as
`%s/watermark.png` — log messages: `loading watermark image`,
`using %ldx%ld watermark centered at %ldx%ld for %ldx%ld screen`, and
the `WatermarkHorizontalAlignment` / `WatermarkVerticalAlignment` keys.
It does **not** load `logo.png`. The Vyra theme ships only `logo.png`,
so the wordmark could never display even if the theme loaded.
(Note: `charge` also ships no `watermark.png` and works, so a missing
watermark alone is **not** the fatal defect — but it is a real defect
that must be fixed for the wordmark to appear at all.)

### Defect 2 — No dialog images (`box.png`, `entry.png`, `lock.png`)

The two-step plugin loads `%s/box.png`, `%s/lock.png`, and the entry
image (`loading box image`, `loading entry`, `loading lock image`) for
its password dialog. The reference theme ships all three plus
`bullet.png`. The Vyra theme ships none of them. The TinyCore Plymouth
guide — a from-scratch two-step theme walkthrough — explicitly creates
1×1 transparent `box.png bullet.png entry.png lock.png` as a required
step for a two-step theme. Whether the plugin loads these eagerly at
theme setup or lazily at the first password prompt is not proven from
static evidence; if eager, their absence is a load failure. Either way
they are missing files the plugin expects.

### Defect 3 — Fonts that do not exist (`Inter 12`, `Inter Bold 30`)

`vyra.plymouth` specifies `Font=Inter 12` and `TitleFont=Inter Bold 30`.
Inter is not installed in the image (WIRING_PLAN T10: fonts not
installed, not supplied) and not in the initramfs — `fc-match`
substituted DejaVu at populate time. The reference themes either name
an installed font (spinner: `Cantarell 12`) or specify no font at all
(charge). A font the system cannot resolve is a needless load-time
risk. (The initramfs has no fontconfig, so at boot the label plugin
falls back to the `Plymouth.ttf` symlink; substitution probably saves
it, but it is an unforced risk.)

A fourth, low-probability hygiene item: the `Description` line contains
an em-dash (U+2014). Non-ASCII in `.plymouth` values is used by shipped
themes (localized `Name[]` entries), so this is almost certainly
harmless — but it costs nothing to replace with a plain hyphen while
the file is being edited.

**What is NOT a defect:** the missing `default.plymouth` symlink (§2/§3);
the `Theme=bgrt` in `plymouthd.defaults` (that is the distro fallback,
correctly overridden by `plymouthd.conf`); the kernel command line
(`rhgb` is present); the dracut/Titanoboa pipeline (§4).

## 7. Fix options, ranked

All options change theme files only (plus, where noted, the Containerfile
lines that copy them). None changes the build pipeline, the kernel, or
dracut. **None has been applied; the approach needs the owner's approval.**

### Option 1 — Complete the Vyra theme (RECOMMENDED)

Fix all three defects in one pass, rebuild, retest.

Exact changes (all in the repo, branch `visual-assets-batch-01`):

1. `vyra-branding/batch-01/` — add `vyra-watermark.png`: a copy of the
   D1 wordmark (`vyra-plymouth-logo.png`) under the name the plugin
   loads. (The D1 file is 260×139 with transparency; the plugin centres
   it via `WatermarkHorizontalAlignment`/`WatermarkVerticalAlignment` —
   add both keys to `vyra.plymouth`, `.5` / `.5`, matching the logo's
   centred placement. Note the wordmark is small at native size; do not
   upscale per the Batch 01 plan.)
2. `vyra-branding/batch-01/` — add `box.png`, `entry.png`, `lock.png`,
   `bullet.png`: minimal transparent images (1×1, per the TinyCore
   pattern) so the plugin's expected files exist. A later pass can draw
   proper gold-styled dialog art; transparent placeholders unblock the
   load without inventing art.
3. `vyra-branding/batch-01/vyra.plymouth` — replace `Font=Inter 12` /
   `TitleFont=Inter Bold 30` with an installed font (e.g. `Cantarell 12`
   / `Cantarell Light 30`, as the spinner theme uses — Cantarell is in
   the image), or delete both keys so the plugin uses its default.
   Replace the em-dash in `Description` with a plain hyphen.
4. `Vyra-Foundation/Containerfile`, Phase B RUN — copy the four new
   files into `/usr/share/plymouth/themes/vyra/` alongside the existing
   `vyra.plymouth` + `logo.png` copies. No other RUN changes.

- **Size:** ~18 KB (the watermark is a copy of the existing D1 file;
  the dialog images are 1×1). Negligible against the ISO budget.
- **Risk:** low. Theme files only; if the theme still fails to load,
  the boot falls back to the text theme exactly as today — no
  regression possible from these files.
- **Verification:** (a) `lsinitrd` on the next ISO shows
  `watermark.png`, `box.png`, `entry.png`, `lock.png` under
  `usr/share/plymouth/themes/vyra/`; (b) the next boot test's Plymouth
  screenshot shows the Obsidian background + gold wordmark + gold
  progress bar instead of the three dots.

### Option 2 — Capture the Plymouth debug log (DIAGNOSTIC — do it with the next boot test regardless)

If Option 1 does not fix it, the exact failure line is needed. At the
GRUB menu of the next boot test, press `e`, append `plymouth.debug` to
the `linux` line (this writes `/var/log/plymouth-debug.log` in the live
session), boot, then read the log from Konsole. The log will contain
one of the daemon's strings — `Loading boot splash theme 'vyra'`,
`Theme vyra not found`, or a plugin-load error — which names the fatal
step. No image change is needed for this step; it is a boot-time GRUB
edit. **Do this in the run-26 boot test even if Option 1 is applied,
so a failure is diagnosable instead of silent.**

### Option 3 — Rebuild the theme from the charge template (if Option 1 fails)

Copy `charge.plymouth` + its five files verbatim as the starting point,
then change only `BackgroundStartColor`/`BackgroundEndColor` to
`0x050505`, `ProgressBarForegroundColor` to `0xDCAE43`, and add
`watermark.png`. This isolates whether the failure is in the Vyra theme
file's structure/content vs the two-step plugin itself. More churn than
Option 1 for the same likely outcome; only worth it if Option 1 +
debug log point at the file rather than the missing assets.

### Option 4 — Re-skin the spinner theme instead (NOT recommended)

Change `ModuleName` to `spinner` and supply the spinner theme's
animation/throbber frames. Different plugin, different image
requirements — it sidesteps the two-step load path entirely. But it
abandons the designed two-step look (centred wordmark + progress bar)
for a rotating throbber, and the spinner plugin's image requirements
are larger (36 animation + 30 throbber frames). Only if two-step
proves unfixable.

## 8. Cheapest verification (no full boot test)

The `lsinitrd`-style check from §2 can be re-run on any future ISO
without booting it: extract `/IMAGES/PXEBOOT/INITRD.IMG` from the ISO
(`pycdlib`), decompress the zstd stream after the early-microcode
cpio, list the newc entries, and confirm
`usr/share/plymouth/themes/vyra/` contains `vyra.plymouth`,
`logo.png`, `watermark.png`, `box.png`, `entry.png`, `lock.png`, and
that `etc/plymouth/plymouthd.conf` still says `Theme=vyra`. That check
takes ~2 minutes and proves the theme is embedded; it cannot prove
plymouthd will load it — only a boot (with `plymouth.debug`, Option 2)
proves that.

## 9. Honest limits

- **The exact fatal defect is not proven.** Static evidence proves the
  theme is embedded, the config is right, and the theme has three
  defects — but which of them (if any) makes `load_theme` fail can only
  be settled by the Plymouth debug log from a boot (Option 2). Option 1
  fixes all three at once precisely because the single culprit cannot
  be isolated statically.
- The text-theme identification rests on the "3 box countdown"
  description, the daemon's hardcoded
  `/usr/share/plymouth/themes/text/text.plymouth` fallback path, and the
  byte-identical splash across runs with and without the Vyra theme. The
  #2e3436 background was measured; it is attributed to the text plugin
  by that match, not by reading the text plugin's source.
- The dracut `45plymouth` module-setup.sh itself was not re-fetched in
  this pass (the GitLab fetch was denied); the mechanism is established
  from the Fedora-shipped `plymouth-populate-initrd` script it calls,
  which was read in full from the Fedora 45 RPM, and from the initramfs
  contents, which match that script's behaviour exactly.
- Versions are a November 2026 snapshot: Plymouth 26.134.222-6.fc45,
  dracut 111-5.fc45. Re-check at time of use.

## 10. Sources

- Run-25 ISO initramfs, inspected directly (method in §2).
- `Vyra-Foundation/Containerfile` Phase B RUN; `iso_files/configure_iso.sh`
  lines 43–50; `installer/Containerfile.live`; `installer/iso.yaml`.
- `vyra-branding/batch-01/WIRING_PLAN.md` §2; `vyra-branding/batch-01/vyra.plymouth`.
- Titanoboa `build_iso.sh` line 45 and `main.sh` lines 21–24, pinned
  `5c457c3d0518bd17e754be0fd98a60d29d26abb4` (copy, don't regenerate).
- Fedora 45 RPMs, downloaded from `dl.fedoraproject.org` and extracted
  with a Python RPM parser: `plymouth-26.134.222-6.fc45`,
  `plymouth-scripts-26.134.222-6.fc45` (`plymouth-set-default-theme`,
  `plymouth-populate-initrd`), `plymouth-plugin-two-step-26.134.222-6.fc45`
  (`two-step.so`, strings + `readelf -d`), `plymouth-theme-charge-26.134.222-6.fc45`,
  `plymouth-theme-spinner-26.134.222-6.fc45` (incl. `bgrt.plymouth`).
- Dracut `45plymouth` module behaviour: dracut-ng search results
  (module renumbered from `50plymouth`; `install()` calls
  `plymouth-populate-initrd -t`).
- TinyCore Linux wiki, "boot_splash" — two-step theme guide (creates
  1×1 `box.png bullet.png entry.png lock.png`; `plymouth.debug=file:…`
  for the debug log).
- `first-run/WALKTHROUGH.md` run-23/24/25 Plymouth verdicts;
  `first-run/run24-02-plymouth.png` (background #2e3436 measured with PIL).
