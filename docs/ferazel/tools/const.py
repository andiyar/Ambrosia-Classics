import sys; import os; sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from pef import *
for a in sys.argv[1:]:
    x=int(a,16)
    print('%s: bytes=%s f32=%r f64=%r i32=%d i16=%d' % (a, b(x,8).hex(), f32(x), f64(x), i32(x), i16(x)))
