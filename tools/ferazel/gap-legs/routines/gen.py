import csv,json,re,sys
S='/private/tmp/claude-504/-Users-andiyar-Developer-Ambrosia-Classics/3bba0f30-b169-412b-825f-0332f01d5b6b/scratchpad/'
G='/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/'
rows=list(csv.reader(open(G+'docs/ferazel/gap-ledger/routines.tsv'),delimiter='\t'))[1:]
calls=json.load(open(S+'rt/callers.json'))
exec(open(S+'rt/overrides.py').read())   # defines OV: name -> (status, why, reach, conf, note)
L14={'Walker','Crawler','Roach','Bat','Blob','Frog'}
P5_OFF={'Gremlin','Floater','Salamander','Crab','EnemyShot','Geyser','Swarm','Insect'}
P6={'Dillo','Warrior','Demon','Chief','Wizard','Xichra'}
LIB=('.MT_','._MT_','.Atomic','.Memory','.Queue','.StringGetLength','.StringCopySafe','.StringAppend','.StringFromNumber',
     '.StringFormatSafe','._String','.P2CStringCopy','.Thread','._Thread','.Mutex','._Mutex','.Timer','._MacOS','.Platform',
     '.SystemSetQuitProc','.DisplayManager','.MyDMIterator','.GetD3','.SetD3','.SB','.SL','.pcstrcat','.pnumcat','.MetroNub','.Debug')
MATH={'pow','cos','sin','Random','Fix2Long','BitSet','BitTst'}
out=[]
def cls_of(n):
    for c in sorted(L14|P5_OFF|P6,key=len,reverse=True):
        if c in n: return c
    if 'Goblin' in n: return 'Walker'
    return None
for a,n,src,cites,deff,files in rows:
    cites=int(cites);deff=int(deff)
    cl=calls.get(n,{}).get('callers',[])
    if n in OV:
        st,why,reach,conf,note=OV[n]
    elif not n.startswith(('.','_','FUN_')):
        if n in MATH: st,why,reach,conf,note='absorbed','Toolbox math/bit glue','n/a','HIGH','Foundation/Swift arithmetic'
        else: st,why,reach,conf,note='out of scope','Mac Toolbox import stub','n/a','HIGH',('port uses a platform equivalent; cited %d'%cites if cites else 'system glue')
    elif n.startswith(LIB):
        if cites: st,why,reach,conf,note='absorbed','runtime library (monitor/gamma/memory toolkit)','n/a','MED','cited %d (%s)'%(cites,files[:60])
        else: st,why,reach,conf,note='out of scope','runtime library: display/thread/queue/string/timer plumbing','n/a','HIGH','no game logic'
    elif n.startswith('FUN_') and int(a,16)>=0x10090478:
        st,why,reach,conf,note='out of scope','library/Sound Tool/runtime helper','n/a','MED','callers: '+','.join(cl[:3])
    else:
        c=cls_of(n)
        if c and re.match(r'\.(Setup|Handle|Hit|Kill|Init|HitTile)?',n) and not (cites and re.match(r'\.(Init|Setup)',n) and c in L14):
            if c in L14: st,why,reach,conf,note='not built','phase 5 (enemy Handle/Hit/Kill; class inert)','placed L1-4 (stands in Setup face)','HIGH','deliberate (a); callers: '+','.join(cl[:3])
            elif c in P6: st,why,reach,conf,note='not built','phase 6 (boss)','no (not placed L1-4)','HIGH','callers: '+','.join(cl[:3])
            else: st,why,reach,conf,note='not built','phase 5 (enemy class not placed in L1-4)','no','HIGH','callers: '+','.join(cl[:3])
        elif cites and not deff:
            st,why,reach,conf,note='built','cited %d (%s)'%(cites,files[:70]),'—','MED','classified by citation'
        else:
            st,why,reach,conf,note='UNREVIEWED','','','',''
    out.append((a,n,st,why,reach,conf,note))
w=open(S+'out-routines.tsv','w')
w.write('address\tname\tstatus\tphase/why\treachable-L1-4/front-end\tconfidence\tnote\n')
for r in out: w.write('\t'.join(r)+'\n')
from collections import Counter
print(Counter(r[2] for r in out))
print([r[1] for r in out if r[2]=='UNREVIEWED'])
