#!/usr/bin/env python3
"""Later-level ledger (plan Task LL): every table of docs/ferazel/later-levels-ledger.md, regenerated from the data.

Reads (read-only): Resources/Ferazel/ (the world file's Mlvl + Mcnv), docs/ferazel/gap-ledger/placements-all.tsv and
resources-classified.tsv, the committed dump ghidra/ferazel/Ferazel_pef.decompiled.c (its `// ==== name @ addr ====`
headers and bodies), the bank (a pinned list of docs/ferazel/*.md, for the section of each type), the plan
docs/superpowers/plans/2026-11-04-ferazel-remainder.md (its card ids) and the port's sources
(Ferazel/Core/Sources, Ferazel/Core/Tests/FerazelRenderTests/DrawModeAuditTests.swift) for the "port today" columns.
The port columns come from a rule table (`port_arm`) whose every file:line is resolved by an anchor regex at run time,
so a moved line moves with the code; an anchor that no longer matches fails --check. The rule table is static (no
Swift is run); --check also runs it over levels 1-5, where the port sets up every record, and fails on any refusal.

Usage:
  python3 -I tools/ferazel/later-levels-ledger.py            # print every block (Markdown) to stdout
  python3 -I tools/ferazel/later-levels-ledger.py --section levels|switches|wind|types|old-types|per-level|resources|
                                                  header-resources|convs|cache|deps|owners
  python3 -I tools/ferazel/later-levels-ledger.py --write    # regenerate the <!-- LL:… --> blocks of the document
  python3 -I tools/ferazel/later-levels-ledger.py --check    # exit 0 only when: the type ledger's rows (type, first
        level, other levels, record count) equal the census recomputed from placements-all.tsv; the Mlvl records
        agree with placements-all.tsv per level and type; every owner named is a card of the plan's Wave 5-7 tables
        or a proposal named in bold in the document's section 8; the total recomputed from the raw Mlvl records
        equals the TSV's, the level table's and section 0's; every nonzero header switch field of every later level
        appears; no Mcnv uses an opcode the port does not handle; the dump has its 1,236 headers; every pinned bank
        file exists; every port anchor resolves; the port model sets up every record of levels 1-5; and the
        committed document (docs/ferazel/later-levels-ledger.md) holds the generated blocks byte for byte.
Levels in scope: every Mlvl id not in BUILT (1-5).
"""
import os, sys, re, struct, collections, csv, functools
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(ROOT, 'docs/ferazel/tools'))
from rsrc_census import parse          # noqa: E402
from gensprite_map import gen          # noqa: E402

BUILT = [1, 2, 3, 4, 5]
WORLD = os.path.join(ROOT, "Resources/Ferazel/Ferazel's Wand World Data.rsrc")
DUMP = os.path.join(ROOT, 'ghidra/ferazel/Ferazel_pef.decompiled.c')
SRC = os.path.join(ROOT, 'Ferazel/Core/Sources')
AUDIT = os.path.join(ROOT, 'Ferazel/Core/Tests/FerazelRenderTests/DrawModeAuditTests.swift')
PLACEMENTS = os.path.join(ROOT, 'docs/ferazel/gap-ledger/placements-all.tsv')
RESOURCES = os.path.join(ROOT, 'docs/ferazel/gap-ledger/resources-classified.tsv')
DOC = os.path.join(ROOT, 'docs/ferazel/later-levels-ledger.md')
PLAN = os.path.join(ROOT, 'docs/superpowers/plans/2026-11-04-ferazel-remainder.md')
FAILS = []            # --check failures (anchors that no longer resolve, data mismatches)


def h(v):
    return f'0x{v & 0xffff:x}'


def rel(p):
    return os.path.relpath(p, ROOT)


# ---------------------------------------------------------------- data: levels, records, census

_, RES = parse(WORLD)
MLVL = {rid: body for rid, _, body in RES['Mlvl']}
MCNV = {rid: (name, body) for rid, name, body in RES['Mcnv']}
LEVELS = sorted(MLVL)
LATER = [lv for lv in LEVELS if lv not in BUILT]


def records(lv):
    """Every placement record (world-data-format §3.4): flag u8, byte1 u8, type, p1..p4, y, x (i16)."""
    body, out = MLVL[lv], []
    for i in range(511):
        flag, b1, typ, p1, p2, p3, p4, y, x = struct.unpack('>BBhhhhhhh', body[4 + 16 * i:20 + 16 * i])
        out.append(dict(i=i, flag=flag, b1=b1, type=typ, p=(p1, p2, p3, p4), y=y, x=x))
    return out


REC = {lv: records(lv) for lv in LEVELS}
ACTIVE = {lv: [r for r in REC[lv] if r['flag'] == 1 and r['type'] != 0] for lv in LEVELS}
COUNT = {lv: collections.Counter(r['type'] for r in ACTIVE[lv]) for lv in LEVELS}
BUILT_TYPES = set(t for lv in BUILT for t in COUNT[lv])
NEW = {lv: sorted(t for t in COUNT[lv] if t not in BUILT_TYPES) for lv in LATER}
FIRST = {}
for lv in LATER:
    for t in NEW[lv]:
        FIRST.setdefault(t, lv)
LEVELS_OF = collections.defaultdict(list)
for lv in LATER:
    for t in NEW[lv]:
        LEVELS_OF[t].append(lv)


def p_values(t, k=0, lvs=None):
    return sorted(set(r['p'][k] for lv in (LATER if lvs is None else lvs) for r in ACTIVE[lv] if r['type'] == t))


def cls_of(t):
    return gen(t & 0xffff, any(p < 0 for p in p_values(t)))[0] or '-'


# placements-all.tsv agreement (the census the card quotes)
with open(PLACEMENTS) as f:
    tsv = collections.defaultdict(dict)
    for row in csv.DictReader(f, delimiter='\t'):
        tsv[int(row['level'])][int(row['type'])] = int(row['count'])
for lv in LEVELS:
    if dict(COUNT[lv]) != tsv.get(lv, {}):
        FAILS.append(f'placements-all.tsv disagrees with the Mlvl on level {lv}')

# ---------------------------------------------------------------- the dump

DL = open(DUMP, encoding='utf-8', errors='replace').read().split('\n')
HDR = re.compile(r'^// ==== (.+?) @ ([0-9A-Fa-fx]+)(?: \([^)]*\))? ====$')
HEADS = [(i + 1, m.group(1)) for i, l in enumerate(DL) for m in [HDR.match(l)] if m]
SPAN = {}
for k, (ln, name) in enumerate(HEADS):
    end = HEADS[k + 1][0] - 1 if k + 1 < len(HEADS) else len(DL)
    SPAN.setdefault(name, (ln, end))
if len(HEADS) != 1236:
    FAILS.append(f'the dump has {len(HEADS)} function headers, not 1,236')


def func_at(line):
    lo, hi, best = 0, len(HEADS) - 1, None
    while lo <= hi:
        mid = (lo + hi) // 2
        if HEADS[mid][0] <= line:
            best, lo = HEADS[mid][1], mid + 1
        else:
            hi = mid - 1
    return best


def span_txt(name):
    s = SPAN.get(name)
    return f'{name} {s[0]}–{s[1]}' if s else f'{name} (no header)'


def lits(v):
    return [re.compile(r'(?<![0-9A-Za-z_])0x%x(?![0-9A-Za-z_])' % v), re.compile(r'(?<![0-9A-Za-z_.x])%d(?![0-9A-Za-z_.])' % v)]


def hits_in(name, values, cap=4):
    """Lines of function `name` that name any of `values` as a literal (hex or decimal)."""
    s = SPAN.get(name)
    if not s:
        return []
    pats = [p for v in values for p in lits(v)]
    out = [i for i in range(s[0], s[1] + 1) if any(p.search(DL[i - 1]) for p in pats)]
    return out[:cap]


CLASS_FUNCS = {   # class -> (Init, Setup, Handle) as the dump's headers name them
    c: (f'.Init{c}Sprite', f'.Setup{c}Sprite', f'.Handle{c}Sprite') for c in
    ['Bonus', 'Box', 'Background', 'Platform', 'Button', 'Walker', 'Crawler', 'Roach', 'Blob', 'Bat', 'Gremlin',
     'Floater', 'Frog', 'Salamander', 'Warrior', 'Wizard', 'Effect', 'Dillo', 'Crab', 'Chief', 'Demon', 'Xichra',
     'Rope']}

# ---------------------------------------------------------------- the port: anchors

_SRC_CACHE = {}


def src_lines(path):
    if path not in _SRC_CACHE:
        _SRC_CACHE[path] = open(path, encoding='utf-8').read().split('\n')
    return _SRC_CACHE[path]


def anchor(path, start, target=None):
    """file:line of the first line matching `start` (then, with `target`, the first line at or after it matching
    `target`); a miss is a --check failure."""
    full = os.path.join(SRC, path)
    L = src_lines(full)
    for i, l in enumerate(L):
        if re.search(start, l):
            if target is None:
                return f'{path}:{i + 1}'
            for j in range(i, len(L)):
                if re.search(target, L[j]):
                    return f'{path}:{j + 1}'
            break
    FAILS.append(f'anchor not found: {path} /{start}/ /{target}/')
    return f'{path}:?'


SF = 'FerazelCore/Sprites/SetupFaces.swift'
BOX = 'FerazelCore/World/Movers/BoxSprite.swift'
BG = 'FerazelCore/World/Movers/BackgroundSprite.swift'
BON = 'FerazelCore/World/Movers/BonusSprite.swift'
LR = 'FerazelCore/Front/LevelRun.swift'


def sheet_table_picts():
    """Hex literals inside SetupFaces' `sheets` table (the faces `face(t)` arms can draw; SetupFaces.swift `if source
    != .none, sheet == nil { throw … }` refuses any other)."""
    L = src_lines(os.path.join(SRC, SF))
    a = next(i for i, l in enumerate(L) if 'private static let sheets' in l)
    b = next(i for i in range(a, len(L)) if 'return table' in L[i])
    return set(int(x, 16) for l in L[a:b] for x in re.findall(r'0x([0-9a-f]+)', l.split('//')[0]))


SHEETS = sheet_table_picts()
FACE_REFUSAL = None   # resolved lazily (anchor)


def face_refusal():
    global FACE_REFUSAL
    if FACE_REFUSAL is None:
        FACE_REFUSAL = anchor(SF, r'if source != \.none, sheet == nil \{ throw')
    return FACE_REFUSAL


def cached_records():
    """CachedFaces.sets / .singles (LevelRun.swift) as the port registers them today: [(pict, faces, flag)]."""
    L = src_lines(os.path.join(SRC, LR))
    out = {}
    for key in ('sets', 'singles'):
        a = next(i for i, l in enumerate(L) if re.search(r'static let %s: \[Record\] = \[' % key, l))
        b = next(i for i in range(a, len(L)) if L[i].strip() == ']')
        out[key] = [(int(p, 16), int(n), int(fl)) for l in L[a:b]
                    for p, n, fl in re.findall(r'Record\(pict: 0x([0-9a-f]+), faces: (\d+), flag: (\d)\)', l)]
    return out


PORT_CACHE = cached_records()

# ---------------------------------------------------------------- the port: one rule per type range

