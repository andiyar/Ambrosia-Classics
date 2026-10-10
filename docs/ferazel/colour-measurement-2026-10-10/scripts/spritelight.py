# Per sprite blob: does the original darken/light sprites (E1 sprite light pass) or draw them plain (as at E3)?
from common import *
import numpy as np, json
from scipy.ndimage import label, binary_erosion
cal=lambda x:255*(x/255)**0.76
m=json.load(open(S+'/match.json'))
rows=[]
for t,d in m.items():
    s=f"{d['h']}_{d['v']}"; v=view(vframe(float(t))).astype(float)
    a1=view(load_rgb(f'{S}/combos/exact_highest_fs_e1/{s}.rgb')).astype(float); a3=view(load_rgb(f'{S}/combos/exact_highest_fs_e3/{s}.rgb')).astype(float)
    n1=view(load_rgb(f'{S}/combos/nosprites_e1/{s}.rgb')); sp=(view(load_rgb(f'{S}/combos/ruled_highest_fs_e1/{s}.rgb'))!=n1).any(2)
    sp=binary_erosion(sp,iterations=1)
    lab,n=label(sp)
    for k in range(1,n+1):
        R=lab==k
        if R.sum()<250: continue
        ys,xs=np.nonzero(R)
        # structural check: edge NCC of video vs E3 inside bbox
        y0,y1,x0,x1=ys.min(),ys.max()+1,xs.min(),xs.max()+1
        ev=edges(gray(v[y0:y1,x0:x1])); er=edges(gray(a3[y0:y1,x0:x1]))
        ncc=((ev-ev.mean())*(er-er.mean())).sum()/np.sqrt(((ev-ev.mean())**2).sum()*((er-er.mean())**2).sum()+1e-9)
        lv=srgb2lab(v[R].mean(0)); l1=srgb2lab(cal(a1[R]).mean(0)); l3=srgb2lab(cal(a3[R]).mean(0))
        rows.append((t,x0+16,y0+8,int(R.sum()),round(float(ncc),2),round(float(np.linalg.norm(lv-l1)),1),round(float(lv[0]-l1[0]),1),round(float(np.linalg.norm(lv-l3)),1),round(float(lv[0]-l3[0]),1)))
print('frame x y px structNCC | E1 dE dL | E3(plain) dE dL')
for r in rows: print(*r)
good=[r for r in rows if r[4]>0.5]
print('structurally matched blobs',len(good),'E1 better in',sum(r[5]<r[7] for r in good),'E3/plain better in',sum(r[7]<r[5] for r in good))
print('mean dE E1 %.1f E3 %.1f'%(np.mean([r[5] for r in good]),np.mean([r[7] for r in good])))
