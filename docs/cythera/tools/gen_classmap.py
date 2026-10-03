import re,sys
sys.argv=['x','names.txt']
exec(open('demangle.py').read().split("out=collections.OrderedDict()")[0])
names=[l.rstrip('\n') for l in open('names.txt')]
classes={}; free=[]; std=0; glue=0
for l in names:
    nm,addr=l.split(' @ ')
    if nm.startswith('FUN_'): continue
    a=int(addr,16)
    if a>=0x100c1c50: glue+=1; continue
    c,f,args=demangle(nm)
    if c is None and ('__Q23std' in nm or 'red_black' in nm or nm.startswith('.__sinit') and False): std+=1; continue
    if c is not None and ('<' in c or c=='std'): std+=1; continue
    sig=f+'('+(','.join(x for x in args if x!='void') if args is not None else '?')+')'
    if c: classes.setdefault(c,[]).append((addr,sig))
    else: free.append((addr,sig))
D='/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/focused-darwin-329781/docs/cythera'
def section(keys):
    out=[]
    for c in keys:
        out.append('### %s (%d)'%(c,len(classes[c])))
        for a,s in classes[c]: out.append('- `%s` %s'%(a,s.replace('|','\\|')))
        out.append('')
    return out
keys=sorted(classes,key=lambda k:k.lower())
tot=sum(len(v)+2 for v in classes.values()); n=0; split=None
for i,k in enumerate(keys):
    n+=len(classes[k])+2
    if split is None and n>tot/2: split=i+1
A=keys[:split]; B=keys[split:]
hdr='''# Cythera 1.0.4 — demangled class map, part %s

Generated from the `// ==== name @ addr ====` headers of `ghidra/Cythera_pef.decompiled.c` with
`docs/cythera/tools/gen_classmap.py` + `demangle.py` (MPW/CodeWarrior scheme: `name__<len>Class F
<sig>`; `Uc` unsigned char, `s` short, `l` long, `P` pointer, `R` reference, `C` const, `Q2`
qualified name; `__ct`/`__dt` = constructor/destructor, `__pp` operator++, `__opPc` operator
char*). One line per decompiled function: address, demangled name(argument types). Excluded: 290
`FUN_` blocks, %d std-library template instantiations, %d import glue stubs (addresses ≥
0x100C1C50). Totals: %d classes, %d methods, %d free functions. [HIGH — mechanical]

'''
args=(std,glue,len(classes),sum(len(v) for v in classes.values()),len(free))
open(D+'/engine-classmap-1.md','w').write(hdr%(('1 of 3 (classes %s … %s)'%(A[0],A[-1]),)+args)+'\n'.join(section(A))+'\n')
open(D+'/engine-classmap-2.md','w').write(hdr%(('2 of 3 (classes %s … %s)'%(B[0],B[-1]),)+args)+'\n'.join(section(B))+'\n')
fl=['## Free (non-member) game functions (%d)'%len(free),'']
for a,s in free: fl.append('- `%s` %s'%(a,s.replace('|','\\|')))
open(D+'/engine-classmap-3.md','w').write(hdr%(('3 of 3 (free functions)',)+args)+'\n'.join(fl)+'\n')
print(*args)
cnt=sorted(((len(v),k) for k,v in classes.items()),key=lambda x:(-x[0],x[1].lower()))
print(', '.join('%s %d'%(k,n) for n,k in cnt))
