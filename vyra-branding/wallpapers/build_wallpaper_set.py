#!/usr/bin/env python3
"""Vyra wallpaper set builder — 5 designs x dark/light x 4 sizes.

Masters are 2048x1152 (the AI generation size). The Ring design is drawn
procedurally in PIL at 4096x2304 and downscaled (same approach as the logo).
Light modes for the 4 AI masters are a PIL/numpy HSV recolor: gold pixels
are kept (slightly deepened), dark background is remapped to a warm light
field while preserving its luminance structure. Size derivatives are
LANCZOS resizes/crops with a light unsharp pass on upscales.
"""
import math, os, random, shutil
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageOps

BASE = os.path.expanduser("~/workspace/vyra-os/vyra-branding/wallpapers")
MASTERS = os.path.join(BASE, "masters")
GOLD = (220, 174, 67)        # #DCAE43
LIGHT_GOLD = (255, 228, 154)  # #FFE49A
OBSIDIAN = (5, 5, 5)          # #050505
LIGHT_BG = (243, 239, 230)    # warm off-white for light mode
DEEP_GOLD = (201, 151, 58)    # deeper gold for light-mode V

AI = {
    "flow": "media-generation-vyra-wallpaper-flow-dark-maste-0-74a93437-df86-4bb0-acb0-a7909fd90e1a.png",
    "summit": "media-generation-vyra-wallpaper-summit-dark-mas-0-715369c9-fb7a-48d0-a1a8-afc9583e2051.png",
    "prism": "media-generation-vyra-wallpaper-prism-dark-mast-0-91898701-f79f-498e-a952-1c1ee097fb26.png",
    "orbit": "media-generation-vyra-wallpaper-orbit-dark-mast-0-78f2dc48-0ec3-4211-b35b-eaf3e5485b44.png",
}
DESIGNS = ["flow", "summit", "prism", "orbit", "ring"]
SIZES = {
    "3840x2160": (3840, 2160),
    "1920x1080": (1920, 1080),
    "3440x1440": (3440, 1440),
    "1080x1920": (1080, 1920),
}

def to_light(dark_img):
    """Recolor a dark wallpaper to its light-mode equivalent.

    Bright gold is kept (slightly deepened). Everything else gets an
    inverted-luminance remap: dark background -> light field, and the
    mid-tone structure (mountains, smoke, glow) -> light grey, so forms
    stay visible instead of washing out. The gold mask requires a high
    value so dark brown smoke/glow cores are NOT kept as gold.
    """
    rgb = dark_img.convert("RGB")
    hsv = np.asarray(rgb.convert("HSV")).astype(np.float32)
    H, S, V = hsv[..., 0], hsv[..., 1], hsv[..., 2]
    # gold: warm hue, saturated, and BRIGHT (V>130) — only true gold
    gold = (H >= 18) & (H <= 48) & (S > 80) & (V > 130)
    H2 = np.where(gold, H, 12.0)                       # warm hue for background
    S2 = np.where(gold, S, np.minimum(S * 0.25, 30.0)) # desaturate background
    V2 = np.where(gold, V * 0.92, 240.0 - V * 0.35)    # deepen gold, invert bg
    out = np.stack([H2, S2, np.clip(V2, 0, 255)], axis=-1).astype(np.uint8)
    return Image.fromarray(out, "HSV").convert("RGB")

