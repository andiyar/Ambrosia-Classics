#!/usr/bin/env python3
"""Re-implementation of the sprite-plate frame scan (U_SpritePlate.cc, FUN_1001f340 family)
for checking: runs over every '* IA[XXXX].gif' alpha plate under <decoded-dir>/*/im08/ and
compares the game's bottom-left-anchored frame rect with the trimmed bounding box.
Uses RGB compares where the game compares 8-bit indices. Needs Pillow.
Usage: plate_frames.py <decoded-dir written by list_paks.py --decode>
"""
import sys, os
import glob
from PIL import Image
def frames(path):
    im=Image.open(path).convert('RGB'); W,H=im.size; px=im.load()
    grid=px[1,0]; out=[]; row=1
    while row<H:
        h=0
        while row+h<H and px[0,row+h]!=grid: h+=1
        if h<1: row+=1; continue
        col=0
        while col<W:
            w=0
            while col+w<W and all(px[col+w,y]!=grid for y in range(row,row+h)): w+=1
            if w>=1:
                bg=px[col,row]
                ys=[y for y in range(row,row+h) if any(px[x,y]!=bg for x in range(col,col+w))]
                if ys:
                    xs=[x for x in range(col,col+w) if any(px[x,y]!=bg for y in range(row,row+h))]
                    fh=ys[-1]-ys[0]+1; fw=xs[-1]-xs[0]+1
                    top=row+(h-fh)-1; left=col+1
                    out.append(((top,left,top+fh,left+fw),(ys[0],xs[0],ys[0]+fh,xs[0]+fw)))
                col+=w
            else: col+=1
        row+=h+1
    return out
tot=0; mism=0; plates=0; bad=[]
for p in sorted(glob.glob(os.path.join(sys.argv[1], '*', 'im08', '* IA[[]*].gif'))):
    f=frames(p); plates+=1; tot+=len(f)
    m=sum(1 for a,b in f if a!=b); mism+=m
    if m: bad.append((p.split('/')[-1],m,len(f)))
    ic=p.replace(' IA[',' IC[').rsplit('[',1)[0]
print('alpha plates',plates,'frames',tot,'frames where bottom-left rect != trimmed bbox',mism)
print(bad[:20])
