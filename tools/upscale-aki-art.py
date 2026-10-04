#!/usr/bin/env python3
"""Aki Remaster art (docs/DECISIONS.md D11): the original 1.2.0 PNGs upscaled 4x with Upscayl's remacri-4x.

Region map: tools/aki-art-regions.json (coverage enforced by Aki/Core/Tests/AkiCoreTests/ArtRegionsTests.swift).
  picture region -> crop, 8 px edge-replicate pad, remacri 4x, crop the 4x interior back, paste at (4l, 4t)
  mask region and every pixel in no region -> nearest-neighbour 4x from the original (bit-exact)
Outputs (git-ignored, derived from copyrighted originals — D10):
  Resources/Aki/hd-4x/<name>.png            every file, exactly 4x, RGB 8-bit
  Resources/Aki/hd-4x-dedither/<name>.png   "dedither" files only: 3x3 median on the padded crop before remacri
  Resources/Aki/.upscale-cache/<sha256>.png  remacri interiors keyed by (padded PNG bytes, model, scale, variant)

Usage (from the repo root):
  python3 tools/upscale-aki-art.py [--only a.png,b.png]   generate (idempotent; cached crops cost no upscayl call)
  python3 tools/upscale-aki-art.py --check                verify map + outputs; non-zero exit on any failure
  python3 tools/upscale-aki-art.py --sheets [DIR]         contact sheets (default out/remaster-sheets/)
Pillow only.
"""
import argparse
import hashlib
import io
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(REPO, "Resources/Aki/1.2.0.app/Contents/Resources")
OUT = {"plain": os.path.join(REPO, "Resources/Aki/hd-4x"),
       "dedither": os.path.join(REPO, "Resources/Aki/hd-4x-dedither")}
CACHE = os.path.join(REPO, "Resources/Aki/.upscale-cache")
REGIONS = os.path.join(REPO, "tools/aki-art-regions.json")
BIN = "/Applications/Upscayl.app/Contents/Resources/bin/upscayl-bin"
MODELS = "/Applications/Upscayl.app/Contents/Resources/models"
MODEL, SCALE, PAD = "remacri-4x", 4, 8


def load_map():
    with open(REGIONS) as f:
        data = json.load(f)
    return {k: v for k, v in data.items() if k.endswith(".png")}


def original(name):
    return Image.open(os.path.join(SRC, name)).convert("RGB")


def nearest4(img):
    return img.resize((img.width * SCALE, img.height * SCALE), Image.NEAREST)


def edge_pad(img, pad):
    """True edge-replicate padding: border rows/columns stretched outward (corners take the corner pixel)."""
    w, h = img.size
    W, H = w + 2 * pad, h + 2 * pad
    p = Image.new("RGB", (W, H))
    p.paste(img, (pad, pad))
    p.paste(img.crop((0, 0, 1, h)).resize((pad, h), Image.NEAREST), (0, pad))
    p.paste(img.crop((w - 1, 0, w, h)).resize((pad, h), Image.NEAREST), (pad + w, pad))
    p.paste(p.crop((0, pad, W, pad + 1)).resize((W, pad), Image.NEAREST), (0, 0))
    p.paste(p.crop((0, pad + h - 1, W, pad + h)).resize((W, pad), Image.NEAREST), (0, pad + h))
    return p


def padded_input(img, rect, variant):
    crop = img.crop(tuple(rect))
    p = edge_pad(crop, PAD)
    if variant == "dedither":
        p = p.filter(ImageFilter.MedianFilter(3))
    buf = io.BytesIO()
    p.save(buf, format="PNG")
    data = buf.getvalue()
    key = hashlib.sha256(data + f"|{MODEL}|{SCALE}|{variant}".encode()).hexdigest()
    return key, data


def variants_for(entry):
    return ["plain", "dedither"] if entry.get("dedither") else ["plain"]


