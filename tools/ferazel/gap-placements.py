#!/usr/bin/env python3
"""Port-gap ledger helper: every active placement record (flag == 1) of the levels in scope, by type and class.

Record layout world-data-format.md §3.4 (the port's `Placement`, header +4 + 16·i, 511 records): flag u8, byte1 u8,
type i16, p1..p4 i16, y i16, x i16. Class = `.GenerateSprite`'s selection, transcribed in
docs/ferazel/tools/gensprite_map.py (`gen`; p1 < 0 is the record-8 sign the Background range reads).
Usage: tools/ferazel/gap-placements.py [levels | all, default 1 2 3 4] > placements.tsv
Columns: level  type  type_hex  class  idle  count  p1_values (distinct, up to 8)
"""
import os, sys, struct, collections
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(ROOT, 'docs/ferazel/tools'))
from rsrc_census import parse          # noqa: E402
from gensprite_map import gen          # noqa: E402

def main():
    _, res = parse(os.path.join(ROOT, "Resources/Ferazel/Ferazel's Wand World Data.rsrc"))
    mlvl = {rid: body for rid, _, body in res['Mlvl']}
    levels = sorted(mlvl) if sys.argv[1:] == ['all'] else ([int(a) for a in sys.argv[1:]] or [1, 2, 3, 4])
    print('level\ttype\ttype_hex\tclass\tidle\tcount\tp1_values')
    for lv in levels:
        body = mlvl[lv]
        rows = collections.defaultdict(list)
        for i in range(511):
            o = 4 + 16 * i
            flag, b1, typ, p1, p2, p3, p4, y, x = struct.unpack('>BBhhhhhhh', body[o:o + 16])
            if flag == 1 and typ != 0:
                rows[typ].append(p1)
        for typ in sorted(rows):
            p1s = rows[typ]
            cls, idle = gen(typ & 0xffff, any(p < 0 for p in p1s))
            vals = ','.join(str(v) for v in sorted(set(p1s))[:8])
            print(f'{lv}\t{typ}\t0x{typ & 0xffff:x}\t{cls or "-"}\t{int(idle)}\t{len(p1s)}\t{vals}')

if __name__ == '__main__':
    main()
