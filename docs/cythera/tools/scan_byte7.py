"""Heuristic count of byte offsets read from a 0xF008 creature record (Cythera 1.0.4 PPC code).

Purpose: a record pointer is either `lwz rA,4(rX)` (the CharEntry/monster's record pointer) or r3
after `bl 0x10044a60` (ObjToMonst). For each such definition, count loads `lbz/lhz/lha/lwz
rD,N(rA)` in the next 8 instructions and print the counts for N = 5, 6, 7, 8, 14 — showing that
byte 7 is never read (open-items-2026-10-06.md §2.2). The window does not stop when rA is
redefined, so the control total differs from §2.2's 38 (41 here); the N = 7 result is the point.
Banked from recipe D of open-items-2026-10-06.md (review wave 2 m7).

Run (repo root):  python3 docs/cythera/tools/scan_byte7.py [all.dis]
  all.dis = `python3 docs/cythera/tools/ppcdis.py 10000000 100cd280 > all.dis`; when omitted the
  listing is generated in-process (listing.py).
Expected output (1 line):
  {5: 1, 6: 10, 7: 0, 8: 27, 14: 3}
"""
import os, re, sys, collections as C

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import listing  # noqa: E402


def main(argv):
    L = listing.lines(argv[0] if argv else None)
    h = C.Counter()
    for i, ln in enumerate(L):
        m = re.search(r'lwz (r\d+),4\(r\d+\)$', ln)
        A = m.group(1) if m else ('r3' if 'bl 0x10044a60' in ln else None)
        if not A:
            continue
        for j in range(i + 1, min(i + 9, len(L))):
            n = re.search(r'(lbz|lhz|lha|lwz) r\d+,(\d+)\(' + A + r'\)$', L[j])
            if n:
                h[int(n.group(2))] += 1
    print({k: h[k] for k in (5, 6, 7, 8, 14)})


if __name__ == '__main__':
    main(sys.argv[1:])
