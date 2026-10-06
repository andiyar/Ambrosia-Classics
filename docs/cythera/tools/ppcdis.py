#!/usr/bin/env python3
"""ppcdis.py — small PPC32 big-endian decoder for the Cythera 1.0.4 PEF code section (stdlib only).

For bodies Ghidra dropped or merged (TStream reader/writer, TViewer::AddSound, the
TMapWindow::KeyRoutine body Ghidra folds into ShowTileAnimate, DoMove …). It decodes the integer
subset needed to read loads/stores, branches, lis/ori/addi constants, compares, rotates and the
common X/XO-form ops, plus FP loads/stores and basic FP arithmetic. Anything else prints as
`.long 0x…` — never guessed.

Address map: code section = PEF section 0, file offset 0x3470, loaded at 0x10000000, so the
instruction at A is the big-endian u32 at file offset 0x3470 + (A − 0x10000000).
TOC: r2 = 0x100D5280 (LoadLevelMap's `lwz r3,-30292(r2)` reads TOC slot 0x100CDC2C); every
`d(r2)` operand gets a `; TOC 0x…` comment. `bl` targets get the traceback-table name (tb.py).

Output: `addr: bytes  mnemonic operands`. Signed immediates (addi/addis/li/lis/cmpwi/D-form
displacements) print in decimal, logical/unsigned ones (ori/oris/andi./xori/cmplwi) in hex — the
form quoted in docs/cythera/*.md; `--hex` prints every immediate in hex. Branch mnemonics are the
simplified forms (beq/bne/blt/bge/bgt/ble[+cr], bdnz/bdz, blr/bctr[l]); others print `bc BO,BI,t`.

Recipe (run from the repo root; binary = ghidra/Cythera_pef):
  python3 docs/cythera/tools/ppcdis.py 10043c58 10043ff0        # [start, end)
  python3 docs/cythera/tools/ppcdis.py 100c50e8 +5               # start and instruction count
  python3 docs/cythera/tools/ppcdis.py --func DoMove__14TActiveMonster   # whole tb-named body
  python3 docs/cythera/tools/ppcdis.py --hex 10017d50 10017dc4
"""
import argparse, os, re, struct, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tb  # noqa: E402

LOAD, TOC = 0x10000000, 0x100D5280
HEX = False


def s16(x):
    return x - 0x10000 if x & 0x8000 else x


def simm(v):
    return ('-0x%x' % -v if v < 0 else '0x%x' % v) if HEX else '%d' % v


def uimm(v):
    return '0x%x' % v


CC = ['lt', 'gt', 'eq', 'so']
NCC = ['ge', 'le', 'ne', 'ns']


def cr(n):
    return 'cr%d' % n


def bcname(bo, bi, suffix):
    """Simplified mnemonic for a conditional branch, or None."""
    base = bo & 0x1E                      # drop the y (hint) bit
    crf = bi >> 2
    pre = ('cr%d,' % crf) if crf else ''
    if base == 12:
        return 'b' + CC[bi & 3] + suffix, pre
    if base == 4:
        return 'b' + NCC[bi & 3] + suffix, pre
    if base == 16:
        return 'bdnz' + suffix, ''
    if base == 18:
        return 'bdz' + suffix, ''
    if base == 20:
        return 'b' + suffix, ''
    return None, None


SPR = {1: 'xer', 8: 'lr', 9: 'ctr'}
DFORM = {32: 'lwz', 33: 'lwzu', 34: 'lbz', 35: 'lbzu', 36: 'stw', 37: 'stwu', 38: 'stb', 39: 'stbu',
         40: 'lhz', 41: 'lhzu', 42: 'lha', 43: 'lhau', 44: 'sth', 45: 'sthu', 46: 'lmw', 47: 'stmw',
         48: 'lfs', 49: 'lfsu', 50: 'lfd', 51: 'lfdu', 52: 'stfs', 53: 'stfsu', 54: 'stfd', 55: 'stfdu'}
