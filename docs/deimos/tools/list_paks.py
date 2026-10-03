#!/usr/bin/env python3
"""List / decode the Deimos Rising 1.0.6 `.pak` containers (ZIP, STORED only).

Parses each pak by hand (End-Of-Central-Directory -> Central Directory -> Local headers), exactly
as the game's unzip.c does (FUN_10049de0 / FUN_1004a1d0 / FUN_1004a4f0), and classifies every
entry by the game's own suffix table (FUN_10003b20) into a 4-char resource type.

Usage:
  list_paks.py <Paks-dir>                      summary: counts per type + first 20 names per pak
  list_paks.py <Paks-dir> --all                every entry, one line each
  list_paks.py <Paks-dir> --decode <outdir>    also write each entry; text types are de-obfuscated
                                               (byte = ~rotate4(byte), FUN_10046470) to <name>.txt
  list_paks.py <Paks-dir> --audio              AIFF/AIFC COMM summary of every sound entry
  list_paks.py <Paks-dir> --images             GIF/TGA header summary of every image entry
"""
import os, re, struct, sys, collections

# Suffix -> type, from the tables the game walks in FUN_10003b20 (data 0x100e2bc4..0x100e2d90).
SUFFIX = {
 "im08": ".im08 .Im08 .IM08 .gif .GIF .giff .GIFf .GIFF",
 "im16": ".im16 .Im16 .IM16 .tga .TGA .Targa .targa .TARGA",
 "soun": ".snd .Snd .SND .sound .Sound .SOUND .aif .Aif .AIF .aiff .Aiff .AIFF .ima .IMA",
 "stli": ".txt .Txt .TXT .text .Text .TEXT .string .String .STRING .stli .Stli .STLI",
 "flli": ".flt .Flt .FLT .float .Float .FLOAT .flli .Flli .FLLI",
 "wede": ".we .WE .wep .Wep .WEP .wede .Wede .WEDE",
 "reli": ".rect .Rect .RECT .reli .Reli .RELI .rectlist .RectList .RECTLIST",
 "idli": ".id .ID .Id .idli .IDLI .Idli .idlist .IDLIST .IDList",
 "coli": ".co .CO .Co .coli .COLI .Coli .color .COLOR .Color .colorlist .COLORLIST .ColorList",
 "tefo": ".tefo .Tefo .TEFO .textformat .TEXTFORMAT .Textformat .TextFormat",
 "plde": ".plde .Plde .PLDE .player .PLAYER .Player",
 "pref": ".pref .Pref .PREF",
 "film": ".film .Film .FILM",
 "unde": ".unde .Unde .UNDE .unitdef .UnitDef .UNITDEF .unit",
 "leve": ".lvl .Lvl .LVL .leve .Leve .LEVE .level .Level .LEVEL",
}
ORDER = list(SUFFIX)          # the game tests the tables in this order, first match wins
TEXT_TYPES = {"stli", "flli", "wede", "reli", "idli", "coli", "tefo", "plde", "unde", "leve"}

def classify(fname):
    base = fname.rsplit("/", 1)[-1]
    if "." not in base:
        return None
    suf = base[base.index("."):][:15]          # game copies from the FIRST '.', max 15 chars
    for t in ORDER:
        if suf in SUFFIX[t].split():
            return t
    return None

def tag_id(fname):
    m = re.search(r"\[(.{4})\]", fname.rsplit("/", 1)[-1])
    return m.group(1) if m else None

def deob(b):
    return bytes((~(((x << 4) | (x >> 4)) & 0xFF)) & 0xFF for x in b)

def read_zip(path):
    d = open(path, "rb").read()
    eocd = d.rfind(b"PK\x05\x06")
    if eocd < 0:
        raise SystemExit(f"{path}: no End-Of-Central-Directory")
    (_sig, disk, cddisk, n_this, n_total, cd_size, cd_off, clen) = struct.unpack_from("<IHHHHIIH", d, eocd)
    ents, p = [], cd_off
    for _ in range(n_total):
        (sig, vmade, vneed, flags, method, mtime, mdate, crc, csize, usize, nlen, xlen, clen2,
         dstart, iattr, eattr, lho) = struct.unpack_from("<IHHHHHHIIIHHHHHII", d, p)
        assert sig == 0x02014B50, hex(p)
        name = d[p + 46:p + 46 + nlen].decode("mac_roman")
        extra = d[p + 46 + nlen:p + 46 + nlen + xlen]
        # local header: 30 bytes + name + extra, data follows
        lnlen, lxlen = struct.unpack_from("<HH", d, lho + 26)
        data_off = lho + 30 + lnlen + lxlen
        ftype = fcrea = None
        if len(extra) >= 4 and struct.unpack_from("<H", extra, 0)[0] == 0x2705 and extra[4:8] == b"ZPIT":
            # ZipIt Macintosh extra field: id 0x2705, len, 'ZPIT', then (file entries) type+creator
            if len(extra) >= 16:
                ftype, fcrea = extra[8:12].decode("mac_roman"), extra[12:16].decode("mac_roman")
        ents.append(dict(name=name, method=method, csize=csize, usize=usize, crc=crc, lho=lho,
                         data_off=data_off, extra=extra, ftype=ftype, fcrea=fcrea, data=d))
        p += 46 + nlen + xlen + clen2
    return dict(n_total=n_total, cd_off=cd_off, cd_size=cd_size, eocd=eocd, size=len(d)), ents

