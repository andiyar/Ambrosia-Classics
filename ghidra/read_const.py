#!/usr/bin/env python3
"""Resolve Ghidra's FLOAT_<vaddr> / DOUBLE_<vaddr> symbols to real numbers for any thin Mach-O slice.

Ghidra names numeric constants after the virtual address of the literal in __literal4 (floats)
or __literal8 (doubles). This reads the section table with `otool -l`, picks the byte order from
the Mach-O magic (PPC = big-endian, i386 = little-endian) and prints every literal with its vaddr.

Usage: python3 ghidra/read_const.py <binary> [vaddr_hex ...]   # e.g. ghidra/Aki12_i386 33f98 33fa0
       python3 ghidra/read_const.py <binary>                   # dump every literal
PEF binaries (Ferazel/Deimos/Cythera) have no __literal sections: Ghidra reads their constants
inline from the data section, so this tool does not apply to them.
"""
import struct, subprocess, sys, re

def sections(binary):
    out = subprocess.run(["otool", "-l", binary], capture_output=True, text=True, check=True).stdout
    secs = []
    cur = None
    for line in out.splitlines():
        s = line.strip()
        if s.startswith("sectname"):
            cur = {"name": s.split()[1]}
            secs.append(cur)
        elif cur is not None:
            m = re.match(r"(addr|size|offset)\s+(\S+)", s)
            if m:
                cur[m.group(1)] = int(m.group(2), 0)
    return [x for x in secs if x["name"] in ("__literal4", "__literal8") and "offset" in x]

def main():
    if len(sys.argv) < 2:
        print(__doc__); sys.exit(1)
    binary = sys.argv[1]
    want = set(int(a, 16) for a in sys.argv[2:]) or None
    data = open(binary, "rb").read()
    magic = data[:4]
    endian = ">" if magic == b"\xfe\xed\xfa\xce" else "<" if magic == b"\xce\xfa\xed\xfe" else None
    if endian is None:
        sys.exit(f"not a thin 32-bit Mach-O (magic {magic.hex()}); thin it first with lipo -thin")
    for sec in sections(binary):
        size, fmt = (4, "f") if sec["name"] == "__literal4" else (8, "d")
        print(f"=== {sec['name']}  ({sec['addr']:#x}..{sec['addr']+sec['size']:#x}, {endian=}) ===")
        v = sec["addr"]
        while v < sec["addr"] + sec["size"]:
            fo = v - sec["addr"] + sec["offset"]
            val = struct.unpack(endian + fmt, data[fo:fo + size])[0]
            if want is None or v in want:
                print(f"  {v:#010x} = {val!r}")
            v += size

if __name__ == "__main__":
    main()
