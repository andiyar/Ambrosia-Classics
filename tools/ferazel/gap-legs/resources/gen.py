import sys,re,pickle,collections,struct,glob
sys.path.insert(0,'/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/docs/ferazel/tools')
import rsrc_census as r
R='/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/Resources/Ferazel/'
OUT='/private/tmp/claude-504/-Users-andiyar-Developer-Ambrosia-Classics/3bba0f30-b169-412b-825f-0332f01d5b6b/scratchpad/out-resources.tsv'
lit=pickle.load(open('lit.pkl','rb')); lv=pickle.load(open('lv.pkl','rb'))
# --- original users
use=collections.defaultdict(lambda: collections.defaultdict(set))   # type->id->set(user)
cached=set()
for l in open('calls.tsv'):
    f,n,fn,name,t,v=l.rstrip('\n').split('\t')
    if v.startswith('EXPR'): continue
    if t in ('RES','?'): continue
    use[t][int(v)].add(fn.split(' @')[0]+' @'+fn.split('@ ')[1] if '@' in fn else fn)
    if name.startswith('_Cache'): cached.add(int(v))
for l in open('comp.tsv'):
    t,rg,fn=l.rstrip('\n').split('\t'); step=1
    if '/' in rg: rg,s=rg.split('/'); step=int(s)
    a,b=rg.split('-') if '-' in rg else (rg,rg)
    for i in range(int(a),int(b)+1,step):
        use[t][i].add(fn)
for a,b in [(1490,1493),(2805,2849),(2850,2869),(2870,2885),(2920,2928),(2950,2969),(3080,3087),(3000,3005),(1480,1489),(2700,2729)]:
    cached.update(range(a,b+1))
LVL=collections.defaultdict(lambda: collections.defaultdict(set))   # type->id->set(level)
for k,(nm,u) in lv.items():
    for t,i,why in u:
        use[t][i].add(why); LVL[t][i].add(k)
EXTRA={('PICT',145):'DITL 150/170/200-203/1300/1600 picItem (Dialog Manager)',('PICT',146):'DITL 6902/16902 picItem (Options > Controls panel)',
 ('PICT',140):'+DITL 160 picItem',('PICT',4804):'DITL 600 picItem (Credits dialog)',('PICT',160):'DITL 700 picItem (DLOG 700 Memo, never shown)',
 ('PICT',4020):'.SimpleConv sign portrait (.HitPlayerSprite 2902 sign)',('PICT',4001):'Mcnv portraits + .HandleKeys hint .SimpleConv',
 ('PICT',7000):'.ShowWorldMap world-map art (World Data + app both hold 7000)'}
for (t,i),s in EXTRA.items(): use[t][i].add(s)
# Mcnv portraits
d,mw=r.parse(R+"Ferazel's Wand World Data.rsrc")
MC_SCOPE={200,201,203,205,400}
for rid,n,b in mw['Mcnv']:
    for j in range(20):
        p=struct.unpack('>h',b[0x100+j*0x72a+0x70a:0x100+j*0x72a+0x70c])[0]
        if p: use['PICT'][p].add(f'Mcnv {rid} portrait (.DrawConvPic)'); LVL['PICT'][p].add('conv%d'%rid)
# --- classes
PH5={'Walker','Crawler','Roach','Bat','Blob','Frog','Gremlin','Salamander','Dillo','Floater','Crab','EnemyShot'}
PH6={'Warrior','Wizard','Chief','Demon','Xichra'}
PLACED={'Bonus','Box','Background','Button','Platform','Walker','Crawler','Roach','Blob','Bat','Frog','Rope','Player','PlayerShot','Effect'}
placedtypes=set()
for l in open('/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/docs/ferazel/gap-ledger/placements-1-4.tsv'):
    x=l.split('\t')
    if x[0]!='level': placedtypes.add(int(x[1]))
FE={'.DrawMainMenu':'front end','.TrackClickOnCommandButton':'front end','.Credits':'front end','.DoAboutDialog':'front end','.main':'front end (boot)',
 '.AskToContinue':'L1-4 (death screen)','.TrackClickOnCommandButtonDeath':'L1-4 (death screen)','.WandGlow':'L1-4 (death screen)','.Pause':'L1-4 (pause)',
 '.ShowWorldMap':'map','.ReInitWorldMapGraphics':'map','.InitMapFaces':'boot→map','.SetupLevel':'L1-4','.ContinueGame':'L1-4','.ChapterScreen':'L1-4 (chapter card)',
 '.InitAppGlobals':'boot','.InitGameGlobals':'boot→L1-4','.InitSprites':'boot→L1-4','.InitSounds':'boot→L1-4','.InitConversation':'boot→L1-4','.PreparePaintFrame':'L1-4 (first level start)',
 '.LoadCoolingMap':'boot (flame levels 52/55 only draw it)','.Victory':'later (end of game)','.CreditScreen via .Victory/.Credits':'later (end of game)','.SetupOmniPx':'later levels (OmniPx modes 1/2/5/6: L15,5,25,70)',
 '.NewGame':'front end','.GameLoop':'L1-4','.InitMapLevelNames':'map','.HitPlayerSprite':'L1-4','.GenericMessage':'front end/L1-4','.ConfirmAbortGameDialog':'front end/L1-4/map',
 '.PreferencesDialog':'front end/L1-4','.MTInit':'boot','.LoadMenuBar':'boot','.OpenDefaultWorld':'boot','.OpenWorld':'boot','.InitPrefs':'boot','.OpenSG':'front end'}
