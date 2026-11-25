# Fedora Host Setup — building the Vyra OS ISO (Phase 2)

The ISO cannot be built on Coby's sandbox VM: the builder
(bootc-image-builder) needs privileged containers and loop devices, and
the sandbox denies both. A real Fedora machine builds it cleanly. This
guide is the whole path.

## What the host needs

- Fedora 42 or newer (Workstation or Server), x86-64, with internet.
- `podman` and `git`: `sudo dnf install -y podman git`
- About 20 GB free disk (base image ~2 GB, Vyra image ~5 GB, ISO ~5–7 GB,
  plus build scratch).
- A user account with `sudo`.

## Get the code

If the repo is already on GitHub, clone it:

```
git clone <your-repo-url> vyra-os
cd vyra-os/Vyra-Foundation
```

If it is not on GitHub yet, ask Coby for the repo files (he has the full
`Vyra-Foundation` tree ready to hand over).

## Build the ISO

One command, from inside `Vyra-Foundation`:

```
chmod +x scripts/build-iso-fedora.sh
./scripts/build-iso-fedora.sh
```

What it does:

1. Creates the empty CA placeholder the build needs
   (`certs/hatch-egress-ca.crt` — empty on a normal host; the build skips
   it. Never put a real certificate in it here).
2. Builds the Vyra image if it is not already present
   (`localhost/vyra-os:0.1.0-dev`, ~813 packages on the Fedora 45 bootc base).
3. Runs bootc-image-builder (privileged, as the tool requires) and writes
   the Live ISO to `artifacts/`.

Expect 20–45 minutes depending on the machine and connection. When it
finishes, verify:

```
sha256sum artifacts/*.iso
ls -la artifacts/*.iso
```

## Boot-test the ISO

Fastest is on this same Fedora host, if it has KVM (most real machines do):

```
ls /dev/kvm   # if this exists, KVM is available
sudo dnf install -y qemu-system-x86
qemu-system-x86_64 -m 4096 -smp 2 -enable-kvm -cdrom artifacts/*.iso -boot d -display gtk
```

That boots the Live ISO to the installer. A successful boot to the
installer welcome screen is the pass. Installing it onto a disk is a
separate step — do not install it on the host's own drive without deciding
that explicitly first (use a spare disk or a blank virtual disk).

If the host has no KVM, the same command without `-enable-kvm` still
boots, just slowly (emulation). Or send the ISO to Coby: he has QEMU
ready and will boot-test it there. The ISO is several GB, so it needs a
file-sharing link (Google Drive, or any host that takes large files) —
tell Coby and he will fetch it.

## What NOT to do on the host

- Do not run the sandbox variant `scripts/build-iso.sh` here — it is
  written for Coby's VM (custom storage paths, proxy certificates).
- Do not put anything in `certs/` except the empty placeholder the script
  creates. That directory is gitignored for a reason.
- Do not install the ISO onto the host's own drive unless that is a
  deliberate, separate decision. Building the ISO is safe; installing it
  erases the target disk.

## If the build fails

Save the full output (it is long) and send it to Coby with:

- the exact command that was run,
- the last 30 lines of output,
- `podman --version` and `cat /etc/fedora-release`.

## The GitHub route is still available

If the Fedora host stalls, the GitHub Actions route is already prepared
(`.github/workflows/build.yml`, `iso-build` job). Pushing the repo to
GitHub builds the ISO there instead. Either route produces the same ISO.
