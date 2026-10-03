import struct,sys
DATA='/Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/RPG/Cythera/Cythera (installed)/files/Cythera Data'
def toc(path=DATA):
    d=open(path,'rb').read()
    root=d[0x80:0x880]
    segs={}
    pages={}
    for p in range(256):
        off,ln=struct.unpack('>II',root[p*8:p*8+8])
        if p==0: continue
        if ln: pages[p]=(off,ln)
    # page 0 entries themselves are segments 0x0001..0x00ff (=TOC pages)
    for p,(off,ln) in pages.items():
        pg=d[off:off+ln]
        for e in range(len(pg)//8):
            o,l=struct.unpack('>II',pg[e*8:e*8+8])
            if l: segs[(p<<8)|e]=(o,l)
    return d,segs,pages
def dec(buf,sid,skip=0):
    mult=(sid&0x3f)*4+1; add=(sid>>6)&0xff; seed=((sid&0xffff)>>8)^sid
    seed&=0xffffffff
    for _ in range(skip): seed=(add+seed*mult)&0xffffffff
    out=bytearray(buf)
    for i in range(len(out)):
        seed=(add+seed*mult)&0xffffffff; out[i]^=seed&0xff
    return bytes(out)
if __name__=='__main__':
    path=sys.argv[1] if len(sys.argv)>1 else DATA
    d,segs,pages=toc(path)
    print('file',len(d),'pages',len(pages),'segments',len(segs))
    import collections
    g=collections.OrderedDict()
    for sid in sorted(segs):
        g.setdefault(sid>>8,[]).append(sid)
    for p,ids in g.items():
        ls=[segs[i][1] for i in ids]
        print('page %02x: %3d segs  ids %04x..%04x  len %d..%d total %d'%(p,len(ids),ids[0],ids[-1],min(ls),max(ls),sum(ls)))
