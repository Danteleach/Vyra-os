# Vyra OS — Phase 1 Report, 2026-11-24

> **Rename note (2026-11-24 18:07 EST):** the OS is now called **Vyra OS**
> (owner correction; was VFM/44 OS). Repo contents renamed in commit
> 2ebc445; directories renamed after attempt 6 finished
> (`vyra-os/Vyra-Foundation/vyra-branding/`). Slogan/tagline unchanged
> unless the owner says otherwise.

Author: Coby (software/OS role). Owner: VFM Studios, LLC.
Source directive: `workspace/vyra-os/Vyra-OS-Master-Directive-SOURCE.md` (verbatim).
Repo: `workspace/vyra-os/Vyra-Foundation/`, git commit `e1e10844f739aacf062d2cb132dd3574b62dc909`
(Phase 1 source-complete; build-result commit to follow).

## What was completed

- Scaffold audited (11 files, 9,613 bytes): Fedora 45 bootc base, KDE Plasma,
  hardware-report.sh, build-container.sh, preflight.sh, CI workflow, docs.
  The scaffold itself was honest — it stated it was not a built OS, no ISO,
  no certification.
- Fedora bootc workflow verified against current upstream evidence (2026-11-24):
  `quay.io/fedora/fedora-bootc:45` is current (digests updating daily mid-Nov 2026);
  Fedora 46 was seen emerging 2026-11-09. Base pinned by tag + digest:
  `sha256:d440aea898005f376bbf0bbe06c216abdba68dcdb6dfa5cb0fa246cd03fa8d8a`,
  Quay API, last modified Tue, 24 Nov 2026 11:31:44 UTC, manifest list.
  Re-verify at every build.
- Preflight bug fixed: the destructive-command grep matched its own pattern
  line in `preflight.sh`. Now excludes itself; check passes.
- Hardware discovery completed for Phase 1:
  - `scripts/hardware-report.sh` (text) — run on this VM.
  - `scripts/hardware-report.py` (new, JSON) — machine-readable report with
    ENTRY / STANDARD / PERFORMANCE classification and storage classification
    per Directive §5. Run on this VM: ENTRY, 7GB RAM, 4 vCPU, no dGPU.
    That is discovery only, NOT a Victus or entry-level certification.
  - `docs/HARDWARE_MATRIX.md` — both targets remain UNTESTED (exact Victus SKU pending).
- Containerfile hardened: added flatpak, podman, btrfs-progs, cryptsetup (LUKS2),
  fwupd, plasma-workspace-wayland; SELinux/firewall left enforcing/enabled;
  VFM branding tokens copied from `vyra-branding/` (palette + typography,
  text wordmark only — no invented logo; official logo assets were not on disk).
- New: `vyra-branding/`, `config/bootc-image-builder.toml`,
  `scripts/build-iso.sh` (Phase 2 ISO gate, writes only to `artifacts/`),
  `docs/DEPENDENCIES.md`, `docs/APPLICATION_MANIFEST.md` (Phase 1 intent only),
  `LICENSE` (MIT for VFM-authored files only; upstream licences retained).
- Git repo initialised; Phase 1 source committed.
- No physical disks modified. No disk was erased, formatted, or repartitioned.
  All writes are in `workspace/` + `artifacts/`.

## What was tested

- Preflight: PASS on this host after podman install (was FAIL podman-missing at audit).
  `podman found / git found / Fedora 45 bootc base reference present /
  No obvious destructive disk-writing commands` — exit 0.
- Hardware report (text + JSON): PASS on this VM (see `artifacts/hardware-report*.txt/json`).
- Podman install: PASS — `apt-get install podman qemu-utils` on Ubuntu 24.04,
  podman 4.9.3, buildah 1.33.7, qemu-img 8.2.2. This host is Ubuntu, NOT the
  recommended Fedora build host.
- Container build: see Failed / Blocked below.

## What passed

- Source audit, upstream verification, preflight (after install), hardware
  discovery scripts, branding tokens, ISO config, git commit.

## What failed