BUILT_S, REFUSED, NOTBUILT, PARTIAL = 'built', 'refused', 'not built', 'built (Setup) / Handle arm not built'
FLIPLESS = 'built (Setup) / hot-rect flip not built'


def port_arm(t, cls, lvs=None):
    """(state, site, note) for type t over the records of levels `lvs` (default: every later level)."""
    ps = tuple(sorted(set(r['p'] for lv in (LATER if lvs is None else lvs) for r in ACTIVE[lv] if r['type'] == t)))
    n1 = sum(1 for lv in (LATER if lvs is None else lvs) for r in ACTIVE[lv] if r['type'] == t and r['p'][0] != 0)
    return _port_arm(t, cls, ps, n1)


def record_state(r, cls=None):
    """The port's state for ONE placement record (its own parameters only)."""
    return _port_arm(r['type'], cls or cls_of(r['type']), (r['p'],), int(r['p'][0] != 0))[0]


def refused_records(lv, t):
    """How many of type t's active records on level lv the port model does not set up (counted per record)."""
    c = cls_of(t)
    return sum(1 for r in ACTIVE[lv] if r['type'] == t and record_state(r, c) != BUILT_S)


FLIP_RECT = (0xb0b, 0xb10, 0xb11, 0xb12, 0xb13, 0xb14)   # decorations whose Setup gives a non-empty hot rect (M l. 59650–59667)


@functools.lru_cache(maxsize=None)
def _port_arm(t, cls, ps, n1):
    """(state, site, note) for type t as `SetupFaces.setup` and the class code treat it today, over the parameter
    tuples `ps` (p1…p4 of the records considered; `n1` of them have p1 ≠ 0)."""
    p1s = sorted(set(p[0] for p in ps))
    p2s = sorted(set(p[1] for p in ps))
    if cls == 'Background':
        if 0x442 <= t <= 1098:
            if any(p != 0 for p in p1s):
                return (REFUSED, anchor(SF, r'case 0x442\.\.\.1098:', r'guard p\.p1 == 0 else'),
                        f'cannon p1 ≠ 0 ({n1} record{"s" if n1 != 1 else ""}: p1 {",".join(map(str, [p for p in p1s if p]))}); the '
                        f'rotating / path arms: {anchor(BG, r"later: p1 ≠ 0")}')
            return (BUILT_S, anchor(SF, r'case 0x442\.\.\.1098:'), 'cannon p1 0 (W2b)')
        if 0x47e <= t <= 0x481:
            return (BUILT_S, anchor(SF, r'case 0x47e\.\.\.0x481:'),
                    'spring (W2b); its Setup marks cache set 0x47e/0x47f (M l. 62047, 62187) — not in '
                    f'CachedFaces ({anchor(LR, r"static func marks")})')
        if 0x5c8 <= t <= 0x5d1:
            modes = sorted(set(0xb if p == 0 else p for p in p1s))
            if any(m in (1, 2) for m in modes):
                return (REFUSED, anchor(SF, r'case 0x5c8\.\.\.0x5d1:', r'guard !\(1\.\.\.2\)\.contains\(mode\)'),
                        f'mace modes {modes}: modes 1–2 (programmed path) refused')
            return (BUILT_S, anchor(SF, r'case 0x5c8\.\.\.0x5d1:'), f'mace modes {modes} (W2a)')
        if 0xa8c <= t <= 0xaef or 3000 <= t < 0xbc2:
            arm = anchor(SF, r'case 0xa8c\.\.\.0xaef:') if t <= 0xaef else anchor(SF, r'case 3000\.\.<0xbc2:')
            if t in SHEETS:
                return (BUILT_S, arm, 'face in the table')
            return (REFUSED, face_refusal(), f'arm {arm} built; face {h(t)} not in the Setup-face table')
        if 0x730 <= t <= 0x733:
            return (BUILT_S, anchor(SF, r'case 0x730\.\.\.0x733:'), 'spikes (LV3)')
        if 0x76c <= t <= 0x76f:
            return (BUILT_S, anchor(SF, r'case 0x76c\.\.\.0x76f:'), 'dart trap (ES)')
        if t in (0xb54, 0xb55):
            note = 'passage (W2b)'
            if any(p != 0 for p in p2s):
                note += f'; p2 {",".join(map(str, p2s))} ≠ 0: {anchor("FerazelCore/Player/HitPlayerSprite.swift", r"later: Phase 6 — p2 ≠ 0")}'
                return (PARTIAL, anchor(SF, r'case 0xb54, 0xb55:'), note)
            return (BUILT_S, anchor(SF, r'case 0xb54, 0xb55:'), note)
        if t == 0xcb1:
            return (BUILT_S, anchor(SF, r'case 0xcb1:'), 'level exit')
        return (REFUSED, anchor(SF, r'case 0xcb1:', r'throw Error\.notTranscribed'),
                f'no Setup arm; Handle: {anchor(BG, r"// later: fire 0x4b8")}')
    if cls == 'Bonus':
        if t == 0xc25 or (0xc80 <= t <= 0xcb0 and t >= 0xc80 + 0x1b):
            return (REFUSED, anchor(BON, r'guard t != 0xc25 else') if t == 0xc25
                    else anchor(BON, r'guard inTable \|\| outOfTableItems'), 'out-of-table Bonus arm')
        arms = [((0x50a, 0x50b), r'case 0x50a, 0x50b:', 'big crystal'), ((0x50c, 0x50d), r'case 0x50c, 0x50d:', 'money bag'),
                ((0x532, 0x53b), r'\(0x532\.\.\.0x53b\)\.contains', 'sphere'), ((0xbea, 0xbea), r'case 0xbea:', 'hang glider'),
                ((0xc1c, 0xc25), r'if candelabras\.contains\(t\)', 'candelabra'),
                ((0xc80, 0xcb0), r'\} else \{\s+// items', 'item')]
        for (lo, hi), rx, what in arms:
            if lo <= t <= hi:
                note = what + ' (BN; Handle `BonusSprite.handle`)'
                if t == 0xbea:
                    note += '; its Setup marks the four Player cache sets 0x41a…0x41d (M l. 52616–52624) — not in CachedFaces'
                return (BUILT_S, anchor(BON, rx), note)
        return (BUILT_S, anchor(BON, r'public static func setup\('), 'Bonus arm (BN)')
    if cls == 'Box':
        later_box = anchor(BOX, r'Whether the type.s `\.HandleBoxSprite` runs')
        face_arms = [((0xaf5, 0xb21), r'case 0xaf5\.\.<0xb22:', 'decoration'), ((0xb22, 0xb35), r'case 0xb22\.\.<0xb36:', 'rock outcrop'),
                     ((0xb36, 0xb49), r'case 0xb36\.\.<0xb4a:', 'mushroom'), ((0xb56, 0xb5d), r'case 0xb56\.\.<0xb5e:', 'sign'),
                     ((0xb68, 0xb70), r'case 0xb68\.\.<0xb71:', 'furniture'), ((0xb87, 0xb99), r'case 0xb87\.\.<0xb9a:', 'NPC')]
        for (lo, hi), rx, what in face_arms:
            if lo <= t <= hi:
                arm = anchor(SF, rx)
                extra = ' (the 2907 countdown Handle is built)' if t == 0xb5b else ''
                flip = t in FLIP_RECT and n1 > 0
                if flip:
                    extra += (f'; p1 ≠ 0 on {n1} record{"s" if n1 != 1 else ""} with a non-empty hot rect: the `.FlipHRect` (M l. 59670–59673) '
                              f'is not built ({anchor(BOX, r"later: `[.]FlipHRect")})')
                if t in SHEETS:
                    return (FLIPLESS if flip else BUILT_S, arm, what + extra)
                return (REFUSED, face_refusal(), f'{what}: arm {arm} built; face {h(t)} not in the Setup-face table{extra}')
        fixed = {0x426: r'case 0x426:', 0x429: r'case 0x429:', 0x42e: r'case 0x42e, 0x433, 0x434:',
                 0x433: r'case 0x42e, 0x433, 0x434:', 0x434: r'case 0x42e, 0x433, 0x434:', 0x42f: r'case 0x42f, 0x430:',
                 0x430: r'case 0x42f, 0x430:', 0xb72: r'case 0xb72, 0xb73:', 0xb73: r'case 0xb72, 0xb73:',
                 0xb7d: r'case 0xb7d:', 0xb7c: r'case 0xb7c:', 0x51c: r'case 0x51c:', 0x5b5: r'case 0x5b5, 0x5b6:',
                 0x5b6: r'case 0x5b5, 0x5b6:', 0x5b8: r'case 0x5b8:', 0x5be: r'case 0x5be:', 0xb5e: r'case 0xb5e, 0xb5f:',
                 0xb5f: r'case 0xb5e, 0xb5f:', 0xb74: r'case 0xb74:'}
        if t in fixed:
            return (BUILT_S, anchor(SF, fixed[t]), 'Box arm')
        if 0x4e2 <= t <= 0x4ff:
            return (BUILT_S, anchor(SF, r'case 0x4e2\.\.\.0x4ff:'), 'switch block (BT)')
        if 0x5aa <= t <= 0x5ad:
            return (BUILT_S, anchor(SF, r'case 0x5aa\.\.\.0x5ad:'), 'spout (BT)')
        if 0x5a0 <= t <= 0x5a8:
            return (BUILT_S, anchor(SF, r'case 0x5a0\.\.\.0x5a8:'), f'geyser (GY); p1 {",".join(map(str, p1s))}')
        if 0xc12 <= t <= 0xc14:
            return (BUILT_S, anchor(SF, r'case 0xc12\.\.\.0xc14:'), 'crate')
        dflt = anchor(SF, r'case 0xc12\.\.\.0xc14:', r'throw Error\.notTranscribed')
        if 0x5d2 <= t <= 0x5d5:
            return (REFUSED, dflt, f'enemy pipe: `setupPipe` built ({anchor(BOX, r"public static func setupPipe")}), '
                                   'not wired into the level spawn (6A-L10…L22, level 21)')
        if t in (0x424, 0x425):
            return (REFUSED, dflt, f'teleporter: `BoxSprite.setup` arm built ({anchor(BOX, r"case 0x424\.\.\.0x426:")}); '
                                   'no SetupFaces face arm (boot singles 0x424 / 0x425, M l. 58737–58740)')
        if t in (0x438, 0x439, 0x5c3, 0x5c4, 0xb71, 0xbfe):
            return (REFUSED, dflt, f'no Setup face arm; Handle not built ({later_box})')
        return (REFUSED, dflt, 'no Setup face arm')
    if cls == 'Platform':
        return (BUILT_S, anchor(SF, r'case \.platform:'), f'modes p1 {",".join(map(str, p1s))} (W1: every mode)')
    if cls == 'Rope':
        if 0xbcc <= t <= 0xbce:
            return (BUILT_S, anchor(SF, r'case \.rope:'), 'rope (W3)')
        return (REFUSED, anchor(SF, r'guard RopeSprite\.types\.contains'), 'no rope-segment arm')
    enemy = {'Walker': (r'case 0x6d6\.\.\.0x6df: face', 'WK2'), 'Bat': (r'case \.bat:', 'BA'),
             'Blob': (r'case \.blob:', 'BL'), 'Crab': (r'case \.crab:', 'BL'), 'Gremlin': (r'case \.gremlin:', 'GF'),
             'Floater': (r'case \.floater:', 'GF'), 'Salamander': (r'case \.salamander:', 'FR'),
             'Dillo': (r'case \.dillo:', 'DL'), 'Frog': (r'case \.frog:', 'FR'),
             'Crawler': (r'case \.crawler:', 'CR'), 'Roach': (r'case \.roach:', 'CR'), 'Button': (r'case \.button:', 'BT'),
             'Warrior': (r'case \.warrior:', 'LV5 ◇')}
    if cls in enemy:
        guards = {'Walker': lambda: t in (0x6a4, 0x6a9) or 0x6d6 <= t <= 0x6e9,
                  'Crab': lambda: 0x762 <= t <= 0x766, 'Floater': lambda: 0x6f4 <= t <= 0x6fd,
                  'Dillo': lambda: t in (0x74e, 0x74f), 'Frog': lambda: 0x708 <= t <= 0x711,
                  'Salamander': lambda: 0x712 <= t <= 0x71b}
        if cls in guards and not guards[cls]():
            return (REFUSED, anchor(SF, enemy[cls][0], r'throw Error\.notTranscribed'), f'{cls} variant refused')
        if cls == 'Bat' and t in (0x6cd, 0x6ce, 0x73b, 0x73c):
            ms = set()
            for p in p1s:
                m = -p if p < 1 else p
                ms.add(m - 100 if 99 < m < 200 else m)
            if ms & {10, 11}:
                return (REFUSED, anchor(SF, r'case \.bat:', r'if 9 < m && m < 0xc'), 'bat path modes 10 / 11 (.MakeRadial)')
        return (BUILT_S, anchor(SF, enemy[cls][0]), f'{cls} ({enemy[cls][1]})')
    if cls in ('Chief', 'Wizard', 'Demon', 'Xichra'):
        return (REFUSED, anchor(SF, r'case \.warrior:', r'throw Error\.notTranscribed'),
                f'boss class not transcribed (`.inert`; {anchor("FerazelCore/Session/FerazelSession.swift", r"the four bosses not placed on levels 1–5")})')
    return (REFUSED, anchor(SF, r'case \.warrior:', r'throw Error\.notTranscribed'), 'class not transcribed')


