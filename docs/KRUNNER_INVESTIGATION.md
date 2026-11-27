# KRunner Failure — Investigation

Date: 2026-11-27. Status: research only — no code changed, no build triggered.
Scope: why KRunner (Alt+F2) fails in the Vyra OS live session (runs 24/25), and
what the portal-registration error in the run-25 log actually means.

## 0. Bottom line

There are **two separate failures, not one**, and the error message that looks
like the cause is a **red herring**:

1. **D-Bus activation fails — "startup job failed" (runs 11, 24, 25 boot 1).**
   Top hypothesis, strongly supported: the systemd user unit
   `plasma-krunner.service` has **`TimeoutSec=5sec`**. D-Bus activation routes
   through systemd, and krunner must claim the bus name `org.kde.krunner`
   within 5 seconds or systemd kills the start job. Under QEMU TCG, krunner
   startup takes far longer than 5 s. The timeout has **not** been confirmed
   by a captured journal line — the confirming check is in §6.
2. **Alt+F2 does not summon an already-running daemon (run 25 boot 3).**
   With krunner started manually (outside systemd, so no timeout), Alt+F2
   still produced no window, and plain `krunner` (which should show its
   window immediately) showed none in the two screenshots taken 1–2 min
   after start. **Unresolved.** Candidates: QML window still loading under
   TCG, kglobalacceld not invoking the running instance, or a
   layer-shell/compositor issue. Needs the diagnostics in §6.
3. **The portal error is cosmetic and non-blocking.** Qt registers the app ID
   `org.kde.krunner` with xdg-desktop-portal; the portal looks it up in
   `/usr/share/applications/`; krunner has no desktop file there (by upstream
   design — its desktop file lives in `/usr/share/kglobalaccel/`); the lookup
   fails and Qt logs a warning. The daemon stays alive after the warning.
   KDE bug 512650 documents the identical error for other KDE apps and
   states explicitly that the operation still works.

## 1. Failure history (corrected)

The run-24 walkthrough section claims "KRunner worked in run #23 boot 2".
**That claim is wrong**, and it matters because it framed this as a
run-23→24 regression. The run-23 record shows:

- Run 23 boot 1: launcher, Konsole, System Settings verified. KRunner was
  never exercised as a standalone check.
- Run 23 boot 2: the desktop never rendered (black background, no panel).
  Alt+F2 "produced no change — the session is unresponsive to the desktop
  shell" and "Alt+F2 dead". KRunner did not work in boot 2; nothing worked.

Corrected history:

| Run | Result |
|---|---|
| Run 11, attempt 3 | FAIL — "Could not activate remote peer 'org.kde.krunner'" (under installer load; kwin 34% CPU, plasmashell 861 MB RSS) |
| Run 23 | NOT TESTED as a standalone check (boot 1: not exercised; boot 2: desktop never rendered) |
| Run 24, boot 1 | FAIL — System Notification "Launching KRunner (Failed) — Could not activate remote peer 'org.kde.krunner': startup job failed" (`run24-10-launcher.png`) |
| Run 25, boot 1 | FAIL — Alt+F2 produced nothing; `pgrep -af krunner` empty |
| Run 25, boot 3 | FAIL — Alt+F2 no window and no visible error after ~50 s; a notification bell appeared afterwards but the popup would not open, so its text was not read. Manual `krunner` starts the daemon (MESA-EGL warnings, then the portal error); Alt+F2 **still** did not summon the window (`run25c-14` through `run25c-19`) |

So this is **not a run-23→24 regression**. It is an intermittent,
load-dependent failure present since run 11, now with a concrete mechanism
for the activation half (§4) and an unresolved second half (§5).

## 2. What is actually installed (verified from the RPMs)

Verified by parsing the RPM headers of the exact Fedora 45 builds listed in
the image package list (`artifacts/vyra-os-0.1.0-dev-packages.txt`) — a
small Python RPM-header parser, header metadata only, no payload extraction.
Downloads from kojipkgs.fedoraproject.org (the Fedora build artifacts).

