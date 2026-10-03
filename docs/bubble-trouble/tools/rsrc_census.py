#!/usr/bin/env python3
"""Census of a classic Mac resource fork (flat .rsrc file or a file's ..namedfork/rsrc).

Generic classic resource-map parser (Inside Macintosh: More Macintosh Toolbox, "Resource Manager"):
  header, 16 bytes big-endian: u32 data offset, u32 map offset, u32 data length, u32 map length
  map:  +24 u16 offset of type list (from map start), +26 u16 offset of name list
  type list: u16 (number of types - 1), then per type: OSType, u16 (count - 1), u16 ref-list offset
             (from the type-list start)
  ref list entry, 12 bytes: i16 id, u16 name offset (0xFFFF = none), u8 attrs, u24 data offset
             (from the data start), u32 reserved handle
  each resource's data: u32 length, then the bytes.

Prints one markdown table per file, types in map order: type | count | size min-max (B) | ids min..max.
With --extract DIR also writes every payload to DIR/<TYPE>_<id>.bin (type spaces become '_').

Usage: python3 docs/bubble-trouble/tools/rsrc_census.py [--extract DIR] FILE.rsrc [FILE.rsrc ...]
"""
import os
import struct
import sys


def parse(path):
    d = open(path, 'rb').read()
    doff, moff, dlen, mlen = struct.unpack('>IIII', d[:16])
    if moff + mlen > len(d) or doff + dlen > len(d):
        raise ValueError('%s: header offsets exceed file size — not a resource fork' % path)
    m = d[moff:moff + mlen]
    tlo, nlo = struct.unpack('>HH', m[24:28])
    tl = m[tlo:]
    ntypes = struct.unpack('>H', tl[:2])[0] + 1
    out = []  # (type, [(id, name, attrs, data), ...]) in map order
    for i in range(ntypes):
        t, cnt, ro = struct.unpack('>4sHH', tl[2 + 8 * i:10 + 8 * i])
        items = []
        for j in range(cnt + 1):
            rid, no, attr_off, _h = struct.unpack('>hHII', tl[ro + 12 * j:ro + 12 * j + 12])
            attrs, off = attr_off >> 24, attr_off & 0xFFFFFF
            ln = struct.unpack('>I', d[doff + off:doff + off + 4])[0]
            data = d[doff + off + 4:doff + off + 4 + ln]
            name = None
            if no != 0xFFFF:
                nl = m[nlo + no]
                name = m[nlo + no + 1:nlo + no + 1 + nl].decode('mac_roman')
            items.append((rid, name, attrs, data))
        out.append((t.decode('mac_roman'), items))
    return out, len(d)


def main(argv):
    extract = None
    if len(argv) >= 2 and argv[0] == '--extract':
        extract, argv = argv[1], argv[2:]
    if not argv:
        print(__doc__)
        return 2
    for p in argv:
        types, size = parse(p)
        print('== %s (%s B)' % (os.path.basename(p), format(size, ',')))
        print('| type | count | size (B) | ids |')
        print('|---|---|---|---|')
        for t, items in types:
            s = [len(x[3]) for x in items]
            ids = sorted(x[0] for x in items)
            print('| `%s` | %d | %d–%d | %d..%d |' % (t, len(items), min(s), max(s), ids[0], ids[-1]))
            if extract:
                os.makedirs(extract, exist_ok=True)
                for rid, _n, _a, data in items:
                    with open(os.path.join(extract, '%s_%d.bin' % (t.replace(' ', '_'), rid)), 'wb') as f:
                        f.write(data)
        print()
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