# ---------------------------------------------------------------- owners (plan Waves 5–7; LL's split)

def wave(lv):
    return '6A' if lv <= 22 else ('6B' if lv <= 52 else '6C')


LTASK = {'6A': '6A-L10…L22', '6B': '6B-L25…L52', '6C': '6C-L55…L70'}
BOSS = {'Chief': '6A-CH', 'Wizard': '6B-WZ', 'Demon': '6C-DM', 'Xichra': '6C-XI'}


def bg_split(t):
    """LL's proposed split of 6A-BG1 (the unbuilt Background types first placed on 10–22)."""
    if 0xc08 <= t <= 0xc0f or 0xb4a <= t <= 0xb4d:
        return '6A-BG1a'                      # trees + clouds: single-face scenery with their own Handle arms
    if t == 0xbf4 or 0x5c8 <= t <= 0x5d1 or 0x442 <= t <= 1098:
        return '6A-BG1b'                      # moving hazards: rotating blade (.SectLineSegs), path maces, cannons p1≠0
    return '6A-BG1c'                          # cached faces: plants (+ fire 0x4b8 if placed ≤ 22)


def first_refused(t, cls):
    """The first later level on which type t's records are not all set up by the port (None: built everywhere)."""
    return next((lv for lv in LEVELS_OF[t] if port_arm(t, cls, [lv])[0] != BUILT_S), None)


def type_owner(t, cls, state):
    """One owner per type: a boss card; the countdown / pipes cards; else the wave of the first level that needs work
    (the first level whose records the port refuses), by class; a type built everywhere goes to its first level's task."""
    fr = first_refused(t, cls)
    w = wave(fr if fr is not None else FIRST[t])
    if cls in BOSS:
        return BOSS[cls]
    if t == 0xb5b:
        return '6B-TM'
    if 0x5d2 <= t <= 0x5d5:
        return '6A-L10…L22 (level 21 pipe wiring)'
    if fr is None:
        return LTASK[w]
    if cls == 'Background':
        return bg_split(t) if w == '6A' else ('6B-BG2' if w == '6B' else '6C-BG3')
    if cls == 'Box':
        if w == '6A':
            if t in (0x438, 0x439):
                return '6A-BX1c'
            return '6A-BX1a' if 0xaf5 <= t <= 0xb49 else '6A-BX1b'
        return '6B-BX2' if w == '6B' else '6C-BX3'
    if cls in ('Bonus', 'Platform', 'Rope'):
        return {'6A': '6A-BN1', '6B': '6B-BN2', '6C': '6C-BN3'}[w]
    return LTASK[w]


# ---------------------------------------------------------------- bank sections

BANK = [   # pinned (the topical RE bank at 2f25cf6): a new document under docs/ferazel/ — the phase6-* contracts, this
          # ledger, a review — must not move the bank column, so the list is explicit, not a directory scan
    'bosses-2.md', 'bosses-3.md', 'bosses.md', 'conversations-mcnv.md', 'draw-effects.md', 'enemies-flyers.md',
    'enemies-ground-2.md', 'enemies-ground.md', 'enemies-water-cave.md', 'enemy-shots-and-damage-2.md',
    'enemy-shots-and-damage.md', 'engine.md', 'geysers.md', 'held-item-melee.md', 'lighting-tables.md', 'particles.md',
    'physics-sprites.md', 'physics.md', 'pickups-boxes-2.md', 'pickups-boxes.md', 'platforms-ropes-radial-2.md',
    'platforms-ropes-radial.md', 'player-states-2.md', 'player-states.md', 'rendering-omnipx-titles.md',
    'save-continue.md', 'spells-detail-2.md', 'spells-detail.md', 'spells-items.md', 'sprites-backgrounds-sounds.md',
    'triggers-background-2.md', 'triggers-background.md']
for _f in BANK:
    if not os.path.exists(os.path.join(ROOT, 'docs/ferazel', _f)):
        FAILS.append(f'pinned bank file missing: docs/ferazel/{_f}')
_BANK_LINES = {f: open(os.path.join(ROOT, 'docs/ferazel', f), encoding='utf-8').read().split('\n') for f in BANK
               if os.path.exists(os.path.join(ROOT, 'docs/ferazel', f))}
BANK_PREF = {   # the topical bank files of each class, searched first
    'Background': ['triggers-background', 'triggers-background-2', 'platforms-ropes-radial', 'platforms-ropes-radial-2',
                   'enemy-shots-and-damage'],
    'Box': ['pickups-boxes', 'pickups-boxes-2', 'geysers', 'triggers-background', 'triggers-background-2',
            'enemies-flyers', 'conversations-mcnv'],
    'Bonus': ['pickups-boxes', 'pickups-boxes-2', 'spells-items', 'held-item-melee'],
    'Platform': ['platforms-ropes-radial', 'platforms-ropes-radial-2', 'physics-sprites'],
    'Rope': ['platforms-ropes-radial', 'platforms-ropes-radial-2', 'physics-sprites'],
    'Walker': ['enemies-ground', 'enemies-ground-2', 'bosses-3'], 'Dillo': ['enemies-ground', 'enemies-ground-2'],
    'Blob': ['enemies-water-cave'], 'Crab': ['enemies-water-cave'], 'Salamander': ['enemies-water-cave'],
    'Bat': ['enemies-flyers'], 'Gremlin': ['enemies-flyers'], 'Floater': ['enemies-flyers'],
    'Chief': ['bosses', 'bosses-2', 'bosses-3'], 'Wizard': ['bosses', 'bosses-2', 'bosses-3'],
    'Demon': ['bosses', 'bosses-2', 'bosses-3'], 'Xichra': ['bosses', 'bosses-2', 'bosses-3'],
}


def bank_section(t, cls):
    """The first bank section naming type t: the class's topical files first, hex before decimal."""
    hexp = re.compile(r'(?<![0-9A-Za-z_])0x%x(?![0-9a-f])' % t)
    decp = re.compile(r'(?<![0-9A-Za-z_.,])%d(?![0-9])(?! ?(?:px|B|bytes|ms|frames))' % t)
    pref = [f + '.md' for f in BANK_PREF.get(cls, []) if f + '.md' in _BANK_LINES]
    rest = [f for f in BANK if f not in pref and f in _BANK_LINES]
    for files, pat in ((pref, hexp), (pref, decp), (rest, hexp), (rest, decp)):
        for f in files:
            L = _BANK_LINES[f]
            for i, l in enumerate(L):
                if l.startswith('#'):
                    continue
                if pat.search(re.sub(r'(M |handler |h\. )?l\. [0-9–, …]+', '', l)):
                    head = next((L[j] for j in range(i, -1, -1) if L[j].startswith('#')), '')
                    m = re.match(r'#+\s*([0-9]+(?:\.[0-9]+)*)', head)
                    return f'{f[:-3]} §{m.group(1)}' if m else f'{f[:-3]} ({head.strip("# ")[:30]})'
    return '—'


def arm_base(t, cls):
    """The range base the class Setup / Handle test for type t (the dump writes ranges as base + count)."""
    bases = [0x442, 0x47e, 0x4b8, 0x5c8, 0x5cd, 0xa8c, 3000, 0x730, 0x76c, 0xb4a, 0xb54, 0xc08, 0x50a, 0x50c, 0x532,
             0xc1c, 0xc80, 0x424, 0x438, 0x5a0, 0x5c3, 0x5d2, 0xaf5, 0xb22, 0xb36, 0xb56, 0xb68, 0xb86, 0xb87, 0xc12,
             0x578, 0xbcc, 0x6cc, 0x73a, 0x744, 0x74d, 0x6c2, 0x6ea, 0x6f4, 0x712, 0x74e, 0x762, 0x6d6, 0x776, 0x726,
             0x780, 0x7c6]
    cand = [b for b in bases if b <= t and t - b < 0x40]
    return [max(cand)] if cand else []


# ---------------------------------------------------------------- header switches

