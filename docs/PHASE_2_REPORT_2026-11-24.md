# Phase 2 Report — Vyra OS Core Operating System (Bootable Foundational Image)
Date: 2026-11-24. Directive Phase 2 deliverable: **Bootable foundational image.**

## Phase 2 items (directive §14) and where they stand
- Build the bootc image — DONE in Phase 1 (image `localhost/vyra-os:0.1.0-dev`,
  Id `8bfa7eab…`, 1,347 packages). This phase proves it is bootable.
- Configure the kernel and required drivers — kernel + drivers come from the
  Fedora 45 bootc base; `pciutils`, `usbutils`, `lshw`, `inxi`, `mesa-dri-drivers`,
  `vulkan-tools` installed. No Victus-specific driver tuning yet (no SKU).
- Configure networking and audio — NetworkManager (+wifi/bluetooth),
  PipeWire/WirePlumber, BlueZ installed.
- Configure security — SELinux enforcing (bootc base default), firewalld
  installed; LUKS2 is a Phase 7 installer concern, not yet exercised.
- Establish the update and rollback process — bootc's image-based update +
  rollback is inherent to the bootc base; not yet demonstrated by an actual
  update cycle (needs a second image version — later phase).

## Plan
1. Build a Live ISO (anaconda installer) from the 0.1.0-dev image with
   bootc-image-builder (`scripts/build-iso.sh`). Writes only to `artifacts/`.
2. Verify the ISO: size, SHA256, bootable structure, installer payload.
3. Boot-test in QEMU on this host. NOTE: no `/dev/kvm` here, so TCG
   emulation only (slow). Goal for this phase: prove the ISO boots to the
   installer. Full hardware certification is Phase 8.
4. Report: what passed/failed/blocked, artifact locations, next phase.

## Environment notes (carried from Phase 1)
- Build host: Ubuntu 24.04.5 LTS VM, 4 vCPU, 7GB RAM, 136G free disk.
  NOT the recommended Fedora host. Podman 4.9.3 with vfs driver;
  plain `podman build` layer-commit is broken here (pipe error) — the
  image was assembled via export/import.
- Egress proxy MITMs TLS; host CA bundle trusts it (verified, curl 200).
  The builder container gets the host CA bundle bind-mounted over its
  CA bundle paths (see `scripts/build-iso.sh`).
- `/var/tmp` is a 2.0G tmpfs — TMPDIR is set to a workspace dir on the
  big disk for the ISO build.
- No physical disks will be modified. No KVM. qemu-system-x86_64 not
  installed yet at phase start (qemu-img 8.2.2 only).

## Attempts

### Attempt 1 — bootc-image-builder, privileged (FAILED, ~20:35 EST)
Log: `artifacts/build-iso-attempt1.log`. The bib image pulled fine
(3 blobs + config). The builder container then failed to START:
`Error: crun: mount 'sysfs' to 'sys': Operation not permitted: OCI
permission denied`, exit 126. No ISO. Diagnosis: this sandbox denies
privileged containers at creation (sysfs mount). Diagnostic runs
confirmed: the bib image starts fine WITHOUT --privileged (bib itself
then refuses: "this command requires a privileged container"), and
fails the same sysfs error WITH --privileged. Second independent
blocker: no /dev/loop* devices exist on this host, which osbuild disk
work needs. QEMU install SUCCEEDED in parallel: qemu-system-x86_64
8.2.2 at /usr/bin/qemu-system-x86_64 — boot-test tooling is ready,
waiting on an ISO.

