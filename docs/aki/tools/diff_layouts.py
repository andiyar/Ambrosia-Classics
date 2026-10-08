#!/usr/bin/env python3
"""Extract and diff the 12 built-in Aki layouts between 1.2.0 (i386 dump) and 1.1.0 (PPC).

Sources (all read-only):
  1.2: ghidra/aki/Aki12_i386.decompiled.c  -- `_AddTile(lo,hi,lo,hi,layer)` calls; each double is two
       32-bit words (little-endian i386 stack: low word first), so (0,0x40140000) = 5.0.
  1.1: ghidra/aki/Aki_ppc.decompiled.c -- `AddTile(DOUBLE_x,DOUBLE_y,..)`
       gives x,y (resolved from the PPC __literal8 pool) but Ghidra lost the layer argument (the
       short lives in r7 under the Mach-O PPC ABI because the two doubles shadow r3..r6). So the
       1.1 layer is recovered by a minimal PPC decoder over the binary's __text: it tracks
       `addis rD,0,hi` / `addi`/`li`, `lfd fD,d(rA)`, `fmr`, and records (f1,f2,r7) at every
       `bl AddTile`. The decoder's (x,y) must equal the dump's (x,y) call-for-call -- checked.

Usage: python3 docs/aki/tools/diff_layouts.py [--dump-12 N] [--dump-11 N]   (N = level 1..12)
       python3 docs/aki/tools/diff_layouts.py --markdown   (regenerates the levels-layouts.md tables)
"""
import re, struct, sys

D12 = "ghidra/aki/Aki12_i386.decompiled.c"
D11 = "ghidra/aki/Aki_ppc.decompiled.c"
B11 = "ghidra/aki/Aki_ppc"
HDR = re.compile(r'^// ==== (.+?) @ ([0-9A-Fa-fx]+) ====$', re.M)
# LoadLayout (both builds): level index g->level (0-based) -> function called
LEVEL_TO_FUNC = {1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 10, 7: 7, 8: 11, 9: 9, 10: 6, 11: 8, 12: 12}


def blocks(path):
    t = open(path, encoding="utf-8", errors="replace").read()
    hs = list(HDR.finditer(t))
    for i, m in enumerate(hs):
        e = hs[i + 1].start() if i + 1 < len(hs) else len(t)
        yield m.group(1), int(m.group(2), 16), t[m.start():e]


def w2d(lo, hi):
    return struct.unpack('<d', struct.pack('<II', lo & 0xffffffff, hi & 0xffffffff))[0]


def parse12():
    out = {}
    rx = re.compile(r'_AddTile\((\w+),(\w+),(\w+),(\w+),(\w+)\)')
    for name, addr, body in blocks(D12):
        m = re.fullmatch(r'_Layout(\d+)', name)
        if not m:
            continue
        calls = []
        for a in rx.findall(body):
            v = [int(x, 0) for x in a]
            calls.append((w2d(v[0], v[1]), w2d(v[2], v[3]), v[4]))
        out[int(m.group(1))] = (addr, calls)
    return out


def ppc_literals():
    data = open(B11, 'rb').read()
    # __literal8 of Aki_ppc: addr 0xd4470 size 0x1f0 offset 865392 (otool -l)
    lit = {}
    for i in range(0, 0x1f0, 8):
        lit[0xd4470 + i] = struct.unpack('>d', data[865392 + i:865392 + i + 8])[0]
    return data, lit


def parse11_dump(lit):
    out = {}
    rx = re.compile(r'AddTile\(DOUBLE_([0-9a-f]+),DOUBLE_([0-9a-f]+),')
    for name, addr, body in blocks(D11):
        m = re.fullmatch(r'Layout(\d+)', name)
        if not m or 'halt_baddata' in body:
            continue          # the 0xd01f0.. blocks are [clone .eh] tails, not code
        out[int(m.group(1))] = (addr, [(lit[int(x, 16)], lit[int(y, 16)]) for x, y in rx.findall(body)])
    return out