# X-form (10-bit xo) with rD/rS, rA, rB in the usual slots
X31 = {0: 'cmpw', 32: 'cmplw', 4: 'tw', 19: 'mfcr', 20: 'lwarx', 23: 'lwzx', 24: 'slw', 26: 'cntlzw',
       28: 'and', 54: 'dcbst', 55: 'lwzux', 60: 'andc', 83: 'mfmsr', 86: 'dcbf', 87: 'lbzx',
       119: 'lbzux', 124: 'nor', 144: 'mtcrf', 150: 'stwcx.', 151: 'stwx', 183: 'stwux', 215: 'stbx',
       247: 'stbux', 278: 'dcbt', 279: 'lhzx', 284: 'eqv', 311: 'lhzux', 316: 'xor', 339: 'mfspr',
       343: 'lhax', 371: 'mftb', 375: 'lhaux', 407: 'sthx', 412: 'orc', 439: 'sthux', 444: 'or',
       467: 'mtspr', 476: 'nand', 534: 'lwbrx', 535: 'lfsx', 536: 'srw', 567: 'lfsux', 598: 'sync',
       599: 'lfdx', 631: 'lfdux', 662: 'stwbrx', 663: 'stfsx', 695: 'stfsux', 727: 'stfdx',
       759: 'stfdux', 790: 'lhbrx', 792: 'sraw', 824: 'srawi', 918: 'sthbrx', 922: 'extsh',
       954: 'extsb', 982: 'icbi', 1014: 'dcbz'}
# XO-form (9-bit xo, OE at bit 10)
XO31 = {8: 'subfc', 10: 'addc', 11: 'mulhwu', 40: 'subf', 75: 'mulhw', 104: 'neg', 136: 'subfe',
        138: 'adde', 200: 'subfze', 202: 'addze', 232: 'subfme', 234: 'addme', 235: 'mullw',
        266: 'add', 459: 'divwu', 491: 'divw'}
LOGIC = {24, 28, 60, 124, 284, 316, 412, 444, 476, 536, 792}   # rA,rS,rB order
FP63 = {18: 'fdiv', 20: 'fsub', 21: 'fadd', 22: 'fsqrt', 25: 'fmul', 28: 'fmsub', 29: 'fmadd',
        30: 'fnmsub', 31: 'fnmadd', 23: 'fsel', 26: 'frsqrte'}
FP63X = {0: 'fcmpu', 32: 'fcmpo', 12: 'frsp', 14: 'fctiw', 15: 'fctiwz', 40: 'fneg', 72: 'fmr',
         136: 'fnabs', 264: 'fabs', 583: 'mffs', 711: 'mtfsf', 38: 'mtfsb1', 70: 'mtfsb0'}
FP59 = {18: 'fdivs', 20: 'fsubs', 21: 'fadds', 22: 'fsqrts', 24: 'fres', 25: 'fmuls', 28: 'fmsubs',
        29: 'fmadds', 30: 'fnmsubs', 31: 'fnmadds'}