### Attempt 2 — bootc-image-builder, --cap-add=all instead of --privileged (FAILED, ~20:37 EST)
Log: `artifacts/build-iso-attempt2-capadd.log`. The container started
fine, but bib's own validation refuses: `error: cannot validate the
setup: this command requires a privileged container`, exit 1, in 4.5s.
`--cap-add=all` does NOT satisfy bib's check — it wants a privileged
container specifically. No ISO.

### Conclusion: the in-VM ISO path is exhausted
- Privileged containers cannot start in this sandbox (sysfs mount
  denied at creation, attempt 1).
- bib refuses to run without privileged (attempt 2).
- No /dev/loop* devices exist for osbuild disk work.
- The plain `podman build` layer-commit path is already broken here
  (Phase 1), so the image can only be assembled via export/import.
- QEMU 8.2.2 IS installed and ready — the boot test can run here as
  soon as an ISO exists from anywhere.

### CI preparation (done in this phase, so the ISO can build elsewhere)
- `.github/workflows/build.yml` gained an `iso-build` job: builds the
  image with rootful podman, runs bib `--type iso` privileged on the
  GitHub runner, uploads the ISO as an artifact. Nothing is published.
- The Containerfile's dnf RUNs now call `scripts/sandbox-ca.sh`
  (bind-mounted): it trusts the egress CA only when the mounted cert is
  non-empty. On CI the workflow creates an EMPTY placeholder cert, so
  the script skips trusting and dnf just works (no proxy on runners).
  The old inline `cp`/`update-ca-trust`/`rm` sequence is replaced.
- Validated both paths in a running container (~20:38 EST): real cert
  → trusted, `dnf5 makecache` succeeds, removed cleanly; empty cert →
  skipped, no anchor, remove is a no-op. The full `podman build` with
  the new RUNs cannot be verified end-to-end in this sandbox (the
  layer-commit path is broken here), so the first CI run is the real
  test of the new Containerfile.
- The existing `container-build` job also got the placeholder-cert
  step (it uses the same Containerfile).

### Route change (owner, ~23:30 EST): Fedora host instead of GitHub
The owner picked the Fedora host route over GitHub Actions. The GitHub
path is PARKED, not deleted: the `iso-build` workflow job stays in the
repo, and the token request sent for it is simply unused (nothing was
entered). Prepared for the Fedora route and committed:
`scripts/build-iso-fedora.sh` (plain rootful podman, default storage,
empty CA placeholder auto-created, bib privileged — no sandbox
adaptations) and `docs/FEDORA_HOST_SETUP.md` (prerequisites, clone,
build, verify, QEMU/KVM boot test, how to get the ISO back for the
boot test). The sandbox variant `scripts/build-iso.sh` must NOT be run
on a Fedora host. Still unknown: WHICH Fedora host the owner has in
mind (already have one / will install Fedora / needs help setting one
up) — asked in the reply. Once the ISO exists anywhere, verification
and the QEMU boot test proceed as planned.

## Phase 2 outcome (final, 2026-11-24 ~20:40 EST)

**Phase 2 is NOT complete: no ISO was produced on this host.** The core OS
image is real and verified (Phase 1), but turning it into a bootable ISO
cannot happen on this sandbox VM — the tool that does it
(bootc-image-builder) needs privileged containers and loop devices, both
of which this environment denies. This is an environment limit, not a
problem with the Vyra image.

### Tested — passed
- bootc-image-builder image pulls fine on this host.
- The bib container starts WITHOUT --privileged (bib itself then refuses).
- QEMU 8.2.2 installed and ready for the boot test.
- `scripts/sandbox-ca.sh` validated on both paths (real cert trusts and
  dnf works; empty cert skips cleanly).

### Tested — failed
- ISO attempt 1 (privileged bib): container creation denied — crun
  sysfs mount, exit 126.
- ISO attempt 2 (--cap-add=all): bib's own validation refuses —
  "requires a privileged container", exit 1.
- No /dev/loop* devices exist (osbuild disk work needs them).

### Blocked
- ISO build: needs GitHub Actions CI (workflow ready) or a Fedora
  build host (owner decision).
- ISO verification and QEMU boot test: need an ISO first.

### Prepared for the next step (committed in the repo)
- `.github/workflows/build.yml`: new `iso-build` job (build image,
  bib `--type iso`, upload ISO artifact).
- `Containerfile`: dnf RUNs use `scripts/sandbox-ca.sh`, which works on
  both the sandbox (real CA) and CI (empty placeholder).
- `scripts/sandbox-ca.sh`: new helper, validated.

### Artifact locations
- Report: `docs/PHASE_2_REPORT_2026-11-24.md`
- Logs: `artifacts/build-iso-attempt1.log`,
  `artifacts/build-iso-attempt2-capadd.log`
- Image (unchanged from Phase 1): `localhost/vyra-os:0.1.0-dev`,
  Id `8bfa7eab…`

### Next phase
- Once the ISO exists (CI or Fedora host): verify it (size, SHA256,
  bootable structure), then boot-test in QEMU here (TCG, no KVM), then
  Phase 8 hardware certification on the Victus. Phase 3 (Desktop) can
  proceed in parallel with the ISO question — it is image work, not
  ISO work.

## CI runs (GitHub Actions, 2026-11-25) — appended after the in-VM work

### Run #1 — FAILED in ~19s (both jobs, exit 125)
- Trigger: owner's `Create build.yml` commit `00b5f7bc` (web UI).
- container-build 12s, iso-build 17s, no artifacts.
- Root cause: the pinned Fedora 45 bootc amd64 digest
  (`49a5a468…`) no longer existed in Quay ("manifest unknown") —
  Quay rebuilt the image 2026-11-25 12:01 UTC and the old digest was
  garbage-collected, so `podman build` failed instantly pulling the
  base image.
- Fix: re-pinned to the current digests (manifest list
  `2342f957…`, amd64 `bf0f127b…`, Fedora 45.20261125.0, kernel
  7.3.4-300.fc45), Containerfile labels updated (checked 2026-11-25),
  local commit `bbf40fe`, GitHub commit `f5d478b5`.

### Run #2 — FAILED (container-build PASS, iso-build FAIL)
- Trigger: the re-pin commit `f5d478b5`.
- container-build 6m 0s PASS (the re-pin worked; the image builds
  in CI). iso-build 5m 9s FAIL at the "Build Live ISO with
  bootc-image-builder" step (9s, exit 1).
- Root cause (from the owner's screenshots of the job log): bib's
  manifest step — "cannot build manifest: no default root filesystem
  type specified in container, please use '--rootfs' to set manually".
  The image declares no default rootfs.
- Fix: add `--rootfs btrfs` to the bib command (matches the Btrfs
  directive; the image ships btrfs-progs). Local commit `3be715a`.
- Upload blocked by GitHub's workflow-file API rule: apps cannot
  create/update `.github/workflows/*` through the API (403 "Resource
  not accessible by integration"). The owner must edit build.yml via
  the web UI; the updated file was sent as a chat attachment.
- Run #1: https://github.com/Danteleach/Vyra-os/actions/runs/45659127541
- Run #2: https://github.com/Danteleach/Vyra-os/actions/runs/45663106119
  Run #2's total time (~11 min) is the planning figure for run #3.

### Run #3 — FAILED (container-build PASS, iso-build FAIL)
- Trigger: the owner's `--rootfs btrfs` edit, commit `1e57bf9b`.
- Total 5m 59s. container-build passed again. iso-build failed
  again with exit code 1, in the "Build Live ISO" step (38s).
- The `--rootfs` fix WORKED: the manifest step completed ("Done
  generating manifest") and the disk-image step got as far as
  downloading packages. The failure came later, in osbuild's
  `org.osbuild.rpm` stage:
  - `fchownat() of /var/log/btmp failed: Operation not permitted`
  - `fchownat() of /var/log/lastlog failed: Operation not permitted`
  - `RuntimeError: mount: /run/osbuild/tree/dev: permission denied`
    (mount syscall failed, code 32), then "cannot run osbuild:
    error running osbuild: exit status 1".
- Reading: the bib container did not get the mount privileges
  osbuild needs on the GitHub-hosted runner, even running
  `--privileged` under podman. The chown failures on files in the
  build tree point the same way. This is a runner-environment
  limitation, not a defect in the Vyra image (which builds fine)
  or in the workflow's image steps.
- Fix to try (run #4): run the bib step under Docker instead of
  podman — Docker is preinstalled on the runner and is bib's
  documented path. bib cannot read podman's image store, so the
  image is pushed to a throwaway local registry first
  (`podman push` to 127.0.0.1:5000) and bib pulls it from there,
  running with `--network host`. If Docker fails the same way,
  that proves the runner environment itself is the blocker and
  the answer is the Fedora host route (scripts/build-iso-fedora.sh,
  already prepared and committed).
- Run #3: https://github.com/Danteleach/Vyra-os/actions/runs/45672852038
- Run #4: https://github.com/Danteleach/Vyra-os/actions/runs/45680080066
  (triggered by the owner's web-UI commit c6197bc, "Update build.yml",
  2026-11-25 13:55 EST; remote build.yml blob SHA matched local exactly).
  FAILED 2026-11-25 ~14:02 EST, 5m 47s total. container-build passed.
  iso-build failed with exit code 125 in the "Build Live ISO" step
  (41s). Root cause, from the owner's log (screenshot + text,
  15:38 EST): the registry handoff WORKED — `podman push` to
  127.0.0.1:5000 copied all image layers and wrote the manifest.
  The failure was my own flag: `docker run --pull=newer` — Docker
  only accepts "always", "missing" or "never" for --pull
  ("docker: invalid pull option: 'newer'"). So this failure was a
  one-word typo in the workflow, NOT the runner mount block and NOT
  the registry design. The Docker path itself is still untested:
  bib never started. Fix: `--pull=missing` (pull the bib image only
  if it is not already cached — correct Docker equivalent of the
  intended behaviour). Local commit for run #5.
- Run #5: https://github.com/Danteleach/Vyra-os/actions/runs/45697149816
  (triggered by the owner's web-UI commit ce97fad8, "Update build.yml",
  2026-11-25 15:40 EST; remote build.yml blob SHA matched local exactly).
  FAILED 2026-11-25 ~15:55 EST, 6m 16s total (iso-build 6m 16s,
  container-build 3m 11s). container-build passed. iso-build failed
  with exit code 1 in the "Build Live ISO" step (51s). Root cause,
  from the owner's log (screenshot + text, 16:58 EST): the registry
  handoff worked again, Docker pulled the bib image ("Downloaded
  newer image for quay.io/centos-bootc/bootc-image-builder:latest"),
  bib started ("Generating manifest manifest-iso.json"), then:
  "error: cannot build manifest: could not access container storage,
  did you forget -v /var/lib/containers/storage:/var/lib/containers/
  storage? (cannot find "/var/lib/containers/storage/overlay"
  (missing -v /var/lib/containers/storage:/var/lib/containers/
  storage mount?))". So bib reads its input image from container
  storage, and under Docker none was mounted — a missing mount,
  not the run #3 mount denial (osbuild never got reached). Fix for
  run #6: mount /var/lib/containers/storage into the bib container
  and point bib at localhost/vyra-os:ci, the name the iso-build job
  already builds with rootful podman on the same runner; the local
  registry is dropped (no longer needed). This is the decisive test
  of the Docker path: if osbuild then hits the same /dev mount
  denial as run #3, the runner itself is the blocker and the answer
  is the Fedora host route.

### Phase 2 status
- Still NOT complete: no ISO exists yet. Awaiting the owner's
  build.yml web-UI edit for the storage-mount fix, then run #6,
  then ISO download (7-day artifact retention), verification, and
  the QEMU boot test. If run #6 fails with the same osbuild mount
  denial under Docker, pivot to the Fedora host route.

### Research — how other bootc projects build ISOs on GitHub Actions (2026-11-25)

Owner-directed deep research + YouTube review (report:
`workspace/research_notes/bootc-iso-github-actions-workaround-20261125-2235/report.md`).
Findings, with corrections to earlier assumptions:

- **Verdict: hosted runners are NOT proven unable to build bootc
  disk images.** But the path tried in runs #1–#6 (hand-rolled
  `podman`/`docker run` of `quay.io/centos-bootc/bootc-image-builder:latest`,
  `--type anaconda-iso`, from a locally-built image) is the deprecated,
  fragile one. **No project found does it that way.**
- **Canonical pattern** (ublue-os/image-template, AeroCore-OS, fp-os/Agate,
  Aurora-LTS, Margine for qcow2): the official
  `osbuild/bootc-image-builder-action` on **pinned `ubuntu-24.04`**,
  pulling the already-pushed image **from GHCR** (never `--local` /
  `localhost:`), with `ublue-os/remove-unwanted-software` first to reclaim
  disk. The action runs `sudo podman --privileged --security-opt
  label=type:unconfined_t -v /var/lib/containers/storage:/var/lib/containers/storage`.
  **No Docker-based BIB invocation was found anywhere; BIB is
  Podman-only** — which explains run #5, and run #6 compounded Docker +
  a local image.
- **Correction:** run #3's exact error (`fchownat` on `/var/log/btmp` /
  `lastlog` + `mount: /run/osbuild/tree/dev: permission denied`) was
  **NOT found verbatim in any issue, discussion or video** — do not
  treat it as a documented "GitHub blocks this" fact. Closest known
  issues are different errors (BIB #446 storage-driver mismatch;
  BIB #736 bootloader permission denied on arm64).
- **Two independent suspects for Fedora 45:** (1) `quay.io/centos-bootc/bootc-image-builder:latest`
  was frozen when the repo was archived 2026-06-18 — it predates Fedora
  45 GA (Oct 2026), so an anaconda-iso build of a Fedora 45 image with a
  pre-Fedora-45 builder is a real mismatch suspect; (2) `anaconda-iso`
  itself is deprecated — osbuild.org says prefer `bootc-generic-iso` /
  `bootc-installer`; Universal Blue retired it Mar 2025, Margine Jun 2026.
- **YouTube added nothing:** no video addresses either failure; the
  GitHub Actions videos only build/push the container image; bib steps
  are always shown on a local machine. The only runner alternative any
  video demonstrates is a self-hosted/on-prem runner.
- **Recommended next fix (run #7):** replace the hand-rolled iso-build job
  with the action-based `build-disk.yml` pattern verbatim — container-build
  pushes to GHCR, iso-build pulls from GHCR, pinned `ubuntu-24.04`,
  storage reset per BIB #446, `rootfs: btrfs`, `--use-librepo=True`.
  Committed locally (see below).
- **If run #7 fails the same way:** qcow2-only diagnostic — if qcow2
  passes and anaconda-iso fails, the anaconda-iso pipeline (old builder +
  Fedora 45) is the problem, not the runner; pivot to Titanoboa live ISO
  (proven on hosted ubuntu-24.04 by Bluefin/Bazzite/Aurora/Margine) or the
  new `image-builder` `bootc-generic-iso`. `--in-vm` is a second-line
  experiment (no hosted-runner evidence). If an offline anaconda-iso is a
  hard requirement and none of that works: self-hosted runner on your own
  Fedora machine ($0) or Hetzner CX42 ~€12.49/mo (verify price).

### Phase 2 status
- Still NOT complete: no ISO exists yet. Awaiting the owner's
  build.yml web-UI edit for the action-based run #7 workflow, then run #7,
  then ISO download (7-day artifact retention), verification, and
  the QEMU boot test. If run #7 fails with the same osbuild mount
  denial under the action, run the qcow2 diagnostic; if that also fails
  the same way, pivot to the Fedora host route.

## Next build (run #9) — live ISO, anaconda-iso retired (2026-11-26)

Owner decision (2026-11-26 01:11 EST): the next revision ships an
Ubuntu-style live ISO — boot the ISO, land on a live Plasma desktop, try
the OS and test hardware compatibility, and only then install from the
desktop. No forced wipe, no installer-first boot.

### What happened to run #8's ISO

Run #8 built and the ISO verified (3.2 GB, sha256-verified), but the boot
test never reached the desktop: install attempt 1's graphical anaconda
died; attempt 2 (text install) deployed 5.3 GB to disk then stopped with
no finish marker; attempt 3 (custom kickstart skipping the `%post`
registry pull) was still deploying at 4.14 GB when the owner cancelled
it at 01:12 EST 2026-11-26, before the 1:20 AM cutoff. The walkthrough
subagent was closed with the cancellation; its `first-run/` evidence
(screenshots 01–66, logs, the 4.14 GB disk image) is preserved on disk.
The desktop walkthrough was never started — nothing about the desktop is
claimed to have passed.

### Why anaconda-iso is retired (not a retry)

Full research: `docs/INSTALL_DEEP_DIVE_2026-11-26.md` (run #9 spec).
Short version:

- `anaconda-iso` is deprecated upstream (osbuild.org: "on its way out —
  prefer `bootc-generic-iso` or `bootc-installer`"); the builder
  container (`quay.io/centos-bootc/bootc-image-builder:latest`) has been
  frozen since the repo was archived 2026-06-18, before Fedora 45 GA.
  Universal Blue retired it Mar 2025, Margine Jun 2026.
- It can never be a live desktop: it is an automated installer that
  erases the first disk it finds without asking.
- The stall's root cause is unresolved, not proven: the prime suspect
  for attempt 2 is the `%post` registry pull (the install pulls the
  whole ~5 GB image from ghcr.io from inside the VM — the guest almost
  certainly cannot reach ghcr.io through the host's MITM proxy, but the
  network test never produced a result); the prime suspect for attempt 3
  is TCG slowness (8–12x slower than KVM; the disk was still growing
  steadily when cancelled). Both point the same way: remove the
  install-time network dependency and stop treating a TCG full install
  as a quick test.

### What run #9 builds (Rank 1 — Titanoboa live ISO + qcow2 smoke test)

- **New installer image** `installer/Containerfile.live`: FROM the Vyra
  core image (`ghcr.io/danteleach/vyra-os:ci`) + `dracut-live`,
  `livesys-scripts`, `anaconda-live` (GTK first), `libblockdev-btrfs`,
  `dracut-config-generic`, `grub2-efi-x64-cdboot`, `plymouth`,
  `xorriso`/`isomd5sum`; `livesys_session=kde`; SDDM autologin via
  livesys; Anaconda profile `vyra` (`iso_files/vyra.conf`); kickstart
  installing from `containers-storage` with a `%post` `bootc switch`
  repoint only; `iso.yaml` at `/usr/lib/bootc-image-builder/iso.yaml`
  (label "Vyra-OS-Live", GRUB entries "Try Vyra OS" (default) and
  "Install Vyra OS"); EFI tree at `/boot/efi`; initramfs rebuilt with
  the live modules. The install payload is embedded by a nested
  `podman pull` inside the payload build, so install works offline.
- **Hook** `iso_files/configure_iso.sh` does the live-session +
  Anaconda work inside the payload build. Ported from
  bearyjd/bazzite-tower `installer/src/build.sh` and ublue-os/bluefin
  `iso_files/configure_iso_anaconda.sh` — not invented from scratch.
- **Workflow** `.github/workflows/build.yml` (owner applies via the
  GitHub web UI — apps cannot edit workflow files): `container-build`
  unchanged; `iso-build` replaced by `qcow2-smoke` (same bib action,
  `types: qcow2` — the diagnostic: if qcow2 builds and boots, the image
  is good and the problem was the ISO type); new `build-live-iso` job
  (`ublue-os/titanoboa@5c457c3d0518bd17e754be0fd98a60d29d26abb4`, the
  pin bazzite-tower uses). A handoff copy of the workflow lives at
  `workspace/vyra-os/build.yml-next-revision` for the owner to paste.
- **Correction to the deep-dive report (§3.1):** the current Titanoboa
  GitHub Action (HEAD `5c457c3d`, post-#138 "Only use container images
  as the only source of truth") takes ONLY `image-ref` and `iso-dest`
  inputs — no `hook-post-rootfs`, `flatpaks-list`, `kargs`,
  `builder-distro`, `container-image`, or `netinstall` input. The
  report's input list describes the pre-#138 version. All live-session
  config is therefore baked into the payload image (the hook runs as a
  RUN step in `Containerfile.live`), and the embedded payload comes
  from the nested `podman pull`, not from an action input. Verified by
  reading the action's `action.yml`, `main.sh`, and `build_iso.sh` at
  HEAD on 2026-11-26.

### Test plan for run #9 (honest timing)

- Boot the live ISO in QEMU TCG; expect a Plasma desktop (live boot is
  mostly decompression — tens of minutes in TCG, not hours). Screenshot
  each step; open/close Dolphin, Konsole, System Settings per the
  walkthrough checklist.
- From the live desktop, run the installer onto a second disk and let it
  finish — budget hours in TCG and do not call it a failure before
  then; if a KVM-capable host is available (owner's Fedora machine, or
  a cloud VM), run the install test there instead.
- Boot the installed disk and verify SDDM + Plasma. Record everything
  in `first-run/WALKTHROUGH.md`; untested stays untested.
- Also run the 2-minute guest-network test (`curl -sI https://ghcr.io`
  from inside a booted guest) to settle the `%post` network question
  with evidence before any further install attempt.

### Dakota verification — what the live ISO's installer actually is (2026-11-26)

The owner flagged a YouTube walkthrough ("Bluefin's New Installer",
Jorge Castro, Nov 23, 2026 — see deep-dive report §9): a live desktop
with a Try/Install welcome dialog, disk erase confirmation naming the
disk, install running in the background while a setup wizard runs in
parallel, ending installed with a disk recovery key and no forced
reboot. The installer in the video is called Dakota, provided by GNOME
OS; the video never mentions Titanoboa, and it is a GNOME flow, not
KDE. Verified before finalizing run #9 (Titanoboa README read in full;
`action.yml` / `main.sh` / `build_iso.sh` at HEAD `5c457c3d`;
projectbluefin/dakota and dakota-iso READMEs; tuna-os/fisherman and
tuna-os/installer READMEs; the video page text):

- **Titanoboa ships NO installer at all** — neither Dakota nor
  Anaconda. Its README (171 lines) never names Anaconda, Readymade,
  Dakota, or Tuna; the action takes only `image-ref` and `iso-dest`
  and just squashes the input image into an ISO. The installer is
  entirely the payload image's content. The question "does Titanoboa
  ship Dakota or Anaconda" has a third answer: it ships whatever the
  image carries.
- **"Dakota" is an OS image, not an installer app**: Bluefin built on
  GNOME OS, assembled from source (projectbluefin/dakota). The
  installer in the video is GNOME OS's installer running inside the
  Dakota live image. Dakota ISOs are not built with Titanoboa at all —
  dakota-iso uses its own 3-step assembler (live/Containerfile,
  build-live-squashfs.sh, build-iso.sh).
- **The KDE equivalent exists**: tuna-os/installer ("bootc-installer")
  — one fisherman backend, five desktop frontends (GNOME, KDE Plasma,
  COSMIC, Niri, XFCE), all driving the same recipe. The backend
  (tuna-os/fisherman) partitions/encrypts/installs via `bootc install
  to-filesystem`, handles LUKS2 + TPM2 with a recovery key, user
  account, Flatpaks, and offline install from media — the same
  capabilities the video shows. But it is young (2026), its frontends
  have parity gaps (see its docs/PARITY.md), it does not set language /
  keyboard / timezone yet, and it has never been proven inside a
  Titanoboa live image or on Fedora 45 / KDE. It ships as a Flatpak,
  which would need integrating into the payload build. The video
  itself is explicitly WIP (console commands visible, flatpaks
  missing in the demo).
- **Decision for run #9: Anaconda stays.** The run #9 live ISO's
  installer is Anaconda GTK (`liveinst`), installed by
  `iso_files/configure_iso.sh`. That is the documented Titanoboa
  default ("hands off to Anaconda or Readymade") and the KDE path
  proven end-to-end by bazzite-tower. **Plain statement: the run #9
  install UX will differ from the video** — Anaconda's installer UI,
  not the welcome-dialog + parallel-setup-wizard + recovery-key flow.
  Both give the required try-then-install live-desktop UX; Anaconda
  gives it now, with proof, while Dakota/Tuna-KDE gives a nicer
  version of it that is not yet proven for Vyra. Re-evaluate the Tuna
  KDE installer as a follow-up once its KDE frontend is proven in a
  live ISO (check its parity doc and Fedora packaging first).

### Status

- Run #9 is NOT built yet: the installer image, hook, profile,
  `iso.yaml`, and workflow are written and syntax-checked locally
  (2026-11-26); the workflow change is waiting for the owner to apply
  it via the GitHub web UI, after which CI runs it. Do not claim the
  live ISO works until CI builds it and it is boot-tested.
- Fallbacks, in order: Titanoboa fails in CI → Rank 2
  (`bootc-generic-iso` via image-builder); both ISO types fail →
  self-hosted runner on the owner's Fedora machine ($0) or Hetzner
  CX42 (~€12.49/mo, unverified — recheck price).
