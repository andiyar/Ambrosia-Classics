import numpy as np, glob, os, json
from scipy.signal import fftconvolve
from common import *
W=np.zeros((1600,6400,3),np.uint8)
for p in glob.glob(S+'/mosaic/*.rgb'):
    h,v=map(int,os.path.basename(p)[:-4].split('_'))
    W[v:v+384,h:h+608]=view(load_rgb(p))
from PIL import Image; Image.fromarray(W[:,:,:]).resize((3200,800)).save(S+'/mosaic_world.png')
def edges(g):
    gx=np.zeros_like(g); gy=np.zeros_like(g)
    gx[:,1:-1]=g[:,2:]-g[:,:-2]; gy[1:-1]=g[2:]-g[:-2]
    return np.hypot(gx,gy)
def ncc(img,tpl):
    tpl=tpl-tpl.mean(); n=tpl.size
    num=fftconvolve(img,tpl[::-1,::-1],mode='valid')
    s=fftconvolve(img,np.ones_like(tpl),mode='valid'); s2=fftconvolve(img**2,np.ones_like(tpl),mode='valid')
    var=np.maximum(s2-s*s/n,1e-9)
    return num/np.sqrt(var*(tpl**2).sum())
Wg=edges(gray(W))
Wd=Wg[::2,::2]

res={}
for t in FRAMES:
    vf=view(vframe(t)); e=edges(gray(vf))
    c=ncc(Wd,e[::2,::2])
    v,h=np.unravel_index(np.argmax(c),c.shape)
    top=c.max(); c2=c.copy(); c2[max(0,v-10):v+10,max(0,h-10):h+10]=-1
    h0,v0=2*h,2*v
    # fine at full res within +-6
    best=None
    for dv in range(-6,7):
        for dh in range(-6,7):
            hh,vv=h0+dh,v0+dv
            if hh<0 or vv<0 or hh>5760 or vv>1216: continue
            w=Wg[vv:vv+384,hh:hh+608]
            a=w-w.mean(); b=e-e.mean(); r=(a*b).sum()/np.sqrt((a*a).sum()*(b*b).sum())
            if best is None or r>best[0]: best=(r,hh,vv)
    print(t,'coarse',h0,v0,'ncc %.3f second-best %.3f'%(top,c2.max()),'fine',best)
    res[t]=dict(h=int(best[1]),v=int(best[2]),ncc_coarse=float(top),ncc_second=float(c2.max()),ncc_fine=float(best[0]))
json.dump(res,open(S+'/match_coarse.json','w'),indent=1)
