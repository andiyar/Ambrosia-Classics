# Model-independent tone calibration: the HUD / PICT 129 frame (4-bit art, converts canonically under every model).
from common import *
import numpy as np, json
from scipy.optimize import least_squares
m=json.load(open(S+'/match.json'))
R=[];V=[]
for t,d in m.items():
    v=vframe(float(t)).astype(float); r=load_rgb(f"{S}/combos/exact_highest_fs_e1/{d['h']}_{d['v']}.rgb").astype(float)
    R.append(r[392:480]);V.append(v[392:480])
def bm(L): return np.concatenate([a.reshape(22,4,160,4,3).mean((1,3)).reshape(-1,3) for a in L])
Rb=bm(R);Vb=bm(V)
ok=(Rb.mean(1)>20)&(np.abs(Rb.mean(1)-Vb.mean(1))<60)
print('HUD 4x4 blocks',ok.sum())
f=lambda q: (255*(Rb[ok]/255)**q[0]-Vb[ok]).ravel()
q=least_squares(f,[1],loss='soft_l1',f_scale=8).x; print('HUD single gamma %.3f'%q[0],'median |resid| %.2f'%np.median(np.abs(f(q))))
print('identity median |resid| %.2f'%np.median(np.abs(Rb[ok]-Vb[ok])),'mean video-render',(Vb[ok]-Rb[ok]).mean(0).round(2))
for lo in range(0,256,32):
    s=ok&(Rb.mean(1)>=lo)&(Rb.mean(1)<lo+32)
    if s.sum()>20: print(f'render {lo:3d}-{lo+32:3d}: n={s.sum():5d} render {Rb[s].mean():6.1f} video {Vb[s].mean():6.1f} implied gamma {np.log(Vb[s].mean()/255)/np.log(Rb[s].mean()/255):.2f}')