| Package (version in image) | KRunner-relevant files |
|---|---|
| kf6-krunner-6.32.0-1.fc45 | Library only: `/usr/lib64/libKF6Runner.so.6`. **No binary, no D-Bus service, no desktop file.** (This is the framework library, not the app.) |
| plasma-workspace-6.8.3-1.fc45 | `/usr/bin/krunner`, `/usr/share/dbus-1/services/org.kde.krunner.service`, `/usr/lib/systemd/user/plasma-krunner.service`. **No `/usr/share/applications/org.kde.krunner.desktop`. No files under `/usr/share/kglobalaccel/`.** |
| plasma-workspace-libs-6.8.3-1.fc45 | `/usr/share/kglobalaccel/org.kde.krunner.desktop`, krunner runner plugins (`/usr/lib64/qt6/plugins/kf6/krunner/*.so`). |
| plasma-workspace-common-6.8.3-1.fc45 | Licenses only. |
| xdg-desktop-portal-1.22.1-2.fc45, xdg-desktop-portal-kde-6.8.3-1.fc45, xdg-desktop-portal-gtk-1.15.3-6.fc45, kglobalacceld-6.8.3-1.fc45, qt6-qtbase-6.11.2-3.fc45 | All present. |

Conclusion: **no package is missing.** This is a runtime/config issue, not
a missing-package issue. The binary, the D-Bus service file, the systemd
unit, and the global-shortcut definition are all in the image.

## 3. The activation chain (how Alt+F2 is supposed to work)

Traced from the upstream plasma-workspace v6.8.3 source
(KDE/plasma-workspace, tag v6.8.3), which matches the image version:

1. **Shortcut definition** — `/usr/share/kglobalaccel/org.kde.krunner.desktop`
   (from `krunner/org.kde.krunner.desktop.cmake`):
   `DBusActivatable=True`, `X-DBUS-ServiceName=org.kde.krunner`,
   `X-KDE-Shortcuts=Alt+Space,Alt+F2,Search`. kglobalacceld reads this file
   and owns the Alt+F2 binding.
2. **Keypress** — Alt+F2 → kglobalacceld → D-Bus activation of
   `org.kde.krunner`.
3. **D-Bus service file** — `/usr/share/dbus-1/services/org.kde.krunner.service`,
   generated by `ecm_generate_dbus_service_file(NAME org.kde.krunner
   EXECUTABLE "/usr/bin/krunner --daemon" SYSTEMD_SERVICE
   plasma-krunner.service ...)`. The ECM module writes
   `SystemdService=plasma-krunner.service` into the file (verified in
   extra-cmake-modules source), so dbus-daemon hands activation to systemd
   instead of spawning the binary directly.
4. **systemd unit** — `/usr/lib/systemd/user/plasma-krunner.service`
   (from `krunner/plasma-krunner.service.in`):
   ```
   [Unit]
   Description=KRunner
   PartOf=graphical-session.target
   [Service]
   ExecStart=/usr/bin/krunner --daemon
   Type=dbus
   BusName=org.kde.krunner
   TimeoutSec=5sec
   Slice=background.slice
   Restart=no
   ```
5. **Daemon startup** — krunner claims `org.kde.krunner` on the session
   bus. `KDBusService(KDBusService::Unique)` in `krunner/main.cpp` makes a
   second activation request go to the existing instance, which calls
   `updateVisibility()` → `view.toggleDisplay()` — i.e. the window shows.
   Plain `krunner` (no `--daemon`) also calls `toggleDisplay()` at startup,
   so it should show its window immediately; `--daemon` starts hidden.

## 4. Hypothesis 1 (top): the 5-second systemd timeout kills activation under TCG

