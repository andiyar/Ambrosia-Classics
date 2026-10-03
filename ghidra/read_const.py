#!/usr/bin/env python3
"""Dump the float/double literal pools of the i386 slice, keyed by virtual address.

Ghidra renders numeric constants as FLOAT_<vaddr> / DOUBLE_<vaddr> symbols. This
prints every value in __literal4 (floats) and __literal8 (doubles) with its vaddr
so those symbols can be resolved to real numbers. Section addr/offset are from
`otool -l`; a value at vaddr V in a section (secAddr, secOff) sits at file offset
V - secAddr + secOff.

Usage: python3 ghidra/read_const.py [vaddr_hex ...]   # filter to specific vaddrs
       python3 ghidra/read_const.py                    # dump all
"""
import struct, sys

BIN = "ghidra/EV_Override_i386"
# (name, secAddr, secOff, size, count, fmt)
SECTIONS = [
    ("__literal4", 0x000e0dec, 916972, 4, "<f"),
    ("__literal8", 0x000e0f10, 917264, 8, "<d"),
]
SECT_END = {"__literal4": 0x000e0dec + 0x124, "__literal8": 0x000e0f10 + 0x3d8}

def main():
    want = set(int(a, 16) for a in sys.argv[1:]) if len(sys.argv) > 1 else None
    data = open(BIN, "rb").read()
    for name, addr, off, size, fmt in SECTIONS:
        end = SECT_END[name]
        print(f"=== {name}  ({addr:#x}..{end:#x}) ===")
        v = addr
        while v < end:
            fo = v - addr + off
            val = struct.unpack(fmt, data[fo:fo + size])[0]
            if want is None or v in want:
                print(f"  {v:#08x} = {val!r}")
            v += size

if __name__ == "__main__":
    main()
