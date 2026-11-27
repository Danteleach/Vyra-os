#!/usr/bin/env python3
"""Vyra hardware discovery — machine-readable report + performance class.

Reads /proc, /sys, lscpu/lspci/lsblk output where available, and writes JSON.
This is the machine-readable companion to scripts/hardware-report.sh (text).
No disk writes, no destructive operations. Safe to run as an ordinary user;
some fields (PCI/USB details) are richer with sudo / on a Linux test host.

Performance classes — Master Directive §5C, capability detection, not name-only:
  ENTRY:       <16GB RAM, or no dedicated GPU and <8 cores, or integrated-only
  STANDARD:    16GB RAM, modern iGPU or entry dGPU
  PERFORMANCE: >=32GB RAM and a dedicated GPU
Storage classes — §5B:
  32GB USB = live/recovery only; 32GB internal = experimental constrained only;
  64GB = limited; 128GB = entry; 256GB = recommended everyday;
  512GB-1TB = recommended gaming/creative.
"""
import json, os, re, subprocess, sys
from pathlib import Path

def run(cmd):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        return r.stdout.strip()
    except Exception:
        return ""

def vyra_version():
    # Single source of truth: the VERSION file (docs/VERSION_NAMING.md).
    # In the OS it lives at /usr/share/vyra/VERSION; in the repo, at the
    # repo root next to this script's parent dir. Falls back to 0.0.0
    # (pre-release) when neither can be read.
    for p in (Path("/usr/share/vyra/VERSION"),
              Path(__file__).resolve().parent.parent / "VERSION"):
        try:
            v = p.read_text().strip()
            if v:
                return v
        except Exception:
            pass
    return "0.0.0"

def mem_gb():
    try:
        for line in Path("/proc/meminfo").read_text().splitlines():
            if line.startswith("MemTotal:"):
                return int(line.split()[1]) // 1024 // 1024
    except Exception:
        pass
    return None

def cpu_info():
    out = run(["lscpu"])
    model = cores = None
    for line in out.splitlines():
        if line.startswith("Model name:"):
            model = line.split(":", 1)[1].strip()
        if line.startswith("CPU(s):"):
            try: cores = int(line.split(":", 1)[1].strip())
            except Exception: pass
    return model, cores

def pci_gpus():
    out = run(["lspci", "-nn"])
    gpus = [l.strip() for l in out.splitlines() if "VGA" in l or "3D controller" in l or "Display" in l]
    return gpus

def has_dgpu(gpus):
    joined = " ".join(gpus).lower()
    return any(k in joined for k in ["nvidia", "radeon rx", "arc ", "geforce", "rtx", "gtx"])

def disks():
    out = run(["lsblk", "-b", "-o", "NAME,SIZE,TYPE,TRAN,MODEL", "-d"])
    rows = []
    for line in out.splitlines()[1:]:
        parts = line.split(None, 4)
        if len(parts) >= 2:
            try: rows.append({"name": parts[0], "size_bytes": int(parts[1]), "type": parts[2] if len(parts) > 2 else "", "tran": parts[3] if len(parts) > 3 else ""})
            except Exception: pass
    return rows

def storage_class(size_bytes):
    gb = size_bytes / (1000**3)
    if gb < 40: return "32GB-class: live/recovery only; internal install experimental constrained only"
    if gb < 96: return "64GB-class: limited installation, subject to testing"
    if gb < 192: return "128GB-class: entry-level installation"
    if gb < 384: return "256GB-class: recommended everyday installation"
    return "512GB-1TB-class: recommended gaming/creative installation"

def main():
    out_path = sys.argv[1] if len(sys.argv) > 1 else "artifacts/hardware-report.json"
    model, cores = cpu_info()
    gpus = pci_gpus()
    ram = mem_gb()
    dgpu = has_dgpu(gpus)
    if ram is not None and ram >= 32 and dgpu:
        perf = "PERFORMANCE"
    elif ram is not None and ram >= 16:
        perf = "STANDARD"
    else:
        perf = "ENTRY"
    report = {
        "product": "Vyra OS",
        "version": vyra_version(),
        "generator": "scripts/hardware-report.py",
        "os_release": Path("/etc/os-release").read_text() if Path("/etc/os-release").exists() else "",
        "kernel": run(["uname", "-a"]),
        "cpu_model": model,
        "cpu_cores": cores,
        "ram_gb": ram,
        "gpus": gpus,
        "has_dedicated_gpu": dgpu,
        "performance_class": perf,
        "performance_note": "ENTRY = reduced effects, limited gaming expectations; STANDARD = full desktop + supported gaming; PERFORMANCE = full creative + Arena. Class is a capability hint, not a certification.",
        "disks": [{**d, "storage_class": storage_class(d["size_bytes"])} for d in disks()],
        "battery": {p.name: p.read_text().strip() for p in Path("/sys/class/power_supply").glob("*/capacity")} if Path("/sys/class/power_supply").exists() else {},
        "status": "UNTESTED — this report is discovery only, not a certification. HP Victus SKU still pending; entry-level hardware still untested.",
    }
    Path(out_path).parent.mkdir(parents=True, exist_ok=True)
    Path(out_path).write_text(json.dumps(report, indent=2) + "\n")
    print(f"Hardware JSON report written to: {out_path}")
    print(f"Performance class: {perf} (RAM {ram}GB, cores {cores}, dGPU {dgpu})")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
