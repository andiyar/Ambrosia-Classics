import struct,sys
P='ghidra/cythera/Cythera_pef'
d=open(P,'rb').read()
hdr=struct.unpack('>4s4s4sIIIIIHHI',d[:40])
nsec=hdr[8]
secs=[]
for i in range(nsec):
    o=40+28*i
    nameoff,defaddr,total,unpacked,packed,contoff,kind,share,align,res=struct.unpack('>iIIIIIBBBB',d[o:o+28])
    secs.append(dict(defaddr=defaddr,total=total,unpacked=unpacked,packed=packed,off=contoff,kind=kind))
def readarg(b,i):
    v=0
    while True:
        c=b[i];i+=1
        v=(v<<7)|(c&0x7f)
        if not c&0x80: return v,i
def unpack(b):
    out=bytearray();i=0
    while i<len(b):
        c=b[i];i+=1
        op=c>>5;cnt=c&0x1f
        if cnt==0: cnt,i=readarg(b,i)
        if op==0: out+=bytes(cnt)
        elif op==1: out+=b[i:i+cnt];i+=cnt
        elif op==2:
            rep,i=readarg(b,i); blk=b[i:i+cnt];i+=cnt; out+=blk*(rep+1)
        elif op==3:
            com=cnt; cs,i=readarg(b,i); rep,i=readarg(b,i)
            common=b[i:i+com];i+=com
            for k in range(rep):
                out+=common+b[i:i+cs];i+=cs
            out+=common
        elif op==4:
            com=cnt; cs,i=readarg(b,i); rep,i=readarg(b,i)
            for k in range(rep):
                out+=bytes(com)+b[i:i+cs];i+=cs
            out+=bytes(com)
        else: raise Exception('op %d'%op)
    return bytes(out)
if __name__=='__main__':
    for s in secs: print({k:hex(v) for k,v in s.items()})
    ds=[s for s in secs if s['kind']==2][0]
    data=unpack(d[ds['off']:ds['off']+ds['packed']])
    print('unpacked',len(data),hex(ds['unpacked']))
    open(sys.argv[1],'wb').write(data+bytes(ds['total']-len(data)))