def parse11_bin(data, lit, starts, addtile=0x21a2c):
    """Emulate each 1.1 LayoutN (PPC) until blr; record (f1, f2, r7) at every `bl AddTile`.
    The 1.1 source used for-loops (int->double via the 0x43300000 magic) where 1.2 is unrolled,
    so a straight-line decoder is not enough. Only the opcodes these 12 functions contain are
    implemented (census: cmpwi addi addis bc bl blr xoris mflr mtlr extsh lwz stw stwu sth lmw
    stmw lfd stfd fsub fadd fmr); anything else raises."""
    TEXT_VA, TEXT_OFF = 0x87a8, 30632
    def rd32(va):
        o = va - TEXT_VA + TEXT_OFF
        return struct.unpack('>I', data[o:o + 4])[0]
    def litload(addr):
        # literal pools live in the file too; map __literal8 + __const/__data reads through lit/data
        if addr in lit:
            return struct.pack('>d', lit[addr])
        raise ValueError(f"lfd from unexpected address {addr:#x}")
    out = {}
    for n, start in starts.items():
        g = [0] * 32; f = [0.0] * 32; mem = {}; cr = [0] * 8
        g[1] = 0x7fff0000
        pc, calls, steps = start, [], 0
        def sx(v): return v - 0x10000 if v & 0x8000 else v
        def u32(v): return v & 0xffffffff
        def ea(ra, d): return u32((g[ra] if ra else 0) + d)
        while True:
            steps += 1
            if steps > 200000: raise RuntimeError("runaway")
            ins = rd32(pc); op = ins >> 26
            rd, ra, rb = (ins >> 21) & 31, (ins >> 16) & 31, (ins >> 11) & 31
            imm = sx(ins & 0xffff); xo = (ins >> 1) & 0x3ff; npc = pc + 4
            if op == 14: g[rd] = u32((g[ra] if ra else 0) + imm)
            elif op == 15: g[rd] = u32((g[ra] if ra else 0) + (imm << 16))
            elif op == 27: g[ra] = g[rd] ^ ((ins & 0xffff) << 16)            # xoris rA,rS,UIMM
            elif op == 11:                                                   # cmpwi
                a = g[ra] - (1 << 32) if g[ra] & 0x80000000 else g[ra]
                cr[rd >> 2] = 8 if a < imm else 4 if a > imm else 2
            elif op == 16:                                                   # bc
                bo, bi = rd & ~1, ra   # low BO bit is the static prediction hint
                bd = ins & 0xfffc; bd = bd - 0x10000 if bd & 0x8000 else bd
                assert bo in (4, 12), hex(ins)
                bit = (cr[bi >> 2] >> (3 - (bi & 3))) & 1
                if (bo == 12 and bit) or (bo == 4 and not bit): npc = pc + bd
            elif op == 18:                                                   # bl
                li = ins & 0x3fffffc; li = li - 0x4000000 if li & 0x2000000 else li
                assert ins & 1 and u32(pc + li) == addtile, hex(pc)
                r7 = g[7] & 0xffff; r7 = r7 - 0x10000 if r7 & 0x8000 else r7
                calls.append((f[1], f[2], r7))
                for k in list(range(0, 13)): g[k] = 0xdead0000 if k not in (1, 2) else g[k]
                g[3] = 0  # AddTile is void
            elif op == 19 and xo == 16: break                                # blr
            elif op == 31 and xo in (339, 467): pass                         # mflr / mtlr
            elif op == 31 and xo == 922:                                     # extsh rA,rS
                v = g[rd] & 0xffff; g[ra] = u32(v - 0x10000 if v & 0x8000 else v)
            elif op == 32: g[rd] = mem.get(ea(ra, imm), 0)                    # lwz
            elif op == 36: mem[ea(ra, imm)] = g[rd]                           # stw
            elif op == 37: a = ea(ra, imm); mem[a] = g[rd]; g[ra] = a         # stwu
            elif op == 44: pass                                               # sth (to g-> globals)
            elif op == 46:                                                    # lmw
                a = ea(ra, imm)
                for r in range(rd, 32): g[r] = mem.get(a, 0); a += 4
            elif op == 47:                                                    # stmw
                a = ea(ra, imm)
                for r in range(rd, 32): mem[a] = g[r]; a += 4
            elif op == 50:                                                    # lfd
                a = ea(ra, imm)
                if a in mem and (a + 4) in mem:
                    f[rd] = struct.unpack('>d', struct.pack('>II', mem[a], mem[a + 4]))[0]
                else:
                    f[rd] = struct.unpack('>d', litload(a))[0]
            elif op == 54:                                                    # stfd
                a = ea(ra, imm); hi, lo = struct.unpack('>II', struct.pack('>d', f[rd]))
                mem[a], mem[a + 4] = hi, lo
            elif op == 63 and (ins >> 1) & 31 == 20: f[rd] = f[ra] - f[rb]   # fsub
            elif op == 63 and (ins >> 1) & 31 == 21: f[rd] = f[ra] + f[rb]   # fadd
            elif op == 63 and xo == 72: f[rd] = f[rb]                         # fmr
            else: raise RuntimeError(f"unhandled {ins:08x} at {pc:#x}")
            pc = npc
        out[n] = calls
    return out


