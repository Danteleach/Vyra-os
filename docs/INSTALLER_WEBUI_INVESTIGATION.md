# Installer WebUI investigation — why no installer window ever appears

**Date:** 2026-11-27 · **Scope:** research + documentation only. No code changed, no build triggered.
**Status:** root cause found (mode A) with direct evidence; one secondary mode (B) unresolved.

## Verdict (one paragraph)

The installer backend is fine. The window never appears because of a **startup race
between two processes that `liveinst` launches in parallel**: `liveinst` starts the
WebUI viewer (`webui-desktop`) in the background *before* it starts Anaconda, and
`webui-desktop` will **exit after 60 seconds** if Anaconda has not yet written its
runtime config file `/run/anaconda/anaconda.conf` (`get_default_browser()` in
`/usr/libexec/anaconda/webui-desktop`, `timeout=60`, `exit 1` on timeout). Under
QEMU TCG, Anaconda's Python startup (imports + config load + kickstart find) takes
**longer than 60 s** to reach the line that writes that file, so `webui-desktop`
prints `Timed out waiting for anaconda.conf to be available.` and exits — before
any browser is ever launched. Anaconda itself then proceeds normally (all modules
run, Vyra profile loads), but on live media Anaconda does **not** launch the viewer
itself: it only *watches* the PID that `liveinst` started (`_watch_webui_on_live()`),
so a viewer that already exited means no window, ever. The `Timed out…` line is
visible in the run-24 and run-25 liveinst terminal output — it is the kill shot,
not a side warning.

A second, distinct mode exists in runs 11/23: `webui-desktop` *did* run (PIDs present)
but no window appeared in ~17 min. That is most likely Firefox failing to paint
under TCG/Wayland, and it is **unresolved** — see §5.

## 1. The launch chain (verified from the actual F45 files)

All paths below are from the real Fedora 45 packages (`anaconda-live-45.30-1.fc45`,
`anaconda-webui-90-1.fc45`, `anaconda-core-45.30-1.fc45`, `anaconda-gui-45.30-1.fc45`),
downloaded from `dl.fedoraproject.org` and extracted locally. File/line citations
are to those exact files.

```
liveinst  (/usr/bin/liveinst, anaconda-live)
  ├─ (unprivileged) pkexec "$0"            → root  [the polkit dialog seen in run 24]
  ├─ (root) start_anaconda()
  │    ├─ if /usr/share/cockpit/anaconda-webui exists:
  │    │    └─ start_anaconda_web_ui()      →  /usr/libexec/anaconda/webui-desktop -t live &
  │    │                                     (background; PID → /run/anaconda/webui_script.pid)
  │    └─ $ANACONDA = anaconda --liveinst --graphical   (foreground)
  │
  ├─ webui-desktop  (/usr/libexec/anaconda/webui-desktop, anaconda-webui)
  │    ├─ writes /tmp/webui-cockpit-ws.env (WEBUI_AUTH=0, WEBUI_REMOTE=0)
  │    ├─ systemctl start webui-cockpit-ws
  │    │    └─ ExecStart = /usr/libexec/anaconda/cockpit-coproc-wrapper.sh
  │    │         └─ exec cockpit-ws --local-session=- -p 80 -a 127.0.0.1
  │    ├─ setup_user_environment()          → INSTALLER_USER=liveuser (via PKEXEC_UID)
  │    ├─ waits for cockpit-ws on 127.0.0.1:80 (nc, ≤5 s) or sleeps 3 s
  │    ├─ get_default_browser():            ← THE RACE IS HERE
  │    │    └─ waits ≤60 s for /run/anaconda/anaconda.conf; on timeout prints
  │    │       "Timed out waiting for anaconda.conf to be available." and exit 1
  │    ├─ reads webui_web_engine from that file (default: firefox)
  │    ├─ prepares a Firefox profile (theme "live") via pkexec as liveuser
  │    └─ launches Firefox as liveuser → http://127.0.0.1/cockpit/@localhost/anaconda-webui/index.html
  │       then `wait`s on the browser
  │
  └─ anaconda  (/usr/bin/anaconda, anaconda-core)
       ├─ imports, config load (Vyra profile), print_startup_note
       │    ("anaconda 45.30-1.fc45 for Fedora 45 started.")
       ├─ find_kickstart()
       ├─ conf.set_runtime_install_session(...)   ← WRITES /run/anaconda/anaconda.conf
       │    (anaconda.py:435-453; first call, before modules start)
       ├─ dbus_launcher.start() + all pyanaconda modules start
       ├─ parse_kickstart(), network init
       ├─ display.setup_display() → CockpitUserInterface.run()
       │    └─ conf.system.provides_liveuser is True (live OS) →
       │       _watch_webui_on_live(): reads PID from /run/anaconda/webui_script.pid,
       │       PidWatcher watches it; when webui-desktop exits, main loop quits.
       └─ (never reached in runs 24/25 as a visible window, because the viewer
            it watches was already dead)
```

