import json, itertools
import numpy as np
from scipy.optimize import least_squares
from scipy.ndimage import binary_dilation
from common import *
m=json.load(open(S+'/match.json'))
COMBOS=[f'{a}_{b}_{c}_e{e}' for a,b,c,e in itertools.product(['exact','ruled','inv4','inv5'],['lowest','highest'],['none','fs'],[1,2,3])]
B=8
HUDG=0.760  # from hudtone.py (model-independent PICT 129 frame calibration)
def hudcal(x): return 255*(np.clip(x,0,255)/255)**HUDG
def blocks(a,valid):
    H,W=a.shape[:2]; a=a.reshape(H//B,B,W//B,B,-1).astype(float); v=valid.reshape(H//B,B,W//B,B)
    n=v.sum((1,3)); s=(a*v[...,None]).sum((1,3))
    return s/np.maximum(n,1)[...,None], n>=0.75*B*B
def apply_fit(x,p):  # p: 3x3 offset,gain,gamma per channel, x in 0..255
    o=p[:,0];g=p[:,1];ga=p[:,2]
    return np.clip(o+g*255*(np.clip(x,0,255)/255)**ga,0,255)
def fit(R,V):
    P=[]
    for c in range(3):
        f=lambda q: (q[0]+q[1]*255*(R[:,c]/255)**q[2])-V[:,c]
        P.append(least_squares(f,[0,1,1],bounds=([-60,0.2,0.2],[60,5,5]),loss='soft_l1',f_scale=10).x)
    return np.array(P)
frames={}
for t,d in m.items():
    s=f"{d['h']}_{d['v']}"
    vid=view(vframe(float(t)))
    spr=np.zeros(vid.shape[:2],bool)
    for e in (1,3):
        a=view(load_rgb(f'{S}/combos/ruled_highest_fs_e{e}/{s}.rgb')); b=view(load_rgb(f'{S}/combos/nosprites_e{e}/{s}.rgb'))
        spr|=(a!=b).any(2)
    spr=binary_dilation(spr,iterations=6)
    ref=srgb2lab(view(load_rgb(f'{S}/combos/ruled_highest_none_e3/{s}.rgb')))
    L,A,Bb=ref[...,0],ref[...,1],ref[...,2]; ch=np.hypot(A,Bb)
    e1=gray(view(load_rgb(f'{S}/combos/ruled_highest_none_e1/{s}.rgb'))); e3=gray(view(load_rgb(f'{S}/combos/ruled_highest_none_e3/{s}.rgb')))
    reg={'backdrop':L<8,'rock':(ch<12)&(L>=8)&(L<45),'fgedge':(ch<12)&(L>=45),'warm':(ch>=12)&(Bb>0)&(A>-5),'blue':Bb<-15,
         'lit':(e1>e3+12)}
    rend={c:view(load_rgb(f'{S}/combos/{c}/{s}.rgb')) for c in COMBOS}
    frames[t]=dict(vid=vid,spr=spr,reg=reg,rend=rend)
# pass 1: per-frame outlier blocks from the combo-median fitted dE
def evaluate(outlier=None):
    out={}
    # global fit per combo across frames
    for c in COMBOS:
        Rs=[];Vs=[];per={}
        for t,F in frames.items():
            valid=~F['spr']
            vb,ok=blocks(F['vid'],valid); rb,_=blocks(F['rend'][c],valid)
            if outlier is not None: ok&=~outlier[t]
            per[t]=(vb,rb,ok); Rs.append(rb[ok]); Vs.append(vb[ok])
        P=fit(np.concatenate(Rs),np.concatenate(Vs))
        res={'fit':P.tolist(),'frames':{}}
        for t,(vb,rb,ok) in per.items():
            lv=srgb2lab(vb); raw=np.linalg.norm(lv-srgb2lab(rb),axis=-1); fd=np.linalg.norm(lv-srgb2lab(apply_fit(rb,P)),axis=-1); hd=np.linalg.norm(lv-srgb2lab(hudcal(rb)),axis=-1)
            res['frames'][t]=dict(raw=float(raw[ok].mean()),fitted=float(fd[ok].mean()),hud=float(hd[ok].mean()),rawmap=raw,fitmap=fd,ok=ok)
        out[c]=res
    return out
r1=evaluate()
outlier={}
for t in frames:
    med=np.median(np.stack([r1[c]['frames'][t]['fitmap'] for c in COMBOS]),0)
    ok=r1[COMBOS[0]]['frames'][t]['ok']
    thr=np.percentile(med[ok],92); outlier[t]=med>thr
r=evaluate(outlier)
# region scores (pixel level, fitted & raw, with masks)
def regionscores(c):
    P=np.array(r[c]['fit']); out={}
    for t,F in frames.items():
        valid=~F['spr'] & ~np.kron(outlier[t],np.ones((B,B),bool)).astype(bool)
        lv=srgb2lab(F['vid'].astype(float)); rr=F['rend'][c].astype(float)
        lr=srgb2lab(rr); lf=srgb2lab(apply_fit(rr,P))
        for k,mk in F['reg'].items():
            mk=mk&valid
            if mk.sum()<400: continue
            o=out.setdefault(k,{'n':0,'raw':0,'fit':0,'hud':0,'dLraw':0,'dLfit':0,'dLhud':0})
            # region means (Lab of mean colours) -> dE of means
            vm=srgb2lab(F['vid'][mk].mean(0)); rm=srgb2lab(rr[mk].mean(0)); fm=srgb2lab(apply_fit(rr[mk].mean(0),P)); hm=srgb2lab(hudcal(rr[mk]).mean(0))
            n=1
            o['n']+=n; o['raw']+=np.linalg.norm(vm-rm); o['fit']+=np.linalg.norm(vm-fm); o['dLraw']+=vm[0]-rm[0]; o['dLfit']+=vm[0]-fm[0]; o['hud']+=np.linalg.norm(vm-hm); o['dLhud']+=vm[0]-hm[0]
    return {k:{kk:(vv/o['n'] if kk!='n' else vv) for kk,vv in o.items()} for k,o in out.items()}
summary={}
for c in COMBOS:
    fr={t:dict(raw=v['raw'],fitted=v['fitted'],hud=v['hud']) for t,v in r[c]['frames'].items()}
    summary[c]=dict(fit=r[c]['fit'],frames=fr,raw=float(np.mean([v['raw'] for v in fr.values()])),fitted=float(np.mean([v['fitted'] for v in fr.values()])),hud=float(np.mean([v['hud'] for v in fr.values()])),regions=regionscores(c))
json.dump(summary,open(S+'/scores.json','w'),indent=1)
json.dump({t:dict(valid_blocks=int((r[COMBOS[0]]['frames'][t]['ok']).sum()),sprite_px=int(F['spr'].sum()),outlier_blocks=int(outlier[t].sum())) for t,F in frames.items()},open(S+'/masks.json','w'),indent=1)
np.savez(S+'/outlier.npz',**{t:o for t,o in outlier.items()})
rank=sorted(COMBOS,key=lambda c:summary[c]['fitted'])
print('combo raw fitted hud | region dE-of-means hud-calibrated (dL video-minus-render, hud-calibrated)')
for c in rank:
    R=summary[c]['regions']
    print(f"{c:24s} {summary[c]['raw']:6.2f} {summary[c]['fitted']:6.2f} {summary[c]['hud']:6.2f} | "+' '.join(f"{k}:{R[k]['hud']:.1f}({R[k]['dLhud']:+.1f})" for k in ['backdrop','rock','fgedge','warm','lit','blue'] if k in R))
