import pickle,re,collections
have,use=pickle.load(open('hu.pkl','rb')); lv=pickle.load(open('lv.pkl','rb'))
for k,(n,u) in lv.items():
    for t,i,why in u: use.setdefault(t,{}).setdefault(i,set()).add(why+f' (Mlvl {k})')
pickle.dump(use,open('use2.pkl','wb'))
G='/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/ghidra/ferazel/'
src=[]
for fn in ['Ferazel_pef.decompiled.c','Ferazel_handlers.decompiled.c']:
    func='?'
    for i,l in enumerate(open(G+fn,errors='replace')):
        m=re.match(r'// ==== (.*) ====',l)
        if m: func=m.group(1); continue
        src.append((fn[8:11],i+1,func,l))
for t in ['PICT','clut','snd ']:
    rem=sorted(set(have[t])-set(use.get(t,{})))
    print('##',t,len(rem))
    for i in rem:
        pat=re.compile(r'(?<![\w.])(%d|0x%x)(?![\w])'%(i,i))
        hits=[(f,n,fn) for f,n,fn,l in src if pat.search(l) and 'DAT_' not in pat.search(l).group(0)]
        fns=collections.Counter(fn for f,n,fn in hits)
        print(t,i,have[t][i],dict(list(fns.items())[:5]))