Key design fact (from `pyanaconda/ui/webui/__init__.py`, `_watch_webui_on_live`
docstring): *"It takes long time to start Firefox after the user interaction (on
live even 20+ seconds). To avoid that, we are starting the webui-desktop script
early in the liveinst script."* The early start is intentional upstream design —
and the 60 s timeout in `get_default_browser()` is the part that breaks it on slow
hardware/emulation. The script even carries a FIXME referencing
`https://issues.redhat.com/browse/INSTALLER-4223` for this wait.

## 2. Q1 — What provides webui-desktop? (verified against F45 repodata)

| Artifact | Package | Version | Evidence |
|---|---|---|---|
| `/usr/libexec/anaconda/webui-desktop` | `anaconda-webui` | 90-1.fc45 | F45 filelists.xml (840 MB repodata, parsed locally) |
| `/usr/lib/systemd/system/webui-cockpit-ws.service` | `anaconda-webui` | 90-1.fc45 | same |
| `/usr/libexec/anaconda/cockpit-coproc-wrapper.sh` | `anaconda-webui` | 90-1.fc45 | same |
| `/usr/share/cockpit/anaconda-webui/` (the web app) | `anaconda-webui` | 90-1.fc45 | same (216 files) |
| `/usr/bin/liveinst` | `anaconda-live` | 45.30-1.fc45 | same |
| `pyanaconda/ui/webui/` (Python UI) | `anaconda-gui` | 45.30-1.fc45 | same |
| `/usr/libexec/cockpit-ws` (the web server binary) | `cockpit-ws` | 368-1.fc45 | same |

Dependency chain (from F45 `primary.xml`):
- **`anaconda-live` REQUIRES `anaconda-webui`** (plus bash, python3, python3-dbus-next,
  zenity). The payload image installs `anaconda-live` (`configure_iso.sh`), so
  `anaconda-webui` is pulled in automatically.
- `anaconda-webui` REQUIRES `firefox` (or `slitherer` on some spins), `anaconda-core`,
  `cockpit-bridge`, `cockpit-networkmanager`, `cockpit-storaged`, `cockpit-ws`,
  `python3-bugzilla`, `system-logos`.

**Conclusion: a missing package is RULED OUT.** The package is present — proven by
runtime evidence: `cockpit-coproc-wrapper.sh` (a file owned only by `anaconda-webui`)
was running in runs 23 (PID 5587), 24, and 25 (PID 4242). The failure is that
`webui-desktop` exits before launching a browser, not that it is absent.

Note: the payload image is the only place Anaconda lives. The core image package
list (`artifacts/vyra-os-0.1.0-dev-packages.txt`) correctly contains no anaconda /
cockpit packages — Anaconda is payload-only by design.

## 3. Q2 — What launches webui-desktop?

