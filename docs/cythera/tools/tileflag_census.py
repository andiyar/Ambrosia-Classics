"""Census of 0xF002 tile-flag bits with 0xF004 tile names (Cythera 1.0.4).

Purpose: for each requested flag mask, count the drawable tiles 0..0x9FF whose u32 flag word
(segment 0xF002, big-endian, one per tile) has any of the mask's bits set, and list the most
common tile names (segment 0xF004: {u16 last-tile-of-range, C string} ... until an id > 0x2000;
a tile takes the name of the first range whose last tile is >= it). `--eq MASK` instead counts
tiles whose (flags & MASK) == MASK (e.g. 0xc0 for the 2x2 multi-tile case).

Run (repo root):   python3 docs/cythera/tools/tileflag_census.py 0x10 0x200 0x100000 0x10000000
                   python3 docs/cythera/tools/tileflag_census.py --eq 0xc0 0x80 0x40
Expected (Cythera Data as shipped; render.md §2.4):
  0x10 295 [('hydra', 32), ('tree', 21), ('wall', 15), ...]
  0x200 973 [('wall', 48), ('seldane', 48), ('man', 32), ...]
  0x100000 295 [('snowcaps', 49), ('mountains', 45), ('table', 17), ...]
  0x10000000 22 [('floor', 7), ('crack', 4), ('slime', 4), ('vines', 4), ('ethereal void', 3)]
Stdlib only; reads `Cythera Data` through seg.py (its default path).
"""
import os, struct, sys, collections

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import seg  # noqa: E402


def load():
    d, s, _ = seg.toc()
    o, l = s[0xF002]
    flags = struct.unpack('>%dI' % (l // 4), d[o:o + l])
    o, l = s[0xF004]
    b = d[o:o + l]
    names, i = [], 0
    while i < l:
        t = struct.unpack('>H', b[i:i + 2])[0]
        if t > 0x2000:
            break
        e = b.index(b'\0', i + 2)
        names.append((t, b[i + 2:e].decode('mac_roman')))
        i = e + 1
    return flags, names


def name(names, t):
    for last, n in names:
        if t <= last:
            return n
    return '?'


def main(argv):
    eq = False
    if argv and argv[0] == '--eq':
        eq, argv = True, argv[1:]
    masks = [int(a, 16) for a in argv] or [0x10, 0x200, 0x100000, 0x10000000]
    flags, names = load()
    n = min(len(flags), 0xA00)
    for m in masks:
        ts = [t for t in range(n) if ((flags[t] & m) == m if eq else flags[t] & m)]
        c = collections.Counter(name(names, t) for t in ts)
        print(('==' if eq else '') + hex(m), len(ts), c.most_common(12))


if __name__ == '__main__':
    main(sys.argv[1:])
