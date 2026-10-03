import struct,sys
# run from the repo root: python3 docs/cythera/tools/toc.py <TOC-entry-address-hex>...
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pef
_ds=[s for s in pef.secs if s['kind']==2][0]
D=pef.unpack(pef.d[_ds['off']:_ds['off']+_ds['packed']]); D=D+bytes(_ds['total']-len(D))
C=pef.d
DB=0x100cd280
def tocval(a): o=a-DB; return struct.unpack('>I',D[o:o+4])[0]
def cstr_code(v):
    o=0x3470+v; e=C.index(b'\0',o); return C[o:e]
def data_u32(a,n=1): o=a-DB; return [struct.unpack('>I',D[o+4*i:o+4*i+4])[0] for i in range(n)]
if __name__=='__main__':
    for a in sys.argv[1:]:
        v=tocval(int(a,16))
        try: s=cstr_code(v)[:80]
        except Exception: s=b'?'
        print(a, hex(v), s)