FIELDS = [  # (off, size, LevelHeader property, meaning, original readers (dump), owner by level, audit refusal symbol)
    (0x26c6, 1, 'submergedFaces', 'submerged tiles drawn as tinted faces', '.PlainWrapFGTile, .PlainWrapFGOverlayTile, .RedrawScrollGrid', '6A-T11', None),
    (0x26c7, 1, 'omniPxMode', 'OmniPx mode', '.SetupOmniPx, .TurnOnOmniPx, .UpdateOmniPx, .PaintFrameWrap', None, 'LevelOpenRefusal.omniPxMode'),
    (0x26c8, 1, 'startFacingLeft', 'player starts facing left', '.NewGame / .ContinueGame → G+0x16', 'L', None),
    (0x26c9, 1, 'waterSurfaceEffect', 'water-surface effect', '.WrapDrawWaterEffects', 'L', None),
    (0x26ca, 1, 'parallaxRipple', 'parallax ripple', '.RipplePxBackOffsets, .DoubleBlitPPCParallaxOneLayer', '6A-RP', 'Refusal.ripple'),
    (0x26cb, 1, 'patternPeriodSix', 'FG pattern period 6×6', '.GetFGPatternTile', 'L', None),
    (0x26cc, 1, 'pxUsesLevelBaseClut', 'px tilesets under the level+base CLUT', '.LoadPxBackTileset, .LoadPxMidTileset, .MTAddPxSprite', 'L', None),
    (0x26cd, 1, 'inLiquid', 'level-wide "in liquid"', '.HandlePlayerSprite, .SetupBackgroundSprite, .SetupBoxSprite, .SetupFrogSprite', '6B-ICE', None),
    (0x26d0, 1, 'levelSounds', 'own snd set', '.LoadLevelSounds', 'L', None),
    (0x2706, 2, 'darknessEnable', 'per-cell darkness enable', '.GetAmbDarkVal, .DrawLightOverFace, .DrawParticles, .SetupLevel', 'L', None),
    (0x270a, 2, 'cameraOffsetX', 'camera target offset x', '.FindUpperLeftCorner', 'L', None),
    (0x270c, 2, 'cameraOffsetY', 'camera target offset y', '.FindUpperLeftCorner', 'L', None),
    (0x270e, 2, 'landingDamage', 'damaging-surface damage', '.HandlePlayerSprite (+0xd8 == 2)', 'L', None),
    (0x2710, 2, 'iceSlipperiness', 'ice friction', '.HandlePlayerSprite (+0xd8 == 3)', 'ICE', None),
    (0x2712, 2, 'gammaFadeIn', 'gamma fade-in', '.GameLoop', 'L', None),
    (0x2714, 2, 'waterCurrent', 'water-current push', '.StandardSpriteHandles, .WrapDrawWaterEffects', 'L', None),
    (0x2716, 2, 'stripPict', 'horizon strip PICT (draw mode 8)', '.SetupLevel → .MTAddPxSprite; .BlitEncFaceBehindTiles*', '6A-S8', 'LevelOpenRefusal.horizonStrip'),
    (0x2718, 2, 'stripFactor', 'horizon strip x factor', '.SetupLevel → .MTAddPxSprite', '6A-S8', None),
    (0x271a, 2, 'stripBaseY', 'horizon strip base y', '.SetupLevel → .MTAddPxSprite, .BuildSineTable', '6A-S8', None),
    (0x271c, 2, 'altClut', 'alternate CLUT', '.SetupLevel → .AltClutMod', 'L', None),
    (0x271e, 2, 'parallaxMode', 'parallax mode', '.DoubleBlitPPCParallaxOneLayer, .PaintFrameWrap', 'L', None),
    (0x2722, 2, 'flameMode', 'fire backdrop + flame buffer', '.SetupLevel, .PaintFrameWrap, .DoubleBlitPPCParallaxOneLayerFire, .HandleEnemyShotSprite', '6B-FI', 'Refusal.fireVariant'),
    (0x2724, 2, 'arenaBound', 'boss-arena bound (and track 30)', '.FindUpperLeftCorner, .GameLoop, .PlayerConstraints', 'BOSS', None),
    (0x2726, 2, 'autoScrollX', 'auto-scroll x speed', '.SetupLevelSprites, .FindUpperLeftCorner', '6B-AS', None),
    (0x2728, 2, 'autoScrollY', 'auto-scroll y speed', '.SetupLevelSprites, .FindUpperLeftCorner', '6B-AS', None),
    (0x272a, 2, 'autoScrollEnable', 'auto-scroll enable', '.SetupLevelSprites', '6B-AS', 'Error.autoScroll'),
    (0x272c, 2, 'sidePush', 'constant side push', '.HandlePlayerSprite', '6A-RN', None),
    (0x272e, 2, 'secondArenaBound', 'second arena bound', '.FindUpperLeftCorner', 'BOSS', None),
    (0x2730, 2, 'clutAnimMode', 'CLUT animation mode', '.AnimateCLUT', 'CA', None),
    (0x2732, 2, 'clutAnimCount', 'CLUT animation count', '.AnimateCLUT', 'CA', None),
    (0x2734, 2, 'clutAnimPeriod', 'CLUT animation period', '.AnimateCLUT', 'CA', None),
    (0x2736, 2, 'clutAnimAmplitude', 'CLUT animation amplitude', '.AnimateCLUT', 'CA', None),
    (0x284a, 2, 'music', 'music track', '.GameLoop → .SetAIFFMusic', 'L', None),
]
SCAN = [(o, 1) for o in range(0x26c6, 0x26d1)] + [(o, 2) for o in range(0x2706, 0x2738, 2)] + [(0x284a, 2)]
KNOWN = {f[0] for f in FIELDS}


def field_value(lv, off, size):
    b = MLVL[lv]
    return b[off] if size == 1 else struct.unpack('>h', b[off:off + 2])[0]


def hv(lv, off):
    return field_value(lv, off, 2)


for off, size in SCAN:      # a nonzero byte/word the field table does not name is a finding, not silently dropped
    if off not in KNOWN and any(field_value(lv, off, size) for lv in LEVELS):
        FAILS.append(f'header {h(off)} is nonzero on some level and has no row in FIELDS')


def port_readers(prop):
    out = []
    for dp, _, fs in os.walk(SRC):
        for f in sorted(fs):
            if not f.endswith('.swift') or f == 'LevelHeader.swift':
                continue
            p = os.path.join(dp, f)
            for i, l in enumerate(src_lines(p)):
                if re.search(r'\.%s\b' % prop, l):
                    out.append(f'{os.path.relpath(p, SRC).split("/", 1)[1]}:{i + 1}')
    return out


def audit_row(symbol):
    if not symbol:
        return None
    for i, l in enumerate(src_lines(AUDIT)):
        if re.search(r'^\s*R\(".*", "%s"' % re.escape(symbol), l):
            return f'DrawModeAuditTests.swift:{i + 1}'
    FAILS.append(f'DrawModeAuditTests row for {symbol} not found')
    return None


def dump_readers(off):
    pat = re.compile(r'\+ (0x%x|%d)\)' % (off, off))
    fs = collections.OrderedDict()
    for i, l in enumerate(DL):
        if pat.search(l):
            fs.setdefault(func_at(i + 1), i + 1)
    return fs


SWITCH_STATE = {   # LL's reading of the port today, by field (evidence = the port readers column)
    'submergedFaces': 'built: the FG-cell draw (TileGridRenderer) and the lights redraw, overlay cells included '
                      '(LightRenderer `plainWrapFGOverlayTile` = .PlainWrapFGOverlayTile M l. 9720–9735: overlay '
                      'faces tinted under water whatever the flag, the pattern cell with it; the original tints overlay '
                      'cells only there) — 6A-T11 proves it, nothing to build',
    'omniPxMode': 'modes 0/2/4/5 built (OX); 1, 3, 6, 7, ≥ 8 refused at level open',
    'startFacingLeft': 'built', 'waterSurfaceEffect': 'built', 'patternPeriodSix': 'built',
    'parallaxRipple': 'refused (backdrop compositor init)', 'pxUsesLevelBaseClut': 'built',
    'inLiquid': 'built at the readers listed (player liquids, Box gate, Background spring/spike, Frog)',
    'levelSounds': 'not built (0 in all 24)', 'darknessEnable': 'built', 'cameraOffsetX': 'built',
    'cameraOffsetY': 'built', 'landingDamage': 'built', 'iceSlipperiness': 'built (any value)', 'gammaFadeIn': 'built',
    'waterCurrent': 'built', 'stripPict': 'strip sprites built in Core (PxSprites); refused at level open (draw mode 8)',
    'stripFactor': 'read by PxSprites', 'stripBaseY': 'read by PxSprites', 'altClut': 'not built (0 in all 24)',
    'parallaxMode': 'read (0 in all 24)', 'flameMode': 'refused (backdrop compositor init)',
    'arenaBound': 'built (LV5)', 'autoScrollX': 'not built (no reader)', 'autoScrollY': 'not built (no reader)',
    'autoScrollEnable': 'refused (Camera init, level spawn)', 'sidePush': 'built (Player.sidePush)',
    'secondArenaBound': 'built (Camera / BossArena)',
    'clutAnimMode': 'partial: the random draws of .AnimateCLUT consumed at level start; the recolour not built',
    'clutAnimCount': 'partial (as mode)', 'clutAnimPeriod': 'not built (no reader)', 'clutAnimAmplitude': 'not built (no reader)',
    'music': 'built (header-driven)',
}


def switch_owner(rule, off, lv, v):
    w = wave(lv)
    if rule == 'L' or rule is None and off != 0x26c7:
        return LTASK[w]
    if off == 0x26c7:
        return {1: '6A-RN', 2: LTASK[w], 5: LTASK[w], 6: '6C-L55…L70 (its ⚑ part: the mode-6 interlace)'}.get(v, LTASK[w])
    if rule == 'ICE':
        return '6B-ICE' if lv in (30, 31) else LTASK[w]
    if rule == 'BOSS':
        boss = {18: '6A-CH', 25: '6B-WZ', 55: '6C-DM', 67: '6C-XL'}
        return boss.get(lv, LTASK[w])
    if rule == 'CA':
        return '6C-XL' if lv == 67 else '6B-CA'
    return rule


def switch_rows():
    """One row per (field, later level) whose value is nonzero; `new` = not among levels 1–5's values."""
    rows = []
    for off, size, prop, meaning, orig, rule, audit in FIELDS:
        built_vals = set(field_value(lv, off, size) for lv in BUILT)
        for lv in LATER:
            v = field_value(lv, off, size)
            if v:
                rows.append(dict(off=off, prop=prop, lv=lv, v=v, new=v not in built_vals, meaning=meaning, orig=orig,
                                 owner=switch_owner(rule, off, lv, v), audit=audit))
    return rows


# ---------------------------------------------------------------- the picture cache: registration order

def init_order():
    s, e = SPAN['.InitSprites']
    return ['.' + m.group(1).lstrip('_') for i in range(s, e + 1) for m in [re.match(r'\s*_(Init\w+)\(\);', DL[i - 1])] if m]


CALL = re.compile(r'_(Cache1EncFaceFromPICT|CacheEncFaceSetFromPICT)\(([^,]+),([^,]+)(?:,([^,]+),([^,]+),([^,]+),([^,]+))?')
NUM = lambda s: int(s, 16) if s.strip().startswith('0x') else int(s)   # noqa: E731


@functools.lru_cache(maxsize=None)
def _registrations():
    return tuple(_registrations_list())


def registrations():
    return list(_registrations())


