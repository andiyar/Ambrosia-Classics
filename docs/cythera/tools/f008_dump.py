"""Dump of world globals 0xF008 (creature-species records), 0xF005 and 0xF007 (Cythera 1.0.4).

Purpose: 0xF008 = 128 x 16-byte records keyed by the u16 at +0xC (object type); keep the non-zero
ones, report their count, the byte-7 histogram and per-bit set counts of the u16 fields at +8
("f33") and +0xA ("f32") (combat.md §4, open-items-2026-10-06.md §2.1). Then print 0xF005's file
offset, length and bytes, and 0xF007's offset, length and leading u16 count (§5). Banked from
recipe B of open-items-2026-10-06.md (review wave 2 m7).

Run (repo root):  python3 docs/cythera/tools/f008_dump.py
Expected output (5 lines):
  records 50 byte7 {0: 50}
  [(1, 21), (2, 6), (8, 5), (4096, 5), (8192, 2), (16384, 2), (32768, 1)]
  [(1, 9), (2, 5), (4, 23), (16, 16), (32, 10), (64, 15), (128, 8), (256, 5), (512, 5), (1024, 1), (2048, 2), (4096, 3), (8192, 8), (16384, 30), (32768, 3)]
  0x507905 16 d0 08 01 d8 08 01 e0 04 01 e4 04 01 e8 04 01 00
  0x507915 167 33
Stdlib only; reads `Cythera Data` through seg.py (its default path).
"""
import os, sys, struct, collections as C

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import seg  # noqa: E402


def main():
    d, s, _ = seg.toc()
    o, l = s[0xF008]
    R = [d[o + i:o + i + 16] for i in range(0, 0x800, 16)]
    R = [r for r in R if struct.unpack('>H', r[12:14])[0]]
    f33 = C.Counter(); f32 = C.Counter()
    for r in R:
        a, b = struct.unpack('>HH', r[8:12])
        for k in range(16):
            f33[1 << k] += a >> k & 1
            f32[1 << k] += b >> k & 1
    print('records', len(R), 'byte7', dict(C.Counter(r[7] for r in R)))
    print(sorted(i for i in f33.items() if i[1]))
    print(sorted(i for i in f32.items() if i[1]))
    o, l = s[0xF005]; print(hex(o), l, d[o:o + l].hex(' '))
    o, l = s[0xF007]; print(hex(o), l, struct.unpack('>H', d[o:o + 2])[0])


if __name__ == '__main__':
    main()
