#!/usr/bin/env python3
"""Map every call of the permanent-resource accessors to the data-file key it reads.

Accessors (read in the disassembly; r2 = 0x100e6330, TOC slots 0x100df200..0x100df214):
  FUN_10020250(i) -> float  i of flli/Game[gafl]   (220 '#key <float>' lines, file order)
  FUN_10020260(i) -> string i of stli/Game[pgsl]   (37 CR-separated lines, 128 B each)
  FUN_100201f0(i) -> ID     i of idli/Objects[gaob] (40 '#key <ID>' lines)
  FUN_10020210(i) -> ID     i of idli/Sounds[gaso]  (24)
  FUN_10020200(i) -> ID     i of idli/Sprites[gasp] (8)
  FUN_10020220(i,&r) -> RECT i of reli/Rects[inre] (22)
Usage: perm_consumers.py <dump.c> <decoded-Game-dir>   (decoded .txt files from list_paks.py --decode)
Prints:  <func> <addr> | <accessor>:<index>=<key> ...
"""
import re, sys, os

dump, gdir = sys.argv[1], sys.argv[2]

def keys(path, kind):
    t = open(path, encoding="latin-1").read().replace("\r", "\n")
    if kind == "lines":
        return t.split("\n")
    return [m.group(1) for m in re.finditer(r"#\s*([^<\t ]+(?: [^<\t ]+)*)\s*<", t)]

tables = {
    "FUN_10020250": ("F", keys(os.path.join(gdir, "flli/Game[gafl].flli.txt"), "keys")),
    "FUN_10020260": ("S", keys(os.path.join(gdir, "stli/Game[pgsl].stli.txt"), "lines")),
    "FUN_100201f0": ("O", keys(os.path.join(gdir, "idli/Objects[gaob].idli.txt"), "keys")),
    "FUN_10020210": ("SND", keys(os.path.join(gdir, "idli/Sounds[gaso].idli.txt"), "keys")),
    "FUN_10020200": ("SPR", keys(os.path.join(gdir, "idli/Sprites[gasp].idli.txt"), "keys")),
    "FUN_10020220": ("R", keys(os.path.join(gdir, "reli/Rects[inre].reli.txt"), "keys")),
}
HDR = re.compile(r'^// ==== (.+?) @ ([0-9A-Fa-f]+) ====$', re.M)
text = open(dump, encoding="utf-8", errors="replace").read()
hits = list(HDR.finditer(text))
CALL = re.compile(r'\b(FUN_10020250|FUN_10020260|FUN_100201f0|FUN_10020210|FUN_10020200|FUN_10020220)\((0x[0-9a-f]+|\d+)')
for i, m in enumerate(hits):
    body = text[m.end(): hits[i + 1].start() if i + 1 < len(hits) else len(text)]
    out = []
    for f, a in CALL.findall(body):
        tag, tab = tables[f]
        n = int(a, 0)
        k = tab[n].strip() if n < len(tab) else "?OUT-OF-RANGE"
        s = f"{tag}{n}={k}"
        if s not in out:
            out.append(s)
    if out:
        print(f"{m.group(1)} {m.group(2)} | " + " ; ".join(out))