**Mechanism.** Per the systemd.service man page, `TimeoutSec=` is shorthand
for `TimeoutStartSec=` + `TimeoutStopSec=`. A `Type=dbus` unit is considered
started only once it claims `BusName=`; if it does not claim the name
within `TimeoutStartSec`, the start job fails and the process is terminated
(default `TimeoutStartFailureMode=terminate` → SIGTERM). The caller then
sees the activation fail — the "startup job failed" language in the
run-24 notification is systemd's job-failure wording.

**Why it fires here.** KRunner startup is a Qt Quick application: it loads
Qt, the QML engine, `RunCommand.qml`, and all runner plugins, then registers
with the portal. Under QEMU TCG (8–12× slower than hardware), that takes far
longer than 5 seconds of wall-clock. Measured slowness in the same sessions:
Konsole took ~105 s to appear (run 11), the application launcher ~50 s to
render (run 25), Dolphin ~2.5 min, Discover ~3 min. A 5-second budget is
essentially unmeetable under TCG.

**Evidence for:**
- The error text ("Could not activate remote peer … startup job failed")
  matches a systemd start-job failure, not a missing binary or a crash.
- The failure occurs under load in every instance: run 11 attempt 3 (under
  installer load), run 24 boot 1 (early session, plasmashell at 861 MB RSS),
  run 25 boot 1 (early session).
- Manual start works: run outside systemd, there is no timeout, so the
  daemon starts (slowly) and stays alive.
- The unit's `Restart=no` means a timed-out activation is not retried by
  systemd — one failure and the shortcut is dead until something else
  starts krunner.

**Evidence NOT yet captured (honest gap):** no `journalctl --user -u
plasma-krunner` output was recorded in any run, so the timeout firing has
not been directly observed (e.g. a "start operation timed out" line). The
confirming check is in §6. Until that line is seen, this is the top
hypothesis, not a proven root cause.

**Scope note.** On real hardware krunner starts in well under 5 s, so this
timeout may never fire there — the defect as observed may be TCG-only for
the activation half. That does not make it ignorable: ENTRY-class hardware
(slow disk, 4 GB RAM) can also be slow to start, and a 5 s budget is tight
for a cold start. It also does not explain failure 2 (§5).

## 5. Hypothesis 2 (unresolved): Alt+F2 does not summon a running daemon

In run 25 boot 3, krunner was started manually from a terminal. The
screenshots (`run25c-18-krunner-manual.png` 07:31, `run25c-19-krunner-window.png`
07:32) show the process alive in the foreground (no shell prompt returned)
with only MESA-EGL warnings and the "Connecting to deprecated signal
QDBusConnection::serviceOwnerChanged" line — and **no KRunner window on the
desktop**. Alt+F2 still did not summon it.

Candidate explanations (unranked — no evidence distinguishes them yet):

- **(a) The QML window was still loading.** Plain `krunner` calls
  `toggleDisplay()` at startup, but the window only appears once the QML
  engine has loaded `RunCommand.qml` and the compositor has mapped it.
  Under TCG that can take minutes (the launcher took ~50 s to render).
  The two screenshots are only 1–2 min after start; the window may simply
  not have finished appearing. The portal error, which is printed during
  early init, only appears in the later shot (`run25c-25`, 07:44) — the
  process was still initialising ~14 min after start, which supports
  extreme slowness rather than a hang.
- **(b) kglobalacceld is not invoking the running instance.** No `pgrep
  -af kglobalacceld` was recorded in any run, so whether the global
  shortcut daemon is alive in the live session is unknown. (The Meta key
  opening the launcher is ambiguous evidence — the launcher also opens by
  panel click.) If kglobalacceld is down, or if it failed to load the
  binding, Alt+F2 reaches nothing even with the daemon running.
- **(c) Layer-shell / compositor issue.** KRunner's window is a layer-shell
  surface. The session already shows compositor strain under virtio-gpu /
  llvmpipe (MESA-EGL "failed to create dri2 screen", ZINK "failed to
  choose pdev" in the same logs; run 11 attempt 1 had KWin unable to get
  an output). A window that fails to map would look exactly like this.

