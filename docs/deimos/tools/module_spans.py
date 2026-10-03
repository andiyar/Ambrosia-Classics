#!/usr/bin/env python3
"""Attribute functions to source modules by link-order contiguity.

Input: the profile written by func_profile.py. A function whose nearest module-tagged neighbour
BEFORE and AFTER (address order) name the same source file (from assert strings such as
"G_Level.cc") is attributed to that module ("bracketed"). Tagged functions count as "tagged".
CodeWarrior emits each translation unit contiguously, so bracketed attribution is [MED]; the
gap functions between two different modules stay unattributed.
Usage: module_spans.py profile.txt [--list]
"""
import re, sys, collections
rows = []
for l in open(sys.argv[1], encoding="utf-8"):
    a, n = l.split()[:2]
    mod = re.search(r"mod=([^|]*)", l).group(1).strip()
    rows.append((int(a, 16), n, mod.split(",")[0] if mod else ""))
tagged = [i for i, r in enumerate(rows) if r[2]]
attr = {}
for i, r in enumerate(rows):
    if r[2]:
        attr[i] = (r[2], "tagged")
        continue
    prev = max((t for t in tagged if t < i), default=None)
    nxt = min((t for t in tagged if t > i), default=None)
    if prev is not None and nxt is not None and rows[prev][2] == rows[nxt][2]:
        attr[i] = (rows[prev][2], "bracketed")
c = collections.Counter(v[1] for v in attr.values())
unnamed = sum(1 for r in rows if r[1].startswith("FUN_"))
print(f"functions in dump: {len(rows)}; FUN_-named: {unnamed}")
print(f"module-tagged: {c['tagged']}; bracketed: {c['bracketed']}; total attributed: {len(attr)}")
per = collections.Counter(v[0] for v in attr.values())
spans = collections.defaultdict(list)
for i, v in attr.items():
    spans[v[0]].append(rows[i][0])
for m, addrs in sorted(spans.items(), key=lambda x: min(x[1])):
    print(f"  {m:24s} {min(addrs):x}-{max(addrs):x}  {per[m]} functions")
if "--list" in sys.argv:
    for i, v in sorted(attr.items()):
        print(f"{rows[i][0]:x} {rows[i][1]} {v[0]} {v[1]}")