def decode(a, i):
    op = i >> 26
    rD = (i >> 21) & 31; rA = (i >> 16) & 31; rB = (i >> 11) & 31
    imm = i & 0xFFFF; si = s16(imm); rc = '.' if i & 1 else ''
    if op in DFORM:
        m = DFORM[op]   # D-form load/store
        reg = 'f' if m.startswith(('lf', 'stf')) else 'r'
        return '%s %s%d,%s(r%d)' % (m, reg, rD, simm(si), rA)
    if op == 14:
        return ('li r%d,%s' % (rD, simm(si))) if rA == 0 else 'addi r%d,r%d,%s' % (rD, rA, simm(si))
    if op == 15:
        return ('lis r%d,%s' % (rD, simm(si))) if rA == 0 else 'addis r%d,r%d,%s' % (rD, rA, simm(si))
    if op in (7, 8, 12, 13):
        m = {7: 'mulli', 8: 'subfic', 12: 'addic', 13: 'addic.'}[op]
        return '%s r%d,r%d,%s' % (m, rD, rA, simm(si))
    if op in (24, 25, 26, 27, 28, 29):
        if op == 24 and i == 0x60000000:
            return 'nop'
        m = {24: 'ori', 25: 'oris', 26: 'xori', 27: 'xoris', 28: 'andi.', 29: 'andis.'}[op]
        return '%s r%d,r%d,%s' % (m, rA, rD, uimm(imm))
    if op in (10, 11):
        crf = rD >> 2; pre = (cr(crf) + ',') if crf else ''
        if rD & 1:
            return '.long 0x%08x' % i            # L=1 (64-bit compare) invalid on PPC32
        return ('cmplwi %sr%d,%s' % (pre, rA, uimm(imm))) if op == 10 else \
               ('cmpwi %sr%d,%s' % (pre, rA, simm(si)))
    if op == 3:
        return 'twi %d,r%d,%s' % (rD, rA, simm(si))
    if op == 17 and i & 2:
        return 'sc'
    if op == 18:
        li = i & 0x3FFFFFC
        if li & 0x2000000:
            li -= 0x4000000
        t = li if i & 2 else (a + li) & 0xFFFFFFFF
        return 'b%s%s 0x%x' % ('l' if i & 1 else '', 'a' if i & 2 else '', t)
    if op == 16:
        bd = s16(i & 0xFFFC)
        t = bd & 0xFFFFFFFF if i & 2 else (a + bd) & 0xFFFFFFFF
        suf = ('l' if i & 1 else '') + ('a' if i & 2 else '')
        m, pre = bcname(rD, rA, suf)
        if m:
            return '%s %s0x%x' % (m, pre, t)
        return 'bc%s %d,%d,0x%x' % (suf, rD, rA, t)
    if op == 19:
        xo = (i >> 1) & 0x3FF; lk = 'l' if i & 1 else ''
        if xo in (16, 528):
            tgt = 'lr' if xo == 16 else 'ctr'
            m, pre = bcname(rD, rA, '')
            if m == 'b':
                return 'b%s%s' % (tgt, lk)
            if m and not m.startswith('bd'):
                return '%s%s%s %s' % (m, tgt, lk, pre.rstrip(',')) if pre else '%s%s%s' % (m, tgt, lk)
            return 'bc%s%s %d,%d' % (tgt, lk, rD, rA)
        crx = {33: 'crnor', 129: 'crandc', 193: 'crxor', 225: 'crnand', 257: 'crand', 289: 'creqv',
               417: 'crorc', 449: 'cror'}
        if xo in crx:
            return '%s %d,%d,%d' % (crx[xo], rD, rA, rB)
        if xo == 0:
            return 'mcrf cr%d,cr%d' % (rD >> 2, rA >> 2)
        if xo == 150:
            return 'isync'
        return '.long 0x%08x' % i
    if op in (20, 21, 23):
        mb = (i >> 6) & 31; me = (i >> 1) & 31
        if op == 23:
            return 'rlwnm%s r%d,r%d,r%d,%d,%d' % (rc, rA, rD, rB, mb, me)
        return '%s%s r%d,r%d,%d,%d,%d' % ('rlwimi' if op == 20 else 'rlwinm', rc, rA, rD, rB, mb, me)
    if op == 31:
        xo10 = (i >> 1) & 0x3FF; xo9 = (i >> 1) & 0x1FF
        if xo9 in XO31:
            m = XO31[xo9] + ('o' if i & 0x400 else '') + rc
            if xo9 in (104, 200, 202, 232, 234):
                return '%s r%d,r%d' % (m, rD, rA)
            return '%s r%d,r%d,r%d' % (m, rD, rA, rB)
        if xo10 not in X31:
            return '.long 0x%08x' % i
        m = X31[xo10]
        if xo10 in (0, 32):
            crf = rD >> 2
            return '%s %sr%d,r%d' % (m, (cr(crf) + ',') if crf else '', rA, rB)
        if xo10 == 444 and rD == rB:
            return 'mr%s r%d,r%d' % (rc, rA, rD)
        if xo10 in LOGIC:
            return '%s%s r%d,r%d,r%d' % (m, rc, rA, rD, rB)
        if xo10 == 824:
            return 'srawi%s r%d,r%d,%d' % (rc, rA, rD, rB)
        if xo10 in (922, 954, 26):
            return '%s%s r%d,r%d' % (m, rc, rA, rD)
        if xo10 in (339, 467):
            spr = (rB << 5) | rA
            if spr in SPR:
                return ('mf%s r%d' if xo10 == 339 else 'mt%s r%d') % (SPR[spr], rD)
            return '%s r%d,%d' % (m, rD, spr) if xo10 == 339 else '%s %d,r%d' % (m, spr, rD)
        if xo10 == 19 or xo10 == 83:
            return '%s r%d' % (m, rD)
        if xo10 == 144:
            return 'mtcrf 0x%x,r%d' % ((i >> 12) & 0xFF, rD)
        if xo10 == 371:
            return 'mftb r%d' % rD
        if xo10 in (54, 86, 278, 982, 1014):
            return '%s r%d,r%d' % (m, rA, rB)
        if xo10 == 598:
            return 'sync'
        if xo10 == 4:
            return 'tw %d,r%d,r%d' % (rD, rA, rB)
        reg = 'f' if m.startswith(('lf', 'stf')) else 'r'
        return '%s %s%d,r%d,r%d' % (m, reg, rD, rA, rB)
    if op == 63:
        xo5 = (i >> 1) & 31; xo10 = (i >> 1) & 0x3FF; rC = (i >> 6) & 31
        if xo10 in FP63X:
            m = FP63X[xo10]
            if xo10 in (0, 32):
                return '%s cr%d,f%d,f%d' % (m, rD >> 2, rA, rB)
            if xo10 == 583:
                return 'mffs%s f%d' % (rc, rD)
            if xo10 in (38, 70):
                return '%s%s %d' % (m, rc, rD)
            if xo10 == 711:
                return 'mtfsf%s 0x%x,f%d' % (rc, (i >> 17) & 0xFF, rB)
            return '%s%s f%d,f%d' % (m, rc, rD, rB)
        if xo5 in FP63:
            m = FP63[xo5] + rc
            if xo5 in (18, 20, 21):
                return '%s f%d,f%d,f%d' % (m, rD, rA, rB)
            if xo5 == 25:
                return '%s f%d,f%d,f%d' % (m, rD, rA, rC)
            if xo5 in (22, 26):
                return '%s f%d,f%d' % (m, rD, rB)
            return '%s f%d,f%d,f%d,f%d' % (m, rD, rA, rC, rB)
        return '.long 0x%08x' % i
    if op == 59:
        xo5 = (i >> 1) & 31; rC = (i >> 6) & 31
        if xo5 in FP59:
            m = FP59[xo5] + rc
            if xo5 in (18, 20, 21):
                return '%s f%d,f%d,f%d' % (m, rD, rA, rB)
            if xo5 == 25:
                return '%s f%d,f%d,f%d' % (m, rD, rA, rC)
            if xo5 in (22, 24):
                return '%s f%d,f%d' % (m, rD, rB)
            return '%s f%d,f%d,f%d,f%d' % (m, rD, rA, rC, rB)
        return '.long 0x%08x' % i
    return '.long 0x%08x' % i


