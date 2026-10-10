from common import *
import numpy as np
from scipy.ndimage import binary_dilation
HUDG=0.76
cal=lambda x:255*(x/255)**HUDG
v=view(vframe(132)).astype(float)
for m in ['ruled','exact']:
    full=view(load_rgb(f'{S}/combos/{m}_highest_fs_e1/0_0.rgb')).astype(float)
    d24=view(load_rgb(f'{S}/q3/{m}_drop24/0_0.rgb')).astype(float)
    d0=view(load_rgb(f'{S}/q3/{m}_drop0/0_0.rgb')).astype(float)
    nol=view(load_rgb(f'{S}/q3/{m}_nolights/0_0.rgb')).astype(float)
    e3=view(load_rgb(f'{S}/combos/{m}_highest_fs_e3/0_0.rgb')).astype(float)
    spr=(view(load_rgb(f'{S}/combos/ruled_highest_fs_e1/0_0.rgb'))!=view(load_rgb(f'{S}/combos/nosprites_e1/0_0.rgb'))).any(2)
    spr=binary_dilation(spr,iterations=3)
    for name,ref in [('light24 (potion 0xc84)',d24),('light0 (torch)',d0)]:
        reg=(np.abs(full-ref).sum(2)>0)&~spr
        ys,xs=np.nonzero(reg)
        print(m,name,'glow px',reg.sum(),'bbox view x',xs.min(),xs.max(),'y',ys.min(),ys.max())
        lv=srgb2lab(v[reg].mean(0))
        for lab,a in [('E1 all lights',full),('E1 without this light',ref),('E1 no lights',nol),('E3',e3)]:
            la=srgb2lab(cal(a[reg]).mean(0)); pix=np.linalg.norm(srgb2lab(v[reg])-srgb2lab(cal(a[reg])),axis=1).mean()
            print(f'   {lab:24s} region-mean dE {np.linalg.norm(lv-la):5.1f}  dL(video-render) {lv[0]-la[0]:+5.1f}  per-px dE {pix:5.1f}')
print('--- sprite pixels (table, chair, potion) in the potion light bbox x 255..400, y 110..195 (view coords)')
for m in ['ruled','exact']:
    full=view(load_rgb(f'{S}/combos/{m}_highest_fs_e1/0_0.rgb')).astype(float)
    d24=view(load_rgb(f'{S}/q3/{m}_drop24/0_0.rgb')).astype(float)
    e3=view(load_rgb(f'{S}/combos/{m}_highest_fs_e3/0_0.rgb')).astype(float)
    sp=(view(load_rgb(f'{S}/combos/ruled_highest_fs_e1/0_0.rgb'))!=view(load_rgb(f'{S}/combos/nosprites_e1/0_0.rgb'))).any(2)
    from scipy.ndimage import binary_erosion
    sp=binary_erosion(sp,iterations=1)
    box=np.zeros_like(sp); box[110-8:195-8,255-16:400-16]=True
    reg=sp&box
    lit=reg&(np.abs(full-d24).sum(2)>0)
    print(m,'sprite px',reg.sum(),'of which changed by light24',lit.sum())
    for lab,a in [('E1 all lights',full),('E1 without light24',d24),('E3',e3)]:
        for nm,R in [('all table px',reg),('light24-changed px',lit)]:
            lv=srgb2lab(v[R].mean(0)); la=srgb2lab(cal(a[R]).mean(0))
            print(f'   {lab:20s} {nm:20s} region-mean dE {np.linalg.norm(lv-la):5.1f} dL {lv[0]-la[0]:+5.1f}')