def run_upscayl(in_path, out_path):
    cmd = [BIN, "-i", in_path, "-o", out_path, "-s", str(SCALE), "-m", MODELS, "-n", MODEL, "-f", "png"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    return r.returncode, (r.stdout or "") + (r.stderr or "")


def upscale_jobs(jobs, stats):
    """jobs: {key: (padded PNG bytes, (w, h) of the unpadded crop)} -> writes CACHE/<key>.png (the 4x interior)."""
    if not jobs:
        return
    tmp = tempfile.mkdtemp(prefix="aki-upscale-")
    try:
        ind, outd = os.path.join(tmp, "in"), os.path.join(tmp, "out")
        os.makedirs(ind)
        os.makedirs(outd)
        for key, (data, _) in jobs.items():
            with open(os.path.join(ind, key + ".png"), "wb") as f:
                f.write(data)
        t = time.time()
        print(f"upscayl: {len(jobs)} padded crops in one directory call ...", flush=True)
        code, log = run_upscayl(ind, outd)
        stats["upscayl_calls"] += 1
        missing = [k for k in jobs if not os.path.exists(os.path.join(outd, k + ".png"))]
        if code != 0 or missing:
            print(f"upscayl directory mode failed (exit {code}, {len(missing)} missing) — falling back per file",
                  flush=True)
            print(log[-2000:])
            stats["fallback"] = True
            for k in missing:
                c2, log2 = run_upscayl(os.path.join(ind, k + ".png"), os.path.join(outd, k + ".png"))
                stats["upscayl_calls"] += 1
                if c2 != 0:
                    sys.exit(f"upscayl failed on {k}:\n{log2[-2000:]}")
        stats["upscayl_seconds"] += time.time() - t
        print(f"upscayl: done in {time.time() - t:.1f} s", flush=True)
        os.makedirs(CACHE, exist_ok=True)
        for key, (_, (w, h)) in jobs.items():
            up = Image.open(os.path.join(outd, key + ".png")).convert("RGB")
            want = ((w + 2 * PAD) * SCALE, (h + 2 * PAD) * SCALE)
            if up.size != want:
                sys.exit(f"upscayl output {key} is {up.size}, expected {want}")
            interior = up.crop((PAD * SCALE, PAD * SCALE, (PAD + w) * SCALE, (PAD + h) * SCALE))
            interior.save(os.path.join(CACHE, key + ".png"))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def generate(only):
    regions = load_map()
    names = sorted(regions) if not only else only
    stats = {"upscayl_calls": 0, "upscayl_seconds": 0.0, "cache_hits": 0, "regions": 0, "fallback": False}
    t0 = time.time()
    # pass 1: every padded crop; collect the uncached ones
    plan, jobs = {}, {}
    for name in names:
        entry = regions[name]
        img = original(name)
        items = []
        for reg in entry["regions"]:
            if reg["kind"] != "picture":
                continue
            stats["regions"] += 1
            l, t, r, b = reg["rect"]
            for v in variants_for(entry):
                key, data = padded_input(img, reg["rect"], v)
                items.append((v, reg["rect"], key))
                if os.path.exists(os.path.join(CACHE, key + ".png")):
                    stats["cache_hits"] += 1
                elif key not in jobs:
                    jobs[key] = (data, (r - l, b - t))
        plan[name] = items
    print(f"{len(names)} files, {stats['regions']} picture regions, {stats['cache_hits']} cache hits, "
          f"{len(jobs)} crops to upscale", flush=True)
    # pass 2: one upscayl call for everything uncached
    upscale_jobs(jobs, stats)
    # pass 3: compose
    written = {"plain": 0, "dedither": 0}
    for v in OUT.values():
        os.makedirs(v, exist_ok=True)
    for name in names:
        t = time.time()
        entry = regions[name]
        base = nearest4(original(name))
        for v in variants_for(entry):
            out = base.copy()
            for (vv, rect, key) in plan[name]:
                if vv == v:
                    out.paste(Image.open(os.path.join(CACHE, key + ".png")).convert("RGB"),
                              (rect[0] * SCALE, rect[1] * SCALE))
            path = os.path.join(OUT[v], name)
            out.save(path)
            written[v] += os.path.getsize(path)
        print(f"  {name:22s} {len(plan[name]):3d} upscaled crops  {time.time() - t:6.2f} s", flush=True)
    print(f"TOTAL {time.time() - t0:.1f} s: {len(names)} files, {stats['regions']} picture regions, "
          f"{stats['upscayl_calls']} upscayl calls ({stats['upscayl_seconds']:.1f} s), "
          f"{stats['cache_hits']} cache hits{', PER-FILE FALLBACK USED' if stats['fallback'] else ''}")
    print(f"bytes written: hd-4x {written['plain']:,}  hd-4x-dedither {written['dedither']:,}")


def overlaps(a, b):
    return a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]