def _registrations_list():
    """Every .Cache*FromPICT registration in .InitSprites' call order: dict(list, pict, faces, w, h, cols, flag, fn,
    line, ref). Loops (`for (v = 0; … v < N; …)` around `v + BASE`) are unrolled; the cache flag is the value of
    `*_DAT_100a0a48` (or an alias of it) at the call."""
    regs = []
    for fn in init_order():
        if fn not in SPAN:
            continue
        s, e = SPAN[fn]
        alias, flag, loops, depth = {'_DAT_100a0a48'}, 0, [], 0
        last_assign = {}
        for i in range(s, e + 1):
            l = DL[i - 1]
            m = re.match(r'\s*(\w+) = _DAT_100a0a48;', l)
            if m:
                alias.add(m.group(1))
            m = re.match(r'\s*\*(\w+) = (\d);', l)
            if m and m.group(1) in alias:
                flag = int(m.group(2))
            m = re.match(r'\s*(\w+) = ((?:_DAT|PTR_DAT)_\w+|0x[0-9a-f]+);', l)
            if m:
                last_assign[m.group(1)] = m.group(2)
            m = re.search(r'for \((\w+) = 0;.*\(short\)\1 < (0x[0-9a-f]+|\d+);', l)
            if m:
                loops.append((m.group(1), NUM(m.group(2)), depth))
            depth += l.count('{') - l.count('}')
            while loops and depth <= loops[-1][2]:
                loops.pop()
            m = CALL.search(l)
            if not m:
                continue
            kind, ref, pict = m.group(1), m.group(2).strip(), m.group(3).strip()
            ref = last_assign.get(ref, ref)
            lm = re.match(r'(\w+) \+ (0x[0-9a-f]+|\d+)', pict)
            items = []
            if lm and loops and lm.group(1) == loops[-1][0]:
                items = [NUM(lm.group(2)) + k for k in range(loops[-1][1])]
            else:
                items = [NUM(pict)]
            for k, p in enumerate(items):
                if kind == 'CacheEncFaceSetFromPICT':
                    n, w_, h_, c = (NUM(m.group(j)) for j in (4, 5, 6, 7))
                    regs.append(dict(list='set', pict=p, faces=n, w=w_, h=h_, cols=c, flag=flag, fn=fn, line=i, ref=ref,
                                     loop=len(items) > 1))
                else:
                    regs.append(dict(list='single', pict=p, faces=1, w=0, h=0, cols=1, flag=flag, fn=fn, line=i, ref=ref,
                                     loop=len(items) > 1))
    return regs


PICT_FILES = {}
for fname in ("Ferazel's Wand Sprites.rsrc", "Ferazel's Wand Backgrounds.rsrc", "Ferazel's Wand Titles.rsrc",
              "Ferazel's Wand.rsrc", "Ferazel's Wand World Data.rsrc"):
    for rid, _, _ in parse(os.path.join(ROOT, 'Resources/Ferazel', fname))[1].get('PICT', []):
        PICT_FILES.setdefault(rid, fname)


@functools.lru_cache(maxsize=None)
def _mark_index():
    """global -> [line]: every `+1 = 1` store (outside .Init* and the cache routines) through a global directly or
    through a local the same function loaded from it (`v = GLOBAL;`), block-scoped: a load made inside a `{ … }`
    is forgotten when that block closes (so a branch's reload does not hide the function-top load in the next
    branch). The Setups load their cache globals into locals at the top and reload them inside type arms."""
    idx = collections.defaultdict(list)
    store = re.compile(r'\*\((?:undefined1|char|byte) \*\)\((\w+) \+ 1\) = 1;|\b(\w+)\[1\] = 1;')
    load = re.compile(r'^\s*\}?\s*(\w+) = ((?:_DAT|PTR_DAT)_\w+);')
    assign = re.compile(r'^\s*(\w+) = ')
    for k, (ln, fn) in enumerate(HEADS):
        if fn.startswith('.Init') or 'Cache' in fn:
            continue
        end = HEADS[k + 1][0] - 1 if k + 1 < len(HEADS) else len(DL)
        alias, undo, depth = {}, [], 0
        for i in range(ln, end + 1):
            l = DL[i - 1]
            lead = len(l) - len(l.lstrip(' }')) and l.lstrip().startswith('}')
            closes = len(re.match(r'\s*(\}\s*)*', l).group(0).replace(' ', '')) if lead else 0
            depth -= closes
            while undo and undo[-1][2] > depth:
                v, old, _ = undo.pop()
                if old is None:
                    alias.pop(v, None)
                else:
                    alias[v] = old
            m = load.match(l)
            m2 = assign.match(l)
            if m or m2:
                v = (m or m2).group(1)
                undo.append((v, alias.get(v), depth))
                if m:
                    alias[v] = m.group(2)
                else:
                    alias.pop(v, None)
            for a, b in store.findall(l):
                v = a or b
                g = v if v.startswith(('_DAT_', 'PTR_DAT_')) else alias.get(v)
                if g:
                    idx[g].append(i)
            body = l.split('//')[0]
            depth += body.count('{') - (body.count('}') - closes)
    return idx


def mark_sites(ref, loop):
    """Mark sites of a cache record (its global's `+1 = 1` stores, `_mark_index`). Loop rows (one global indexed by
    type) are marked inside the class Setup and are not listed here."""
    if not ref.startswith(('_DAT_', 'PTR_DAT_')):
        return []
    return _mark_index().get(ref, [])


# ---------------------------------------------------------------- conversations

TALK_NPC = range(2951, 2970)
TALK_SIGN = [t for t in range(2902, 2910) if t != 2907] + list(range(2833, 2837))


def level_convs(lv):
    out = []
    for r in REC[lv]:
        t, p1 = r['type'], r['p'][0]
        if r['flag'] == 0:
            continue
        if t in TALK_NPC or (t in TALK_SIGN and p1 > 100):
            out.append((p1, r['i'], t, r['flag']))
        if t in range(0x7c6, 2000) and r['flag'] == 1:
            out += [(c, r['i'], t, 'code') for c in (250, 251, 252)]
    return out


def conv_ops(cid):
    body = MCNV[cid][1]
    conds, acts, pics = set(), set(), set()
    for i in range(20):
        o = 0x100 + i * 0x72a
        pic, ctype = struct.unpack('>hh', body[o + 0x70a:o + 0x70e])
        a1 = struct.unpack('>h', body[o + 0x71c:o + 0x71e])[0]
        a2 = struct.unpack('>h', body[o + 0x722:o + 0x724])[0]
        if ctype:
            conds.add(ctype)
        acts |= {a for a in (a1, a2) if a}
        if pic:
            pics.add(pic)
    return conds, acts, pics


def port_conv_cases():
    p = os.path.join(SRC, 'FerazelCore/Talk/ConvActions.swift')
    L = src_lines(p)
    a = next(i for i, l in enumerate(L) if 'static func condition' in l)
    b = next(i for i, l in enumerate(L) if re.search(r'static func run\(', l))
    c = next((i for i in range(b + 1, len(L)) if re.search(r'static func \w+\(', L[i])), len(L))
    cases = lambda x, y: set(int(n) for l in L[x:y] for n in re.findall(r'^\s*case (\d+):', l))   # noqa: E731
    return cases(a, b), cases(b, c)


PORT_COND, PORT_ACT = port_conv_cases()
ORIG_FALSE_COND = {3}          # conversations-mcnv §3.4: type 3 is accepted and always false; < 0 or > 5 never
ORIG_NOP_ACT = {0, 7, 8}       # §3.4: 0, 7, 8 do nothing


# ---------------------------------------------------------------- resources

def resources_future():
    rows = []
    with open(RESOURCES) as f:
        for r in csv.DictReader(f, delimiter='\t'):
            if r['class'].startswith('a'):
                rows.append(r)
    return rows


def res_levels(r, conv_levels):
    t, rid = r['type'], r['id']
    txt = r['reached-in-scope'] + ' ' + r['class']
    if t == 'Mlvl':
        return [int(rid)]
    if t == 'Mcnv':
        return sorted(conv_levels.get(int(rid), []))
    m = re.findall(r'\[([0-9, ]+)\]', txt)
    if m:
        return sorted(set(int(x) for g in m for x in g.split(',')))
    if 'flame' in txt:
        return [52, 55]
    if 'end of game' in txt or 'victory' in txt:
        return [67]
    if 'OmniPx' in txt:
        pid = int(rid)
        return [lv for lv in LEVELS if {6000: 1, 6001: 1, 6200: 2, 6201: 2, 6300: 5, 6301: 5}.get(pid) == MLVL[lv][0x26c7]]
    if 'cached' in r['reached-in-scope'] and rid.isdigit():
        markers = MARKED_BY(int(rid))
        return [lv for lv in LATER if any(t2 in markers for t2 in COUNT[lv])]
    return []


def marks_record(r, t):
    """Whether type t's Setup marks registration record r. The enemy-shot sets (0x46a ×3, 0x77b) are told apart by
    record: the classes whose Setups store into that record's global (the heuristic mark sites)."""
    if r['pict'] in (0x46a, 0x77b):
        cls = set()
        for ln in mark_sites(r['ref'], r['loop']):
            m = re.match(r'\.(?:Setup|Handle|Kill|Hit)(\w+?)Sprite$', func_at(ln) or '')
            if m:
                cls.add(m.group(1))
        return cls_of(t) in cls
    return t in MARKED_BY(r['pict'])


def MARKED_BY(p):
    """The placed types whose Setup marks cache PICT p (the class Setups' marks as the port's CachedFaces.marks and the
    dump's Setups read them; a type's own single by default)."""
    fam = [((0x6d7, 0x6da), (0x6d6, 0x6df)), ((0x6eb, 0x6ec), (0x6ea, 0x6f3)), ((0x6ea, 0x6ea), (0x6ea, 0x6f3)),
           ((0x74e, 0x751), (0x74e, 0x757)), ((0x762, 0x762), (0x762, 0x76b)), ((0x767, 0x767), (0x762, 0x76b)),
           ((0x73a, 0x73b), (0x73a, 0x73e)), ((0x744, 0x744), (0x744, 0x74c)), ((0x6f4, 0x6f4), (0x6f4, 0x6fd)),
           ((0x712, 0x712), (0x712, 0x71b)), ((0x71c, 0x71e), (0x71c, 0x725)), ((0x726, 0x728), (0x726, 0x72f)),
           ((0x776, 0x77a), (0x776, 0x77f)), ((0x780, 0x784), (0x780, 0x789)), ((0x7b2, 0x7c3), (0x7c6, 1999)),
           ((0x5a0, 0x5a2), (0x5a0, 0x5a8)), ((0x76c, 0x76c), (0x76c, 0x76d)), ((0xbfe, 0xc00), (0xbfe, 0xbfe)),
           ((0x41a, 0x41d), (0xbea, 0xbea)), ((0x442, 0x442), (0x442, 1098)), ((0x480, 0x480), (0x480, 0x481)),
           ((0x730, 0x730), (0x730, 0x731)), ((0x732, 0x733), (0x732, 0x733)), ((0xb72, 0xb73), (0xb72, 0xb73)),
           ((0x6b8, 0x6b9), (0x6b8, 0x6b8)), ((0x6ae, 0x6b1), (0x6b0, 0x6b0)), ((0x6a5, 0x6a6), (0x6a4, 0x6a4)),
           ((0x6aa, 0x6ab), (0x6a9, 0x6a9)), ((0x6e0, 0x6e0), (0x6e0, 0x6e9)), ((0x6cc, 0x6cc), (0x6cc, 0x6d5)),
           ((0x6c2, 0x6c2), (0x6c2, 0x6cb)), ((0x708, 0x708), (0x708, 0x711)), ((0x6fe, 0x6ff), (0x6fe, 0x707)),
           ((0x5b5, 0x5b5), (0x5b5, 0x5b6)), ((0x4b8, 0x4b9), (0x4b8, 0x4b8))]   # fire 1208: sets 0x4b8 + 0x4b9, M l. 62018–62019
    for (lo, hi), (tlo, thi) in fam:
        if lo <= p <= hi:
            return set(range(tlo, thi + 1))
    if p in (0x46a, 0x77b):         # the boss Setups (heuristic mark sites in the cache table)
        return set(range(0x726, 0x730)) | set(range(0x776, 0x780)) | set(range(0x780, 0x78a)) | set(range(0x7c6, 2000))
    return {p}


