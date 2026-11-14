#!/usr/bin/env python3
"""script_canon.py — canonical parity form of the committed scriptdis.py listings (Cythera plan, Task C9).

Reads a directory of `scriptdis.py` listings (`ghidra/cythera/cythera-scripts/<seg>.txt`, the committed
oracle) and reduces each to the canonical text the Swift `ScriptCanonical.text(_:)` produces:

    seg <ID4> kind <kind> len <TOC length>
    <OFFS4> <LEN> <MNEMONIC> <FLAG>

one line per listing line that starts with `XXXX:` (the indented 0x45 inline-block lines and the `;`
comment lines are not instructions), each line ending in a newline. `ID4`/`OFFS4` are four upper-case
hex digits; `LEN` is decimal bytes (the byte pairs shown + the `…+N` continuation; 0 for the combat-AI
`name`/`entry` lines; the byte count for a data line); `FLAG` is `-` reached, `>` jump target, `x` dead.
For data-kind segments the data-line pattern is applied FIRST (the instruction pattern also matches a data
line and would yield the mnemonic `00`). The kind is the token after `; kind ` in the header (`ai` when the
header says "compiled combat AI"); the length is the header's byte count (the TOC length).

Stdlib only. Run from the repo root:

    python3 -I docs/cythera/tools/script_canon.py ghidra/cythera/cythera-scripts
    python3 -I docs/cythera/tools/script_canon.py ghidra/cythera/cythera-scripts --out DIR --sha256 FILE

Prints the totals (files, lines, flags, kinds, the mnemonic histogram). `--out DIR` writes one
`<ID4>.canon` per segment; `--sha256 FILE` writes `<sha256>  <ID4>` per segment, sorted by id (the
committed copy is `docs/cythera/script-parity.sha256`). Any line starting `XXXX:` that matches neither
pattern is an error (exit 1).
"""
import argparse, collections, hashlib, os, re, sys

INSN = re.compile(r'^([0-9A-F]{4}):([> x])(?:((?:[0-9a-f]{2} )*[0-9a-f]{2})(?: …\+(\d+))?)?\s*(\S+)')
DATA = re.compile(r'^([0-9A-F]{4}):  ((?:[0-9a-f]{2} ?)+)$')
LEAD = re.compile(r'^[0-9A-F]{4}:')
KIND = re.compile(r'^; kind (\S+)')
LENGTH = re.compile(r'length (\d+) bytes')
FLAGS = {' ': '-', '>': '>', 'x': 'x'}


class CanonError(Exception):
    pass


def canon(name, text):
    """(id, kind, canonical text, [(mnemonic, flag)]) of one listing."""
    lines = text.split('\n')
    m = re.match(r'^; segment ([0-9A-Fa-f]{4}) ', lines[0])
    if not m:
        raise CanonError('%s: no "; segment" header' % name)
    sid = int(m.group(1), 16)
    kind = length = None
    for ln in lines:
        if not ln.startswith(';'):
            break
        k = KIND.match(ln)
        if k and kind is None:
            kind = k.group(1)
        n = LENGTH.search(ln)
        if n and length is None:
            length = int(n.group(1))
    if kind is None and 'compiled combat AI' in lines[0]:
        kind = 'ai'
    if kind is None or length is None:
        raise CanonError('%s: kind or length missing from the header' % name)
    out = ['seg %04X kind %s len %d' % (sid, kind, length)]
    rows = []
    for no, ln in enumerate(lines, 1):
        if not LEAD.match(ln):
            continue
        d = DATA.match(ln) if kind == 'data' else None
        if d:
            off, n, mn, flag = d.group(1), len(d.group(2).split()), '.data', '-'
        else:
            i = INSN.match(ln)
            if not i:
                raise CanonError('%s:%d: unmatched line %r' % (name, no, ln))
            off = i.group(1)
            shown = len(i.group(3).split()) if i.group(3) else 0
            n = shown + (int(i.group(4)) if i.group(4) else 0)
            mn, flag = i.group(5), FLAGS[i.group(2)]
        out.append('%s %d %s %s' % (off, n, mn, flag))
        rows.append((mn, flag))
    return sid, kind, '\n'.join(out) + '\n', rows


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('listings', help='directory of scriptdis.py listings (<seg>.txt)')
    ap.add_argument('--out', metavar='DIR', help='write one <ID4>.canon per segment')
    ap.add_argument('--sha256', metavar='FILE', help='write "<sha256>  <ID4>" per segment, sorted by id')
    a = ap.parse_args(argv)
    names = sorted(f for f in os.listdir(a.listings) if f.endswith('.txt'))
    if a.out:
        os.makedirs(a.out, exist_ok=True)
    kinds, flags, mns = collections.Counter(), collections.Counter(), collections.Counter()
    hashes = {}
    total = 0
    try:
        for f in names:
            with open(os.path.join(a.listings, f), encoding='utf-8') as fh:
                sid, kind, text, rows = canon(f, fh.read())
            if sid in hashes:
                raise CanonError('%s: segment %04X listed twice' % (f, sid))
            data = text.encode('utf-8')
            hashes[sid] = hashlib.sha256(data).hexdigest()
            kinds[kind] += 1
            total += len(rows)
            for mn, fl in rows:
                mns[mn] += 1
                flags[fl] += 1
            if a.out:
                with open(os.path.join(a.out, '%04X.canon' % sid), 'wb') as fh:
                    fh.write(data)
    except CanonError as e:
        print('script_canon: %s' % e, file=sys.stderr)
        return 1
    if a.sha256:
        with open(a.sha256, 'w', encoding='ascii', newline='\n') as fh:
            for sid in sorted(hashes):
                fh.write('%s  %04X\n' % (hashes[sid], sid))
    print('files %d  lines %d' % (len(names), total))
    print('flags  - %d  > %d  x %d' % (flags['-'], flags['>'], flags['x']))
    print('kinds  ' + '  '.join('%s %d' % kv for kv in sorted(kinds.items(), key=lambda kv: (-kv[1], kv[0]))))
    print('mnemonics %d: ' % len(mns) + ' · '.join('%s %d' % kv for kv in
                                                    sorted(mns.items(), key=lambda kv: (-kv[1], kv[0]))))
    return 0


if __name__ == '__main__':
    sys.exit(main())
