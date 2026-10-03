import os,sys; sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import sys,bisect
from pef import *
starts=sorted(NAMES)
def fn(a):
    i=bisect.bisect_right(starts,a)-1; return NAMES[starts[i]]
for t in sys.argv[1:]:
    t=int(t,16); d=(t-0x100a7840)&0xffff
    hits=[]
    for o in range(0,len(CODE),4):
        w=struct.unpack('>I',CODE[o:o+4])[0]
        if (w>>26)==32 and ((w>>16)&31)==2 and (w&0xffff)==d:
            hits.append((hex(0x10000000+o),fn(0x10000000+o)))
    print(hex(t),len(hits),hits)