def draw_ring(mode):
    """Draw the Ring design (concentric gold rings + faceted V) at 4096x2304."""
    W, H = 4096, 2304
    dark = mode == "dark"
    bg = OBSIDIAN if dark else LIGHT_BG
    gold = GOLD if dark else DEEP_GOLD
    img = Image.new("RGB", (W, H), bg)
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = 2048, 1150
    # soft glow behind the V
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([cx - 900, cy - 700, cx + 900, cy + 700], fill=gold + (26 if dark else 18,))
    glow = glow.filter(ImageFilter.GaussianBlur(180))
    img = Image.alpha_composite(img.convert("RGBA"), glow)
    d = ImageDraw.Draw(img)
    # concentric rings
    for r, col, wd, al in [(620, LIGHT_GOLD, 7, 220), (860, gold, 7, 200), (1100, gold, 6, 150)]:
        ring = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        rd = ImageDraw.Draw(ring)
        rd.ellipse([cx - r, cy - r, cx + r, cy + r], outline=col + (al,), width=wd)
        img = Image.alpha_composite(img, ring)
    # flowing sine lines (faint)
    for base, amp, lam, ph, al in [(500, 90, 2600, 0.0, 70), (1850, 110, 3000, 1.2, 60), (2050, 80, 2400, 2.4, 50)]:
        pts = [(x, base + amp * math.sin(2 * math.pi * x / lam + ph)) for x in range(0, W + 1, 16)]
        ln = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ld = ImageDraw.Draw(ln)
        ld.line(pts, fill=gold + (al,), width=6)
        img = Image.alpha_composite(img, ln)
    # faceted V (chevron) with diagonal gradient
    chevron = [(1488, 780), (2048, 1560), (2608, 780), (2348, 780), (2048, 1380), (1748, 780)]
    mask = Image.new("L", (W, H), 0)
    md = ImageDraw.Draw(mask)
    md.polygon(chevron, fill=255)
    # diagonal gradient gold -> light gold
    yy, xx = np.mgrid[0:H, 0:W]
    t = np.clip((xx + yy) / (W + H), 0, 1)
    g0 = np.array(gold, dtype=np.float32)
    g1 = np.array(LIGHT_GOLD if dark else (255, 214, 130), dtype=np.float32)
    grad = (g0[None, None, :] * (1 - t[..., None]) + g1[None, None, :] * t[..., None]).astype(np.uint8)
    grad_img = Image.fromarray(grad, "RGB").convert("RGBA")
    img = Image.composite(grad_img, img, mask)
    # facet highlight on the right arm
    facet = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fd = ImageDraw.Draw(facet)
    fd.polygon([(2048, 1380), (2478, 780), (2348, 780)], fill=(255, 240, 200, 90))
    img = Image.alpha_composite(img, facet)
    # gold dust
    random.seed(7)
    dust = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dd = ImageDraw.Draw(dust)
    for _ in range(320):
        x, y = random.randint(0, W - 1), random.randint(0, H - 1)
        r = random.randint(1, 4)
        dd.ellipse([x - r, y - r, x + r, y + r], fill=gold + (random.randint(50, 200),))
    img = Image.alpha_composite(img, dust)
    return img.convert("RGB").resize((2048, 1152), Image.LANCZOS)

def center_crop(img, target_ratio):
    w, h = img.size
    r = w / h
    if r > target_ratio:  # too wide: crop width
        nw = int(h * target_ratio)
        x0 = (w - nw) // 2
        return img.crop((x0, 0, x0 + nw, h))
    nw_h = int(w / target_ratio)
    y0 = (h - nw_h) // 2
    return img.crop((0, y0, w, y0 + nw_h))

def sharpen(img):
    return img.filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=3))

def sizes_for(master_img, design, mode):
    for sname, (tw, th) in SIZES.items():
        out = os.path.join(BASE, sname, f"{design}-{mode}-{sname}.png")
        if os.path.exists(out):
            continue
        ratio = tw / th
        if abs(master_img.size[0] / master_img.size[1] - ratio) < 0.01:
            im = master_img.resize((tw, th), Image.LANCZOS)
        else:
            im = center_crop(master_img, ratio).resize((tw, th), Image.LANCZOS)
        if tw > master_img.size[0]:
            im = sharpen(im)
        im.save(out)
        print("  wrote", out)

def main():
    masters = {}
    # 1. AI dark masters -> clean names
    for design, fname in AI.items():
        src = os.path.join(BASE, fname)
        dst = os.path.join(MASTERS, f"{design}-dark.png")
        if not os.path.exists(dst):
            shutil.copy(src, dst)
        masters[(design, "dark")] = Image.open(dst)
        print("master dark:", dst, masters[(design, "dark")].size)
    # 2. Ring (procedural) dark + light
    for mode in ("dark", "light"):
        dst = os.path.join(MASTERS, f"ring-{mode}.png")
        if not os.path.exists(dst):
            draw_ring(mode).save(dst)
        masters[("ring", mode)] = Image.open(dst)
        print("master ring", mode, ":", dst)
    # 3. Light modes for the 4 AI designs
    for design in AI:
        dst = os.path.join(MASTERS, f"{design}-light.png")
        if not os.path.exists(dst):
            to_light(masters[(design, "dark")]).save(dst)
        masters[(design, "light")] = Image.open(dst)
        print("master light:", dst)
    # 4. Size derivatives for all 10 masters
    for (design, mode), img in sorted(masters.items()):
        print(f"sizes for {design}-{mode}:")
        sizes_for(img, design, mode)
    print("DONE")

if __name__ == "__main__":
    main()