- Container build, first attempt (2026-11-24 17:31 EST):
  `podman build --pull=always -t localhost/vyra-os:0.1.0-dev -f Containerfile .`
  failed at STEP 1/15 pulling the pinned base:
  `Error: creating build container: initializing source
  docker://quay.io/fedora/fedora-bootc@sha256:d440aea898005f376bbf0bbe06c216abdba68dcdb6dfa5cb0fa246cd03fa8d8a:
  can't talk to a V1 container registry` — BUILD_EXIT=125.
  Log: `artifacts/build-0.1.0-dev.log`. Image inspect: FAILED (image not known).
- Diagnostic: a small Docker Hub pull (`hello-world:latest`) DID succeed
  after one TLS-handshake retry, so podman + egress proxy can pull in general.
  Quay API via curl also succeeds. The Quay registry pull is the failing path —
  possibly the pinned manifest-list digest with podman 4.9.3, or the egress
  proxy handling of `quay.io/v2/`. A tag-only pull
  (`podman pull quay.io/fedora/fedora-bootc:45`) was attempted next — it
  SUCCEEDED (see Update below). The digest pin was then fixed to the amd64
  child digest, and attempt 2 failed later on a different host limit
  (missing /dev/fuse, see Update below).

## What remains blocked

- No container image built in this session (see above).
- No ISO — Phase 2 gate, not attempted until a container image builds.
- No QEMU boot test, no Victus test, no entry-level test.
- No CI workflow run (GitHub Actions not run in this session).
- HP Victus exact SKU still pending from the owner.
- This VM: 7.7GB RAM (only ~0.5GB free at build time), Ubuntu host, old
  podman 4.9.3 — below the recommended Fedora host + 80GB + RAM headroom
  for a Plasma bootc build. Even after a successful pull, a full Plasma
  build may be slow or memory-constrained here.

## Build artifacts and verified locations

- `workspace/vyra-os/Vyra-OS-Master-Directive-SOURCE.md` — directive verbatim.
- `workspace/vyra-os/Vyra-Foundation/` — Phase 1 source, git `e1e1084`.
- `workspace/vyra-os/Vyra-Foundation/artifacts/build-0.1.0-dev.log` — failed build log.
- `workspace/vyra-os/Vyra-Foundation/artifacts/hardware-report-this-vm.txt`
- `workspace/vyra-os/Vyra-Foundation/artifacts/hardware-report.json`
- No ISO, no image, no checksum exists for 0.1.0-dev yet. Do not claim otherwise.

## Time and resource requirements for the next phase

- Phase 2 needs, in order: (1) resolve the Quay pull — try tag-only pull,
  then a newer podman (Fedora host or podman 5.x) or `skopeo` copy, then
  retry the build; (2) a Fedora build host (or a VM with 16GB+ RAM and
  80GB+ free) for a credible Plasma build; (3) `bootc-image-builder` ISO
  run via `scripts/build-iso.sh`; (4) QEMU/KVM boot test.
- Owner input needed: exact HP Victus SKU (model/product number) when
  available, and a decision on build host — Fedora host/VM, or continue
  attempting on this Ubuntu VM with its limits stated above.
- Do NOT proceed to claiming a bootable OS, a certification, or a release
  until the container build + image inspect + ISO + QEMU boot all have
  recorded PASS evidence.

## Update — tag-only Quay pull (2026-11-24 17:35 EST)

Tag-only pull SUCCEEDED: `podman pull quay.io/fedora/fedora-bootc:45`,
PULL_EXIT=0, 28 blobs + config, image Id `0e96e9e184db`, 2.02GB.
`podman image inspect` RepoDigests:
- `quay.io/fedora/fedora-bootc@sha256:49a5a46879e972f231d1045bf12a7801f35d262c4adf4cb2d874436bebbe0ec3` (amd64 child)
- `quay.io/fedora/fedora-bootc@sha256:d440aea898005f376bbf0bbe06c216abdba68dcdb6dfa5cb0fa246cd03fa8d8a` (manifest list)

