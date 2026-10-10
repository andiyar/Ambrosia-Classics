import json
from common import *

m=json.load(open(S+'/match_coarse.json'))
out={}
for t,d in m.items():
    sc=[(d['h']+dh,d['v']+dv) for dv in (-2,-1,0,1,2) for dh in (-2,-1,0,1,2) if d['h']+dh>=0 and d['v']+dv>=0 and d['h']+dh<=5760 and d['v']+dv<=1216]
    R=render('ruled','highest','fs',1,True,sc,S+'/ref')
    e=edges(gray(view(vframe(float(t)))))
    sc_scores=[]
    for s,a in R.items():
        w=edges(gray(view(a))); x=w-w.mean(); y=e-e.mean()
        sc_scores.append(((x*y).sum()/np.sqrt((x*x).sum()*(y*y).sum()),s))
    sc_scores.sort(reverse=True)
    print(t,sc_scores[:3])
    out[t]=dict(h=sc_scores[0][1][0],v=sc_scores[0][1][1],ncc=float(sc_scores[0][0]),ncc_2nd=float(sc_scores[1][0]),coarse=d)
json.dump(out,open(S+'/match.json','w'),indent=1)
