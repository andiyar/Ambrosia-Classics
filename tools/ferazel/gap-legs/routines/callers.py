import re,sys,json
G='/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/ghidra/ferazel/'
funcs={}  # name -> (addr, body)
for fn in ['Ferazel_pef.decompiled.c','Ferazel_handlers.decompiled.c']:
    cur=None;buf=[]
    for line in open(G+fn,errors='replace'):
        m=re.match(r'// ==== (\S+) @ (\w+) ====',line)
        if m:
            if cur: funcs.setdefault(cur[0],[cur[1],''])[1]+=''.join(buf)
            cur=(m.group(1),m.group(2));buf=[]
        else: buf.append(line)
    if cur: funcs.setdefault(cur[0],[cur[1],''])[1]+=''.join(buf)
names=list(funcs)
callers={n:[] for n in names}
tok=re.compile(r'[A-Za-z_.][A-Za-z0-9_.]*')
idx={}
for n in names:
    idx.setdefault(n,n); idx.setdefault(n.lstrip('.'),n)
for caller,(a,body) in funcs.items():
    for t in set(tok.findall(body)):
        k=idx.get(t) or idx.get(t.lstrip('.')) or (idx.get(t[1:]) if t.startswith('_') else None) or idx.get('.'+t.lstrip('_'))
        if k and k!=caller and not body.count('debug::'+t): callers[k].append(caller)
    # also FUN_ addresses / PTR refs by address
for n,(a,b) in funcs.items():
    pass
json.dump({n:{'addr':funcs[n][0],'callers':sorted(set(callers[n])),'len':funcs[n][1].count('\n')} for n in names},open(sys.argv[1],'w'))
