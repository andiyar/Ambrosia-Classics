"""Prop-segment census (Cythera 1.0.4): kind bytes over every level-prop segment, and kind 0x11.

Purpose: walk all prop segments 0x8100..0x81FF of `Cythera Data` (16-byte PropItem records,
data-format.md §4), count the kind byte (byte 0), and for kind 0x11 collect the owner (u16 at
+2), the level, byte 6 and the frame field ((byte 4 >> 2) & 0x1F). Banked from recipe A of
open-items-2026-10-06.md (review wave 2 m7).

Run (repo root):  python3 docs/cythera/tools/props_census.py
Expected output (3 lines):
  40 [(0, 12104), (1, 116), (2, 46), (8, 618), (9, 241), (10, 7), (16, 32), (17, 55), (24, 31), (28, 1), (66, 879), (68, 298), (128, 52), (255, 5)]
  21 [4, 9, 10, 11, 12, 13, 14, 16, 23, 24, 31, 56, 59, 62, 64, 71, 72, 73, 79, 91, 95]
  [3, 6, 8, 11, 13, 17, 24] Counter({0: 55}) Counter({0: 55})
i.e. 40 levels; the kind census of data-format §4.3; kind 0x11: 21 owners, 7 levels, byte 6 and
frame all 0. Stdlib only; reads `Cythera Data` through seg.py (its default path).
⚑ corrected (review wave 3 2026-10-06): argparse — `--help` prints this text and exits 0;
`--data PATH` overrides the `Cythera Data` path; a missing file is a one-line error.
"""
import argparse, os, sys, struct, collections as C

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import seg  # noqa: E402


def main(data=seg.DATA):
    d, s, _ = seg.toc(data)
    K = C.Counter(); own = set(); lv = set(); b6 = C.Counter(); fr = C.Counter()
    L = [k for k in s if 0x8100 <= k < 0x8200]
    for sid in L:
        o, l = s[sid]
        for i in range(0, l, 16):
            r = d[o + i:o + i + 16]
            K[r[0]] += 1
            if r[0] == 0x11:
                own.add(struct.unpack('>H', r[2:4])[0]); lv.add(sid - 0x8100)
                b6[r[6]] += 1; fr[(r[4] >> 2) & 0x1f] += 1
    print(len(L), sorted(K.items()))
    print(len(own), sorted(own))
    print(sorted(lv), b6, fr)


def cli(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--data', default=seg.DATA, help='path of `Cythera Data` (default: seg.py DATA)')
    a = ap.parse_args(argv)
    if not os.path.isfile(a.data):
        sys.exit('%s: error: no such file: %s' % (ap.prog, a.data))
    main(a.data)


if __name__ == '__main__':
    cli()
