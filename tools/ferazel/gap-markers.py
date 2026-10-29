#!/usr/bin/env python3
"""Port-gap ledger, part 2: every port marker that refuses, throws, stubs, skips or defers.

Walks the Ferazel port's Swift sources (Core, Shared, App, Windows) and prints one TSV row per marker:
consecutive comment lines that match are merged into one marker (first line kept as the anchor).
Usage: tools/ferazel/gap-markers.py [repo root] > markers.tsv
Columns: id  file  line  kind  text   (kind = the keyword families that matched, comma-separated)
Re-runnable; read-only. Classification (a/b/c/d) is done by hand in docs/ferazel/port-gap-ledger.md.
"""
import os, re, sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
DIRS = ['Ferazel/Core/Sources/FerazelCore', 'Ferazel/Core/Sources/FerazelRender', 'Ferazel/Core/Sources/ferazel-census',
        'Ferazel/Shared', 'Ferazel/App', 'Ferazel/Windows/Sources']
FAMILIES = [
    ('refuse',   r'\brefus\w*'),
    ('unbuilt',  r'not built|unbuilt|not yet|unimplemented|not implemented|no[t]? modelled|not modelled|not ported'),
    ('defer',    r'\blater\b|\bPhase\s*[0-9W]\b|phase\s*[0-9]\b|\bfuture\b|\bdeferred?\b'),
    ('todo',     r'\bTODO\b|\bFIXME\b|\bXXX\b|\bHACK\b'),
    ('stub',     r'\bstub\w*|placeholder|\bno-?op\b'),
    ('scope',    r'out of scope|unsupported|not supported'),
    ('skip',     r'\bskip(s|ped|ping)?\b|\bignor(e|es|ed|ing)\b'),
    ('trap',     r'fatalError|preconditionFailure|assertionFailure|\btry!|precondition\('),
    ('throw',    r'\bthrow\s'),
]
RX = [(k, re.compile(p, re.I if k not in ('todo',) else 0)) for k, p in FAMILIES]

def files():
    for d in DIRS:
        base = os.path.join(ROOT, d)
        for dp, dn, fn in os.walk(base, followlinks=False):
            dn.sort()
            for f in sorted(fn):
                if f.endswith('.swift'):
                    yield os.path.join(dp, f)

def main():
    seen = set()
    n = 0
    print('id\tfile\tline\tkind\ttext')
    for path in files():
        real = os.path.realpath(path)
        if real in seen:      # Windows symlinks the shared files; count each source once
            continue
        seen.add(real)
        rel = os.path.relpath(path, ROOT)
        lines = open(path, encoding='utf-8', errors='replace').read().split('\n')
        prev_comment_hit = False
        for i, line in enumerate(lines, 1):
            s = line.strip()
            kinds = [k for k, rx in RX if rx.search(s)]
            is_comment = s.startswith('//') or s.startswith('*') or s.startswith('/*')
            if not kinds:
                prev_comment_hit = prev_comment_hit and is_comment
                continue
            if is_comment and prev_comment_hit:
                continue      # same comment block as the previous marker
            n += 1
            text = s.replace('\t', ' ')
            if len(text) > 220:
                text = text[:217] + '...'
            print(f'M{n:04d}\t{rel}\t{i}\t{",".join(kinds)}\t{text}')
            prev_comment_hit = is_comment
    print(f'# {n} markers', file=sys.stderr)

if __name__ == '__main__':
    main()
