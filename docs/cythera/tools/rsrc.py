import struct,sys,collections
def parse(path):
    d=open(path,'rb').read()
    if len(d)<16: return None
    do,mo,dl,ml=struct.unpack('>4I',d[:16])
    if mo+ml>len(d) or do+dl>len(d): return None
    m=d[mo:mo+ml]
    tlo,nlo=struct.unpack('>HH',m[24:28])
    nt=struct.unpack('>H',m[28:30])[0]+1
    res=[]
    for i in range(nt):
        t,cnt,ro=struct.unpack('>4sHH',m[tlo+2+8*i:tlo+10+8*i])
        for j in range(cnt+1):
            rid,no,attr_off,_=struct.unpack('>hHII',m[tlo+ro+12*j:tlo+ro+12*j+12])
            attr=attr_off>>24; off=attr_off&0xffffff
            ln=struct.unpack('>I',d[do+off:do+off+4])[0]
            name=None
            if no!=0xffff:
                nl=m[nlo+no]; name=m[nlo+no+1:nlo+no+1+nl].decode('mac_roman')
            res.append((t.decode('mac_roman'),rid,name,ln,do+off+4,attr))
    return res,d
if __name__=='__main__':
    for p in sys.argv[1:]:
        r=parse(p)
        if r is None: print('##',p,'-- not a resource fork'); continue
        res,_=r
        c=collections.OrderedDict()
        for t,rid,n,ln,off,a in res:
            c.setdefault(t,[]).append(ln)
        print('##',p.split('/')[-1],'resources:',len(res),'types:',len(c))
        for t,v in sorted(c.items()):
            print('  %-6s %5d  %7d..%-7d total %d'%(repr(t)[1:-1],len(v),min(v),max(v),sum(v)))
