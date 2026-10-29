#!/usr/bin/env python3
"""Port-gap ledger, part 1: every resource in the original's data × does the port ask for it.

Inputs: the six Resources/Ferazel/*.rsrc maps + the music folder, and a trace made by tools/ferazel/gap-trace.sh (every
distinct resource lookup the Ferazel/Core test suite makes, with its call stack). The static half — who in the ORIGINAL
asks for each resource, whether levels 1–4 / the front end reach it, and a static search of the port — is the hand/leg
table docs/ferazel/gap-ledger/resources-classified.tsv; this script joins the two and flags disagreements.

Usage: tools/ferazel/gap-resources.py <trace> > docs/ferazel/gap-ledger/resources-joined.tsv
Columns: file type id name bytes trace via static_port static_class reached note
  trace = game  (asked for on a path through the game's own code: GameFlow, LevelRun, the session, renderers, boot lists…)
        | test  (asked for only by a test calling a loader directly — does not prove the game asks)
        | all   (snd: the app's SoundBank decodes every snd at start — FerazelDriver.swift; the suite only tests it directly)
        | -     (never asked for in the suite; App/Windows-only paths such as dialogs' dctb are not in the suite)
  via = the outermost port routines on the game path (up to 3)
"""
import os, sys, re, subprocess, collections
sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'docs/ferazel/tools'))
from rsrc_census import parse  # noqa: E402

FILES = [("Ferazel's Wand.rsrc", 'FW.rsrc'), ("Ferazel's Wand World Data.rsrc", 'World'),
         ("Ferazel's Wand Backgrounds.rsrc", 'Backgrounds'), ("Ferazel's Wand Sprites.rsrc", 'Sprites'),
         ("Ferazel's Wand Sounds.rsrc", 'Sounds'), ("Ferazel's Wand Titles.rsrc", 'Titles')]
SYSTEM = {'BNDL', 'FREF', 'ICN#', 'icl4', 'icl8', 'ics#', 'ics4', 'ics8', 'icns', 'SIZE', 'cfrg', 'vers', 'setl', 'tset',
          'isap', 'VWCI'}
LOADERS = re.compile(r'PictureSource|FaceSheet|PlainFaceSheet|WaterFaceSheet|ColorLUT|FerazelResources|LevelFile|'
                     r'Conversation\.load|Conversation\.init|StringList|WorldFile|WorldMap\.load|WorldMap\.init|'
                     r'ConvertedPicture|EncodedFace|LightFaces\.load|TileSets\.load|DialogResources|SavedGameFile|PrefsFile|'
                     r'frameSize|FerazelData|DialogItemList|ControlTemplate|MenuTemplate|DialogTemplate|AlertTemplate|LightFace\.load|FerazelCensus')

def demangle(symbols):
    syms = sorted(symbols)
    out = subprocess.run(['swift', 'demangle', '--simplified', '--compact'], input='\n'.join(syms), capture_output=True,
                         text=True).stdout.split('\n')
    return {s: (out[i] if i < len(out) and out[i] else s) for i, s in enumerate(syms)}

def main():
    trace = sys.argv[1]
    rows = []
    for line in open(trace, encoding='utf-8', errors='replace'):
        p = line.rstrip('\n').split('\t')
        if len(p) < 5 or p[0] != 'xctest':
            continue          # the census tool's own enumeration is not the game
        rows.append((p[1], p[2], p[3] == '1', p[4].split(' ')))
    syms = {f.split(':', 1)[1] for _, _, _, fr in rows for f in fr if ':' in f}
    dm = demangle(syms)
    ask = collections.defaultdict(lambda: {'game': collections.Counter(), 'test': 0, 'all': 0})
    for typ, rid, found, frames in rows:
        fer = []
        for f in frames:
            sym = f.split(':', 1)[1] if ':' in f else f
            # Modules are linked into the test image, so the module comes from the mangled name, not the image.
            if sym.startswith(('$s18FerazelRenderTests', '$s16FerazelCoreTests')):
                break
            if sym.startswith(('$s11FerazelCore', '$s13FerazelRender')):
                fer.append(dm.get(sym, sym))
        key = (typ, rid)
        if rid == 'ALL':
            if any('SoundBank' in n or 'MusicTrack' in n for n in fer):
                ask[key]['all'] += 1
            continue
        if not found:
            continue
        game = [n for n in fer if not LOADERS.search(n)]
        if game:
            outer = re.sub(r'\(.*', '', game[-1])[:60]
            ask[key]['game'][outer] += 1
        else:
            ask[key]['test'] += 1
    static = {}
    leg = os.path.join(ROOT, 'docs/ferazel/gap-ledger/resources-classified.tsv')
    if os.path.exists(leg):
        for line in open(leg, encoding='utf-8'):
            p = line.rstrip('\n').split('\t')
            if len(p) >= 9 and p[0] != 'file':
                static[(p[0], p[1], p[2])] = p
    print('file\ttype\tid\tname\tbytes\ttrace\tvia\tstatic_port\tstatic_class\treached\tnote')
    counts = collections.Counter()
    for fname, short in FILES:
        _, res = parse(os.path.join(ROOT, 'Resources/Ferazel', fname))
        for typ in sorted(res):
            if typ in SYSTEM:
                counts['system (out of scope)'] += len(res[typ])
                continue
            for rid, name, body in sorted(res[typ], key=lambda r: r[0]):
                a = ask.get((typ, str(rid)))
                if a and a['game']:
                    tr, via = 'game', ', '.join(n for n, _ in a['game'].most_common(3))
                elif a and a['test']:
                    tr, via = 'test', ''
                elif typ == 'snd ':
                    tr, via = 'all', 'SoundBank (every snd; Shared/FerazelDriver.swift)'
                else:
                    tr, via = '-', ''
                s = static.get((short, typ, str(rid)))
                sp, sc, reached = (s[6], s[7], s[5]) if s else ('?', '?', '?')
                note = ''
                if tr == 'game' and sp.startswith('no'):
                    note = 'CHECK: trace says the game asks; static said no'
                elif tr in ('-', 'test') and sp.startswith('yes') and typ not in ('dctb', 'DLOG', 'DITL', 'CNTL', 'MENU', 'MBAR', 'WIND', 'ALRT'):
                    note = 'static yes, not on a traced game path (App-only, later level, or untested)'
                counts[f'{typ.strip()} trace={tr}'] += 1
                print(f'{short}\t{typ}\t{rid}\t{(name or "").replace(chr(9), " ")}\t{len(body)}\t{tr}\t{via}\t{sp}\t{sc}\t{reached}\t{note}')
    music = os.path.join(ROOT, "Resources/Ferazel/Ferazel's Wand Music")
    for f in sorted(os.listdir(music)):
        if f.isdigit():
            s = static.get(('Music', 'music', str(int(f)))) or static.get(('Music', 'music', f))
            print(f'Music\tmusic\t{int(f)}\t\t{os.path.getsize(os.path.join(music, f))}\t-\t\t'
                  f'{s[6] if s else "?"}\t{s[7] if s else "?"}\t{s[5] if s else "?"}\tmusic is streamed by the app (not traced)')
    for k, v in sorted(counts.items()):
        print(f'# {k}: {v}', file=sys.stderr)

if __name__ == '__main__':
    main()