What this is **not**: it is not the portal error (§6 of the mechanism
below) — the portal warning is printed and the process continues. It is
not a missing shortcut definition — the kglobalaccel desktop file is in
the image (§2).

## 6. The portal error — mechanism and why it is a red herring

**What happens, step by step:**

1. KRunner is a Qt application (Qt 6.11.2 in the image). On startup, Qt's
   QPA services layer registers the application with xdg-desktop-portal
   so the portal knows the app's identity. The app ID it passes is
   `org.kde.krunner` (from `QGuiApplication::desktopFileName()`).
2. xdg-desktop-portal looks up that ID in the desktop-file database —
   `/usr/share/applications/` (and `$XDG_DATA_DIRS/applications`). There
   is no `org.kde.krunner.desktop` there, so the lookup fails.
3. The portal returns
   `QDBusError("org.freedesktop.portal.Error.Failed", "Could not register
   app ID: App info not found for 'org.kde.krunner'")`, and Qt logs
   `qt.qpa.services: Failed to register with host portal …` as a warning.
   (The `qt.qpa.services` logging category is declared in Qt's
   `qplatformservices.cpp`; the exact call site in the Qt 6.11 tree was
   not pinned down — searched `qguiapplication.cpp` (6.11 and dev),
   `qxdgdesktopportaltheme.cpp`, `qwaylanddisplay.cpp`,
   `qwaylandintegration.cpp`, `qplatformservices.cpp` without finding the
   string. This does not affect the conclusion.)
4. Qt logs the warning and **continues**. The daemon stays alive — proven
   by the run-25 evidence itself: the manually started krunner printed
   the warning and kept running.

**Why there is no desktop file in `/usr/share/applications/`:** by upstream
design. KRunner's desktop file is installed to
`/usr/share/kglobalaccel/org.kde.krunner.desktop` (see §3), because its
purpose is the global-shortcut definition, not appearing in the app menu.
The portal only searches the applications directories, so it cannot find
it there. (Side note from the GNOME portals blog: for host apps,
xdg-desktop-portal also derives the app ID from the systemd unit name, and
D-Bus-activated apps get `dbus-`-prefixed unit names, so the exposed app ID
is empty — a second reason the portal cannot identify krunner.)

**Upstream confirmation that this is non-blocking:**

- **KDE bug 512650** — "Error message when executing `xdg-open`": the
  byte-identical error for `org.kde.kioclient` on Fedora 43 / Plasma 6.5.3
  / Qt 6.10.1. The report states: "Note: The `xdg-open` command still
  functions correctly and opens the target directory as expected. The
  output is a non-blocking error message." (Read via the mail-archive
  mirror; bugs.kde.org itself is blocked from this environment.)
  The same thread notes the issue appeared after a Fedora upgrade and
  mentions a fix in Plasma 6.5.5 — but users still reported it afterwards
  for other apps (`kstart`, and with an empty app ID `org.kde.`), so the
  fix was app-specific, not general. KRunner on Plasma 6.8.3 still prints
  it.
- **EndeavourOS forum** ("Xdg-Open Works, But Shows an Error Message"):
  same error for `org.kde.kioclient` on Plasma 6.5.3/Wayland; xdg-open
  works, only the error is shown; fixed (cosmetically) by creating
  `/usr/share/applications/org.kde.kioclient.desktop`.
  <https://forum.endeavouros.com/t/xdg-open-works-but-shows-an-error-message/76803>
- **Manjaro forum**: same error and same workaround for kioclient.
  <https://forum.manjaro.org/t/xdg-open-throws-filed-to-register-with-host-portal-error/183762>
- **Arch forum (krdpserver)**: same error for `org.kde.krdp-server`;
  worked around by copying the desktop file and adding
  `X-DG-APP-ID=org.kde.krdp-server`.