So the manifest-list digest itself was correct; podman 4.9.3 just cannot
pull by it. The Containerfile now pins the amd64 child digest
(`49a5a468…`), git-committed.

## Update — build attempt 2, child-digest pin (2026-11-24 17:36 EST)

Digest pull WORKED: STEP 1/16 pulled the base by child digest, all blobs
copied, config written. Then the build failed at container creation:
`Error: mounting new container: … using mount program /usr/bin/fuse-overlayfs:
fuse: device not found, try 'modprobe fuse' first … exit status 1`,
BUILD2_EXIT=1. Log: `artifacts/build-0.1.0-dev-attempt2.log`.
Cause: `/dev/fuse` does not exist in this VM and `modprobe fuse` fails
("Module fuse not found in directory /lib/modules/7.0.0-44-generic").
Native overlay is in the kernel (`nodev overlay` in /proc/filesystems)
but podman fell back to fuse-overlayfs and that path is dead here.
This is a host limitation, not a Containerfile error.

## Update — build attempt 3, vfs storage driver (in progress)

Workaround: `vfs` storage driver with a separate graphroot, which needs
no overlay/fuse mount. First try failed instantly on a podman limit —
runroot path longer than 50 characters. Retried with short paths:
`--root $PWD/.vfs --runroot /tmp/vr --storage-driver vfs build`.
Log: `artifacts/build-0.1.0-dev-attempt3-vfs.log`. Result to be recorded
here when it lands. VFS is slower and uses more disk, but 147GB is free.
If vfs also fails, Phase 1 stays source-complete / build-blocked and the
next step is a real Fedora host or VM with fuse/overlay support — not
more retries in this VM.

## Update — build attempt 3, vfs (2026-11-24 17:51 EST)

VFS worked past the mount problem: STEPS 2–9 (LABELs) succeeded, so vfs
container creation works in this VM. It failed at STEP 10/16, the dnf5
install RUN:
`error running container: from /usr/bin/crun creating container for
[/bin/sh -c dnf5 install …]: cannot open sd-bus: No such file or directory`,
BUILD3_EXIT=1. Log: `artifacts/build-0.1.0-dev-attempt3-vfs.log`.
Podman reports CgroupManager=systemd, crun 1.14.1, host PID 1 is systemd —
so this is crun trying to reach systemd's bus from the build container
and not finding it, a known sandboxed-host failure mode, not a
Containerfile error.

## Update — build attempt 4, vfs + cgroupfs (2026-11-24 17:54 EST, confirmed 17:56)

cgroupfs fixed the sd-bus error — the build got to STEP 10 again, fast,
on cache. It then failed at the same RUN step with a NEW error:
`error running container: … ioctl(SIOCSIFFLAGS): Operation not permitted`,
BUILD4_EXIT=1, image inspect FAILED. Log: `artifacts/build-0.1.0-dev-attempt4-vfs-cgroupfs.log`.
Confirmed on completion (not just from the live log): the failure is at
container creation for the RUN step, before dnf runs at all.

## Update — build attempt 5, vfs + cgroupfs + --network host (2026-11-24 17:59 EST)

`--network host` WORKED past container creation: STEP 10's dnf actually
ran — the SIOCSIFFLAGS error is gone. dnf then failed on TLS:
`Curl error (60): SSL peer certificate or SSH remote key was not OK …
[SSL certificate OpenSSL verify result: self-signed certificate in
certificate chain (19)]` for mirrors.fedoraproject.org and the Fedora
updates archive. BUILD5_EXIT=1, image inspect FAILED.
Log: `artifacts/build-0.1.0-dev-attempt5-vfs-cgroupfs-hostnet.log`.
Cause: the sandbox egress proxy MITMs TLS. The host trusts it because
`/usr/local/share/ca-certificates/hatch-egress-ca.crt` (symlink to
`/run/hatch/cell-anchors/hatch-egress-ca.pem`, "Hatch Sandbox Egress CA",
self-signed) is in the host CA store — host curl to the same mirrors
returns 200, openssl verify 0. The Fedora container image does not have
that CA, so dnf rejects the chain. Rejected workaround: `sslverify=false`
— that would sacrifice TLS verification; not used.

