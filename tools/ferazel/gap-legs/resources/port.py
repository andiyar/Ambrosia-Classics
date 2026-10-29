import re,os,collections,pickle
B='/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/Ferazel/'
roots=['Core/Sources/FerazelCore','Core/Sources/FerazelRender','App','Shared','Windows/Sources']
lit=collections.defaultdict(set)
def iv(s): return int(s,16) if s.lower().startswith('0x') else int(s)
N=r'(0x[0-9a-fA-F]+|\d+)'
for r in roots:
    for dp,dn,fs in os.walk(B+r):
        if '/Census' in dp: continue
        for f in fs:
            if not f.endswith('.swift'): continue
            p=os.path.join(dp,f); rel=p[len(B):]
            for ln,l in enumerate(open(p,errors='replace')):
                code=l.split('//')[0] if not l.strip().startswith('///') else ''
                if not code.strip(): continue
                for m in re.finditer(r'(?<![\w.])'+N+r'(?![\w.])',code):
                    v=iv(m.group(1)); 
                    if 100<=v<=30000: lit[v].add((f"{rel}:{ln+1}",code))
                for m in re.finditer(N+r'\)?\s*\.\.<\s*'+N+r'\s*\+\s*'+N,code):
                    a,b,n=iv(m.group(1)),iv(m.group(2)),iv(m.group(3))
                    for v in range(a,b+n): lit[v].add((f"{rel}:{ln+1}~",code))
                for m in re.finditer(N+r'\)?\s*\.\.\.\s*'+N,code):
                    a,b=iv(m.group(1)),iv(m.group(2))
                    if b-a<200:
                        for v in range(a,b+1): lit[v].add((f"{rel}:{ln+1}~",code))
pickle.dump(dict(lit),open('lit.pkl','wb'))
print(len(lit))
