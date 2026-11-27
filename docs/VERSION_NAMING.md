# Vyra OS Version Naming & Numbering

Owner-decided 2026-11-27 (two messages: the inventor-name rule, then the
three-part numbering rule). This is the naming/numbering rule and the design
for how the version propagates. It is not a build change by itself — the
version in the live build changes only as the "Dynamic update" section below
says, and only after the owner's go on that package.

## Format: MAJOR.MINOR.PATCH

Three numbers, e.g. `1.1.1`. Each category of update determines one number.

| Position | Category | What it means | Name? |
|---|---|---|---|
| 1st (major) | **Major** | Big updates — new generation of the OS, major new capabilities | YES — an inventor's last name only |
| 2nd (minor) | **Minor** | Feature updates — new features, new apps, new capabilities inside the same generation | YES — one of that inventor's inventions, one word or a simple abbreviation, in parentheses |
| 3rd (patch) | **Patch** | Security updates, bug fixes, alterations, extras, etc. | NO — never named |

Full name form: `VyraOS <version> - <Inventor> [(<Invention>)]`.
The patch number never carries a name.

## Confirmed assignments (owner's examples, 2026-11-27)

| Version | Full name |
|---|---|
| VyraOS 1.0 | VyraOS 1.0 - Edison |
| VyraOS 1.1 | VyraOS 1.1 - Edison (Bulb) |
| VyraOS 2.0 | VyraOS 2.0 - Tesla |
| VyraOS 2.1 | VyraOS 2.1 - Tesla (AC) |
| VyraOS 2.2 | VyraOS 2.2 - Tesla (Radio) |

Further inventors named by the owner as the pool: Carver, etc. Which inventor
heads 3.0, and which invention subtitles later minors (1.2, 1.3, 2.3, ...),
are the owner's to name when those releases are planned. A patch (1.1.1,
1.1.2, ...) is just the number — no invention, no inventor change.

## Pre-release: no name, version 0.0.0

Owner answer 2026-11-27 to the 0.x question: **pre-release has no name**.
The pre-release version is **VyraOS 0.0.0** — numbered only, no inventor,
no invention. This replaces the 0.1.0-dev label on the current dev build
once the owner confirms the reset (see "Open decision" below).

## Progression — macOS as the standard

The number progresses to match the phase of the OS's development, using
macOS as the standard for naming change periods and reasoning:

- **Major** = the big named release, like a yearly macOS release
  (Sequoia, Sonoma...). A new major means a new generation and a new
  inventor name.
- **Minor** = feature updates inside that generation, like macOS 15.1,
  15.2 adding features through the year. A new minor means new features
  and a new invention subtitle from the same inventor.
- **Patch** = security updates and bug fixes, like macOS 15.0.1 / 15.1.1.
  No new features, no name — just the number going up.

The bump size follows the amount and complexity of the changes, same
reasoning as Apple: small fix → patch; new features → minor; a new
generation → major.

Release sequence (from the master directive) mapped to versions:
0.1 Foundation, 0.2 Desktop, 0.3 Arena, 0.4 Link, 0.5 Unified,
0.8 Beta, 0.9 RC, 1.0 Stable (Edison). Pre-release phases are numbered
only (no name) until 1.0.

## Dynamic update — one version, everywhere

Once an update is **confirmed as finished**, all version numbers across
the entire OS change dynamically to the next version number, chosen by the
amount and complexity of the changes (major / minor / patch as above).

Design (IMPLEMENTED for the 0.0.0 reset, 2026-11-27): a **single source of
truth** — the `VERSION` file at the repo root — and every place that
displays or uses the version reads it at build time, so one bump
propagates everywhere:

- `VERSION` holds the version (`0.0.0`).
- `Containerfile`: `ARG Vyra_VERSION=0.0.0` (default mirrors the VERSION
  file); the image `LABEL`, `/usr/share/vyra/release`, and the os-release
  `PRETTY_NAME` all use `${Vyra_VERSION}`. `COPY VERSION
  /usr/share/vyra/VERSION` ships the file in the image for runtime readers.
- CI (`build.yml`): the core-image build passes
  `--build-arg Vyra_VERSION=$(cat VERSION)`; artifact names use the
  version (`vyra-os-0.0.0-qcow2`, `vyra-os-0.0.0-live-iso`).
- `scripts/hardware-report.py`: `vyra_version()` reads
  `/usr/share/vyra/VERSION`, then the repo `VERSION`, falling back to
  `0.0.0`.
- `scripts/build-container.sh`, `build-iso.sh`, `build-iso-fedora.sh`:
  image tag derived from the `VERSION` file; `build-container.sh` also
  passes the build arg.

On a future bump: change `VERSION` first, then the `ARG` default in the
Containerfile to match. The `build.yml` artifact names are the one place
still hand-edited per bump (workflow files are owner-edited via web UI).

Live places the version appears today (mapped 2026-11-27; historical
dated docs are records and are NOT rewritten):

| Place | What shows the version |
|---|---|
| `VERSION` (repo root) | The version itself (`0.0.0`) — single source of truth |
| `Containerfile` | `ARG Vyra_VERSION` + image `LABEL` + `/usr/share/vyra/release` + `/usr/share/vyra/VERSION` + os-release `PRETTY_NAME="Vyra OS 0.0.0"` (grep guard) |
| `scripts/hardware-report.py` | `vyra_version()` (reads the VERSION file) |
| `.github/workflows/build.yml` | `--build-arg Vyra_VERSION=$(cat VERSION)` + artifact names `vyra-os-0.0.0-qcow2`, `vyra-os-0.0.0-live-iso` (owner edits workflow files via web UI only) |
| `scripts/build-container.sh`, `build-iso.sh`, `build-iso-fedora.sh` | image tag `localhost/vyra-os:0.0.0` (derived from VERSION) |

Where the full name appears when 1.0 ships: product name in os-release
PRETTY_NAME, installer, About screen, Welcome Center, release notes —
full form `VyraOS 1.0 - Edison`, not just the number.

## Open decision (owner to confirm)

**Reset the current build to 0.0.0 now, or keep 0.1.0-dev until the next
confirmed finish?** — DECIDED 2026-11-27 ~11:55 EST: owner tapped
"Reset the build to 0.0.0 for run 28". Reset implemented + pushed
(commit 922ca20d, 2026-11-27 ~12:0x EST): VERSION file, Containerfile,
hardware-report.py, three build scripts — all remote-verified. The
`build.yml` half (build arg + artifact names) is prepared as a paste file
(`workspace/vyra-os/build.yml`, sha256
`1463ad0509f702f6451bdec43a64c8ac5979b27d032a6f17e7962115dc1231cb`, 254
lines); the owner pastes it via web UI, then run 28 is triggered. The
run-27 ISO (0.1.0-dev) is unaffected — its boot test proceeds as-is.