## Update — build attempt 6, + bind-mounted egress CA for one RUN (in progress)

Fix: the CA cert (certificate only, extracted with `openssl x509` — no
private key, verified by grep) is bind-mounted from the build context
(`certs/hatch-egress-ca.crt`, gitignored, never committed) into the dnf
RUN via `RUN --mount=type=bind,…,ro`, trusted with `update-ca-trust`,
dnf installs, then the CA is removed and trust is updated again — all in
one RUN layer, so the sandbox CA never lands in a committed image layer.
Command: same vfs + cgroupfs + `--network host` build, `--pull=newer`.
Log: `artifacts/build-0.1.0-dev-attempt6-vfs-ca.log`.
If this fails, the remaining ladder is: `buildah --isolation chroot`,
then GitHub Actions CI (no MITM proxy there), then a Fedora host.

## Update — build attempt 6, CA bind-mount (2026-11-24 18:23 EST)

The TLS workaround WORKED: dnf trusted the proxy, metadata loaded, and
all 806 packages installed (Plasma 6.8.3, KDE, PipeWire, etc.). The build
then FAILED at the very end while committing that layer:
`storing layer "861ca11ba675…" to file: io: read/write on closed pipe`,
BUILD6_EXIT=125, image inspect FAILED — no image. So the install itself
is proven good; the failure is podman/vfs storing the finished layer, a
new failure mode (not the Containerfile, not dnf, not TLS). The CA was
removed again in the same RUN as designed. Log:
`artifacts/build-0.1.0-dev-attempt6-vfs-ca.log`. Rescue check: no working
container survived (`podman ps -a` empty), disk 142G free — not a space
issue, nothing to commit. Attempt 7 started (2026-11-24 ~18:25 EST):
`buildah --isolation chroot`, same vfs storage, host network, CA
bind-mount, tag `localhost/vyra-os:0.1.0-dev`. Log:
`artifacts/build-0.1.0-dev-attempt7-buildah-chroot.log`.
First try FAILED instantly (BUILD7_EXIT=125): `Error: accepts at most 1
arg(s), received 6` — the `--pull newer` flag did not bind its value
(buildah's `--pull` takes an optional value, so `newer` fell through as
a positional arg), and the follow-up `podman image inspect` failed with
`database static dir "" does not match our static dir "…/.vfs/libpod"`:
moving the repo directory broke podman's libpod DB path. Diagnosis:
`buildah images` reads the same storage fine (base 0e96e9e184db + LABELS
image 4a4949e26e6f both present, cache intact), only podman's DB is
unhappy — verification will use buildah, not podman, until that is
addressed. Retry 7b started 18:28 EST with `=`-bound flags and `--pull`
dropped (its default already pulls if newer/not present). Log:
`artifacts/build-0.1.0-dev-attempt7b-buildah-chroot.log`.
Retry 7b FAILED in 37s at STEP 10: buildah chroot cannot do the
bind-mount remount in this sandbox — `remounting "…/mnt/rootfs/tmp/
hatch-egress-ca.crt" in mount namespace with flags 0x1 instead of 0x0:
operation not permitted`, BUILD7B_EXIT=1. So the CA bind-mount works
under podman/crun (attempt 6 proved it) but NOT under buildah chroot.
Podman DB fix: removing the stale `.vfs/db.sql` (backup
`/tmp/vyra-libpod-db.sql.bak`) fixed the mismatch — `podman images`
again lists the base + LABELS images, cache intact. Attempt 8 started
(2026-11-24 ~18:29 EST): podman, same proven attempt-6 recipe (vfs +
cgroupfs + `--network host` + CA bind-mount), tag
`localhost/vyra-os:0.1.0-dev` — retrying the layer commit that failed
once with the pipe error. Log:
`artifacts/build-0.1.0-dev-attempt8-vfs-ca.log`. Attempt 8 was CUT OFF
by a runtime restart (~18:44 EST): log ends at dnf `Complete!` (813
packages, 0 errors), no BUILD8_EXIT, no image. Podman itself was gone
after the restart (apt-installed in the old VM, not persisted) —
reinstalled 18:58 EST (podman 4.9.3, buildah 1.33.7, crun 1.14.1).
Storage survived (.vfs 94G, 68 layer dirs), but `localhost/vyra-os`
is NOT in it — the save did not land. Attempt 9 started ~18:59 EST:
same podman recipe, rerun. Log:
`artifacts/build-0.1.0-dev-attempt9-vfs-ca.log`. Attempt 9 FAILED in
~4 min at STEP 10, same TLS error as attempt 5 — the CA bind-mount ran
but the cert did not match the proxy chain. Root cause: the egress CA
is PER-VM and changed across the restart (same name, different
fingerprint: live 65:99:58:DB:…, repo file F2:67:80:7A:…; host curl
still 200, so the host store has the new CA). The repo's cert was
extracted pre-restart and was stale. Fix: re-extracted the current CA
(cert only, no private key, fingerprint verified matching live) and
noted the rotation rule in the Containerfile. Attempt 10 started
~19:03 EST, same podman recipe. Log:
`artifacts/build-0.1.0-dev-attempt10-vfs-ca.log`. Attempt 10: dnf
succeeded again (813 packages), then the layer commit failed AGAIN
with the identical error — `storing layer "2eba24b7f531…" to file: io:
read/write on closed pipe`, BUILD10_EXIT=125, no image. Twice now at
the same step, so this is systematic, not a flake: the vfs driver
cannot store one huge dnf layer in this sandbox. Attempt 11 started
~19:18 EST: the install is split into three smaller RUNs (Plasma,
system, tools), each repeating the CA trust dance and removing the CA
again, to test whether smaller layers store cleanly. Log:
`artifacts/build-0.1.0-dev-attempt11-vfs-split.log`. If small layers
fail the same way, the next rung is GitHub Actions CI. Attempt 11
FAILED at the FIRST small RUN (Plasma only) with the identical error —
`storing layer "2ff338b95ef8…" to file: io: read/write on closed pipe`,
BUILD11_EXIT=125. So it is NOT layer size. Decisive test: a trivial
`podman run` + `podman commit` (one file changed) SUCCEEDED
(COMMIT_EXIT=0) — the commit path itself works. The failure is
specific to the dnf layer's content. Debug build started ~19:33 EST:
Plasma RUN only with `--log-level=debug`, to capture the swallowed
underlying error (`Containerfile.debug`, log
`artifacts/build-debug-plasma.log`). Debug build FAILED the same way
(BUILD_DEBUG_EXIT=125, ~19:47 EST) but the log is informative: the
tar writer fails on EVERY file with "Can't add file … to tar: io:
read/write on closed pipe" — the first failure (19:44:53, a Breeze
icon SVG) comes ~85s after COMMIT starts (19:43:28), with no
level=error/warning logged at all. So the pipe's read end is already
closed when the tar stream starts; the reader (tar-split assembler)
dies silently at setup. Not one bad file, not size. Inode check (attempt-11 follow-up): `df -i` reports 0/0 (filesystem does
not expose inode stats — inconclusive), but `.vfs` holds 5,481,436
files across its layers; `podman system df` shows 18 images, 2.016GB
(100% reclaimable). No confirmation of inode exhaustion, so the
commit failure's root cause remains unproven. Attempt 12 started
~19:52 EST — the export path, which uses a different save mechanism
than the broken layer store: install everything inside a RUNNING
container (`podman run`, same CA dance via a bind-mounted cert), then
`podman export` the container to a rootfs tarball
(`artifacts/vyra-os-0.1.0-dev-rootfs.tar`), then test `podman import`
of that tarball as the image. Log:
`artifacts/build-0.1.0-dev-attempt12-export.log`. If export works,
Phase 1 has a real rootfs even if import fails; if export fails the
same way, the in-VM ladder is exhausted and the next rung is GitHub
Actions CI. Attempt 12 result (~20:20 EST): RUN_EXIT=0 (dnf inside
the container installed all 813 packages, "Complete!") and
EXPORT_EXIT=0 — the export SUCCEEDED. The rootfs tarball exists:
`artifacts/vyra-os-0.1.0-dev-rootfs.tar`, 4,970,950,144 bytes. This is
the first real Vyra OS filesystem artifact. Import FAILED on a new,
fixable cause: `writing blob … /var/tmp/container_images_storage…/1:
no space left on device` — /var/tmp is a small tmpfs and the blob is
~5GB. (The log's IMPORT_EXIT=0 is wrong — it measured tee, not
podman; the import error and "image not known" are the truth.)
Import retry started ~20:21 EST with TMPDIR set to a workspace
directory on the big disk. Import SUCCEEDED (~20:24 EST):
Id `d8bda62e53c93756840d81a4acb88ac51cd8abb8d822284b26823fc702e1246a`,
Size 4,970,951,255 bytes. **The Vyra OS 0.1.0-dev image EXISTS.**
Root cause of the first import failure: /var/tmp is a 2.0G tmpfs and
the blob is ~5GB — TMPDIR on the big disk fixed it. Tarball sanity:
os-release, flatpak, plasma binaries present. One flag: the tarball
contains an entry `tmp/hatch-egress-ca.crt` (the bind-mount
mountpoint placeholder — expected to be empty, content being
verified). Labels=map[] on import — `podman import` does not carry
labels, so the image has NO Vyra labels yet; a label-only commit via
`buildah config` is being tested (LABEL steps committed fine in every
attempt, and the trivial commit worked, so a metadata-only commit
should succeed). Verification of the image (os-release, bootc dir,
package count, no CA anchor) also running.
SIOCSIFFLAGS is bringing a network interface up inside the container's
network namespace — this sandbox denies that capability (no CAP_NET_ADMIN
in the build's namespace). Each workaround has peeled one layer:
manifest-list digest → fuse mount → sd-bus → network-namespace setup.
The Containerfile is not the problem; the sandbox's container RUN
execution is.

Standing rule from the owner (2026-11-24): find the best workaround
without sacrificing functionality or performance, and articulate plainly
how unfinished parts are handled. The workaround ladder, in order:
1. `podman build --network host` — uses the host network namespace, so
   crun creates no interface and needs no SIOCSIFFLAGS; dnf still gets
   full network. No functionality sacrificed. (Attempt 5.)
2. `buildah build --isolation chroot` — runs RUN steps in a chroot on the
   host, no container / network namespace at all. Industry-standard for
   sandboxed builds. (Attempt 6 if 5 fails.)
3. GitHub Actions CI — the repo already has `.github/workflows/build.yml`
   (ubuntu-latest + podman); the image builds where the host allows it.
   Source stays reproducible; nothing is faked locally. (Fallback.)
4. A Fedora host/VM with fuse + overlay + full capabilities — the
   recommended build host from the start. (If 1–3 all fail, Phase 1
   stays source-complete / build-blocked in this VM, honestly, and the
   build moves there.)

## Phase 1 outcome (final, 2026-11-24 ~20:28 EST)

**Phase 1 is source-complete AND image-complete.** The Vyra OS 0.1.0-dev
container image exists, is verified, and carries the Vyra labels.

### Completed
- Full source scaffold: Containerfile (Fedora 45 bootc, pinned amd64 child
  digest), KDE Plasma + system package set, hardware-report tool, branding,
  bootc-image-builder ISO config (Phase 2 gate), dependency/application
  docs, MIT licence, CI workflow, preflight script.
- Rename from VFM/44 OS to Vyra OS complete (contents commit 2ebc445,
  directories commit e3993ab), zero leftovers outside the verbatim
  SOURCE file and historical logs.
- Image built and verified (see below).

### The image
- Tag: `localhost/vyra-os:0.1.0-dev`
- Id: `8bfa7eabc814a22870667d8e8ab4ab2be8370df8b386475b73cdfc9606373695`
- Size: 4,970,953,819 bytes
- Base: Fedora Linux 45 (Forty Five), stable; `/usr/lib/bootc/` present
  (bound-images.d, initramfs-setup, install, kargs.d)
- Packages: 1,347 installed (`artifacts/vyra-os-0.1.0-dev-packages.txt`),
  including plasma-desktop 6.8.3, sddm, dolphin, konsole, NetworkManager,
  PipeWire/WirePlumber, BlueZ, firewalld, Flatpak, Podman, btrfs-progs,
  cryptsetup, fwupd
- Labels: all eight Vyra labels present (title, description, vendor,
  version, io.vyra.base, base-digest, base-manifest-list-digest,
  base-digest-checked)
- Rootfs tarball: `artifacts/vyra-os-0.1.0-dev-rootfs.tar`
  (4,970,950,144 bytes)

### Tested — passed
- Preflight script passes (after the false-positive fix).
- Hardware discovery runs on this VM (ENTRY class; discovery only).
- dnf installs succeed repeatedly (813 packages, 0 errors, attempts
  6/10/11/12 + debug build).
- Trivial `podman run` + `podman commit` succeeds.
- `podman export` of the fully installed container succeeds.
- `podman import` of the rootfs tarball succeeds (with TMPDIR on the
  big disk).
- Label-only `buildah config` + `buildah commit` succeeds.
- Image self-check: os-release, bootc dir, package count, plasma
  version, no sandbox CA anchor, no CA content in the tarball
  (the `tmp/hatch-egress-ca.crt` entry is an empty 0-byte mountpoint
  placeholder).

### Tested — failed (and what it means)
- Plain `podman build` layer commit: FAILED four times (attempts 6, 10,
  11, debug) with `storing layer … to file: io: read/write on closed
  pipe`, exit 125 — regardless of layer size. Debug logging shows the
  tar reader dies silently before the first file is written; no
  underlying error is logged. The vfs layer-store path is broken for
  dnf-sized layers in this sandbox. Worked around via export/import;
  the Containerfile as written will NOT build with plain `podman build`
  on this host. It should build on a real Fedora host or in GitHub
  Actions CI.
- `buildah chroot` bind-mount remount: denied by the sandbox.
- `podman import` with default TMPDIR: failed — /var/tmp is a 2.0G
  tmpfs, blob is ~5GB. Fixed by TMPDIR on the big disk.

### Blocked / not done
- **No ISO.** Phase 2 gate (`scripts/build-iso.sh` + bootc-image-builder)
  has not run. A container image alone is not bootable media.
- **No boot test.** Nothing has booted — no QEMU/KVM test, no hardware
  boot. No hardware is certified (no HP Victus SKU from the owner yet;
  this VM is not a target).
- **CI never ran.** GitHub Actions workflow exists but the repo is
  local-only (no remote, no owner GitHub account wired up).

### Artifact locations
- Repo: `workspace/vyra-os/Vyra-Foundation/` (git; image Id and logs
  committed with this report)
- Image: local podman storage only (`.vfs`); NOT pushed to any registry
- Rootfs: `artifacts/vyra-os-0.1.0-dev-rootfs.tar`
- Packages: `artifacts/vyra-os-0.1.0-dev-packages.txt`
- Logs: `artifacts/build-0.1.0-dev-attempt*.log`,
  `artifacts/build-debug-plasma.log`,
  `artifacts/build-0.1.0-dev-attempt12-export.log`
- Acceptance: `docs/PHASE_1_ACCEPTANCE.md` (CI box still unchecked)

### Time / resources for Phase 2
- Phase 2 = ISO via bootc-image-builder from this image, then a QEMU/KVM
  boot test. Estimated: one build-iso run (image is ~5GB; the ISO build
  needs several GB of scratch on the big disk, TMPDIR set the same way)
  plus a boot test. The in-VM route for the ISO is unproven — if
  bootc-image-builder hits the same sandbox storage limits, Phase 2
  moves to GitHub Actions CI or a Fedora host, which needs the owner's
  GitHub account / host decision.
- Still needed from the owner: exact HP Victus SKU; build-host decision
  if the in-VM ladder is exhausted in Phase 2.
