#!/usr/bin/env python3
"""Per-function profile of the stripped Deimos Rising PEF decompile dump.

For every `// ==== name @ addr ====` block in ghidra/Deimos_pef.decompiled.c, prints one line:
  addr name | mod=<source file named in its assert strings> | calls=<named callees> |
  strs=<strings it references> | 4cc=<four-char-code literals>
Strings are resolved from Ghidra's `s_xxx_ADDR` labels AND from raw data-section hex
constants (0x100de330..0x100f7be8) using the memory image written by DumpMemory.java.

Usage: python3 docs/deimos/tools/func_profile.py <dump.c> <memdir> > profile.txt
"""
import re, sys, os

dump, memdir = sys.argv[1], sys.argv[2]
DBASE = 0x100de330
data = open(os.path.join(memdir, "100de330.bin"), "rb").read()

def cstr(a):
    o = a - DBASE
    if o < 0 or o >= len(data):
        return None
    e = data.find(b"\0", o, o + 400)
    if e < 0:
        return None
    s = data[o:e]
    if len(s) < 3 or any((b < 32 and b not in (9, 10, 13)) or b > 126 for b in s):
        return None
    return s.decode("latin-1").replace("\r", "\\n").replace("\n", "\\n")

HDR = re.compile(r'^// ==== (.+?) @ ([0-9A-Fa-f]+) ====$', re.M)
text = open(dump, encoding="utf-8", errors="replace").read()
hits = list(HDR.finditer(text))
SREF = re.compile(r'(?<![A-Za-z0-9])s_\w*?_([0-9a-f]{8})\b')
HEX = re.compile(r'0x([0-9a-f]{7,8})\b')
CALL = re.compile(r"(?:\.glue::)?\b([A-Za-z_][A-Za-z0-9_]*)\s*\(")
MOD = re.compile(r'^[A-Z]_\w+\.c(c|pp)$|^unzip\.c$')
KW = {"if", "while", "for", "switch", "return", "sizeof"}

for i, m in enumerate(hits):
    name, addr = m.group(1), m.group(2)
    body = text[m.end(): hits[i + 1].start() if i + 1 < len(hits) else len(text)]
    strs, mods, fcc = [], set(), []
    cands = SREF.findall(body) + HEX.findall(body)
    # TOC slots (PTR_xxx_ADDR) hold a base pointer; strings are then base + small offsets.
    offs = {0} | {int(o, 16) for o in re.findall(r'\+ 0x([0-9a-f]{1,4})\b', body)}
    for slot in set(re.findall(r'(?:\bPTR_\w*?_|\b_?DAT_)([0-9a-f]{8})\b', body)):
        so = int(slot, 16) - DBASE
        if 0 <= so < len(data) - 4:
            base = int.from_bytes(data[so:so + 4], "big")
            for o in sorted(offs):
                t = base + o - DBASE
                if 0 < t < len(data) and data[t - 1] == 0 and cstr(base + o):
                    cands.append("%08x" % (base + o))
    for a in cands:
        v = int(a, 16)
        s = cstr(v)
        if s is None:
            # four-char code literal?
            bs = v.to_bytes(4, "big")
            if all(48 <= b <= 122 or b == 32 for b in bs) and len(a) == 8:
                fcc.append(bs.decode())
            continue
        if MOD.match(s):
            mods.add(s)
        elif s not in strs:
            strs.append(s)
    for a in HEX.findall(body):
        v = int(a, 16)
        if v < DBASE:
            bs = v.to_bytes(4, "big")
            if len(a) == 8 and all((48 <= b <= 57) or (65 <= b <= 90) or (97 <= b <= 122) or b == 32 for b in bs):
                fcc.append(bs.decode())
    calls = []
    for c in re.findall(r"\.glue::(\w+)\s*\(", body):
        if c in KW or c == name:
            continue
        if c not in calls:
            calls.append(c)
    fl = sorted(set(fcc))
    print(f"{addr} {name} | mod={','.join(sorted(mods))} | calls={','.join(calls[:14])} | fun={len(set(re.findall(r"FUN_[0-9a-f]{8}", body)) - {name})} | "
          f"strs={' ¦ '.join(x[:70] for x in strs[:8])} | 4cc={','.join(fl[:16])}")
