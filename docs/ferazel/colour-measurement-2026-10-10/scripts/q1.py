# Q1: duplicate-black tie-break. Where lowest and highest renders differ (FG-200 blacks -> index 1 light yellow vs 255 black),
# which one does the video look like?  Evaluated after the HUD gamma, on pixels outside sprites.
from common import *
import numpy as np, json
from scipy.ndimage import binary_dilation
cal=lambda x:255*(x/255)**0.76
m=json.load(open(S+'/match.json'))
tot={}
for t,d in m.items():
    s=f"{d['h']}_{d['v']}"; v=view(vframe(float(t))).astype(float)
    spr=binary_dilation((view(load_rgb(f'{S}/combos/ruled_highest_fs_e1/{s}.rgb'))!=view(load_rgb(f'{S}/combos/nosprites_e1/{s}.rgb'))).any(2),iterations=4)
    for mo in ['exact','ruled','inv4','inv5']:
        lo=view(load_rgb(f'{S}/combos/{mo}_lowest_fs_e1/{s}.rgb')).astype(float); hi=view(load_rgb(f'{S}/combos/{mo}_highest_fs_e1/{s}.rgb')).astype(float)
        D=(lo!=hi).any(2)&~spr
        # compare at 3x3-blurred level to tolerate video blur
        from scipy.ndimage import uniform_filter
        bl=lambda a: np.stack([uniform_filter(a[...,i],3) for i in range(3)],-1)
        lv=srgb2lab(bl(v)[D]); ll=srgb2lab(bl(cal(lo))[D]); lh=srgb2lab(bl(cal(hi))[D])
        e_lo=np.linalg.norm(lv-ll,axis=1); e_hi=np.linalg.norm(lv-lh,axis=1)
        o=tot.setdefault(mo,{'px':0,'lo':0,'hi':0,'hi_wins':0,'b_video':0,'b_lo':0,'b_hi':0})
        o['px']+=int(D.sum()); o['lo']+=e_lo.sum(); o['hi']+=e_hi.sum(); o['hi_wins']+=int((e_hi<e_lo).sum())
        o['b_video']+=lv[:,2].sum(); o['b_lo']+=ll[:,2].sum(); o['b_hi']+=lh[:,2].sum()
for mo,o in tot.items():
    n=max(o['px'],1)
    print(f"{mo:6s} differing px {o['px']:7d}  dE lowest {o['lo']/n:5.1f}  highest {o['hi']/n:5.1f}  highest closer on {100*o['hi_wins']/n:4.1f}% px | mean b* video {o['b_video']/n:5.1f} lowest {o['b_lo']/n:5.1f} highest {o['b_hi']/n:5.1f}")