def markdown(l12):
    import collections
    def f(v): return '%g' % v
    meta = {}
    for name, addr, body in blocks(D12):
        m = re.fullmatch(r'_Layout(\d+)', name)
        if m:
            g = dict((k, int(v, 0)) for k, v in re.findall(r'\+ (0x94|0x98|0x8e)\) = (0x[0-9a-f]+|\d+);', body))
            sx = lambda v: v - (1 << 32) if v & 0x80000000 else v
            meta[int(m.group(1))] = (sx(g['0x94']), sx(g['0x98']), g['0x8e'])
    for lvl in range(1, 13):
        fn = LEVEL_TO_FUNC[lvl]; addr, c = l12[fn]; o = meta[fn]
        zc = collections.Counter(7 - L for *_, L in c)
        xs = [a for a, _, _ in c]; ys = [b for _, b, _ in c]
        print(f"### Level {lvl} — `_Layout{fn}` @ {addr:#07x} (1.2) — {len(c)} tiles\n")
        print(f"draw offset g+0x94 = {o[0]}, g+0x98 = {o[1]}; background index g+0x8e = {o[2]}; "
              f"x {f(min(xs))}..{f(max(xs))}, y {f(min(ys))}..{f(max(ys))}; tiles per stored layer "
              "z (0 = bottom): " + ", ".join(f"z{z}:{n}" for z, n in sorted(zc.items())) + "\n")
        print("| # | (x, y, L) ×8, in call order |\n|---|---|")
        for i in range(0, len(c), 8):
            ch = c[i:i + 8]
            print(f"| {i + 1}–{i + len(ch)} | " + " ".join(f"({f(x)},{f(y)},{L})" for x, y, L in ch) + " |")
        print()


def main():
    if "--markdown" in sys.argv:
        markdown(parse12())
        return
    l12 = parse12()
    data, lit = ppc_literals()
    l11d = parse11_dump(lit)
    l11b = parse11_bin(data, lit, {n: a for n, (a, _) in l11d.items()})
    print("layout fn | level | 1.2 @addr  n | 1.1 @addr  n(dump) n(bin) | dump==bin xy | 1.2==1.1 (x,y,layer) ordered | as set")
    for lvl in range(1, 13):
        fn = LEVEL_TO_FUNC[lvl]
        a12, c12 = l12[fn]
        a11, c11d = l11d[fn]
        c11 = l11b[fn]
        xy_ok = ([(x, y) for x, y, _ in c11] == c11d) if len(c11d) == len(c11) else 'n/a (dump has loops)'
        same_ord = c12 == c11
        same_set = sorted(c12) == sorted(c11)
        print(f"_Layout{fn:<3}| {lvl:5} | {a12:#07x} {len(c12):3} | {a11:#07x} {len(c11d):3} {len(c11):3} | {xy_ok} | {same_ord} | {same_set}")
        if not same_set:
            s12, s11 = set(c12), set(c11)
            print("     only in 1.2:", sorted(s12 - s11))
            print("     only in 1.1:", sorted(s11 - s12))
            for i, (p, q) in enumerate(zip(c12, c11)):
                if p != q:
                    print(f"     first ordered difference at call #{i + 1}: 1.2 {p}  1.1 {q}")
                    break
        if any(None in c for c in c11):
            print("     WARNING: decoder could not resolve some 1.1 arguments")
    if "--dump-12" in sys.argv:
        fn = LEVEL_TO_FUNC[int(sys.argv[sys.argv.index("--dump-12") + 1])]
        for i, c in enumerate(l12[fn][1], 1):
            print(i, *c)
    if "--dump-11" in sys.argv:
        fn = LEVEL_TO_FUNC[int(sys.argv[sys.argv.index("--dump-11") + 1])]
        for i, c in enumerate(l11b[fn], 1):
            print(i, *c)


if __name__ == "__main__":
    main()
