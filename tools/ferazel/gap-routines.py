#!/usr/bin/env python3
"""Port-gap ledger, part 3: every routine of the original × where the port cites it.

Reads the function list of the committed decompiles (ghidra/ferazel/Ferazel_pef.decompiled.c — 1,236 functions —
and Ferazel_handlers.decompiled.c — the 154 TVector targets of docs/ferazel/tools/targets.txt), then searches the
port's Swift sources (Core, Shared, App, Windows) for each routine's name as the port cites it (`.Name`, a word
boundary after it) or its address (`@ 1004aefc` / `0x1004aefc` / `FUN_1004aefc`).
Usage: tools/ferazel/gap-routines.py [repo root] > routines.tsv
Columns: address  name  source  cites  deferred  files
(deferred = cite lines that also say later / not built / Phase 5–7 / refused / stub / partial: a hint of a partial build)   (source = tvector — a sprite/system callback of targets.txt — or pef; cites = matching lines; files = up to 6)
A routine with 0 cites is "not cited", not necessarily "not built": the hand classification in
docs/ferazel/port-gap-ledger.md §3 decides built / partial / not built (+ phase) / out of scope.
"""
import os, re, sys, collections

ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
DIRS = ['Ferazel/Core/Sources', 'Ferazel/Shared', 'Ferazel/App', 'Ferazel/Windows/Sources']
DEFER = re.compile(r'later|not built|unbuilt|Phase\s*[5-7]|refus|not yet|stub|partial', re.I)
HDR = re.compile(r'^// ==== (\S+) @ ([0-9a-f]{8}) ====')

def functions():
    out = collections.OrderedDict()
    for src, fn in (('pef', 'Ferazel_pef.decompiled.c'), ('handler', 'Ferazel_handlers.decompiled.c')):
        for line in open(os.path.join(ROOT, 'ghidra/ferazel', fn), encoding='utf-8', errors='replace'):
            m = HDR.match(line)
            if m:
                name, addr = m.group(1), m.group(2)
                if addr not in out:
                    out[addr] = (name, src)
    tv = set()
    for line in open(os.path.join(ROOT, 'docs/ferazel/tools/targets.txt')):
        if line.strip():
            tv.add(line.split()[0].lower())
    return collections.OrderedDict((a, (n, 'tvector' if a in tv else 'pef')) for a, (n, s) in out.items())

def sources():
    seen, texts = set(), []
    for d in DIRS:
        for dp, dn, fns in os.walk(os.path.join(ROOT, d)):
            for f in fns:
                if f.endswith('.swift'):
                    p = os.path.join(dp, f)
                    r = os.path.realpath(p)
                    if r in seen:
                        continue
                    seen.add(r)
                    texts.append((os.path.relpath(p, ROOT), open(p, encoding='utf-8', errors='replace').read().split('\n')))
    return texts

def main():
    fns = functions()
    texts = sources()
    print('address\tname\tsource\tcites\tdeferred\tfiles')
    for addr, (name, src) in sorted(fns.items()):
        pats = [re.escape(addr)]
        if not name.startswith('FUN_'):
            bare = name.lstrip('.')
            pats.append(r'(?<![A-Za-z0-9_])\.?' + re.escape(bare) + r'(?![A-Za-z0-9_])' if len(bare) > 5 else
                        r'(?<![A-Za-z0-9_])\.' + re.escape(bare) + r'(?![A-Za-z0-9_])')
        rx = re.compile('|'.join(pats))
        cites, deferred, files = 0, 0, collections.Counter()
        for rel, lines in texts:
            for ln in lines:
                if rx.search(ln):
                    cites += 1
                    files[rel.split('/')[-1]] += 1
                    if DEFER.search(ln):
                        deferred += 1
        top = ','.join(f'{f}:{c}' for f, c in files.most_common(6))
        print(f'{addr}\t{name}\t{src}\t{cites}\t{deferred}\t{top}')

if __name__ == '__main__':
    main()
