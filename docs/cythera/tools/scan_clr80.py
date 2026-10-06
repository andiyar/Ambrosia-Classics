"""Scan for stores that clear bit 0x80 of a byte (Cythera 1.0.4 PPC code section).

Purpose: find every `rlwinm rD,rS,0,25,23` / `rlwinm rD,rS,0,25,31` (mask without bit 7),
`andi. rD,rS,0x7f` or `xori rD,rS,0x80` whose result rD is stored as a byte (`stb rD,0(` or
`stbx rD,`) within the next 4 instructions — the native places that un-hide a prop (kind bit
0x80; schedules-npcs.md §8, open-items-2026-10-06.md §3.1). Banked from recipe C of
open-items-2026-10-06.md (review wave 2 m7).

Run (repo root):  python3 docs/cythera/tools/scan_clr80.py [all.dis]
  all.dis = `python3 docs/cythera/tools/ppcdis.py 10000000 100cd280 > all.dis`; when omitted the
  listing is generated in-process (listing.py).
  ⚑ corrected (review wave 3 2026-10-06): argparse — `--help` prints this text and exits 0; a missing
  all.dis is a one-line error.
Expected output (2 lines):
  1004f188: 5400066e  rlwinm r0,r0,0,25,23 | 1004f18c: 98070000  stb r0,0(r7)
  1005caf0: 5400066e  rlwinm r0,r0,0,25,23 | 1005caf4: 981c0000  stb r0,0(r28)
(1004f188 is in FollowLeader, 1005caf0 in DrawRoutine — `tb.py --at`.)
"""
import argparse, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import listing  # noqa: E402


def main(argv):
    L = listing.lines(argv[0] if argv else None)
    pat = re.compile(r'(rlwinm (r\d+),(r\d+),0,25,(23|31)$|andi\. (r\d+),(r\d+),0x7f$|xori (r\d+),(r\d+),0x80$)')
    for i, ln in enumerate(L):
        m = pat.search(ln)
        if not m:
            continue
        dst = [g for g in (m.group(2), m.group(5), m.group(7)) if g][0]
        for j in range(i + 1, min(i + 5, len(L))):
            if re.search(r'stb ' + dst + r',0\(|stbx ' + dst + ',', L[j]):
                print(ln.strip(), '|', L[j].strip())
                break


def cli(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('listing', nargs='?', metavar='all.dis',
                    help='whole-code ppcdis listing (default: generate it in-process)')
    a = ap.parse_args(argv)
    if a.listing is not None and not os.path.isfile(a.listing):
        sys.exit('%s: error: no such file: %s' % (ap.prog, a.listing))
    main([a.listing] if a.listing is not None else [])


if __name__ == '__main__':
    cli()