`liveinst` only, on live media. Sequence (see §1): `start_anaconda()` in
`/usr/bin/liveinst` starts `webui-desktop -t live` in the background **before**
Anaconda, guarded by the existence of `/usr/share/cockpit/anaconda-webui`.
Anaconda itself never launches the viewer on live media — `CockpitUserInterface.run()`
takes the `_watch_webui_on_live()` branch (because `conf.system.provides_liveuser`
is true for a live OS) and only watches the PID file. On non-live media it would
take `_run_webui()` and launch `webui-desktop` itself. So on the live ISO there is
exactly one chance to start the viewer, and it is the background launch in
`liveinst`.

## 4. Q3 — The two warnings, explained

### 4a. "Timed out waiting for anaconda.conf to be available." — THE KILL SHOT

From `get_default_browser()` in `/usr/libexec/anaconda/webui-desktop` (lines ~100–125):

```bash
get_default_browser() {
    timeout=60
    elapsed=0
    while [ ! -f /run/anaconda/anaconda.conf ]; do
        if [ "$elapsed" -ge "$timeout" ]; then
            echo "Timed out waiting for anaconda.conf to be available." >&2
            exit 1
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    DEFAULT_BROWSER=$(grep '^webui_web_engine =' /run/anaconda/anaconda.conf | cut -d'=' -f2)
    ...
}
```

The file is written by Anaconda's **first** `set_runtime_install_session()` call
(`/usr/bin/anaconda` line ~384), which happens after Python imports, configuration
load (including the Vyra profile), `check_memory`, and `find_kickstart` — and
**before** the D-Bus launcher and module startup. Proof the file is eventually
written in runs 24/25: all pyanaconda modules were running, and module startup
happens strictly after that write. So the file appears — just **after** the 60 s
window. Under TCG, Python startup + importing the whole pyanaconda/dasbus/blivet/
pykickstart tree + config load + kickstart find exceeds 60 s. (For scale: in these
same boots, Konsole takes ~2.5 min to open and the lock→desktop transition ~2 min.)

This message appears in the liveinst terminal output in **run 24**
(`run24-63-installer.png`) and **run 25** (`run25c-25-installer.png`). It does not
appear in the run-23 record — consistent with mode B below.

### 4b. "The unit file… of webui-cockpit-ws.service changed on disk. Run 'systemctl daemon-reload' to reload units." — RED HERRING

This is printed by `systemctl start webui-cockpit-ws` (called by `webui-desktop`).
It means systemd's loaded copy of the unit differs from the file on disk (timestamp
skew in the live image). The start still proceeds: the service **did** start in
every run — `cockpit-coproc-wrapper.sh` (its `ExecStart`) was running in run 23
(PID 5587), run 24, and run 25 (PID 4242). Not the cause of the missing window.
No action needed; do not chase it.

## 5. Q4 — Ranked hypotheses

### H1 — webui-desktop exits at its 60 s wait for /run/anaconda/anaconda.conf because Anaconda is too slow to write it under TCG (mode A: runs 24/25). ★ TOP

- **Supports:** the literal `Timed out…` line in run-24/25 terminal output;
  `timeout=60` + `exit 1` in the shipped script; the write happens after the
  slow Python-import/config phase (`/usr/bin/anaconda` ~line 384); all modules
  later running proves the file was written, just too late; `pgrep -af webui`
  empty in runs 24/25 (the viewer process is gone, not merely windowless);
  cockpit-ws still running (the viewer got as far as starting the service,
  then died at the wait).
- **Rules out:** nothing in the record contradicts it.
- **Confirm/refute (one check, next boot test):** in the liveinst terminal,
  run `date +%s` before launching `liveinst`, then watch for the `Timed out…`
  line and note its timestamp; separately, after Anaconda is up, `ls -l
  --time-style=full-iso /run/anaconda/anaconda.conf` and compare the file's
  mtime with the launch time. If mtime − launch > 60 s, H1 is confirmed. A
  stronger check: `timeout 600` patched build (see §7) → window appears.

