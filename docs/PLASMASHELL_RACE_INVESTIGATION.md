# Vyra OS — plasmashell / kactivitymanagerd startup race investigation

**Date:** 2026-11-27
**Status:** Investigation complete (research + documentation only). No code, Containerfile,
or image changes made. No push, no VM, no build.
**Scope:** the run-25 defect in which boots 1–2 never rendered the desktop, while boot 3
rendered fully. The same black-desktop symptom also occurred in run 23 boot 2.

---

## 0. Executive summary

**Top hypothesis (H1): the shell's load gate depends on a single-shot asynchronous
D-Bus reply that has no retry and no error log.** `ShellCorona::load()` refuses to load
the desktop until `KActivities::Controller::serviceStatus()` reports `Running`. That
status only becomes `Running` when the asynchronous `ListActivitiesWithInformation`
D-Bus call to kactivitymanagerd returns successfully. Under TCG the daemon starts
slowly, the first `load()` call finds the service `NotRunning` and aborts with the
logged warning — and if the follow-up async reply then fails or times out, the
status stays stuck at `Unknown` forever, the retry signal never fires, and the
shell sits unloaded indefinitely while systemd still reports the service `active`.
That is exactly the observed journal: one "Aborting shell load" message, then
silence, a live-but-unloaded shell process, and a black desktop.

**Recommended fix (F1): order kactivitymanagerd before plasmashell in systemd.**
Ship a drop-in for `plasma-plasmashell.service` with
`After=plasma-kactivitymanagerd.service` + `Wants=plasma-kactivitymanagerd.service`.
systemd then starts KAMD first and — because KAMD's unit is effectively
`Type=dbus` — waits until it has claimed `org.kde.ActivityManager` before starting
the shell, so the load gate is already satisfied when the shell checks it. This
is a low-risk ordering change (no code, no upstream patch), and it makes startup
deterministic on any hardware speed. Complement with F2 (raise the 40 s start
timeout) for the separate cold-start timeout. See §6 for the ranked list.

**What is still unresolved:**
- The exact point of failure inside H1 is not pinned down from the evidence: whether
  the async `ListActivitiesWithInformation` reply timed out/failed, or whether the
  `Manager::Running` transition produced no `Consumer` emission (both leave the
  status stuck at `Unknown`). The diagnostic in §6.3 (KActivities debug logging)
  distinguishes them in one boot.
- The cause of the aborted shell's CPU spin (13 min 18 s CPU over 25 min wall,
  ~53% of one core) is not identified. It is a symptom, not yet a diagnosis.
- Whether the race triggers at hardware/KVM speed is unknown — see §7.

**The layout.js / Phase A4 cause is refuted** (§5, H3): `layout.js` runs inside
`loadLayout()`, which is called from `load()` *after* the KAMD gate passes. In the
failing boots `load()` aborted before `loadLayout()` ever ran, so the layout never
executed. The same black-desktop symptom also occurred in run 23 boot 2, before
Phase A4 existed.

---

## 1. The observed failure

### 1.1 Run 25, boots 1–2 (byte-identical pattern)

ISO `live-iso-run25/Vyra-OS-Live.iso`, QEMU TCG 1280×800, `-m 4096 -smp 2`, no disk.
Full record: `first-run/WALKTHROUGH.md` §"Live ISO — run #25" (line 919), journal
screenshots `run25-26/29/30-plasmajournal*.png`, `run25b-10/11/12-*.png`.

**Boot 1** (05:58–06:36 UTC):

| Time (UTC) | Event |
|---|---|
| ~06:04:23 | First `plasma-plasmashell.service` start |
| 06:05:03 | `start operation timed out, terminating; Failed with result 'timeout'` — 3.321 s CPU over 40.394 s wall, 8.2 MB peak. systemd: `Scheduled restart job, restart counter is at 1.` |
| 06:05:04–18 | Restart: `Starting plasma-plasmashell.service` → `Started` |
| 06:05:42 | `plasmashell[1636]: Aborting shell load: The activity manager daemon (kactivitymanagerd) is not running.` + the custom-prefix D-Bus hint |
| 06:06:03–11 | MESA-EGL warnings, `MESA: error: ZINK: failed to choose pdev`, `egl: failed to create dri2 screen`, `Member visible of the object PlasmaQuick::Dialog overrides a member of the base object` |
| 06:06:56 | `Activity added twice "45b03b09-cbda-4089-8bf2-9fbd62f00c23"` |
| 06:07:14 | `Failed to register with host portal QDBusError("org.freedesktop.DBus.Error.NoReply", ...)` |
| ~06:07 | `pgrep -af kactivitymanagerd` → `1668 /usr/libexec/kactivitymanagerd`; `systemctl --user is-active plasma-plasmashell` → `active` |
| ~06:07 | Manual `systemctl --user restart plasma-plasmashell` → new pid 2937, also did not paint within ~5 min |
| 06:30:09–11 | Service stopped: `Consumed 13min 18.029s CPU time over 25min 7.690s wall clock time, 214.1M memory peak` |
| 06:36 | QMP quit; desktop never painted |

