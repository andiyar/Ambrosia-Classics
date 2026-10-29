import sys,collections; sys.path.insert(0,'/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/docs/ferazel/tools')
import rsrc_census as r, glob
R='/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/Resources/Ferazel/'
have=collections.defaultdict(dict)
for f in glob.glob(R+'*.rsrc'):
    d,m=r.parse(f)
    for t,L in m.items():
        for rid,n,b in L: have[t].setdefault(rid,[]).append((f.split('/')[-1].replace("Ferazel's Wand","").replace('.rsrc','').strip() or 'app',n))
use=collections.defaultdict(lambda: collections.defaultdict(set))
for l in open('constuse.tsv'):
    t,i,fn=l.rstrip('\n').split('\t'); use[t][int(i)].add(fn)
for l in open('comp.tsv'):
    t,rg,fn=l.rstrip('\n').split('\t')
    step=1
    if '/' in rg: rg,step=rg.split('/'); step=int(step)
    a,b=(rg.split('-')+[rg])[:2] if '-' in rg else (rg,rg)
    for i in range(int(a),int(b)+1,step): use[t][i].add(fn)
import pickle; pickle.dump((dict(have),{k:dict(v) for k,v in use.items()}),open('hu.pkl','wb'))
for t in ['PICT','clut','snd ']:
    miss=sorted(set(use[t])-set(have[t])); un=sorted(set(have[t])-set(use[t]))
    print(t,'used-but-absent',miss); print(t,'present-unreferenced',len(un),un)
