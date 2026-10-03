import struct, sys
def parse(path):
    d=open(path,'rb').read()
    doff,moff,dlen,mlen=struct.unpack('>IIII',d[:16])
    m=d[moff:moff+mlen]
    tlo,nlo=struct.unpack('>HH',m[24:28])
    nt=struct.unpack('>H',m[tlo:tlo+2])[0]+1
    res={}
    for i in range(nt):
        t,n,ro=struct.unpack('>4sHH',m[tlo+2+8*i:tlo+10+8*i])
        t=t.decode('mac_roman')
        for j in range(n+1):
            e=m[tlo+ro+12*j:tlo+ro+12*j+12]
            rid,no,attr=struct.unpack('>hhB',e[:5])
            off=int.from_bytes(e[5:8],'big')
            ln=struct.unpack('>I',d[doff+off:doff+off+4])[0]
            body=d[doff+off+4:doff+off+4+ln]
            name=None
            if no!=-1:
                L=m[nlo+no]; name=m[nlo+no+1:nlo+no+1+L].decode('mac_roman')
            res.setdefault(t,[]).append((rid,name,body))
    return d,res
def census(path):
    d,res=parse(path)
    print(f'## {path.split("/")[-1]}  ({len(d)} B, {sum(len(v) for v in res.values())} resources, {len(res)} types)')
    for t in sorted(res):
        L=[len(b) for _,_,b in res[t]]; ids=sorted(r for r,_,_ in res[t])
        print(f'  {t!r:8} n={len(L):4} size {min(L)}..{max(L)} ids {ids[0]}..{ids[-1]}')
if __name__=='__main__':
    for p in sys.argv[1:]: census(p)