def loader_of(r):
    u = r['original-user']
    if 'OpenDefaultWorldLevel' in u:
        return 'level open (.OpenDefaultWorldLevel)'
    if 'OpenDefaultWorldConv' in u:
        return 'conversation open (.OpenDefaultWorldConv)'
    if 'Init' in u and 'Sprite' in u:
        return 'level cache (.LoadCachedSpriteFaces; registered by ' + u.split('@')[0].strip() + ')'
    if 'SetupOmniPx' in u:
        return 'level setup (.SetupOmniPx)'
    if 'Victory' in u or 'CreditScreen' in u:
        return 'victory screens (.Victory / .CreditScreen)'
    if 'LoadCoolingMap' in u or 'InitAppGlobals' in u:
        return 'boot (' + u.split('@')[0].strip() + '); drawn by the flame / victory code'
    return u


ALL_SET = set(p for p, _, _ in PORT_CACHE['sets']) | set(p for p, _, _ in PORT_CACHE['singles'])


def boot_picts():
    L = src_lines(os.path.join(SRC, 'FerazelCore/Sprites/BootFaces.swift'))
    out = set()
    for l in L:
        for x in re.findall(r'(?:one|set)\(0x([0-9a-f]+)', l):
            out.add(int(x, 16))
        for a, n in re.findall(r'Int16\(0x([0-9a-f]+)\)\.\.<0x[0-9a-f]+ \+ (0x[0-9a-f]+|\d+)', l):
            out |= set(range(int(a, 16), int(a, 16) + NUM(n)))
    return out


BOOT = boot_picts()


def port_today(r):
    t, rid = r['type'], r['id']
    if t != 'PICT' or not rid.isdigit():
        return 'no (no level / screen opens it)'
    p = int(rid)
    if p in ALL_SET:
        return 'registered in CachedFaces'
    if p in SHEETS:
        return 'in the Setup-face table'
    if p in BOOT:
        return 'boot list'
    named = code_mentions(p)
    return f'named in code only: {named}' if named else 'no'


def code_mentions(p):
    """The first code (not comment) line of the port's sources that names PICT p as a hex literal."""
    pat = re.compile(r'(?<![0-9A-Za-z_])0x%x(?![0-9a-f])' % p)
    for dp, _, fs in sorted(os.walk(SRC)):
        for f in sorted(fs):
            if f.endswith('.swift'):
                path = os.path.join(dp, f)
                for i, l in enumerate(src_lines(path)):
                    if pat.search(l.split('//')[0]):
                        return f'{os.path.relpath(path, SRC).split("/", 1)[1]}:{i + 1}'
    return None


HEADER_RES = [  # (off, what, default, pair)
    (0x2716, 'horizon strip PICT', 0, False), (0x284c, 'PxBack tileset PICT', 5000, False),
    (0x284e, 'PxMid tileset PICT pair', 0, True), (0x2850, 'FG (+FG water) tileset PICT', 181, False),
    (0x2852, 'BG tileset PICT', 180, False), (0x2856, 'FG pattern tileset PICT', 206, False),
    (0x285c, 'level CLUT', 201, False), (0x285e, 'level+sprite CLUT', 202, False), (0x284a, 'music track', 0, False)]


def header_res(lv):
    out = []
    for off, what, dflt, pair in HEADER_RES:
        v = hv(lv, off)
        if off in (0x284c, 0x2856) and v < 1 or off in (0x2850, 0x2852, 0x285c, 0x285e) and v == 0:
            v = dflt
        if v == 0:
            continue
        ids = [v, v + 1] if pair else [v]
        out.append((what, ids))
    ch = hv(lv, 0x273c)
    if ch:
        out.append(('chapter card PICT / clut', [ch * 10 + 0x11f8, ch + 0x118]))
    return out


BUILT_HEADER_RES = set((w, tuple(ids)) for lv in BUILT for w, ids in header_res(lv))

# ---------------------------------------------------------------- output


def md_types():
    out = ['| type | hex | class | first level | also on | records (all later levels) | p1 values | port today | port site | '
           'note | dump: Setup / Handle span · arm lines | bank | owner |', '|' + '---|' * 13]
    owners = {}
    for t in sorted(FIRST):
        c = cls_of(t)
        st, site, note = port_arm(t, c)
        own = type_owner(t, c, st)
        owners[t] = own
        init, setup, handle = CLASS_FUNCS.get(c, ('', '', ''))
        arm_lines = hits_in(setup, [t]) + hits_in(handle, [t], 2)
        sp = f'{span_txt(setup)} / {span_txt(handle)}'
        if arm_lines:
            arm = '; type literal l. ' + ', '.join(map(str, arm_lines))
        else:
            b = [x for x in arm_base(t, c) if x != t]
            bl = hits_in(setup, b) + hits_in(handle, b, 2) if b else []
            arm = (f'; range from {h(b[0])} l. ' + ', '.join(map(str, bl))) if bl else '; no literal'
        recs = sum(COUNT[lv][t] for lv in LATER)
        fr = first_refused(t, c)
        if st != BUILT_S and fr is not None and fr != FIRST[t]:
            st = f'{st} (from L{fr}; built on {", ".join(str(x) for x in LEVELS_OF[t] if x < fr)})'
        also = ', '.join(str(lv) for lv in LEVELS_OF[t] if lv != FIRST[t]) or '—'
        p1 = ','.join(map(str, p_values(t)))[:40]
        out.append(f'| {t} | {h(t)} | {c} | {FIRST[t]} | {also} | {recs} | {p1} | {st} | `{site}` | {note} | {sp}{arm} | '
                   f'{bank_section(t, c)} | {own} |')
    return out, owners


def md_levels():
    out = ['| level | name | active records | types | types new vs 1–5 (census) | of which first placed here | header switches new vs 1–5 |',
           '|---|---|---:|---:|---:|---:|---|']
    names = {rid: name for rid, name, _ in RES['Mlvl']}
    sw = switch_rows()
    for lv in LEVELS:
        recs = sum(COUNT[lv].values())
        if lv in BUILT:
            out.append(f'| {lv} | {names[lv]} | {recs} | {len(COUNT[lv])} | — | — | (built) |')
            continue
        firsts = sum(1 for t in NEW[lv] if FIRST[t] == lv)
        s = ', '.join(f'{h(r["off"])}={r["v"]}' for r in sw if r['lv'] == lv and r['new']) or '—'
        out.append(f'| {lv} | {names[lv]} | {recs} | {len(COUNT[lv])} | {len(NEW[lv])} | {firsts} | {s} |')
    tot = sum(sum(COUNT[lv].values()) for lv in LEVELS)
    out.append(f'| **all** | {len(LEVELS)} levels | **{tot:,}** | | **{sum(len(NEW[lv]) for lv in LATER)}** | '
               f'**{len(FIRST)}** distinct | |')
    return out


def md_level_sections(owners):
    """One section per later level with the card's six items (compact; the master tables carry the detail)."""
    names = {rid: name for rid, name, _ in RES['Mlvl']}
    sw = switch_rows()
    cl = conv_levels_map()
    fut = resources_future()
    regs = registrations()
    out = []
    for lv in LATER:
        out.append(f'### Level {lv} — {names[lv]}')
        out.append('')
        out.append(f'{sum(COUNT[lv].values())} active records, {len(COUNT[lv])} types, {len(NEW[lv])} not placed on '
                   f'levels 1–5 ({sum(1 for t in NEW[lv] if FIRST[t] == lv)} first placed here).')
        out.append('')
        rows = [r for r in sw if r['lv'] == lv]
        new_ = [f'{h(r["off"])} `{r["prop"]}` = {r["v"]} → {r["owner"]}' for r in rows if r['new']]
        same = [f'{h(r["off"])}={r["v"]}' for r in rows if not r['new']]
        wn = wind_cells(lv)[0]
        out.append('1. **Switches new vs 1–5:** ' + ('; '.join(new_) if new_ else 'none') +
                   (f'. Nonzero but as on a built level: {", ".join(same)}' if same else '') +
                   (f'. Wind overlay cells: {wn} → 6A-WD' if wn and wave(lv) == '6A' else (f'. Wind overlay cells: {wn}' if wn else '')) + '.')
        items = []
        for t in NEW[lv]:
            c = cls_of(t)
            st, site, _ = port_arm(t, c, [lv])
            tag = '' if FIRST[t] == lv else f', first L{FIRST[t]}'
            nr = refused_records(lv, t)
            part = f' ({nr} of {COUNT[lv][t]})' if 0 < nr < COUNT[lv][t] else ''
            items.append(f'{t} {c} ×{COUNT[lv][t]}{tag} — {st}{part}' + ('' if st == BUILT_S else f' `{site}`'))
        out.append('2. **New types:** ' + '; '.join(items) + '.')
        old = [l.split('|') for l in md_old_types()[2:]]
        olds = [f'{x[1].strip()} ×{x[5].strip()}, {x[6].strip()} refused, p1 {x[7].strip()} — {x[8].strip()}'
                for x in old if int(x[4]) == lv]
        if olds:
            out.append(f'   Also refused here (types built on 1–5, records the port refuses): {"; ".join(olds)}.')
        res = [r for r in fut if lv in res_levels(r, cl)]
        rs = collections.defaultdict(list)
        for r in res:
            rs[(loader_of(r).split(' (')[0], port_today(r).split(':')[0])].append(f'{r["type"]} {r["id"]}')
        out.append('3. **Future-phase resources:** ' + ('; '.join(f'{k[0]} [port: {k[1]}]: {", ".join(v)}' for k, v in sorted(rs.items())) or 'none') + '.')
        hdr = [f'{w} {",".join(map(str, ids))}' for w, ids in header_res(lv) if (w, tuple(ids)) not in BUILT_HEADER_RES]
        out.append(f'   Header-named, new vs 1–5 (generic loaders, never exercised): {"; ".join(hdr) or "none"}.')
        cv = level_convs(lv)
        if cv:
            parts = []
            for cid, ri, t, fl in cv:
                conds, acts, _ = conv_ops(cid)
                parts.append(f'{cid} (rec {ri}, type {t}, flag {fl}; cond {sorted(conds) or "—"}, act {sorted(acts) or "—"})')
            out.append('4. **Conversations:** ' + '; '.join(parts) + ' — every opcode handled by the port\'s interpreter.')
        else:
            out.append('4. **Conversations:** none.')
        ch = hv(lv, 0x273c)
        if ch:
            out[-1] += f' Chapter card {ch} (PICT {ch * 10 + 0x11f8}, clut {ch + 0x118}, `.ChapterScreen`).'
        own = collections.Counter(owners[t] for t in NEW[lv] if FIRST[t] == lv)
        out.append('5. **Owners (types first placed here; switches above):** ' +
                   (', '.join(f'{o} ×{n}' for o, n in sorted(own.items())) or 'none') + f'; the level itself: {LTASK[wave(lv)]}.')
        need = collections.defaultdict(set)
        for t in NEW[lv]:
            for k, r in enumerate(regs):
                if marks_record(r, t):
                    idx = sum(1 for x in regs[:k + 1] if x['list'] == r['list'])
                    need[(r['list'], idx, r['pict'])].add(t)
        out.append('6. **Cache records its new types mark (list #, by the MARKED_BY rule):** ' +
                   (', '.join(f'{l} #{i} {p}' + ('' if ts == {p} else f' (by {",".join(map(str, sorted(ts)))})')
                              for (l, i, p), ts in sorted(need.items())) or 'none') + '.')
        out.append('')
    return out


