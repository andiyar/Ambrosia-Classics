#!/usr/bin/env python3
"""Census of a classic Mac resource fork stored as a flat file (.rsrc = raw fork bytes).
Header (16 bytes, big-endian u32): dataOffset, mapOffset, dataLength, mapLength.
Map: +24 u16 typeListOffset (from map start), +26 u16 nameListOffset; type list starts with
u16 (numTypes-1), then 8-byte entries: OSType, u16 (count-1), u16 refListOffset (from type list).
Ref entry (12 bytes): s16 id, s16 nameOffset (-1 = none), u8 attrs, u24 dataOffset (from data
start), u32 reserved. Each resource's data is prefixed with a u32 length.
Usage: python3 docs/aki/tools/rsrc_census.py <file.rsrc> [TYPE ...]   (lists ids/sizes for TYPEs)
"""
import struct, sys

def census(path):
    b = open(path, 'rb').read()
    doff, moff, dlen, mlen = struct.unpack('>4I', b[:16])
    m = b[moff:moff + mlen]
    tl, nl = struct.unpack('>HH', m[24:28])
    ntypes = struct.unpack('>H', m[tl:tl + 2])[0] + 1
    out = {}
    for i in range(ntypes):
        t, cnt, ref = struct.unpack('>4sHH', m[tl + 2 + 8 * i: tl + 10 + 8 * i])
        rows = []
        for j in range(cnt + 1):
            rid, noff, a, d3 = struct.unpack('>hhB3s', m[tl + ref + 12 * j: tl + ref + 12 * j + 8])
            do = int.from_bytes(d3, 'big')
            size = struct.unpack('>I', b[doff + do: doff + do + 4])[0]
            name = ''
            if noff != -1:
                ln = m[nl + noff]
                name = m[nl + noff + 1: nl + noff + 1 + ln].decode('mac_roman')
            rows.append((rid, size, name))
        out[t.decode('mac_roman')] = rows
    return (doff, moff, dlen, mlen), out

if __name__ == '__main__':
    hdr, out = census(sys.argv[1])
    print('header dataOff=%d mapOff=%d dataLen=%d mapLen=%d' % hdr)
    for t, rows in sorted(out.items()):
        print(f"{t!r}: {len(rows)} resources, {sum(r[1] for r in rows)} bytes")
    for t in sys.argv[2:]:
        for rid, size, name in sorted(out.get(t, [])):
            print(f"  {t} {rid:6} {size:8} {name}")
