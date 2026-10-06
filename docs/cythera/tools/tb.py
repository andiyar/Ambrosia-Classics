#!/usr/bin/env python3
"""tb.py — list the PPC traceback tables in the Cythera 1.0.4 PEF code section (stdlib only).

Metrowerks emits an AIX-style traceback table after every function body: a zero word, then
  byte 0 version (0), byte 1 language (9 = C++, 0 = C), byte 2 flags (0x20 has_tboff, 0x08 has_ctl),
  byte 3 flags (0x80 int_hndl, 0x40 name_present, 0x20 uses_alloca), bytes 4-5, byte 6 fixedparms,
  byte 7 floatparms<<1 | parmsonstk;
  optional: parminfo u32 (if fixedparms|floatparms), tb_offset u32 (if has_tboff), hand_mask u32
  (if int_hndl), ctl_info u32 count + count*u32 (if has_ctl), name_len u16 + name (if name_present).
tb_offset is the distance from the function entry to the zero word, so
  entry = zero-word address - tb_offset and the body is [entry, zero word).
Ghidra's main dump (ghidra/Cythera_pef.decompiled.c) misses many of these bodies; this table names
them (e.g. `.DoMove__14TActiveMonsterFss` entry 0x1004B8E8, length 0x1DEC, zero word 0x1004D6D4).

Code section = PEF section 0 (kind 0, not packed), file offset 0x3470, loaded at 0x10000000
(the address Ghidra uses), so address A <-> file offset 0x3470 + (A - 0x10000000).

Recipe (run from the repo root; binary = ghidra/Cythera_pef, a copy of `…/files/Cythera`):
  python3 docs/cythera/tools/tb.py > ghidra/Cythera_pef.tb.txt          # 1,994 tables (C++ and C)
  python3 docs/cythera/tools/tb.py --cxx-only                           # 1,952 = the C++ (lang 9)
                                                                         # ones; byte-identical to the
                                                                         # 2026-10-03 scratch run
  python3 docs/cythera/tools/tb.py --tb                                 # + zero-word and name addrs
  python3 docs/cythera/tools/tb.py --at 1004c51c                         # function containing A
  python3 docs/cythera/tools/tb.py --grep 'TActiveMonster'               # regex on names
  python3 docs/cythera/tools/tb.py --missing ghidra/Cythera_pef.decompiled.c   # entries with no
                                                                         # `// ==== … @ addr` block
Default line format (same as the 2026-10-03 scratch run): `%08x %5x %s` = entry, length, name.
"""
import argparse, os, re, struct, sys

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_BIN = os.path.join(HERE, '..', '..', '..', 'ghidra', 'Cythera_pef')
LOAD = 0x10000000


def code_section(path):
    d = open(path, 'rb').read()
    if d[:12] != b'Joy!peffpwpc':
        sys.exit('%s: not a PEF PowerPC container' % path)
    nsec = struct.unpack('>H', d[32:34])[0]
    for i in range(nsec):
        o = 40 + 28 * i
        _n, _da, total, _unp, _pk, off, kind = struct.unpack('>iIIIIIB', d[o:o + 25])
        if kind == 0:                       # code section (never packed)
            return d[off:off + total], off
    sys.exit('no code section')


def tables(code, langs=(0, 9)):
    """Yield (entry, length, zero_word_addr, name_addr, name) for every traceback table."""
    n = len(code)
    for i in range(0, n - 24, 4):
        if code[i:i + 4] != b'\0\0\0\0' or code[i + 4] != 0 or code[i + 5] not in langs:
            continue
        b2, b3, fixedparms, flt = code[i + 6], code[i + 7], code[i + 10], code[i + 11]
        if not (b2 & 0x20 and b3 & 0x40):          # need tb_offset and a name
            continue
        j = i + 12
        if fixedparms or (flt >> 1):
            j += 4                                  # parminfo
        tboff = struct.unpack('>I', code[j:j + 4])[0]; j += 4
        if b3 & 0x80:
            j += 4                                  # hand_mask
        if b2 & 0x08:                               # ctl_info
            cnt = struct.unpack('>I', code[j:j + 4])[0]; j += 4 + 4 * cnt
        if j + 2 > n:
            continue
        ln = struct.unpack('>H', code[j:j + 2])[0]
        name = code[j + 2:j + 2 + ln]
        if not ln or not all(32 <= c < 127 for c in name):
            continue
        if tboff == 0 or tboff > i or tboff & 3:
            continue
        yield LOAD + i - tboff, tboff, LOAD + i, LOAD + j, name.decode('ascii')


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0],
                                 epilog='See the module docstring for the recipe.')
    ap.add_argument('--bin', default=DEFAULT_BIN, help='PEF binary (default ghidra/Cythera_pef)')
    ap.add_argument('--tb', action='store_true', help='also print zero-word and name-field addresses')
    ap.add_argument('--at', metavar='HEX', help='print the function containing this address')
    ap.add_argument('--grep', metavar='REGEX', help='only names matching REGEX')
    ap.add_argument('--cxx-only', action='store_true', help='only language 9 (C++) tables')
    ap.add_argument('--missing', metavar='DUMP', help='only entries with no block in this Ghidra dump')
    a = ap.parse_args()
    code, _off = code_section(a.bin)
    rows = list(tables(code, (9,) if a.cxx_only else (0, 9)))
    if a.at:
        x = int(a.at, 16)
        rows = [r for r in rows if r[0] <= x < r[2]]
    if a.grep:
        rx = re.compile(a.grep)
        rows = [r for r in rows if rx.search(r[4])]
    if a.missing:
        have = set(int(m.group(1), 16) for m in
                   re.finditer(r'^// ==== .+? @ ([0-9a-fA-F]+) ====', open(a.missing, errors='replace').read(), re.M))
        rows = [r for r in rows if r[0] not in have]
    for e, ln, z, na, name in rows:
        if a.tb:
            print('%08x %5x %s  tb@%08x name@%08x' % (e, ln, name, z, na))
        else:
            print('%08x %5x %s' % (e, ln, name))


if __name__ == '__main__':
    main()