def md_switches():
    out = ['| field | property | meaning | level | value | new vs 1–5 | original readers (dump: first line per function) | '
           'port readers | port today | audit refusal row | owner |', '|' + '---|' * 11]
    readers_cache = {}
    for r in switch_rows():
        if r['prop'] not in readers_cache:
            pr = port_readers(r['prop'])
            dr = dump_readers(r['off'])
            readers_cache[r['prop']] = (pr, dr)
        pr, dr = readers_cache[r['prop']]
        d = ', '.join(f'{fn} {ln}' for fn, ln in list(dr.items())[:4]) or r['orig']
        p = ', '.join(pr[:4]) + (f' (+{len(pr) - 4})' if len(pr) > 4 else '') if pr else 'none'
        a = audit_row(r['audit']) or '—'
        out.append(f'| {h(r["off"])} | `{r["prop"]}` | {r["meaning"]} | {r["lv"]} | {r["v"]} | {"**yes**" if r["new"] else "no"} | '
                   f'{d} | {p} | {SWITCH_STATE[r["prop"]]} | {a} | {r["owner"]} |')
    return out


def conv_levels_map():
    m = collections.defaultdict(set)
    for lv in LEVELS:
        for cid, _, _, _ in level_convs(lv):
            m[cid].add(lv)
    return m


def md_convs():
    out = ['| level | Mcnv | name | record / type / flag | conditions used | actions used | portraits | interpreter |',
           '|---|---|---|---|---|---|---|---|']
    for lv in LATER:
        for cid, ri, t, fl in level_convs(lv):
            if cid not in MCNV:
                out.append(f'| {lv} | {cid} | (no Mcnv) | rec {ri} / {t} / {fl} | | | | the open fails (no resource) |')
                continue
            conds, acts, pics = conv_ops(cid)
            bad = [f'cond {c}' for c in conds if c not in PORT_COND and c not in ORIG_FALSE_COND and 1 <= c <= 5]
            bad += [f'action {a}' for a in acts if a not in PORT_ACT and a not in ORIG_NOP_ACT and 0 <= a <= 10]
            verdict = 'every opcode handled' if not bad else 'NOT handled: ' + ', '.join(bad)
            if conds & ORIG_FALSE_COND or acts & ORIG_NOP_ACT:
                verdict += ' (cond 3 / action 0·7·8 fall to the port default, as the original)'
            out.append(f'| {lv} | {cid} | {MCNV[cid][0]} | rec {ri} / {t} / {fl} | {sorted(conds) or "—"} | '
                       f'{sorted(acts) or "—"} | {", ".join(map(str, sorted(pics)))} | {verdict} |')
    c_all, a_all, bad = conv_opcode_audit()
    c6, a6 = set(), set()
    for lv in LATER:
        if wave(lv) == '6A':
            for cid, _, _, _ in level_convs(lv):
                if cid in MCNV:
                    c6 |= conv_ops(cid)[0]
                    a6 |= conv_ops(cid)[1]
    out += ['', f'Checked, every `Mcnv` in the world file ({len(MCNV)}, placed or not): conditions used {sorted(c_all)}, '
                f'actions used {sorted(a_all)}; outside the port\'s handled sets (conditions {sorted(PORT_COND)}, actions '
                f'{sorted(PORT_ACT)}) and the original\'s no-ops (condition 3, actions 0 / 7 / 8): '
                f'{", ".join(bad) or "none"}. Levels 10–22 use conditions {sorted(c6)}, actions {sorted(a6)}.']
    return out


def conv_opcode_audit():
    """The opcodes of every Mcnv resource; `bad` = any the port neither handles nor the original treats as a no-op."""
    c_all, a_all, bad = set(), set(), []
    for cid in sorted(MCNV):
        conds, acts, _ = conv_ops(cid)
        c_all |= conds
        a_all |= acts
        bad += [f'Mcnv {cid} cond {c}' for c in sorted(conds) if c not in PORT_COND and c not in ORIG_FALSE_COND]
        bad += [f'Mcnv {cid} action {a}' for a in sorted(acts) if a not in PORT_ACT and a not in ORIG_NOP_ACT]
    return c_all, a_all, bad


def md_resources():
    """Totals of the future-phase rows (the rows themselves are in each level's item 3)."""
    cl = conv_levels_map()
    fut = resources_future()
    unplaced = [r for r in fut if not [lv for lv in res_levels(r, cl) if lv in LATER]]
    counts = collections.Counter(r['type'] for r in fut)
    per = collections.Counter()
    for r in fut:
        for lv in res_levels(r, cl):
            if lv in LATER:
                per[(r['type'], port_today(r).split(':')[0])] += 1
    out = [f'Future-phase rows read (resources-classified.tsv, class a / a5 / a6): {len(fut)} — '
           + ', '.join(f'{k} {v}' for k, v in sorted(counts.items())) + '.',
           'Level × resource pairs by port state: ' + ', '.join(f'{k[0]} {k[1]} {v}' for k, v in sorted(per.items())) + '.',
           'Rows that map to no later level: ' + ('; '.join(f'{r["type"]} {r["id"]} ({r["reached-in-scope"]})' for r in unplaced) or 'none') + '.']
    return out


def md_header_res():
    out = ['| level | header-named resource | ids | new vs 1–5 |', '|---|---|---|---|']
    for lv in LATER:
        for what, ids in header_res(lv):
            new = (what, tuple(ids)) not in BUILT_HEADER_RES
            out.append(f'| {lv} | {what} | {", ".join(map(str, ids))} | {"**yes**" if new else "no"} |')
    return out


def md_cache():
    regs = registrations()
    port_sets = [p for p, _, _ in PORT_CACHE['sets']]
    port_singles = [p for p, _, _ in PORT_CACHE['singles']]
    out = ['| # | list | PICT | faces (w×h, cols) | flag | in data | registered by (M l.) | record global | port CachedFaces | mark sites (M l.) |',
           '|---:|---|---|---|---:|---|---|---|---|---|']
    k = {'set': 0, 'single': 0}
    for r in regs:
        k[r['list']] += 1
        inport = ('yes' if r['pict'] in (port_sets if r['list'] == 'set' else port_singles) else '**no**')
        geo = f'{r["faces"]} ({r["w"]}×{r["h"]}, {r["cols"]})' if r['list'] == 'set' else '1'
        marks = mark_sites(r['ref'], r['loop'])
        ms = ', '.join(map(str, marks[:5])) + (f' (+{len(marks) - 5})' if len(marks) > 5 else '') if marks else (
            'unknown (not derived)' if not r['loop'] else 'indexed (see the class Setup)')
        out.append(f'| {k[r["list"]]} | {r["list"]} | {r["pict"]} ({h(r["pict"])}) | {geo} | {r["flag"]} | '
                   f'{"yes" if r["pict"] in PICT_FILES else "**absent**"} | {r["fn"]} {r["line"]} | `{r["ref"]}` | {inport} | {ms} |')
    nsets, nsing = k['set'], k['single']
    faces = sum(r['faces'] for r in regs)
    pr = len(port_sets) + len(port_singles)
    order_ok = check_port_order(regs)
    tail = ['', f'Registered: {nsets} sets + {nsing} singles = {nsets + nsing} records, {faces} faces in all. '
                f'The port registers {len(port_sets)} sets + {len(port_singles)} singles = {pr} today. '
                f'Port subset in the original order: {order_ok}.']
    return out + tail


def check_port_order(regs):
    res = []
    for key, lst in (('set', [p for p, _, _ in PORT_CACHE['sets']]), ('single', [p for p, _, _ in PORT_CACHE['singles']])):
        orig = [r['pict'] for r in regs if r['list'] == key]
        pos, last, bad = {}, -1, []
        for i, p in enumerate(orig):
            pos.setdefault(p, []).append(i)
        used = collections.Counter()
        for p in lst:
            cand = [i for i in pos.get(p, []) if i > last]
            if not cand:
                bad.append(h(p))
                continue
            last = cand[0]
        flags = {r['pict']: r['flag'] for r in regs if r['list'] == key}
        fbad = [h(p) for p, _, fl in PORT_CACHE['sets' if key == 'set' else 'singles'] if flags.get(p, fl) != fl]
        res.append(f'{key}s {"in order" if not bad else "OUT OF ORDER at " + ", ".join(bad)}'
                   f'{"" if not fbad else "; flag differs: " + ", ".join(fbad)}')
    return '; '.join(res)


def wind_cells(lv):
    """Overlay cells `.StandardSpriteHandles` turns into wind (M l. 32489–32507): the overlay map (hdr+0xb298, world-
    data-format §3.1: after PxBack, PxMid and three main-grid maps), `.GetFGOverlay1Tile` = low byte − 1 in 0…15 and
    `.GetFGOverlay2Tile` = high byte − 1 > 0."""
    b = MLVL[lv]
    w0, h0, w1, h1, w2, h2 = struct.unpack('>6h', b[0xb278:0xb284])
    o = 0xb29c + 2 * (w0 * h0 + w1 * h1) + 3 * 2 * w2 * h2
    n, kinds, strengths = 0, collections.Counter(), collections.Counter()
    for i in range(w2 * h2):
        v = struct.unpack('>H', b[o + 2 * i:o + 2 * i + 2])[0]
        lo, hi = (v & 0xff) - 1, ((v >> 8) & 0xff) - 1
        if 0 <= lo <= 15 and hi > 0:
            n += 1
            kinds[lo] += 1
            strengths[hi] += 1
    return n, kinds, strengths


def md_wind():
    out = ['| level | wind cells | direction index (low byte − 1) × cells | strength (high byte − 1) × cells | owner |',
           '|---|---:|---|---|---|']
    for lv in LEVELS:
        n, k, s = wind_cells(lv)
        if n or lv in BUILT:
            own = '—' if lv in BUILT else ('6A-WD' if wave(lv) == '6A' else wave(lv) + ' (new card)')
            out.append(f'| {lv} | {n} | {", ".join(f"{a}×{c}" for a, c in sorted(k.items())) or "—"} | '
                       f'{", ".join(f"{a}×{c}" for a, c in sorted(s.items())) or "—"} | {own} |')
    return out