**Boot 2** (06:36–~07:00 UTC): the same pattern to the second — first start
~06:42:31 → timeout 06:43:11 (3.720 s CPU / 40.523 s wall, 7.7 MB) → restart
06:43:11–28 → abort 06:43:52 (pid 1602) → `Activity added twice` 06:45:10 →
portal `NoReply` 06:45:12 → kactivitymanagerd pid 1642, plasmashell pid 1602
(`/usr/bin/plasmashell --no-respawn`) alive but nothing painted. Killed by a
host service restart ~07:00 UTC.

**Boot 3** (07:09–08:14 UTC) is the control: pid 1634 started cleanly — the
last 12 journal lines (`run25c-56-journal.png`, 07:18–08:00 UTC) show only
benign warnings (`QSqlQuery::value: not positioned on a valid record`,
`context kaput`, `No object for name "@DEFAULT_SOURCE@"`, a Wayland
popup-parent warning, one taskmanager `TooltipDelegate` TypeError). **No
timeout, no abort, no restart.** The same pid was still the running shell at
07:28 UTC, and the desktop (floating dock, gold-V Kickoff, dark hero) ran all
session.

### 1.2 Precedent: run 23 boot 2

Run 23 boot 2 (same ISO shape, pre-Phase-A4 layout) also never rendered the
desktop: after unlocking, "the background stayed pure black with no panel and
no desktop icons… the session is unresponsive to the desktop shell"
(`first-run/WALKTHROUGH.md`, run-23 section). Its cause was never diagnosed
(no journal was captured), so it is the same *symptom*, not a confirmed same
*cause* — but it shows black-desktop flakiness predates Phase A4. Run 24's
three boots all rendered. Failure rate under TCG across runs 23–25 is
roughly 3 of 8 boots (run 23: 1/2, run 24: 0/3, run 25: 2/3) — high and
variable, consistent with a timing race, not a deterministic bug.

### 1.3 What the failure is NOT (from the journal alone)

- The Welcome Center rendered in all three boots — it is a GTK app, not
  plasmashell, so it is unaffected.
- `kactivitymanagerd` **is** in the image (`kactivitymanagerd-6.8.3-1.fc45`)
  and **does** start (pid 1668 boot 1, pid 1642 boot 2) — just after the
  shell has already aborted.
- The shell process does **not** exit after aborting: systemd reports the
  service `active`, and the process stays alive (and spinning, §1.1) until
  stopped. From systemd's point of view nothing failed after the first
  timeout — so nothing restarts it into a working state.

---

## 2. The startup sequence (verified from source and the Fedora RPMs)