### H2 — webui-desktop launched Firefox, but Firefox never painted a window under TCG/Wayland (mode B: runs 11/23).

- **Supports:** `webui-desktop -t live` PIDs existed in run 11 (attempt 2) and
  run 23 (PIDs 5578/5619) — so it got past the 60 s wait (Anaconda was fast
  enough those times) and was alive in `wait $BLOCK_ON_PID`, i.e. a browser
  process existed; still no window in ~17 min. Firefox cold start under TCG
  with software GL is extremely slow, and the live session was heavily loaded.
- **Against / unknown:** no Firefox process state, no webui-desktop stderr, and
  no `/tmp/webui-browser.log` (only written on the fallback path) were captured
  in those runs, so a Firefox crash vs. a slow first paint cannot be
  distinguished from the existing evidence.
- **Confirm/refute (next boot test, if H1's fix lands and the window still does
  not appear):** after launching `liveinst`, check `pgrep -af firefox` and
  `pgrep -af webui-desktop`; capture the liveinst terminal's webui-desktop
  stderr lines ("Using default browser: …", "Using Firefox browser command: …").
  If Firefox is running but no window paints in >5 min, it is a Firefox/TCG
  rendering problem, not an Anaconda problem.

### H3 — The Vyra profile is missing something the WebUI needs.