- **Gentoo bug 984260 (Zoom)**: "Could not register app ID: App info not
  found for 'Zoom'" — fixed by installing the desktop entry with the
  matching name. <https://bugs.gentoo.org/show_bug.cgi?format=multiple&id=984260>
- **SeisComP forum**: "The message from `qt.qpa.services` comes from Qt
  and is not an error for the application. The fix you mentioned is in the
  code at Github but hasn't reached a release yet."

**Conclusion on the portal error:** it is a known, upstream, cosmetic
warning affecting KDE apps/daemons that have no `/usr/share/applications/`
desktop file. It does not prevent krunner from running and does not explain
either Alt+F2 failure. Do not treat it as the root cause. It is still worth
silencing (fix option 2, §7) because it pollutes the log and misleads
diagnosis — which is exactly what happened here.

## 7. Fix options, ranked

### Option 1 — Raise the systemd start timeout for plasma-krunner (recommended first)

- **What:** a drop-in `/etc/systemd/user/plasma-krunner.service.d/vyra-timeout.conf`
  with `TimeoutStartSec=60s` (or `TimeoutSec=60s`). Applied by the
  Containerfile (a Vyra-owned `/etc` drop-in, three-way merged across
  bootc updates — the same pattern as the RAM Expansion policy config).
  No upstream file is modified.
- **Fixes:** hypothesis 1 — D-Bus activation under TCG and on slow
  ENTRY-class hardware. Does not fix hypothesis 2.
- **Risk:** low. Only affects krunner's start timeout; on fast hardware the
  timeout never comes into play. It diverges from upstream's 5 s, and it
  masks genuinely hung startups for 60 s — acceptable for a launcher.
- **Verification (single check):** in the next boot test, press Alt+F2
  once the desktop is up and confirm the KRunner window appears. Also
  confirm no `plasma-krunner` timeout lines in
  `journalctl --user -u plasma-krunner -b`.

### Option 2 — Ship `/usr/share/applications/org.kde.krunner.desktop` (cosmetic, do alongside option 1)

- **What:** install a `NoDisplay=true` desktop file named
  `org.kde.krunner.desktop` into `/usr/share/applications/` (content: the
  upstream file minus the `X-KDE-Shortcuts` lines, or the upstream file
  verbatim — it is already `DBusActivatable`). This is the exact workaround
  the kioclient/kstart/krdp-server threads use.
- **Fixes:** only the portal warning. It does **not** fix Alt+F2.
- **Risk:** very low. `NoDisplay=true` keeps it out of the app menu. The
  kglobalaccel copy remains the shortcut authority.
- **Verification:** run `krunner` manually in the next boot test and confirm
  the portal warning no longer appears.

### Option 3 — Diagnose before changing anything (required for hypothesis 2)

Run these in the next boot test, before or alongside options 1–2:

1. `pgrep -af kglobalacceld` — is the global shortcut daemon alive?
2. `systemctl --user status plasma-krunner` and
   `journalctl --user -u plasma-krunner -b` — look for "start operation
   timed out" (confirms hypothesis 1) or a clean start.
3. After a manual `krunner` start, wait **5 minutes** (not 1–2) and watch
   for the window — distinguishes "still loading" from "never shows".
4. With the daemon running, invoke it directly over D-Bus
   (e.g. `qdbus org.kde.krunner /App org.kde.krunner.App.display`, or the
   `display` method on the KRunner D-Bus interface) — distinguishes "the
   shortcut path is broken" from "the window cannot show".
5. `grep -i krunner ~/.config/kglobalshortcutsrc` — is the Alt+F2 binding
   present in the session config?

### Option 4 — Retest on real hardware / with KVM (no code change)

- **What:** run the same Alt+F2 check on real hardware or KVM, where
  startup is fast.
- **Fixes:** nothing by itself, but it separates "TCG timing" from "image
  defect" for hypothesis 1. It does **not** resolve hypothesis 2, which
  is unexplained even with the daemon running.
- **Risk:** none, but it is not a fix — do it as a verification step, not
  instead of options 1–3.