def check():
    regions = load_map()
    fails = []
    pngs = sorted(f for f in os.listdir(SRC) if f.endswith(".png"))
    if sorted(regions) != pngs:
        fails.append(f"map files != shipped PNGs: missing {sorted(set(pngs) - set(regions))}, "
                     f"extra {sorted(set(regions) - set(pngs))}")
    for name in sorted(regions):
        entry = regions[name]
        if not os.path.exists(os.path.join(SRC, name)):
            continue
        img = original(name)
        w, h = img.size
        if list(entry["size"]) != [w, h]:
            fails.append(f"{name}: map size {entry['size']} != real {w}x{h}")
        regs = entry["regions"]
        for i, a in enumerate(regs):
            l, t, r, b = a["rect"]
            if not (0 <= l < r <= w and 0 <= t < b <= h):
                fails.append(f"{name}: region {a['note']} {a['rect']} out of bounds")
            if a["kind"] not in ("picture", "mask"):
                fails.append(f"{name}: region {a['note']} kind {a['kind']}")
            for bb in regs[i + 1:]:
                if overlaps(a["rect"], bb["rect"]):
                    fails.append(f"{name}: {a['note']} overlaps {bb['note']}")
        # the 4x pixels that must be nearest-neighbour: everything outside picture regions
        keep = Image.new("L", (w * SCALE, h * SCALE), 255)
        d = ImageDraw.Draw(keep)
        for a in regs:
            if a["kind"] == "picture":
                l, t, r, b = a["rect"]
                d.rectangle((l * SCALE, t * SCALE, r * SCALE - 1, b * SCALE - 1), fill=0)
        expect = nearest4(img)
        for v in variants_for(entry):
            path = os.path.join(OUT[v], name)
            if not os.path.exists(path):
                fails.append(f"{v}/{name}: missing")
                continue
            out = Image.open(path)
            if out.mode != "RGB" or out.size != (w * SCALE, h * SCALE):
                fails.append(f"{v}/{name}: {out.mode} {out.size}, expected RGB {(w * SCALE, h * SCALE)}")
                continue
            # bit-exact at 4x (implies the 4x4 box-downsample of those blocks equals the original exactly)
            diff = ImageChops.difference(out, expect).convert("L").point(lambda x: 255 if x else 0)
            bad = ImageChops.multiply(diff, keep).getbbox()
            if bad:
                fails.append(f"{v}/{name}: mask/undeclared pixels not bit-exact in 4x box {bad}")
            # and the explicit 4x4 box-downsample of the kept area
            down = out.resize((w, h), Image.BOX)
            keep1 = keep.resize((w, h), Image.NEAREST)
            bad1 = ImageChops.multiply(ImageChops.difference(down, img).convert("L").point(lambda x: 255 if x else 0),
                                       keep1).getbbox()
            if bad1:
                fails.append(f"{v}/{name}: box-downsample differs from the original in box {bad1}")
    n_out = sum(len(variants_for(regions[n])) for n in regions)
    if fails:
        print(f"CHECK FAILED ({len(fails)}):")
        for f in fails:
            print("  " + f)
        sys.exit(1)
    print(f"CHECK OK: {len(regions)} files, {sum(len(e['regions']) for e in regions.values())} regions, "
          f"{n_out} outputs exactly 4x, mask + undeclared pixels bit-exact")


