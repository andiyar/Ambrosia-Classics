import re,sys,collections
names=[l.rstrip('\n') for l in open(sys.argv[1])]
def parse_type(s,i):
    # returns (str, i)
    quals=''
    while i<len(s) and s[i] in 'CVU S'.replace(' ',''):
        if s[i]=='C': quals+='const '
        elif s[i]=='U': quals+='unsigned '
        elif s[i]=='S': quals+='signed '
        elif s[i]=='V': quals+='volatile '
        i+=1
    if i>=len(s): return quals,i
    c=s[i]
    if c=='P':
        t,i=parse_type(s,i+1); return quals+t+'*',i
    if c=='R':
        t,i=parse_type(s,i+1); return quals+t+'&',i
    if c=='A':
        j=i+1
        while s[j].isdigit(): j+=1
        n=s[i+1:j]; t,i=parse_type(s,j+1); return quals+t+'['+n+']',i
    if c=='F':
        # function type F<args>_<ret>
        args,i=parse_args(s,i+1,stop='_')
        i+=1
        r,i=parse_type(s,i)
        return quals+r+'(*)('+','.join(args)+')',i
    if c.isdigit():
        j=i
        while s[j].isdigit(): j+=1
        n=int(s[i:j]); return quals+s[j:j+n],j+n
    if c=='Q':
        n=int(s[i+1]); i+=2; parts=[]
        for _ in range(n):
            j=i
            while s[j].isdigit(): j+=1
            k=int(s[i:j]); parts.append(s[j:j+k]); i=j+k
        return quals+'::'.join(parts),i
    m={'v':'void','c':'char','s':'short','i':'int','l':'long','f':'float','d':'double','b':'bool','e':'...','r':'long double','x':'long long','w':'wchar_t'}
    return quals+m.get(c,'?'+c),i+1
def parse_args(s,i,stop=None):
    args=[]
    while i<len(s) and (stop is None or s[i]!=stop):
        if s[i]=='T' and i+1<len(s) and s[i+1].isdigit():
            args.append('T'+s[i+1]); i+=2; continue
        if s[i]=='N' and i+2<len(s):
            n=int(s[i+1]); idx=int(s[i+2]); args += [args[idx-1] if idx-1<len(args) else '?']*n; i+=3; continue
        t,i=parse_type(s,i); args.append(t)
    return args,i
def demangle(n):
    n=n.lstrip('.')
    m=re.match(r'^(.+?)__(\d+|Q\d)(.*)$',n)
    cls=None;rest=None;name=None
    m2=re.match(r'^(.+?)__F(.*)$',n)
    # try class form first: name__<len>ClassF...
    mm=re.match(r'^(.*?[^_])__(\d+)(.*)$',n)
    if mm:
        name=mm.group(1); L=int(mm.group(2)); r=mm.group(3)
        cls=r[:L]; rest=r[L:]
        if rest.startswith('F') or rest.startswith('CF') or rest=='':
            const = rest.startswith('CF')
            rest=rest[2:] if const else rest[1:]
            try: args,_=parse_args(rest,0)
            except Exception: args=['?'+rest]
            return cls,name,args
    if m2:
        try: args,_=parse_args(m2.group(2),0)
        except Exception: args=['?'+m2.group(2)]
        return None,m2.group(1),args
    return None,n,None
out=collections.OrderedDict()
free=[]
for l in names:
    nm,addr=l.split(' @ ')
    if nm.startswith('FUN_'): continue
    c,f,a=demangle(nm)
    sig = f+'('+(','.join(x for x in a if x!='void') if a is not None else '')+')' if a is not None else f
    if c: out.setdefault(c,[]).append((sig,addr,nm))
    else: free.append((sig,addr,nm))
mode=sys.argv[2] if len(sys.argv)>2 else 'counts'
if mode=='counts':
    for c,v in sorted(out.items(),key=lambda x:-len(x[1])): print(len(v),c)
    print(len(free),'<free functions>')
else:
    for c,v in sorted(out.items()):
        print('##',c,len(v))
        for s,a,n in v: print('  ',a,s)
    print('## <free>',len(free))
    for s,a,n in free: print('  ',a,s)