def initclass(fn):
    m=re.match(r'\.Init(\w+)Sprite',fn); return m.group(1) if m else None
def portq(i,strong_only=True):
    hits=[(loc,code) for loc,code in lit.get(i,[]) if '/Census/' not in loc]
    good=[loc for loc,code in hits if re.search(r'pict|PICT|snd|clut|Clut|CLUT|[Ss]heet|one\(|set\(|ones\(|single|[Ff]ace|[Pp]icture|music|[Tt]rack|load|Load|\bid\b|ids|[Ss]lot|portrait|Portrait',code)]
    return good, hits
rows=[]
def add(*c): rows.append('\t'.join(str(x) for x in c))
counts=collections.defaultdict(collections.Counter)
FINDER={'BNDL','FREF','ICN#','icl4','icl8','ics#','ics4','ics8','icns','SIZE','cfrg','vers','setl','tset','isap','VWCI'}
files=sorted(glob.glob(R+'*.rsrc'))
allres=[]
for f in files:
    fn=f.split('/')[-1]; d,m=r.parse(f)
    for t,L in m.items():
        for rid,n,b in L: allres.append((fn,t,rid,n))
allres.sort(key=lambda x:(x[1],x[2],x[0]))
def phase_of(users):
    for u in users:
        c=initclass(u)
        if c in PH6: return 'a6'
        if c in PH5: return 'a5'
    return None
for fn,t,rid,name in allres:
    if t in FINDER: counts[t]['out-of-scope']+=1; continue
    yield_=None
    users=use[t].get(rid,set()) if t in use else set()
    # resolution chain: skip copies shadowed? note duplicates
    reach=[]; cls=None; conf='HIGH'; note=''
    if t in ('PICT','clut','snd '):
        for u in users:
            key=u.split(' @')[0]
            if key in FE: reach.append(FE[key])
            c=initclass(u)
            if c:
                if rid in cached:
                    if rid in placedtypes: reach.append('L1-4 (cached; type placed)')
                    elif c in PLACED: reach.append('L1-4? (cached; class %s placed, need-flag per type not resolved)'%c); conf='MED'
                    else: reach.append('later levels (cached; class %s not placed in L1-4)'%c)
                else:
                    reach.append('boot' + (' (class placed L1-4)' if c in PLACED else ' (class %s not placed L1-4)'%c))
            if u.startswith(('PxBack','PxMid','FG','BG','level','alt','chapter','parallax')):
                L=LVL[t][rid]; inl=sorted(x for x in L if isinstance(x,int) and x<=4)
                reach.append('L'+','.join(map(str,inl)) if inl else 'later levels %s'%sorted(x for x in L if isinstance(x,int)))
            if re.match(r'Mcnv \d',u):
                mc=int(u.split()[1]); reach.append('L1-4 (conv)' if mc in MC_SCOPE else 'later levels (conv %d)'%mc)
            if u.startswith('DITL 6902'): reach.append('front end (Options)')
            if u.startswith('DITL 150'): reach.append('front end/L1-4 (DLOG 200/202)')
            if u.startswith('DITL 600'): reach.append('front end (Credits)')
            if u.startswith('.SimpleConv') : reach.append('L1-4 (sign L1,L2)')
            if u.startswith('.ShowWorld'): reach.append('map')
    good,hits=portq(rid)
    reach=sorted(set(reach))
    rs=';'.join(reach) if reach else ('never' if not users else '?')
    port=('yes ' + ','.join(sorted(set(g.split(':')[0].split('/')[-1]+':'+g.split(':')[1] for g in good))[:3])) if good else ('weak-literal '+','.join(h[0].split('/')[-1] for h in hits[:2]) if hits else 'no')
    inscope=any(x.startswith(('front','L1','L2','L3','L4','map','boot→','L1-4')) and not x.startswith('L1-4?') for x in reach)
    maybe=any(x.startswith('L1-4?') for x in reach)
    if not users: cls='n'; rs='never'
    elif good: cls='used'
    elif inscope: cls='c?'
    elif maybe: cls='c?'; conf='MED'
    elif any('later' in x for x in reach): cls='a'+('6' if phase_of(users)=='a6' else '5/6')
    elif phase_of(users): cls=phase_of(users)
    elif any(x.startswith('boot') for x in reach): cls='n (boot-only, unread in scope)'
    else: cls='?'
    add(fn.replace("Ferazel's Wand",'FW'),t,rid,name or '',' | '.join(sorted(users))[:200],rs,port[:160],cls,conf,note)
pickle.dump(rows,open('rows.pkl','wb'))
print(len(rows))
