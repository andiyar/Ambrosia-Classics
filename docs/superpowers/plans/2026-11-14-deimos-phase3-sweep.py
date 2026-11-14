import os, re, sys, glob, subprocess, collections
D = os.path.expanduser('~/Developer/Ghidra/deimos/proj/data/Game')
SRC = sys.argv[1]  # Deimos/Core/Sources/DeimosCore
tagre = re.compile(r'\[(....)\]\.(\w+)\.txt$')
units = {}
for f in glob.glob(D + '/unde/*.unde.txt'):
    m = tagre.search(f); units[m.group(1)] = f
def parse(f):
    states = []; top = []; cur = top
    for line in open(f, encoding='latin-1'):
        line = line.strip()
        mm = re.match(r'#(\S+?) <(.*)>$', line)
        if not mm: continue
        k, v = mm.groups()
        if k == 'stateName_STR':
            cur = [(k, v)]; states.append(cur); continue
        cur.append((k, v))
    return top, states
U = {t: parse(f) for t, f in units.items()}
def refs(t):
    top, states = U[t]
    out = set()
    for k, v in top + [kv for s in states for kv in s]:
        if k.endswith('_ID') and v in units and v != t: out.add(v)
    return out
# level units
order = ["Lucena", "Yippe", "Vista", "Swoop", "Conrad", "Delos", "Sparta", "Saratoga", "Hannibal", "Leonidas", "Thebes", "Yamato"]
levs = {}
for f in glob.glob(D + '/leve/*.leve.txt'):
    m = tagre.search(f); txt = open(f, encoding='latin-1').read()
    ident = re.search(r'#indentifier_STR <(.*?)>', txt).group(1)
    us = re.findall(r'#unit_ID <(....)>', txt)
    levs[order.index(ident) + 1] = (m.group(1), us)
# perm objects (idli Game objects?) — include global perm units for every level
perm = set()
for f in glob.glob(D + '/idli/*.txt'):
    for v in re.findall(r'<(....)>', open(f, encoding='latin-1').read()):
        if v in units: perm.add(v)
# weapons
weps = {}
for f in glob.glob(D + '/wede/*.wede.txt'):
    m = tagre.search(f); txt = open(f, encoding='latin-1').read()
    def g(k):
        r = re.search('#' + k + r' <(.*?)>', txt); return r.group(1) if r else None
    rs = set(v for v in re.findall(r'_ID <(....)>', txt) if v in units)
    weps[m.group(1)] = (g('type_ID') or g('weaponType_ID'), g('minimumLevelAvailable_INT'), g('maximumLevelAvailable_INT'), g('name_STR'), rs)
plde = set()
for f in glob.glob(D + '/plde/*.txt'):
    plde |= set(v for v in re.findall(r'_ID <(....)>', open(f, encoding='latin-1').read()) if v in units)
def closure(seed):
    seen = set(); st = list(seed)
    while st:
        t = st.pop()
        if t in seen or t not in units: continue
        seen.add(t); st.extend(refs(t))
    return seen
common = closure(perm | plde)
print('perm units', len(perm), 'plde refs', len(plde), 'common closure', len(common))
print('weapons:')
for w, (ty, mn, mx, nm, rs) in sorted(weps.items(), key=lambda x: (str(x[1][0]), int(x[1][1] or 0))):
    print(' ', w, ty, mn, mx, nm, sorted(rs))
per = {}
for s in range(1, 13):
    tag, us = levs[s]
    wset = set()
    for w, (ty, mn, mx, nm, rs) in weps.items():
        if mn and mx and int(mn) <= s <= int(mx): wset |= rs
    per[s] = closure(set(us) | wset) - common
    print('sector', s, tag, 'placed', len(us), 'distinct', len(set(us)), 'closure(excl common)', len(per[s]))
filmed = set().union(*[per[s] for s in (1, 2, 3, 4)]) | common
late = {s: per[s] - filmed for s in range(5, 13)}
allLate = set().union(*late.values())
print('units reachable only in sectors 5-12:', len(allLate))
for t in sorted(allLate):
    secs = [s for s in range(5, 13) if t in per[s]]
    print('  ', t, U[t][0][0][1][:40], secs)
# feature flags: BOOL TRUE / nonzero ints / non-empty strings by key, filmed vs late
def feats(t):
    top, states = U[t]; out = set()
    for k, v in top + [kv for s in states for kv in s]:
        if k.endswith('_BOOL') and v == 'TRUE': out.add(k)
        elif k.endswith('_STR') and k in ('stateRuleCondition_STR', 'stateRuleAction_STR') and v: out.add(k + '=' + v)
        elif k == 'pickup_Type_ID' and v != 'none': out.add(k + '=' + v)
        elif k == 'drawLayer_ID' or k == 'layer_ID': out.add(k + '=' + v)
    return out
def featset(ts):
    s = set()
    for t in ts: s |= feats(t)
    return s
fF = featset(filmed)
for s in range(5, 13):
    pass
lateF = collections.defaultdict(set)
for s in range(5, 13):
    for f in featset(per[s]) - fF: lateF[f].add(s)
print('features used only by sectors 5-12 units:')
for f, ss in sorted(lateF.items()):
    print('  ', f, sorted(ss))
# rule conditions in shipped data overall
conds = collections.Counter(); acts = collections.Counter()
for t in units:
    top, states = U[t]
    for st in states:
        d = st
        for k, v in st:
            pass
print('done')
# non-unit IDs (particles, sounds, sprites, layers, media) filmed vs late
def ids(ts, pred):
    out = collections.defaultdict(set)
    for t in ts:
        top, states = U[t]
        for k, v in top + [kv for s in states for kv in s]:
            if k.endswith('_ID') and v not in units and v != 'none' and pred(k): out[k.split('_')[0] if False else k].add(v)
    return out
fI = ids(filmed, lambda k: True)
lI = collections.defaultdict(set)
for s in range(5, 13):
    for k, vs in ids(per[s], lambda k: True).items():
        for v in vs - fI.get(k, set()):
            lI[(k, v)].add(s)
print('non-unit IDs only in 5-12 (key, value, sectors):')
for (k, v), ss in sorted(lI.items()):
    print('  ', k, v, sorted(ss))
