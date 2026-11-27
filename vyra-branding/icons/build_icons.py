#!/usr/bin/env python3
"""Build the Vyra icon set from the draft gold-V mark.

Source: ~/workspace/vyra-os/vyra-logo/vyra-logo-mark-1024.png
  - RGB (no alpha), solid Obsidian #050505 background, gold faceted V.
  - The task's "mark already has transparency" is WRONG for this file:
    it is RGB. This script derives transparency from luminance, the same
    technique used for the Batch 01 D1 wordmark crop (luminance ramp).

Alpha ramp: luminance <= 10 -> transparent; >= 110 -> opaque; linear
between. That keeps the bright gold V fully opaque, preserves the
anti-aliased V edges, and lets the faint gold ring/lines stay subtle
(partly transparent) instead of vanishing or turning into a black box.

Outputs (under vyra-branding/icons/):
  vyra-logo-mark-1024-transparent.png  transparent master (1024)
  vyra-<size>.png  for size in 16 22 24 32 48 64 128 256 512
  (LANCZOS downscale from the transparent master)
"""
import os
import numpy as np
from PIL import Image

SRC = os.path.expanduser('~/workspace/vyra-os/vyra-logo/vyra-logo-mark-1024.png')
OUT = os.path.expanduser('~/workspace/vyra-os/Vyra-Foundation/vyra-branding/icons')
SIZES = [16, 22, 24, 32, 36, 48, 64, 96, 128, 256, 512]
LO, HI = 10.0, 110.0

os.makedirs(OUT, exist_ok=True)

im = Image.open(SRC).convert('RGB')
a = np.asarray(im).astype(np.float32)
lum = a.mean(axis=2)
alpha = np.clip((lum - LO) / (HI - LO), 0.0, 1.0) * 255.0
rgba = np.dstack([a.astype(np.uint8), alpha.astype(np.uint8)])
master = Image.fromarray(rgba, 'RGBA')
master.save(os.path.join(OUT, 'vyra-logo-mark-1024-transparent.png'))
print('transparent master:', master.size, master.mode)

for s in SIZES:
    small = master.resize((s, s), Image.LANCZOS)
    p = os.path.join(OUT, f'vyra-{s}.png')
    small.save(p)
    print(f'vyra-{s}.png  {os.path.getsize(p)} bytes')

# sanity: the 48px icon's centre should be mostly opaque gold, corners transparent
chk = np.asarray(Image.open(os.path.join(OUT, 'vyra-48.png')))
print('48px corner alpha:', chk[0, 0, 3], chk[0, 47, 3], chk[47, 0, 3], chk[47, 47, 3])
print('48px centre alpha:', chk[24, 24, 3], ' centre RGB:', tuple(chk[24, 24, :3]))