- **Against:** the profile loads cleanly (`/tmp/anaconda.log`: "Found the 'vyra'
  profile", "The 'vyra' profile is detected", "Load the 'vyra' profile
  configuration"); the WebUI's only profile-read dependency is
  `webui_web_engine`, which defaults to `firefox` when unset
  (`get_default_browser`); Firefox is installed. The profile also satisfies
  the WebUI's `supports_web_ui` gate (live OS ⇒ true) and `provides_liveuser`
  (live OS ⇒ true) — both are derived from the system type (`--liveinst`),
  not from profile keys. **Ruled out as a cause.** One genuine gap remains
  (see §6).

### H4 — A display/Wayland condition blocks the browser (no DISPLAY/WAYLAND_DISPLAY).

- **Against:** the desktop session itself renders (Plasma/Wayland works; Konsole,
  Dolphin, Discover all open). `webui-desktop` reuses the liveuser session's
  display (`USER_GRAPHICAL_SESSION_AVAILABLE` path) when `PKEXEC_UID` is set,
  which it is after the pkexec step. If no display existed it would print
  "Error: no graphical session detected" and exit 1 — that line was never seen.
  **Ruled out.**

### H5 — cockpit-ws / the WebUI backend never started.

- **Against:** `cockpit-coproc-wrapper.sh` (the `webui-cockpit-ws.service`
  ExecStart) was running in runs 23/24/25, and `pgrep` showed the anaconda
  D-Bus daemon plus all pyanaconda modules. The backend starts; the viewer
  dies before it can use it. **Ruled out.**

### H6 — A nondeterministic race (sometimes the viewer starts, sometimes not).

- **Partially true, but it is H1's mechanism, not a separate cause.** Runs 11/23
  (viewer alive) vs 24/25 (viewer dead at 60 s) is the same race with different
  outcomes depending on how slow Anaconda's startup was on that boot. The
  variance is in Anaconda's startup time under TCG, not in the viewer logic.

## 6. Q5 — Vyra profile vs stock fedora profile

Stock `/etc/anaconda/profile.d/fedora.conf` (from `anaconda-core-45.30`) vs
`iso_files/vyra.conf`:

| Section / key | Stock fedora.conf | Vyra vyra.conf | Matters? |
|---|---|---|---|
| `[Profile] profile_id` | fedora | vyra | No (matches `os_id=vyra`) |
| `[Profile Detection] os_id` | fedora | vyra | No |
| `[Network] default_on_boot` | FIRST_WIRED_WITH_LINK | FIRST_WIRED_WITH_LINK | No |
| `[Bootloader] efi_dir` | fedora | fedora (comment: on-disk EFI vendor dir, not branding) | No |
| `[Bootloader] menu_auto_hide` | — (absent) | True | No (cosmetic) |
| `[Storage] default_scheme` / `btrfs_compression` | BTRFS / zstd:1 | BTRFS / zstd:1 | No |
| `[Storage] default_partitioning` | — (absent) | / (1–70 GiB), /home, /var | No (Vyra-specific, fine) |
| `[Localization] use_geolocation` | — (absent) | False | No |
| `[User Interface] custom_stylesheet` | `/usr/share/anaconda/pixmaps/fedora.css` | `/usr/share/anaconda/pixmaps/vyra/vyra.css` | No (branding) |
| `[User Interface] webui_web_engine` | **firefox** | **— absent —** | **Gap, not the cause.** `webui-desktop` defaults to firefox when the key is absent, so the viewer still launches Firefox. But the profile should match upstream and state it explicitly. One-line hardening fix (see §7). |
| `[Payload] default_source` etc. | CLOSEST_MIRROR + GPG keys + updates repos | — absent — | No. Vyra installs from the embedded ostreecontainer image via `interactive-defaults.ks`; a mirror default would be wrong. Correctly absent. |

**Conclusion:** no profile key blocks the WebUI. The only profile change worth making
is adding `webui_web_engine = firefox` under `[User Interface]`, for parity with the
stock profile and to remove any ambiguity about which browser the viewer launches.

## 7. Fix to try (specified, NOT applied)

### Fix 1 (the fix for H1 — required): raise webui-desktop's config wait from 60 s to 600 s

The file is Fedora-shipped (`anaconda-webui` RPM), so patch it at payload-build time
in `iso_files/configure_iso.sh`, right after the `dnf install -y anaconda-live`
block, with a guard that fails the build if upstream changes the script's shape:

```bash
# webui-desktop waits only 60 s for Anaconda to write /run/anaconda/anaconda.conf
# (get_default_browser); under TCG — and on slow hardware — Anaconda's Python
# startup exceeds that, so webui-desktop exits before any browser is launched
# (installer window never appears, runs 24/25). Raise the wait to 600 s.
# Guard: fail the build if upstream changes the timeout line.
# CORRECTION 2026-11-27 (run 26 failed on the original pattern): the line in
# the shipped anaconda-webui-90-1.fc45 script is INDENTED ("    timeout=60"
# inside get_default_browser), so ^timeout=60$ never matched and the guard
# correctly failed the build. Match with optional leading whitespace and
# preserve it. Verified against the extracted RPM (line 108, 4-space indent).
sed -i 's/^\([[:space:]]*\)timeout=60$/\1timeout=600/' /usr/libexec/anaconda/webui-desktop
grep -q '^[[:space:]]*timeout=600$' /usr/libexec/anaconda/webui-desktop
```

Why 600 s: the slowest observed Anaconda startup phase is bounded by the live
session's own timings (lock→desktop ~2 min, Konsole ~2.5 min to open); 600 s is
10× the current timeout and comfortably covers TCG startup without waiting forever
on a genuinely stuck Anaconda. Why patch here rather than elsewhere: the timeout
lives in the viewer script, and `configure_iso.sh` is the payload hook that already
owns installer-time customisation; patching the vendor file is a deliberate,
documented, grep-guarded workaround (standing rule: best workaround without
sacrificing functionality; upstream fix is a separate, longer-term item — see §8).

### Fix 2 (hardening, one line): add the web engine to the Vyra profile

In `iso_files/vyra.conf`, under `[User Interface]`, add:

```ini
# The default browser for the Web UI (matches the stock fedora profile).
webui_web_engine = firefox
```

This changes no behaviour today (firefox is already the default when the key is
absent) but makes the profile explicit and removes a difference from upstream.

### What NOT to do

- Do **not** pre-create `/run/anaconda/anaconda.conf` before launching the viewer:
  Anaconda overwrites it at startup, and a stale pre-seeded file could mask a real
  startup failure.
- Do **not** switch to the old GTK UI: Fedora 45's `--graphical` is the WebUI;
  `DisplayModes` has only GUI/TUI, and the GTK path is not a supported live-install
  route (`fallback_to_tui_if_gtk_ui_is_not_available` exists precisely because GTK
  may be absent). The WebUI is the supported path; fix its race.
- Do **not** chase the `webui-cockpit-ws.service changed on disk` warning (§4b).

## 8. Verification plan (next boot test, after Fix 1 is built)

1. Launch `liveinst` from Konsole; note the wall-clock launch time.
2. Watch the liveinst terminal: the `Timed out…` line must **not** appear; instead
   expect `Using default browser: firefox` / `Using Firefox browser command: …`
   from webui-desktop, then a Firefox window with the Anaconda WebUI.
3. `pgrep -af webui-desktop` and `pgrep -af firefox` must both return PIDs.
4. `ls -l --time-style=full-iso /run/anaconda/anaconda.conf` — record the file's
   mtime vs the launch time; if the window appears, record how long the wait was
   (this calibrates whether 600 s is generous or tight).
5. If the window still does not appear after Fix 1, run the H2 checks (§5): Firefox
   process state + webui-desktop stderr from the liveinst terminal. That would
   mean mode B (Firefox paint failure) is now the blocker, and the fix is a
   Firefox/TCG problem, not an Anaconda one.
6. Still required regardless: a real-hardware/KVM retest before calling any
   installer behaviour an image defect (standing note from runs 11/23/24/25).

## 9. Honest limits

- No live boot was performed for this investigation (research only, by task
  design). The race is established from the shipped scripts + the observed
  terminal output + the process lists, not from a live reproduction with
  timestamps. The timestamp check in §8 step 4 is the confirmation that is
  still owed.
- Mode B (runs 11/23: viewer alive, no window) is **not** resolved from the
  available evidence — no Firefox process state or webui-desktop stderr was
  captured in those runs. H2 is the best-supported explanation, not a proven cause.
- Upstream context: the 60 s wait carries an upstream FIXME referencing
  INSTALLER-4223. The durable fix belongs upstream (make the wait configurable
  or event-driven); Fix 1 is a local workaround, documented as such.
- All package facts are from the Fedora 45 release repodata (filelists +
  primary) and the extracted `45.30-1.fc45` / `90-1.fc45` RPMs. If the payload
  build ever pins a different Anaconda release, re-verify the timeout line and
  the file paths — the `grep -q` guard in Fix 1 exists for exactly that.

## Sources (all fetched and verified in this pass)

- F45 repodata: `dl.fedoraproject.org/pub/fedora/linux/releases/45/Everything/x86_64/os/repodata/`
  (`repomd.xml`, `filelists.xml.zst`, `primary.xml.zst`) — parsed locally.
- RPMs extracted locally (own Python RPM extractor, `/tmp/rpm_extract.py`):
  `anaconda-live-45.30-1.fc45.noarch`, `anaconda-webui-90-1.fc45.noarch`,
  `anaconda-core-45.30-1.fc45.x86_64`, `anaconda-gui-45.30-1.fc45.x86_64`.
- Repo files read: `installer/Containerfile.live`, `installer/iso.yaml`,
  `iso_files/configure_iso.sh`, `iso_files/vyra.conf`.
- Test evidence: `first-run/WALKTHROUGH.md` run #11 (§ installer), run #23
  (R8 + defect 3), run #24 (installer section + defect 3), run #25 (§9 + defect 2);
  screenshots `run24-63-installer.png`, `run24-66-webui.png`, `run24-69-sudo.png`,
  `run25c-25-installer.png`, `run25c-29-pgrep-webui.png`.