def md_deps(owners):
    """Per later level: the tasks its records and new-value switches need besides its own level task."""
    out = ['| level | records refused today (per record, old types included) | tasks its types need (refused records) | '
           'tasks its switches need | classes of its census types |', '|---|---:|---|---|---|']
    sw = switch_rows()
    totals = []
    for lv in LATER:
        need, refused = collections.Counter(), 0
        for t in COUNT[lv]:
            n = refused_records(lv, t)
            if n:
                need[owners[t] if t in owners else old_type_owner(t, lv)] += n
                refused += n
        sws = sorted(set(r['owner'] for r in sw if r['lv'] == lv and r['new'] and r['owner'] != LTASK[wave(lv)]))
        if wind_cells(lv)[0]:
            sws.append('6A-WD' if wave(lv) == '6A' else 'wind (new card)')
        classes = sorted(set(cls_of(t) for t in COUNT[lv] if t not in BUILT_TYPES))
        out.append(f'| {lv} | {refused} | {", ".join(f"{o} ({n})" for o, n in sorted(need.items())) or "—"} | '
                   f'{", ".join(sws) or "—"} | {", ".join(classes)} |')
        totals.append(refused)
    six_a = sum(n for lv, n in zip(LATER, totals) if wave(lv) == '6A')
    out += ['', f'Refused records, levels 10–22: **{six_a}**; all later levels: **{sum(totals)}**.']
    return out


def built_levels_selftest():
    """The port model must set up every record of levels 1–5 (LevelThreeTests / LevelFourTests / LV5 say the port
    does): any refusal there is a rule-table error."""
    bad = []
    for lv in BUILT:
        for t in COUNT[lv]:
            c = gen(t & 0xffff, any(r['p'][0] < 0 for r in ACTIVE[lv] if r['type'] == t))[0] or '-'
            if port_arm(t, c, [lv])[0] != BUILT_S:
                bad.append(f'L{lv} {t}')
    return bad


def md_old_types():
    """Types placed on levels 1–5 (so outside the census) whose records on a later level the port refuses."""
    out = ['| type | hex | class | later level | records | refused (per record) | p1 values there | port today | site | '
           'note | owner |', '|---|---|---|---|---:|---:|---|---|---|---|---|']
    for t in sorted(BUILT_TYPES):
        for lv in LATER:
            if t not in COUNT[lv]:
                continue
            c = cls_of(t)
            st, site, note = port_arm(t, c, [lv])
            if st == BUILT_S:
                continue
            p1 = ','.join(map(str, sorted(set(r['p'][0] for r in ACTIVE[lv] if r['type'] == t))))
            out.append(f'| {t} | {h(t)} | {c} | {lv} | {COUNT[lv][t]} | {refused_records(lv, t)} | {p1} | {st} | '
                       f'`{site}` | {note} | {old_type_owner(t, lv)} |')
    return out


def old_type_owner(t, lv):
    """The owner of a level-1–5 type's refused records on later level lv (by that level's wave and the class)."""
    w, c = wave(lv), cls_of(t)
    if c == 'Background':
        return bg_split(t) if w == '6A' else ('6B-BG2' if w == '6B' else '6C-BG3')
    if c == 'Box':
        return {'6A': '6A-BX1b', '6B': '6B-BX2', '6C': '6C-BX3'}[w]
    return LTASK[w]


def md_owners(owners):
    by = collections.defaultdict(list)
    for t, o in owners.items():
        by[o].append(t)
    for r in switch_rows():
        if r['new']:
            by[r['owner']].append(f'{h(r["off"])}@L{r["lv"]}')
    out = ['| owner | count | types (decimal) and new-value switches (field@level) |', '|---|---:|---|']
    for o in sorted(by):
        items = by[o]
        out.append(f'| {o} | {len(items)} | {", ".join(str(x) for x in items)} |')
    return out


def sections():
    types, owners = md_types()
    S = collections.OrderedDict()
    S['levels'] = md_levels()
    S['switches'] = md_switches()
    S['types'] = types
    S['per-level'] = md_level_sections(owners)
    S['resources'] = md_resources()
    S['header-resources'] = md_header_res()
    S['convs'] = md_convs()
    S['cache'] = md_cache()
    S['old-types'] = md_old_types()
    S['wind'] = md_wind()
    S['deps'] = md_deps(owners)
    S['owners'] = md_owners(owners)
    return S, owners


def render(S):
    out = []
    for k, v in S.items():
        out.append(f'<!-- LL:{k} -->')
        out += v
        out.append(f'<!-- /LL:{k} -->')
        out.append('')
    return '\n'.join(out)


def plan_cards():
    """The card ids of the plan's Wave 5–7 tables (first cell; `6B-BG2 / BX2 / BN2` → three ids)."""
    if not os.path.exists(PLAN):
        return set()
    t = open(PLAN, encoding='utf-8').read()
    a, b = t.find('\n## Wave 5'), t.find('\n## Wave 8')
    ids = set()
    for l in t[a:b].split('\n'):
        m = re.match(r'\| (?:\*\*)?(6[ABC])-([^|]+?) ?\|', l)
        if not m:
            continue
        for k, part in enumerate(f'{m.group(1)}-{m.group(2)}'.split(' / ')):
            tok = part.split()[0].strip('*')
            if k == 0:
                ids.add(tok)
            elif re.fullmatch(r'[A-Z]{2,}[0-9]*', tok):      # `BX2` in `6B-BG2 / BX2 / BN2`, not `Platform`
                ids.add(f'{m.group(1)}-{tok}')
            else:
                break
    return ids


def doc_proposals():
    """The proposed card ids named in bold in §8 of the document (`**6A-BG1a** …`, `**6A-CF — …**`)."""
    if not os.path.exists(DOC):
        return set()
    t = open(DOC, encoding='utf-8').read()
    a = t.find('\n## 8.')
    b = t.find('\n## ', a + 1)
    return set(re.findall(r'\*\*(6[ABC]-[0-9A-Za-z…]+)', t[a:b])) if a >= 0 else set()


def blocks_in_doc():
    if not os.path.exists(DOC):
        return {}
    t = open(DOC, encoding='utf-8').read()
    return {m.group(1): m.group(2) for m in re.finditer(r'<!-- LL:([\w-]+) -->\n(.*?)\n<!-- /LL:\1 -->', t, re.S)}


def main():
    args = sys.argv[1:]
    S, owners = sections()
    if '--check' in args:
        ok = True
        # (1) the census, recomputed from placements-all.tsv (an independent count) against the type ledger's rows
        t_built = set(t for lv in BUILT for t in tsv.get(lv, {}))
        t_first, t_levels, t_recs = {}, collections.defaultdict(list), collections.Counter()
        for lv in sorted(tsv):
            if lv in BUILT:
                continue
            for t, n in tsv[lv].items():
                if t not in t_built:
                    t_first.setdefault(t, lv)
                    t_levels[t].append(lv)
                    t_recs[t] += n
        rows = {}
        for l in S['types'][2:]:
            x = [c.strip() for c in l.split('|')]
            rows.setdefault(int(x[1]), []).append((int(x[4]), x[5], int(x[6])))
        dup = sorted(t for t, v in rows.items() if len(v) != 1)
        missing, extra = sorted(set(t_first) - set(rows)), sorted(set(rows) - set(t_first))
        wrong = [t for t in sorted(set(rows) & set(t_first)) if rows[t][0] != (
            t_first[t], ', '.join(str(lv) for lv in t_levels[t] if lv != t_first[t]) or '—', t_recs[t])]
        if dup or missing or extra or wrong:
            ok = False
            print(f'type ledger vs placements-all.tsv: doubled {dup}, missing {missing}, extra {extra}, '
                  f'first level / also on / records differ {wrong}')
        census = set(t_first)
        # (2) every owner is a plan card (Waves 5–7) or a proposal named in §8 of the document
        cards = plan_cards()
        props = doc_proposals()
        used = set()
        for l in S['owners'][2:]:
            used.add(l.split('|')[1].strip())
        for key, col in (('types', -2), ('old-types', -2), ('switches', -2)):
            for l in S[key][2:]:
                used.add(l.split('|')[col].strip())
        for l in S['deps'][2:]:
            x = l.split('|')
            if len(x) > 4:
                used |= set(re.findall(r'(6[ABC]-[^,(]+?)(?: \(|,|$)', x[3].strip() + ',' + x[4].strip()))
        ids = set(u.split(' (')[0].strip() for u in used if u.strip() and u.strip() != '—')
        unknown = sorted(i for i in ids if i not in cards and i not in props)
        if not cards:
            ok = False
            print('owners: no card ids read from the plan (Waves 5–7 tables)')
        if unknown:
            ok = False
            print(f'owners not a plan card or a §8 proposal: {unknown}')
        if set(t for t in owners) != census:
            ok = False
            print('owners: the owner map does not cover the census (placements-all.tsv)')
        # (3) the total, recomputed from the raw Mlvl level records (own parse) against the table and §0
        raw = sum(1 for lv in LEVELS for rec in struct.iter_unpack('>BBh12x', MLVL[lv][4:4 + 511 * 16])
                  if rec[0] == 1 and rec[2] != 0)
        tsv_tot = sum(sum(v.values()) for v in tsv.values())
        doc_txt = open(DOC, encoding='utf-8').read() if os.path.exists(DOC) else ''
        if f'**{raw:,}**' not in '\n'.join(S['levels']) or raw != tsv_tot or f'| {raw:,} | {raw:,} | yes |' not in doc_txt:
            ok = False
            print(f'total: Mlvl records {raw:,}, placements-all.tsv {tsv_tot:,}; the level table or §0 disagrees')
        tot = raw
        c_all, a_all, bad_ops = conv_opcode_audit()
        if bad_ops:
            ok = False
            print('Mcnv opcodes outside the port\'s handled sets:', bad_ops)
        sw = switch_rows()
        need = set((h(off), lv) for off, size in SCAN for lv in LATER if field_value(lv, off, size))
        have = set((h(r['off']), r['lv']) for r in sw)
        if need - have:
            ok = False
            print('header switches missing from the ledger:', sorted(need - have))
        doc = blocks_in_doc()
        for k, v in S.items():
            if doc.get(k) != '\n'.join(v):
                ok = False
                print(f'document block "{k}" is stale or missing (regenerate: --write)')
        bad = built_levels_selftest()
        if bad:
            ok = False
            print('port model refuses records of a built level (rule-table error):', bad)
        for f in FAILS:
            ok = False
            print('FAIL:', f)
        print(f'later-levels-ledger --check: {"OK" if ok else "FAILED"} — {len(census)} census types once, '
              f'{len(need)} nonzero header fields on {len(LATER)} later levels, {tot:,} active records over {len(LEVELS)} levels, '
              f'{sum(len(NEW[lv]) for lv in LATER)} level×type census entries')
        sys.exit(0 if ok else 1)
    if '--write' in args:
        t = open(DOC, encoding='utf-8').read()
        for k, v in S.items():
            t, n = re.subn(r'<!-- LL:%s -->\n.*?<!-- /LL:%s -->' % (re.escape(k), re.escape(k)),
                           lambda m, k=k, v=v: f'<!-- LL:{k} -->\n' + '\n'.join(v) + f'\n<!-- /LL:{k} -->', t, flags=re.S)
            if n != 1:
                print(f'block {k}: {n} markers in the document', file=sys.stderr)
        open(DOC, 'w', encoding='utf-8').write(t)
        return
    if '--section' in args:
        k = args[args.index('--section') + 1]
        print('\n'.join(S[k]))
        return
    print(render(S))


if __name__ == '__main__':
    main()