def comm(b):
    if b[:4] != b"FORM" or b[8:12] not in (b"AIFF", b"AIFC"):
        return "not AIFF"
    p, out = 12, {}
    while p + 8 <= len(b):
        ck, n = b[p:p + 4], struct.unpack(">I", b[p + 4:p + 8])[0]
        if ck == b"COMM":
            ch, frames, bits = struct.unpack(">hIh", b[p + 8:p + 16])
            e = b[p + 16:p + 26]
            exp = (struct.unpack(">H", e[:2])[0] & 0x7FFF) - 16383
            mant = struct.unpack(">Q", e[2:10])[0]
            rate = mant * 2.0 ** (exp - 63)
            comp = b[p + 26:p + 30].decode() if b[8:12] == b"AIFC" else "NONE"
            out = dict(form=b[8:12].decode(), ch=ch, frames=frames, bits=bits, rate=rate, comp=comp)
        if ck == b"SSND":
            out["ssnd"] = n
        p += 8 + n + (n & 1)
    return out

def main():
    a = sys.argv[1:]
    paks = a[0]
    outdir = a[a.index("--decode") + 1] if "--decode" in a else None
    for pk in sorted(f for f in os.listdir(paks) if f.endswith(".pak")):
        info, ents = read_zip(os.path.join(paks, pk))
        files = [e for e in ents if not e["name"].endswith("/")]
        meth = collections.Counter(e["method"] for e in ents)
        types = collections.Counter(classify(e["name"]) for e in files)
        print(f"== {pk}: {info['size']} B, {info['n_total']} central-dir entries "
              f"({len(ents) - len(files)} folder entries, {len(files)} files), CD at {info['cd_off']} "
              f"size {info['cd_size']}, EOCD at {info['eocd']}; methods {dict(meth)}")
        print("   per type: " + ", ".join(f"{t}={n}" for t, n in sorted(types.items(), key=lambda x: str(x[0]))))
        mism = [e["name"] for e in files if e["csize"] != e["usize"]]
        print(f"   entries with compressed!=uncompressed size: {len(mism)}")
        lst = files if "--all" in a else files[:20]
        for e in lst:
            print(f"   {classify(e['name']) or '????'} {tag_id(e['name']) or '----'} {e['usize']:>9} "
                  f"@{e['data_off']:<9} {e['ftype'] or ''}/{e['fcrea'] or ''}  {e['name']}")
        if "--audio" in a:
            for e in files:
                if classify(e["name"]) == "soun":
                    b = e["data"][e["data_off"]:e["data_off"] + e["usize"]]
                    print(f"   AUDIO {e['name']}: {comm(b)}")
        if "--images" in a:
            for e in files:
                t = classify(e["name"])
                b = e["data"][e["data_off"]:e["data_off"] + min(e["usize"], 32)]
                if t == "im08":
                    w, h, fl = struct.unpack("<HHB", b[6:11])
                    print(f"   GIF {e['name']}: {b[:6].decode()} {w}x{h} gct={2 ** ((fl & 7) + 1) if fl & 0x80 else 0}")
                elif t == "im16":
                    it, w, h, bpp, desc = b[2], *struct.unpack("<HH", b[12:16]), b[16], b[17]
                    print(f"   TGA {e['name']}: type={it} {w}x{h} bpp={bpp} desc=0x{desc:02x}")
        if outdir:
            for e in files:
                b = e["data"][e["data_off"]:e["data_off"] + e["usize"]]
                op = os.path.join(outdir, pk[:-4], e["name"])
                os.makedirs(os.path.dirname(op), exist_ok=True)
                open(op, "wb").write(b)
                if classify(e["name"]) in TEXT_TYPES:
                    open(op + ".txt", "wb").write(deob(b).replace(b"\r", b"\n"))

if __name__ == "__main__":
    main()