All version claims below are for the packages in the image
(`plasma-workspace-6.8.3-1.fc45`, `kactivitymanagerd-6.8.3-1.fc45`,
`dbus-broker-37-9.fc45`), verified against the Fedora 45 RPMs downloaded
from koji and the `Plasma/6.8` branch of `KDE/plasma-workspace` (the branch
Fedora 45's 6.8.3 is built from) and `master` of `KDE/plasma-activities`.

### 2.1 The systemd units (exact contents, from the Fedora 45 RPMs)

`plasma-plasmashell.service` — `/usr/lib/systemd/user/plasma-plasmashell.service`
(335 bytes, `plasma-workspace-6.8.3-1.fc45`):

```ini
[Unit]
Description=KDE Plasma Workspace
After=plasma-ksmserver.service
PartOf=graphical-session.target
StartLimitIntervalSec=60s
StartLimitBurst=3

[Service]
ExecStart=/usr/bin/plasmashell --no-respawn
Restart=on-failure
Type=dbus
BusName=org.kde.plasmashell
Slice=session.slice
TimeoutSec=40sec

[Install]
WantedBy=plasma-core.target
```

Three facts in this file explain the journal:

- **`Type=dbus` + `BusName=org.kde.plasmashell` + `TimeoutSec=40sec`** — systemd
  considers the service started only when the process claims the
  `org.kde.plasmashell` D-Bus name, and kills it if that has not happened
  within 40 s. That is the 06:05:03 / 06:43:11 "start operation timed out"
  (40.394 s / 40.523 s wall — the match is exact, not approximate).
- **`Restart=on-failure`** — the timeout kill is a failure, so systemd
  restarts the shell once (restart counter 1 in the journal). The second
  instance then hits the KAMD abort.
- **`StartLimitBurst=3` / `StartLimitIntervalSec=60s`** — three failures
  within 60 s would stop further restarts. This limit was *not* hit in run
  25, because the aborted second instance stayed alive (it had claimed the
  bus name, so systemd considered it started and healthy).

`plasma-kactivitymanagerd.service` — `/usr/lib/systemd/user/plasma-kactivitymanagerd.service`
(232 bytes, `kactivitymanagerd-6.8.3-1.fc45`):

```ini
[Unit]
Description=KActivityManager Activity manager Service
PartOf=graphical-session.target
Before=graphical-session.target

[Service]
ExecStart=/usr/libexec/kactivitymanagerd
BusName=org.kde.ActivityManager
Slice=background.slice
```

Notes: there is **no `[Install]` section** — the unit is *not* enabled by
default and nothing orders it before the shell. It is started purely by
D-Bus activation (see §2.2). `BusName=` implies `Type=dbus`, so systemd
waits for it to claim `org.kde.ActivityManager` when it is started.

`org.kde.ActivityManager.service` — `/usr/share/dbus-1/services/org.kde.ActivityManager.service`
(129 bytes, `kactivitymanagerd-6.8.3-1.fc45`):

```ini
[D-BUS Service]
Name=org.kde.ActivityManager
Exec=/usr/libexec/kactivitymanagerd
SystemdService=plasma-kactivitymanagerd.service
```

When D-Bus needs to activate `org.kde.ActivityManager`, it asks systemd to
start `plasma-kactivitymanagerd.service` rather than exec'ing the daemon
directly.

### 2.2 The D-Bus activation chain

1. `plasmashell` starts. `main()` (`shell/main.cpp`, `Plasma/6.8` branch)
   constructs a `KDBusService` (`KDBusService::Unique`) at line 395 — **before**
   `corona.init()` at line 398. `KDBusService` claims the `org.kde.plasmashell`
   D-Bus name synchronously in its constructor. This is what satisfies
   systemd's `Type=dbus` readiness.
2. The `ShellCorona` constructor creates the activities controller
   (`m_activityController(new KActivities::Controller(this))`).
   `KActivities::Controller` is a thin subclass of `Consumer`
   (`plasma-activities/src/lib/controller.cpp`); the real logic is in
   `Consumer` / `ActivitiesCache` / `Manager`.
3. Constructing the first `Consumer` creates the `ActivitiesCache` singleton,
   which creates the `Manager` singleton. `Manager::self()`
   (`plasma-activities/src/lib/manager_p.cpp`) checks
   `isServiceRegistered(org.kde.ActivityManager)`; if it is not registered,
   it issues an **asynchronous** `StartServiceByName` D-Bus call and sets its
   status to `Starting`. D-Bus (dbus-broker in this image) then asks systemd
   to start `plasma-kactivitymanagerd.service`; the daemon starts, opens its
   SQLite database, and claims `org.kde.ActivityManager`.
4. `Manager` watches the name with a `QDBusServiceWatcher`; when the owner
   appears it sets its status to `Running` and emits `serviceStatusChanged`.
   It also calls the daemon's `serviceVersion()` as a sanity check — if that
   call fails it logs `KActivities: FATAL ERROR: Failed to contact the
   activity manager daemon` and sets its status back to `NotRunning`
   (without emitting, in that path).
5. `ActivitiesCache::setServiceStatus()` maps the Manager status onto the
   Consumer status (see §2.3) and, on `Running`, fires the async activity
   list load.

### 2.3 The status machine — and the single point of failure

`Consumer::serviceStatus()` returns a cached value,
`d->cache->m_status` (`plasma-activities/src/lib/consumer.cpp`, L99–105),
and `serviceStatusChanged` is forwarded from the cache (L53). The status
enum is `NotRunning / Unknown / Running`
(`plasma-activities/src/lib/consumer.h`, L178–186).

`ActivitiesCache::setServiceStatus()` (`src/lib/activitiescache_p.cpp`,
L112–153):

```cpp
case Manager::NotRunning:  m_status = Consumer::NotRunning; break;
case Manager::Starting:    m_status = Consumer::Unknown;    break;
case Manager::Running:
    // will become running once loaded
    m_status = Consumer::Unknown;
    updateAllActivities();   // async CurrentActivity + ListActivitiesWithInformation
    break;
...
if (m_status != oldStatus) {
    Q_EMIT serviceStatusChanged(m_status);
}
```

And the only place the Consumer status ever becomes `Running` is the async
reply handler (`setAllActivities`, L396–425):

```cpp
m_status = Consumer::Running;
Q_EMIT serviceStatusChanged(m_status);
```

Three consequences, all verified from this source:

1. **The Manager's `Running` transition produces no Consumer emission when
   the cache was already `Unknown`.** `Starting → Unknown`, then `Running →
   Unknown` is *not a change*, so `setServiceStatus` emits nothing and
   `ShellCorona::load()` is not retried at that point. The retry depends
   entirely on the later async reply.
2. **The async reply is single-shot with no retry and no error log.**
   `updateAllActivities()` fires `CurrentActivity` and
   `ListActivitiesWithInformation` as async D-Bus calls; the reply handler
   (`passInfoFromReply`, L252–275) does nothing at all on an error reply
   (`if (!reply.isError()) { … }` — no else branch). If the call fails or
   times out, `m_status` stays `Unknown` forever, no signal fires, and
   nothing is logged.
3. **`load()` is silent for `Unknown`.** `ShellCorona::load()`
   (`shell/shellcorona.cpp`, `Plasma/6.8` branch, L1421–1463) prints the
   "Aborting shell load" warning only when the status is `NotRunning`; for
   `Unknown` it returns silently. That matches the journal exactly: one
   warning, then silence.

### 2.4 The shell's load gate

`ShellCorona::init()` (`shellcorona.cpp`, `Plasma/6.8` branch, L511–551):

```cpp
unload();
/*
 * we want to make an initial load once we have loaded the activities
 * _IF_ KAMD is running … it is valid for KAMD to not be running.
 * Potentially 2 async jobs … there is an issue where
 * m_activityController will start the kactivitymanagerd, as KAMD is
 * starting the serviceStatus will be "not running" … m_activityController
 * will change from "not running" to unknown, and might still be unknown
 * when the kscreen fetching is complete. … if that happens we want to
 * continue monitoring for state changes, and only finally load when it
 * is up.
 * See https://bugs.kde.org/show_bug.cgi?id=342431 be careful about changing
 * The unique connection makes sure we don't reload plasma if KAMD ever
 * crashes and reloads, the signal is disconnected in the body of load
 */
connect(m_activityController, &KActivities::Controller::serviceStatusChanged,
        this, &ShellCorona::load, Qt::UniqueConnection);
load();
```

`ShellCorona::load()` (L1421–1463):

```cpp
auto activityStatus = m_activityController->serviceStatus();
if (activityStatus != KActivities::Controller::Running
    && !qApp->property("org.kde.KActivities.core.disableAutostart").toBool()) {
    if (activityStatus == KActivities::Controller::NotRunning) {
        qCWarning(PLASMASHELL) << "Aborting shell load: The activity manager daemon (kactivitymanagerd) is not running.";
        qCWarning(PLASMASHELL) << "If this Plasma has been installed into a custom prefix, ...";
    }
    return;
}
disconnect(m_activityController, &KActivities::Controller::serviceStatusChanged, this, &ShellCorona::load);
// … sanitizeScreenLayout, loadLayout (runs layout.js), checkActivities, …
```

So the intended design is a retry: `load()` is called once directly, and
again on every `serviceStatusChanged` until the status is `Running`, at
which point the connection is disconnected and the layout loads. The design
assumes the status *will* eventually become `Running` and emit. In the
failing boots it never did.

### 2.5 Putting the two failures together

- **First instance (timeout):** cold start under TCG. Before `main()` reaches
  the `KDBusService` construction (line 395) it must load Qt, the QML engine
  libraries, fontconfig, and establish the KWayland connection. Under TCG
  that takes longer than the unit's 40 s `TimeoutSec`, so systemd kills it
  before it ever claims `org.kde.plasmashell`. This failure has nothing to
  do with KAMD — it is pure cold-start slowness.
- **Second instance (abort, then stuck):** warm page cache, so it reaches
  the bus-name claim and `load()` quickly — but KAMD is still starting
  (D-Bus activation → systemd → fork/exec → SQLite init, all slow under
  TCG), so `load()` finds `NotRunning`, prints the warning, and returns.
  The retry then depends on the chain in §2.3. The daemon does come up
  (pid 1668 / 1642), but the Consumer status never reaches `Running` —
  either the async activity-list reply failed/timed out (H1a) or the
  `Running` transition produced no emission and the reply path never
  completed (H1b). Either way the shell sits unloaded, `active` in systemd,
  burning CPU (§4) and never painting.

---

## 3. Why the retry never fires (the crux, in detail)

The retry has exactly one trigger: `serviceStatusChanged(Running)` emitted
by `ActivitiesCache::setAllActivities()`, which runs only when the async
`ListActivitiesWithInformation` D-Bus call returns successfully. Two ways
that trigger is lost, both consistent with the evidence:

- **H1a — the async reply fails or times out.** Under TCG the daemon answers
  slowly (it must open/create its SQLite database on the live session's
  overlay filesystem on first run). Qt's async D-Bus calls carry a timeout;
  on error `passInfoFromReply` silently drops the reply — no retry, no log,
  status stuck at `Unknown`. Supporting evidence: the journal shows the
  *same* slowness elsewhere in the same boots — the portal registration
  failed with `NoReply` (a timed-out D-Bus call) at 06:07:14 / 06:45:12,
  which is a second, independent D-Bus call timing out in the same window.
  The single check that confirms it: run with KActivities debug logging
  (§6.3) and watch whether `ListActivitiesWithInformation` returns or
  errors.
- **H1b — the `Running` transition emits nothing and the reply path never
  runs.** If the `Manager::serviceStatusChanged(Running)` signal is emitted
  *before* the `ActivitiesCache` has connected to it (construction ordering),
  or if `updateAllActivities()` is never reached because the cache's
  `setServiceStatus(Running)` call happens while the Manager is still
  `Starting`, the async calls may never be issued at all. This is harder to
  distinguish from H1a without the debug log, and the fix is the same (F1):
  make KAMD already-running before the shell starts, so the whole fragile
  transition is avoided.

Either way, the structural point stands: **the load gate has no timeout, no
fallback, and no retry of its own** — it waits forever on a signal that, in
this environment, never arrives. That is upstream behaviour (KDE bug 342431
is the original report of this dance, from 2014), not a Vyra invention, and
it is exposed by slow boot, not caused by Vyra's configuration.

---

## 4. The CPU spin (observed, cause not identified)

The aborted second instance consumed **13 min 18 s CPU over 25 min 7.7 s
wall (~53% of one core)** before it was stopped at 06:30:09 — while painting
nothing. This is a real symptom, but its cause is **not identified** from the
available evidence. Candidate causes, none confirmed:

- The Qt Quick render loop spinning on a window that never gets content
  (unlikely: no window exists before `load()` creates the containments).
- A D-Bus retry loop (e.g. repeated portal registration attempts after the
  `NoReply` failure).
- The `KActivities::Manager` / `QDBusServiceWatcher` machinery churning on
  name-owner changes.
- Ordinary TCG overhead of the shell's event loop plus the KWin/Wayland
  connection (but 53% sustained is far above an idle event loop).

The diagnostic that identifies it: while the shell is in the stuck state,
sample the process — `perf record -p <plasmashell-pid>` for 10 s, or
`gdb -p <pid> -batch -ex 'thread apply all bt'` — and see which frames
dominate. Do not guess from the journal alone.

---

## 5. Ranked hypotheses

### H1 — TCG-slow D-Bus activation + single-shot async reply failure (TOP)

*Claim:* KAMD starts too slowly under TCG for the shell's first `load()`
check, and the retry then fails because the async activity-list reply
times out or never completes, leaving the Consumer status stuck at `Unknown`.
*Supporting:* the exact 40 s timeouts; the KAMD pids appearing *after* the
abort; the portal `NoReply` (a second D-Bus timeout in the same window);
the verified code path (§2.3) in which the only route to `Running` is that
single async reply; boot 3 starting cleanly when the timing happened to
line up.
*Contradicting:* none — no evidence rules it out.
*Single check:* boot with `QT_LOGGING_RULES="kde.plasma.activities.debug=true"`
and `journalctl --user -u plasma-plasmashell -u plasma-kactivitymanagerd`
(§6.3); if the log shows the Manager reaching `Running` but the Consumer
never emitting `Running`, H1 is confirmed and the sub-case (reply timeout
vs. missed emission) is visible in the log.

### H2 — KAMD D-Bus activation itself is slow or failing (contributing, not standalone)

*Claim:* activation of `org.kde.ActivityManager` through dbus-broker +
systemd is the slow step.
*Supporting:* KAMD's pid appears 1–2 min after the shell first needed it;
the daemon must open/create its SQLite database on first run.
*Contradicting:* activation *does* succeed (the daemon runs) — it is slow,
not broken. H2 alone cannot explain why the shell never loads *after* KAMD
is running; that needs H1's stuck-status mechanism. H2 is best read as the
trigger for H1.
*Single check:* `systemd-analyze plot` / `journalctl --user -u
plasma-kactivitymanagerd` timestamps: measure KAMD start → name-claimed
latency in a failing boot vs. boot 3.

### H3 — Phase A4 layout.js / defaults cause (REFUTED)

*Claim:* the new floating-dock `layout.js` (or the `defaults` file) breaks
shell startup.
*Refuting evidence:* (a) `layout.js` runs inside `loadLayout()`, which
`load()` calls only *after* the KAMD gate passes — in the failing boots the
gate aborted first, so the layout never executed; (b) the same black-desktop
symptom occurred in run 23 boot 2, before Phase A4 existed; (c) boot 3 ran
the identical layout.js and defaults and rendered the dock correctly.
A malformed layout could cause a *different* failure after the gate passes;
that failure is not observed here. No further work on this hypothesis.

### H4 — KAMD missing / D-Bus service file missing (REFUTED)

*Claim:* the daemon or its activation file is absent from the image.
*Refuting evidence:* `kactivitymanagerd-6.8.3-1.fc45` is in the package list;
the D-Bus service file and the systemd unit ship in that exact RPM
(verified by extraction, §2.1); the daemon demonstrably starts (pid 1668 /
1642). No further work.

### H5 — dbus-broker vs. dbus-daemon (WEAK)

*Claim:* dbus-broker (the Fedora 45 default; `dbus-broker-37-9.fc45` is in
the image) mishandles service activation under TCG, and switching the user
bus to dbus-daemon would fix it.
*Supporting:* one Arch Linux forum report of the *identical* "Aborting shell
load" error, where the reporter concluded the problem was D-Bus and
switching from `dbus-broker-units` to `dbus-daemon-units` fixed it
(https://bbs.archlinux.org/viewtopic.php?pid=2176949). A Manjaro thread
reports the same abort alongside `ServiceUnknown` D-Bus errors
(https://forum.manjaro.org/t/stable-update-2024-05-29-kernels-plasma-6-0-5-gnome-46-2-mesa/162887?page=5).
*Contradicting:* in those reports activation failed *entirely* ("The name is
not activatable" / "not provided by any .service file"); in Vyra's case
activation succeeds, just slowly. dbus-broker is Fedora's default and works
for the rest of the session (the shell's own bus name, the portal, KWin all
function). Switching the session bus is a system-wide change with broad
implications for a weak, second-hand lead.
*Single check:* only pursue if the §6.3 diagnostics show activation
*requests* failing (not merely slow). Do not switch the bus on speculation.

### H6 — A separate upstream bug in the 6.8.3 status machine (UNRESOLVED, low)

*Claim:* something in this specific 6.8.3 build of plasma-activities or
plasma-workspace drops the `serviceStatusChanged` emission.
*Supporting:* the retry is designed to work (bug 342431) yet observably did
not; upstream bugs exist in this area (KDE bug 458356, Plasma 5.25 on
FreeBSD, same abort; KDE bug 483813, Plasma Bigscreen, same abort after
`org.kde.ActivityManager` *was* successfully activated — the reporter saw
"Successfully activated service 'org.kde.ActivityManager'" followed by a
second "Aborting shell load", which is the closest upstream analogue to
Vyra's stuck state).
*Contradicting:* boot 3 worked with the same binaries, so it is not a
deterministic code bug — at most a race in the same code.
*Single check:* the §6.3 debug log; if the log shows the Manager emitting
`Running` and the cache receiving it but never emitting `Running` itself,
this becomes the leading hypothesis and the fix belongs upstream (or as a
targeted patch), not in Vyra's configuration.

---

## 6. Fix options (ranked)

### F1 — Order kactivitymanagerd before plasmashell (RECOMMENDED)

*Change:* ship a systemd drop-in in the image, e.g.
`/usr/lib/systemd/user/plasma-plasmashell.service.d/10-kactivitymanagerd.conf`:

```ini
[Unit]
After=plasma-kactivitymanagerd.service
Wants=plasma-kactivitymanagerd.service
```

*Why it works:* `Wants=` starts KAMD when the shell starts; `After=` orders
it first; and because KAMD's unit is effectively `Type=dbus`, systemd waits
until KAMD has claimed `org.kde.ActivityManager` before starting the shell.
When the shell's `load()` then runs, the Manager status is already
`Running`, the async activity list has a live daemon to answer, and the
fragile transition in §2.3 is avoided entirely.
*Risk:* low. An ordering dependency, not a code change; `Wants=` (not
`Requires=`) means a KAMD failure degrades to the current behaviour instead
of blocking the shell. It is Vyra-specific hardening (upstream does not
order these units — upstream relies on D-Bus activation plus the retry), so
note it as such in the Containerfile comment.
*Verify:* in the next boot test, the journal must show
`plasma-kactivitymanagerd.service` started *before*
`plasma-plasmashell.service`, with no "Aborting shell load" and no 40 s
timeout; the desktop must render on the first boot, repeatedly (at least 3
consecutive boots, given the current ~3/8 failure rate).

### F2 — Raise the systemd start timeout (COMPLEMENTARY to F1)

*Change:* in the same drop-in, add `TimeoutSec=120sec` under `[Service]`
(or `TimeoutStartSec=120sec`).

*Why it works:* the first instance's 40 s kill is pure cold-start slowness
under TCG (§2.5). 120 s gives a cold TCG start room to reach the
`KDBusService` claim.
*Risk:* low, but it only fixes the first-instance timeout, not the KAMD
race — on its own it would likely convert "timeout then abort" into just
"abort". It also delays detection of a genuinely wedged shell. Apply
together with F1, not instead of it.
*Verify:* no "start operation timed out" line in the journal of a failing
boot; the first instance reaches the bus-name claim.

### F3 — Run the §6.3 diagnostics in the same test (DO WITH F1/F2)

*Change:* none to the image — a test procedure (below). This is the only
way to confirm H1a vs. H1b and to close the "unresolved" items in §0.
*Risk:* none (observation only).

### F4 — Pre-start KAMD in the live session (ALTERNATIVE to F1)

*Change:* start `plasma-kactivitymanagerd.service` early in session
startup (e.g. from the livesys/SDDM autologin path, or by adding it to
`plasma-core.target`'s `Wants=` via a drop-in).
*Why:* same effect as F1, but at the session level rather than the shell
unit. Useful if the shell-unit drop-in proves awkward.
*Risk:* low-medium. It is a second mechanism doing F1's job; prefer F1
unless there is a reason the unit drop-in cannot be used. Note it would
only help the live session unless also applied to installed systems.

### F5 — Add a restart delay (`RestartSec=`) to the shell unit (LAST-RESORT TIMING HACK)

*Change:* `RestartSec=10s` in the shell drop-in, so the post-timeout
restart gives KAMD more time to come up.
*Risk:* medium. It is a timing guess, not a fix; it papers over the race
and can still lose it on a slower boot. Only consider if F1 proves
insufficient.

### F6 — Switch the user bus from dbus-broker to dbus-daemon (DO NOT DO ON SPECULATION)

*Change:* install `dbus-daemon-units` in place of `dbus-broker-units` for
the user bus.
*Risk:* medium-high. System-wide change to Fedora's default bus, broad
implications, and the evidence (H5) is weak and second-hand. Pursue only
if §6.3 shows activation requests *failing*, not merely slow.

### F7 — Disable the KAMD gate (NOT RECOMMENDED — RULED OUT)

*Change:* set the `org.kde.KActivities.core.disableAutostart` application
property so `load()` proceeds without KAMD.
*Why not:* it is a code/wrapper change, not a configuration one, and it
trades a startup race for a shell that loads with no activity backend
(the activity list, current activity, and everything that reads them
would be broken or empty). Mentioned only to rule it out.

### 6.3 Diagnostic procedure (to run in the next boot test)

In a live session (or a booted VM), before the shell is restarted:

```sh
# 1. Enable KActivities debug logging for the shell's next start
systemctl --user set-environment QT_LOGGING_RULES="kde.plasma.activities.debug=true"

# 2. Restart the shell and capture the full journal for both units
systemctl --user restart plasma-plasmashell
journalctl --user -u plasma-plasmashell -u plasma-kactivitymanagerd --no-pager -o short-precise > /tmp/shell-race.log

# 3. While the shell is stuck (if it sticks), sample what the process is doing
pid=$(pgrep -x plasmashell); perf record -p $pid -g -- sleep 10   # or:
gdb -p $pid -batch -ex 'thread apply all bt' > /tmp/shell-stack.txt

# 4. Check the live status values directly
busctl --user get-property org.kde.ActivityManager / org.freedesktop.DBus.Properties ...  # (or qdbus)
gdbus call --session --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus \
    --method org.freedesktop.DBus.ListNames | grep -i activity
```

What the log must show to confirm H1: the Manager reaching `Running`
while the Consumer stays `Unknown`, and either (H1a) the
`ListActivitiesWithInformation` call erroring/timing out, or (H1b) no
`serviceStatusChanged(Running)` emission from the cache at all. If instead
the log shows the Manager never reaching `Running`, the problem is
activation (H2/H5), not the cache.

---

## 7. TCG timing artifact or real defect?

**Short answer: the trigger is TCG-amplified, but the fragility is real
upstream code and the fix is valid on any hardware.**

- TCG makes everything ~8–12× slower *and* more variable, which widens the
  race window enormously: the shell must claim its bus name within 40 s
  (F2's domain) and KAMD must start and answer before the shell's first
  `load()` check (F1's domain). On real hardware or KVM both happen in
  well under a second, so the window is far narrower and the race may
  never trigger in practice.
- But the underlying fragility — a load gate that waits forever on a
  single-shot async reply with no retry, no timeout, and no error log
  (§2.3) — exists on every machine. Any sufficiently slow or loaded first
  boot (slow eMMC, a heavily loaded session, a cold disk cache) can hit
  it. Upstream reports of the same abort on real hardware (bugs 458356,
  483813, the Arch/Manjaro threads in §5) show it is not TCG-only in
  principle.
- **What a KVM / real-hardware retest would prove:** whether the race
  triggers at hardware speed. If 5+ consecutive KVM boots all render, the
  race is TCG-specific *in practice* and the fix is still worth doing (it
  costs nothing on fast hardware and removes the flakiness from the test
  environment). If it triggers even once on KVM, it is a real defect that
  must be fixed regardless of TCG. A KVM retest therefore answers "how
  often", not "whether the code is fragile".
- **What a KVM retest would not prove:** it cannot prove the fragility is
  gone — only that the window is narrow at that speed. Do not treat "5
  clean KVM boots" as proof the race is fixed; treat it as evidence about
  the trigger rate.

---

## 8. Sources

### Verified from the Fedora 45 RPMs (downloaded from koji, extracted locally)

- `plasma-workspace-6.8.3-1.fc45.x86_64.rpm` — `plasma-plasmashell.service`
  (quoted in full in §2.1), `plasma-core.target`, `plasma-workspace.target`.
- `kactivitymanagerd-6.8.3-1.fc45.x86_64.rpm` —
  `plasma-kactivitymanagerd.service`, `org.kde.ActivityManager.service`
  (quoted in full in §2.1).
- Image package list: `kactivitymanagerd-6.8.3-1.fc45`,
  `plasma-workspace-6.8.3-1.fc45`, `plasma-desktop-6.8.3-1.fc45`,
  `dbus-broker-37-9.fc45` (`Vyra-Foundation/artifacts/vyra-os-0.1.0-dev-packages.txt`).

### Verified from upstream source (KDE GitHub mirror)

- `KDE/plasma-workspace`, branch `Plasma/6.8` (the branch Fedora 45's 6.8.3
  is built from), `shell/shellcorona.cpp` — `ShellCorona::init()` (the
  bug-342431 comment, the `serviceStatusChanged → load` connection) and
  `ShellCorona::load()` (the `NotRunning` abort). The `master` branch is
  essentially identical for these functions.
- `KDE/plasma-workspace`, branch `Plasma/6.8`, `shell/main.cpp` —
  `KDBusService` constructed (line 395) before `corona.init()` (line 398).
- `KDE/plasma-activities`, `master`, `src/lib/consumer.cpp` /
  `consumer.h` (cached `m_status`, `NotRunning/Unknown/Running` enum),
  `src/lib/activitiescache_p.cpp` (the `Manager::Running → Unknown`
  mapping, the single-shot async load, `setAllActivities` as the only
  route to `Running`, silent drop of error replies),
  `src/lib/manager_p.cpp` (D-Bus watcher, `StartServiceByName`, status
  transitions), `src/lib/controller.cpp` (thin `Consumer` subclass).

### Upstream reports (real results only)

- KDE bug 342431 — cited in the `shellcorona.cpp` comment as the reason
  the retry connection exists ("be careful about changing").
- KDE bug 458356, Plasma 5.25 on FreeBSD — same "Aborting shell load"
  abort; `plasmashell --replace` in the broken state produced a working
  desktop (https://bugs.kde.org/show_bug.cgi?id=458356).
- KDE bug 483813, Plasma Bigscreen — same abort *after*
  `org.kde.ActivityManager` was successfully activated, the closest
  upstream analogue to Vyra's stuck state
  (https://bugs.kde.org/show_bug.cgi?id=483813).
- Arch Linux Forums, "KDE Plasma on wayland only shows black screen with
  cursor" — identical abort; reporter traced it to D-Bus and fixed it by
  switching from `dbus-broker-units` to `dbus-daemon-units`
  (https://bbs.archlinux.org/viewtopic.php?pid=2176949).
- Manjaro Forums, stable update 2024-05-29 — same abort alongside
  `ServiceUnknown` D-Bus errors
  (https://forum.manjaro.org/t/stable-update-2024-05-29-kernels-plasma-6-0-5-gnome-46-2-mesa/162887?page=5).

### Vyra evidence

- `first-run/WALKTHROUGH.md` — "Live ISO — run #25" (line 919; boots 1–2
  journal, boot-3 control), "Live ISO — run #23" (line 309; boot 2 black
  desktop), "Live ISO — run #24" (line 592; all three boots rendered).
- Journal screenshots: `first-run/run25-29-after-restart.png`,
  `run25-30-plasmajournal2.png`, `run25b-10-plasmajournal.png`,
  `run25b-11-kact2.png`, `run25b-12-kact2.png`, `run25c-56-journal.png`
  (boot 3, clean).
- Phase A4 files examined and exonerated as a cause:
  `Vyra-Foundation/vyra-branding/plasma/look-and-feel/org.vyra.desktop/contents/layouts/org.kde.plasma.desktop-layout.js`
  (runs inside `loadLayout()`, i.e. after the gate) and
  `contents/defaults` (read during look-and-feel application, also after
  the gate); Containerfile Phase A2/A4 RUNs (colour scheme + icons only,
  no shell-startup change).

---

## 9. Honest limits

- The ActivitiesCache/Manager/ShellCorona analysis is from upstream source
  (`Plasma/6.8` branch and `master`); the exact 6.8.3 Fedora build was not
  recompiled or disassembled. The `Plasma/6.8` branch matches 6.8.3's
  lineage, and the relevant functions are unchanged between the branch and
  `master`, but a Fedora-specific patch to these paths cannot be ruled out
  from source alone.
- The H1a-vs-H1b distinction (async reply timeout vs. missed emission) is
  **not** resolved from the journal screenshots — the journal does not log
  KActivities internals at default verbosity. The §6.3 diagnostic is the
  single run that resolves it.
- The CPU-spin cause (§4) is not identified; it is reported as a symptom
  with the diagnostic that would identify it.
- No VM was booted for this investigation, so none of the fixes has been
  tested. F1/F2 are specified exactly enough to implement, but their
  verification (3+ consecutive clean boots, §6) still has to happen in a
  boot test.
- The `invent.kde.org` source browser is blocked in this environment, so
  the upstream code was read via the GitHub mirror (`KDE/plasma-workspace`,
  `KDE/plasma-activities`), which is the same upstream content.
