import json, itertools
from concurrent.futures import ThreadPoolExecutor
from common import *
m=json.load(open(S+'/match.json'))
SC=[(d['h'],d['v']) for d in m.values()]
COMBOS=list(itertools.product(['exact','ruled','inv4','inv5'],['lowest','highest'],['none','fs'],[1,2,3]))
def job(c):
    mo,ti,di,ef=c
    render(mo,ti,di,ef,True,SC,f'{S}/combos/{mo}_{ti}_{di}_e{ef}')
if __name__=='__main__':
    with ThreadPoolExecutor(8) as ex: list(ex.map(job,COMBOS))
    for ef in (1,2,3):
        render('ruled','highest','fs',ef,False,SC,f'{S}/combos/nosprites_e{ef}')
    print('done',len(COMBOS))