def main():
    global HEX
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0],
                                 epilog='See the module docstring for the address map and recipe.',
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('start', nargs='?', help='start address (hex)')
    ap.add_argument('end', nargs='?', help='end address (hex, exclusive) or +N instructions')
    ap.add_argument('--func', metavar='REGEX', help='disassemble every tb-named body matching REGEX')
    ap.add_argument('--hex', action='store_true', help='print all immediates in hex')
    ap.add_argument('--bin', default=tb.DEFAULT_BIN, help='PEF binary (default ghidra/cythera/Cythera_pef)')
    ap.add_argument('--no-names', action='store_true', help='no traceback names on bl targets')
    a = ap.parse_args()
    HEX = a.hex
    code, _ = tb.code_section(a.bin)
    names = {} if a.no_names else {e: n for e, _l, _z, _na, n in tb.tables(code)}
    ranges = []
    if a.func:
        rx = re.compile(a.func)
        ranges = [(e, z, n) for e, _l, z, _na, n in tb.tables(code) if rx.search(n)]
        if not ranges:
            sys.exit('no traceback name matches %r' % a.func)
    elif a.start:
        s = int(a.start, 16)
        e = s + 4 * int(a.end[1:]) if a.end and a.end.startswith('+') else \
            (int(a.end, 16) if a.end else s + 4)
        ranges = [(s, e, None)]
    else:
        ap.error('give START [END|+N] or --func')
    for s, e, title in ranges:
        if title:
            print('---- %s @ %08x' % (title, s))
        for x in range(s & ~3, e, 4):
            o = x - LOAD
            if not 0 <= o <= len(code) - 4:
                sys.exit('%08x outside the code section' % x)
            w = struct.unpack('>I', code[o:o + 4])[0]
            t = decode(x, w)
            m = re.search(r'(-?(?:0x)?[0-9a-f]+)\(r2\)', t)
            if m:
                t += '  ; TOC 0x%x' % ((TOC + int(m.group(1), 0)) & 0xFFFFFFFF)
            elif re.match(r'addi r\d+,r2,', t):
                t += '  ; = 0x%x' % ((TOC + int(t.split(',')[-1], 0)) & 0xFFFFFFFF)
            if t.startswith('bl ') and int(t[3:], 16) in names:
                t += '  ; ' + names[int(t[3:], 16)]
            if x in names and not title:
                print('---- %s' % names[x])
            print('%08x: %08x  %s' % (x, w, t))


if __name__ == '__main__':
    main()
