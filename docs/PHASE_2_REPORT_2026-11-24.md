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
