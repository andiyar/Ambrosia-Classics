import struct,sys
import os
P=os.environ.get('FZ_PEF', os.path.join(os.path.dirname(__file__),'../../../ghidra/Ferazel_pef'))
d=open(P,'rb').read()
hdr=struct.unpack('>4s4s4sIIIIIHHI',d[:40])
nsec=hdr[8]
secs=[]
for i in range(nsec):
    s=struct.unpack('>iIIIIIBBBB',d[40+28*i:40+28*(i+1)])
    secs.append(s)
def arg(b,p):
    v=0
    while True:
        x=b[p];p+=1;v=(v<<7)|(x&0x7f)
        if not x&0x80: return v,p
def unpack(b,size):
    out=bytearray();p=0
    while p<len(b):
        x=b[p];p+=1;op=x>>5;c=x&0x1f
        if c==0: c,p=arg(b,p)
        if op==0: out+=b'\0'*c
        elif op==1: out+=b[p:p+c];p+=c
        elif op==2:
            r,p=arg(b,p); blk=b[p:p+c];p+=c; out+=blk*(r+1)
        elif op==3:
            cs,p=arg(b,p); rc,p=arg(b,p); common=b[p:p+c];p+=c
            out+=common
            for i in range(rc): out+=b[p:p+cs];p+=cs; out+=common
        elif op==4:
            cs,p=arg(b,p); rc,p=arg(b,p)
            out+=b'\0'*c
            for i in range(rc): out+=b[p:p+cs];p+=cs; out+=b'\0'*c
        else: raise Exception('op %d'%op)
    out+=b'\0'*(size-len(out))
    return bytes(out)
SECS={}
for s in secs:
    name,da,tot,unp,pk,off,kind,share,align,_=s
    raw=d[off:off+pk]
    if kind==2: data=unpack(raw,tot)
    else: data=raw+b'\0'*(tot-len(raw))
    SECS[kind]=(da,tot,unp,pk,off,data)
if __name__=='__main__':
    print('header',hdr)
    for s in secs: print('sec name=%d def=%#x total=%#x unpacked=%#x packed=%#x off=%#x kind=%d share=%d align=%d'%s[:9])
DBASE=0x1009f840
DATA=SECS[2][5]
CODE=SECS[0][5]
def b(a,n):
    if a>=DBASE: return DATA[a-DBASE:a-DBASE+n]
    return CODE[a-0x10000000:a-0x10000000+n]
def u32(a): return struct.unpack('>I',b(a,4))[0]
def i32(a): return struct.unpack('>i',b(a,4))[0]
def i16(a): return struct.unpack('>h',b(a,2))[0]
def f32(a): return struct.unpack('>f',b(a,4))[0]
def f64(a): return struct.unpack('>d',b(a,8))[0]
def pstr(a): L=b(a,1)[0]; return b(a+1,L).decode('mac_roman')
def cstr(a):
    x=b(a,256); return x[:x.index(0)].decode('mac_roman') if 0 in x else x.decode('mac_roman')
NAMES={}
for line in open(os.path.join(os.path.dirname(__file__),'fer_names.txt')):
    n,a=line.strip().split('@'); NAMES[int(a,16)]=n
def tocfunc(t):
    tv=u32(t)+DBASE
    c=u32(tv)+0x10000000
    return hex(tv),hex(c),NAMES.get(c,'?')
for _l in open(os.path.join(os.path.dirname(__file__),'targets.txt')):
    _a,_n=_l.split(); NAMES[int(_a,16)]=_n
