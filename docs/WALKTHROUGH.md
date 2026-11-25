# Vyra OS — New User Walkthrough

> DRAFT — written 2026-11-24. File names, version numbers, and download links
> are the planned 0.1.0 values; they become final when the first release is
> published. If a link below doesn't work yet, the release isn't out.

## What is Vyra OS?

Vyra OS is a real Linux operating system for desktop PCs and laptops, built on
Fedora with the KDE Plasma desktop. It is designed for everyday use, gaming,
and creating — and it is built to be hard to break: if an update ever goes
wrong, it boots back to the last version that worked.

**Slogan:** ONE CORE. TWO WORLDS. EVERY DEVICE.

## What you need

- A 64-bit PC or laptop (the first release targets HP Victus laptops and
  similar modern machines; it also runs on most entry-level PCs).
- A USB flash drive, 8 GB or bigger. Everything on it will be erased.
- About 30 GB of free space on the computer's drive for the install.
- An internet connection for downloading the parts and for the upgrade packs.
- **Back up anything you care about first.** Installing an operating system
  can erase a drive. Vyra OS will only install where you tell it to, but a
  backup is the only real safety net.

## The three parts

Vyra OS comes in three parts, in this order. **Only Part 1 is required.**
Parts 2 and 3 are upgrades you add after installing.

| Part | What it is | Do you need it? |
| --- | --- | --- |
| **1 — Stability** | The core system. Boots, installs, and runs on its own. | **Yes — this is Vyra OS.** |
| **2 — Performance** | Tuning and gaming upgrades: faster startup, game mode, FPS overlay, graphics drivers. | Recommended, optional. |
| **3 — Aesthetics** | The full Vyra look: wallpapers, themes, login screen, boot screen, fonts, sounds. | Optional — install it to make Vyra look like Vyra. |

Total download for all three parts: about **3.8–4.0 GB**. On disk after
installing everything: about **10 GB**.

## Step 1 — Download Part 1

1. Go to the Vyra OS core repo releases page:
   `https://github.com/<owner>/vyra-os/releases`
2. Download **`vyra-os-0.1.0-core.iso`** (about 1.9 GB).
3. While it downloads, note the **SHA256 checksum** shown on the release page.

### Check the download (do not skip this)

A checksum proves the file you got is the file we published, with nothing
changed in transit.

On Windows (PowerShell):

```
Get-FileHash vyra-os-0.1.0-core.iso -Algorithm SHA256
```

On macOS or Linux (Terminal):

```
shasum -a 256 vyra-os-0.1.0-core.iso
```

Compare the long string of letters and numbers it prints with the one on the
release page. They must match exactly. If they don't, delete the file and
download it again.

## Step 2 — Make a bootable USB drive

You need a tool that writes the ISO to the USB drive. Any of these works:

- **Fedora Media Writer** (Windows, macOS, Linux) — pick "Custom Image" and
  choose the ISO.
- **Balena Etcher** (Windows, macOS, Linux) — pick the ISO, pick the USB drive,
  Flash.
- **Rufus** (Windows) — pick the ISO, leave the other settings alone, Start.

This erases the USB drive. When the tool says it is done, leave the drive
plugged in.

## Step 3 — Boot from the USB drive

1. Restart the computer.
2. As it starts, open the boot menu. The key is different per machine — try
   **F12, F9, F8, or Esc** (HP machines usually use F9 or Esc). If you miss
   it, restart and try again.
3. Pick the USB drive from the boot menu.
4. Vyra OS starts the installer.

## Step 4 — Install Vyra OS

The installer walks you through it:

1. Pick your language and keyboard.
2. Pick the drive to install on. **Double-check this screen.** Installing
   erases the drive you pick.
3. Create your user account and password.
4. Let it install. It takes roughly 10–20 minutes.
5. When it finishes, remove the USB drive and restart.

## Step 5 — First boot

1. Log in with the account you created.
2. You land on the Vyra desktop. Networking, sound, and the app store work.
3. A welcome window offers to check for updates and to fetch the upgrade
   packs. You can say yes now or do it later from the Vyra Pack tool.

## Step 6 — Add Part 2 (Performance)

1. Go to the Vyra packs repo releases page:
   `https://github.com/<owner>/vyra-os-packs/releases`
2. Download **`vyra-os-0.1.0-performance.vyrapack`** (about 1.1 GB) and check
   its SHA256 the same way as Step 1.
3. Open the **Vyra Pack** tool (in the application menu) and choose the pack
   file. It verifies the file, builds the upgrade, and asks you to reboot.
4. Reboot. Vyra now runs with the performance tuning and game mode.

You can also let the Pack tool download Part 2 for you — it fetches it from
the packs repo and checks it automatically.

## Step 7 — Add Part 3 (Aesthetics)

Same as Step 6, with **`vyra-os-0.1.0-aesthetics.vyrapack`** (about 1.0 GB).
After the reboot, Vyra has the full look: wallpapers, themes, login screen,
boot screen, and sounds.

If you installed Part 2 first, the Pack tool already knows where Part 3 is
and offers to fetch it next. If you skipped Part 2, Part 3 still installs
fine on its own.

## If something goes wrong

- **The computer won't boot after an upgrade:** Vyra keeps the previous
  version. At the boot screen, pick the older entry and the system comes back
  as it was. Then tell us what happened so we can fix it.
- **A download's checksum doesn't match:** delete it and download again. Never
  install a file that fails the check.
- **The installer can't see your drive:** make sure the drive isn't encrypted
  by another system (like BitLocker) and that there is free space. Ask for
  help with the exact message you see.
- **Wi-Fi doesn't work after install:** plug in an Ethernet cable if you can,
  run the updater, and check for driver updates. Laptop Wi-Fi drivers are a
  known early rough edge; report your exact laptop model.

## Where to get help

- Open an issue on the `vyra-os` repo with your laptop model, what step you
  reached, and the exact message you saw.
- Include the version (0.1.0) and which parts you installed.

## Quick recap

1. Download the core ISO → check its checksum → write it to USB.
2. Boot from USB → install → reboot → log in.
3. Add the Performance pack, then the Aesthetics pack.
4. Done. Welcome to Vyra OS.
