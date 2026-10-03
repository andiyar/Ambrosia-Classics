#!/usr/bin/env python3
"""Key -> struct-offset tables for the text-tag parsers (U_Token readers).

Every data parser in the dump is a straight run of reader calls:
  FUN_1002cb20(buf,&cur,s__key_STR_..,dst+OFF,maxlen)   string (copied, NUL-terminated)
  FUN_1002c7d0(buf,&cur,s__key_ID_..,dst+OFF)           4-char ID (must be exactly 4 chars)
  FUN_1002c880(buf,&cur,s__key_INT_..,dst+OFF)          sscanf "%i"
  FUN_1002c960(buf,&cur,s__key_FLOAT_..,dst+OFF)        sscanf (float)
  FUN_1002ca40(buf,&cur,s__key_BOOL_..,dst+OFF)         == "TRUE" -> 1 byte
  FUN_1002cbd0(buf,&cur,s__key_COLOR_..,dst+OFF)        HTML RRGGBB -> 16-bit pixel (2 bytes)
  FUN_1002cc90(buf,&cur,s__key_RECT_..,dst+OFF)         "a, b, c, d" -> 4 ints
This script prints, per parser function, the keys in call order with the destination expression.
Usage: key_offsets.py <dump.c> FUN_100122f0 FUN_1003fda0 FUN_10040920 ...
"""
import re, sys
READ = {"FUN_1002cb20": "STR", "FUN_1002c7d0": "ID", "FUN_1002c880": "INT", "FUN_1002c960": "FLOAT",
        "FUN_1002ca40": "BOOL", "FUN_1002cbd0": "COLOR", "FUN_1002cc90": "RECT"}
HDR = re.compile(r'^// ==== (.+?) @ ([0-9A-Fa-f]+) ====$', re.M)
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
hits = list(HDR.finditer(text))
want = set(sys.argv[2:])
# Ghidra labels a key string `s__key…` when it starts with '#' and `s_key…` otherwise (e.g.
# `s_stateNumSpawnSets_INT`, `s_stateRuleAction_STR` in FUN_10040920) — match both (review 2026-10-03 #12).
CALL = re.compile(r'(FUN_1002c[0-9a-f]{3})\(\s*[^,]+,\s*[^,]+,\s*(s__?\w+?)_[0-9a-f]{8}\s*,\s*([^,)]+)', re.S)
for i, m in enumerate(hits):
    if m.group(1) not in want:
        continue
    body = text[m.end(): hits[i + 1].start() if i + 1 < len(hits) else len(text)]
    print(f"## {m.group(1)} @ {m.group(2)}")
    for f, key, dst in CALL.findall(body):
        if f not in READ:
            continue
        dst = " ".join(dst.split())
        mo = re.search(r'\+ (0x[0-9a-f]+|\d+)\)?$', dst)
        off = int(mo.group(1), 0) if mo else (0 if re.fullmatch(r'\(?\w+\)?', dst) else None)
        offs = f"0x{off:03x}" if off is not None else dst
        name = key[3:] if key.startswith("s__") else key[2:]
        print(f"  {READ[f]:5s} {offs:>8s}  #{name}")
