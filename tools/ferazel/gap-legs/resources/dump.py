import sys; sys.path.insert(0,'/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/docs/ferazel/tools')
import rsrc_census as r, glob
def ranges(ids):
    out=[];s=p=ids[0]
    for i in ids[1:]:
        if i==p+1: p=i; continue
        out.append((s,p)); s=p=i
    out.append((s,p)); return ','.join(str(a) if a==b else f'{a}-{b}' for a,b in out)
for f in sorted(glob.glob('/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/Resources/Ferazel/*.rsrc')):
  d,m=r.parse(f); print('##',f.split('/')[-1])
  for t in sorted(m): ids=sorted(x[0] for x in m[t]); print('  ',repr(t),len(ids),ranges(ids))