### Not recommended

- **Patching Qt or krunner to skip portal registration.** Upstream issue,
  upstream fix pending; patching Qt in the image is out of scope and would
  fork a core library for a cosmetic warning.
- **Removing the systemd unit / switching to direct D-Bus activation.**
  Diverges from upstream for no benefit; the timeout is the problem, not
  the systemd routing.
- **Calling the defect "TCG-only" and closing it.** Hypothesis 1 may be
  TCG-only, but hypothesis 2 is unexplained and the failure has recurred
  across four runs.

## 8. Honest limits

- The 5-second timeout firing has **not** been directly observed in a
  journal; it is inferred from the unit file + the error text + TCG
  slowness. The confirming check is option 3, step 2.
- Hypothesis 2 (Alt+F2 not summoning a running daemon) is **unresolved**;
  the three candidates in §5 are not distinguished by the available
  evidence.
- The exact Qt call site for the portal registration was not pinned down
  (searched the Qt 6.11 tree files listed in §6). The mechanism is
  established by the error text, the category, and the upstream bug
  reports; the file/line is not.
- KDE bug 512650 was read via the mail-archive mirror
  (<https://www.mail-archive.com/kde-bugs-dist@kde.org/msg1116482.html>);
  bugs.kde.org itself is blocked from this environment, so the bug's
  current status/resolution was not re-checked live.
- The run-25 notification's exact text was never read (the popup would
  not open); the run-24 text is the evidence for the "startup job failed"
  wording.

## 9. Sources

- RPM file lists (header parse, kojipkgs.fedoraproject.org):
  kf6-krunner-6.32.0-1.fc45, plasma-workspace-6.8.3-1.fc45,
  plasma-workspace-libs-6.8.3-1.fc45, plasma-workspace-common-6.8.3-1.fc45.
- Fedora plasma-workspace.spec (f45 branch, src.fedoraproject.org cgit):
  line 641, `%{_kf6_datadir}/kglobalaccel/org.kde.krunner.desktop` in
  `%files libs`.
- Upstream plasma-workspace v6.8.3 (github.com/KDE/plasma-workspace):
  `krunner/CMakeLists.txt`, `krunner/main.cpp`,
  `krunner/org.kde.krunner.desktop.cmake`,
  `krunner/plasma-krunner.service.in`.
- extra-cmake-modules master:
  `modules/ECMGenerateDBusServiceFile.cmake` (writes `SystemdService=`).
- systemd.service man page (freedesktop.org): `TimeoutSec=`,
  `TimeoutStartSec=`, `TimeoutStartFailureMode=`, `Type=dbus`/`BusName=`.
- Qt 6.11 tree (github.com/qt/qtbase): `src/gui/kernel/qguiapplication.cpp`
  (`desktopFileName`), `src/gui/kernel/qplatformservices.cpp`
  (`qt.qpa.services` category); portal call site not pinned down (see §8).
- KDE bug 512650 (mail-archive mirror):
  <https://www.mail-archive.com/kde-bugs-dist@kde.org/msg1116482.html>
- EndeavourOS forum:
  <https://forum.endeavouros.com/t/xdg-open-works-but-shows-an-error-message/76803>
- Manjaro forum:
  <https://forum.manjaro.org/t/xdg-open-throws-filed-to-register-with-host-portal-error/183762>
- Gentoo bug 984260:
  <https://bugs.gentoo.org/show_bug.cgi?format=multiple&id=984260>
- GNOME blogs, Ignacy Kuchciński, "Portals":
  <https://blogs.gnome.org/ignapk/category/portals/>
- Vyra evidence: `first-run/WALKTHROUGH.md` (run 11 attempt 3, run 23
  boots 1–2, run 24 §KRunner, run 25 §8); screenshots `run24-10-launcher.png`,
  `run25c-14-krunner.png` through `run25c-19-krunner-window.png`,
  `run25c-25-installer.png`.