def sheets(outdir):
    os.makedirs(outdir, exist_ok=True)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 28)
    except OSError:
        font = ImageFont.load_default()

    def panels_for(name, rect):
        img = original(name)
        l, t, r, b = rect
        s = SCALE
        ps = [("original nearest 4x", nearest4(img.crop(rect)))]
        for v, label in (("plain", "hd-4x"), ("dedither", "hd-4x-dedither")):
            p = os.path.join(OUT[v], name)
            if os.path.exists(p):
                ps.append((label, Image.open(p).convert("RGB").crop((l * s, t * s, r * s, b * s))))
        return ps

    def save(sheet_name, panels, title):
        w, h = panels[0][1].size
        side = w >= h * 1.6  # wide crops stack vertically, others sit side by side
        gap, head = 12, 44
        if side:
            W, H = w, len(panels) * (h + head) + head
        else:
            W, H = len(panels) * (w + gap) - gap, h + 2 * head
        sheet = Image.new("RGB", (W, H), (255, 255, 255))
        d = ImageDraw.Draw(sheet)
        d.text((6, 6), title, fill=(0, 0, 0), font=font)
        for i, (label, im) in enumerate(panels):
            x, y = (0, head + i * (h + head)) if side else (i * (w + gap), head)
            d.text((x + 6, y + 6), label, fill=(160, 0, 0), font=font)
            sheet.paste(im, (x, y + head))
        longest = max(sheet.size)
        if longest > 4000:
            f = 4000 / longest
            sheet = sheet.resize((int(sheet.width * f), int(sheet.height * f)), Image.LANCZOS)
        path = os.path.join(outdir, sheet_name + ".png")
        sheet.save(path)
        print(f"{path} {sheet.size}")

    save("01-background1", panels_for("background1.png", (300, 200, 500, 350)), "background1.png (300,200,500,350)")
    save("02-background7", panels_for("background7.png", (300, 200, 500, 350)), "background7.png (300,200,500,350)")
    save("03-map", panels_for("map.png", (250, 150, 450, 300)), "map.png (250,150,450,300)")
    # tiles rows 0..276 next to faces 0 and 10 (raw sheet rows, not composited)
    tiles = panels_for("tiles.png", (0, 0, 53, 276))
    f0 = panels_for("tile_pictures.png", (0, 0, 38, 50))
    f10 = panels_for("tile_pictures.png", (0, 500, 38, 550))
    combo = []
    for (label, t), (_, a), (_, b) in zip(tiles, f0, f10):
        c = Image.new("RGB", (t.width + 12 + a.width, t.height), (255, 255, 255))
        c.paste(t, (0, 0))
        c.paste(a, (t.width + 12, 0))
        c.paste(b, (t.width + 12, a.height + 12))
        combo.append((label, c))
    save("04-tiles-faces", combo, "tiles.png rows 0-276 + faces 0, 10")
    save("05-misc", panels_for("misc.png", (0, 30, 467, 468)), "misc.png (0,30,467,468)")
    save("06-plate", panels_for("plate.png", (0, 0, 786, 68)), "plate.png (0,0,786,68)")
    save("07-pause", panels_for("pause.png", (0, 0, 208, 480)), "pause.png left half")
    save("08-previews0", panels_for("previews.png", (0, 0, 236, 180)), "previews.png strip 0")
    save("09-proverbs0", panels_for("proverbs.png", (0, 0, 392, 157)), "proverbs.png strip 0")
    save("10-notavail", panels_for("notavail.png", (0, 0, 240, 150)), "notavail.png")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--sheets", nargs="?", const=os.path.join(REPO, "out/remaster-sheets"))
    ap.add_argument("--only", help="comma-separated file names (generate only)")
    a = ap.parse_args()
    if a.check:
        check()
    elif a.sheets:
        sheets(a.sheets)
    else:
        generate(a.only.split(",") if a.only else None)


if __name__ == "__main__":
    main()
