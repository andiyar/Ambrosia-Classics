#!/usr/bin/env python3
"""Function-aware search over the Ghidra decompilation dump.

The dump (ghidra/EV_Override_i386.decompiled.c, produced by DumpDecompile.java)
separates functions with lines of the form:  // ==== <name> @ <addr> ====
This splits on those markers and prints whole functions whose header OR body
matches a regex, so RE searches return complete functions instead of stray lines.

Usage:
  python3 ghidra/find_func.py '<regex>'                 # print matching functions
  python3 ghidra/find_func.py '<regex>' --names         # just headers (survey)
  python3 ghidra/find_func.py '<regex>' --max 5         # cap number printed
  python3 ghidra/find_func.py '<regex>' --file <path>   # alternate dump file
  python3 ghidra/find_func.py --func FUN_00801234       # print one function by name
"""
import sys, re, argparse

DEFAULT = "ghidra/Aki12_i386.decompiled.c"
HDR = re.compile(r'^// ==== (.+?) @ ([0-9A-Fa-fx]+) ====$', re.M)


def blocks(path):
    text = open(path, encoding="utf-8", errors="replace").read()
    hits = list(HDR.finditer(text))
    for i, m in enumerate(hits):
        end = hits[i + 1].start() if i + 1 < len(hits) else len(text)
        yield m.group(1), m.group(2), text[m.start():end]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pattern", nargs="?", default=None)
    ap.add_argument("--file", default=DEFAULT)
    ap.add_argument("--names", action="store_true", help="print only headers")
    ap.add_argument("--func", default=None, help="exact function name to print")
    ap.add_argument("--max", type=int, default=0, help="cap functions printed (0=all)")
    a = ap.parse_args()

    if a.func:
        for name, addr, body in blocks(a.file):
            if name == a.func:
                sys.stdout.write(body)
                return
        print(f"(no function named {a.func})")
        return

    rx = re.compile(a.pattern, re.I) if a.pattern else None
    n = 0
    for name, addr, body in blocks(a.file):
        if rx is None or rx.search(body):
            n += 1
            if a.names:
                # count matches in body for ranking
                c = len(rx.findall(body)) if rx else 0
                print(f"{name:32} @ {addr}   ({c} hits)")
            else:
                sys.stdout.write(body)
            if a.max and n >= a.max:
                break
    if a.names or n == 0:
        print(f"\n[{n} function(s) matched]", file=sys.stderr)


if __name__ == "__main__":
    main()
