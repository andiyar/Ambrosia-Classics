import pickle,re,collections
rows=[r.split('\t') for r in pickle.load(open('rows.pkl','rb'))]
pl_all=collections.defaultdict(set)
for l in open('/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/docs/ferazel/gap-ledger/placements-all.tsv'):
    x=l.split('\t')
    if x[0]!='level': pl_all[int(x[1])].add(int(x[0]))
PH5={'Walker','Crawler','Roach','Bat','Blob','Frog','Gremlin','Salamander','Dillo','Floater','Crab','EnemyShot'}
PH6={'Warrior','Wizard','Chief','Demon','Xichra'}
out=[]
for f,t,rid,name,users,reach,port,cls,conf,note in rows:
    rid=int(rid); U=users
    def P(s): return s
    # ---- port overrides
    if t=='snd ' and ('.InitSounds' in U or '.InitAppGlobals' in U):
        port='yes SoundSlots.table / FerazelDriver.loadSounds (SoundBank decodes every snd)'; 
    elif re.search(r'^(PxBack|PxMid|FG|BG|level|parallax|alt)|\| (PxBack|PxMid|FG|BG|level)',U):
        port='yes LevelHeader fields → TileSets / ColorLUT (header-driven)'
    elif 'ChapterScreen' in U or 'chapter' in U:
        port='yes StageScreens chapter formula (n*10+0x11f8, clut n+0x118)'
    elif t=='PICT' and 4901<=rid<=4915:
        port='yes MainMenu.highlightPicture/normalPicture (0x1324+n)'
    elif t=='PICT' and rid in (4925,4935,134):
        port='no — replica menu is always 640×480 (MainMenu.swift:8)'; cls='d'; note='original shows these only when the screen is not 640×480'
    elif t=='PICT' and rid==4985:
        port='no — InputSprocket forced off (DeathScreen.swift:17)'; cls='d'; note='ISp keyboard cursor; original also off without ISp'
    elif t=='PICT' and (4970<=rid<=4981 or 172<=rid<=177):
        port='yes DeathScreen (0x1369/0x1373+n, 0xac…0xb1)'
    elif 'Mcnv' in U and 'portrait' in U:
        port='yes ConversationRun (portrait id read from Mcnv)'
    elif t=='PICT' and rid in (145,146,4804):
        port='yes Dialog picItem (DialogViews / DialogWindow)'
    elif t=='PICT' and rid==8003:
        port='no — loaded, never read (MapRenderer.swift:19)'; cls='n'; note='original loads into _DAT_100a0c40, no reader'
    elif t=='PICT' and rid==1600:
        port='no'; cls='n'; note='.PreparePaintFrame loads into _DAT_100a0104, no reader (written only)'
    elif t=='PICT' and rid==4921: port='yes Pause.banner'
    elif t=='PICT' and rid in (8001,8002,8004,8000): port='yes FrontFaceSet / MapRenderer'
    elif t=='PICT' and rid in (811,812,813,821,830,801,802,806,810,822): port='yes LightFaces.callSites'
    elif t=='clut' and rid==131: port='no'; cls='n'; note='loaded twice at boot, never read (rendering-omnipx-titles §4.2)'
    elif t=='clut' and rid==4000: note='loaded by .InitConversation, never read (conversations-mcnv §6.1)'
    elif t=='PICT' and rid==7000 and 'World' in f: port='no (port draws the app-fork 7000 via .frontEnd)'; cls='n?'; conf='MED'; note='World Data and app 7000 differ (md5); original closes the world file after Mmap → app copy shown [MED]'
    elif t=='PICT' and rid==7000: port='yes WorldMapRun.mapPicture (.frontEnd chain → this app copy)'
    elif t=='PICT' and rid in (206,207) and 'Sprites' in f: port='n/a shadowed'; cls='n'; note='level chain finds the Backgrounds copy first; this Sprites copy is never served'
    elif t=='PICT' and rid in (600,601) and 'Backgrounds' in f: note='PxBack of levels 5/25 (level chain); the map 600/601 are the Sprites copies'
    elif t=='PICT' and rid in (600,601) and 'Sprites' in f: port='yes MapRenderer (ReInitWorldMapGraphics)' if port.startswith(('yes','weak')) else port
    elif t=='PICT' and rid==265 and 'Sprites' in f: cls='n'; port='n/a shadowed'; note='identical to Backgrounds 265'
    if port.startswith('weak-literal'):
        conf='MED'; 
    # ---- class
    if cls in ('c?','used','?') or cls.startswith(('a','n (boot')):
        if not U: cls='n'
        elif port.startswith('yes'): cls='used'
        else:
            reachL=reach
            inscope=bool(re.search(r'(^|;)(front end|map|boot→|L1-4 \(|L\d)',reachL)) and 'L1-4?' not in reachL
            cl=re.findall(r'\.Init(\w+)Sprite',U)
            c=cl[0] if cl else None
            levs=pl_all.get(rid,set())
            if 'cached' in reachL:
                if levs and min(levs)<=4: cls='c?'; note=(note+'; ' if note else '')+f'type {rid} placed L{sorted(levs)}'
                elif c in PH6: cls='a6'
                elif c in PH5: cls='a5'
                elif levs: cls='a (later levels %s)'%sorted(levs)[:6]
                else: cls='d?'; conf='MED'; note=(note+'; ' if note else '')+'cached sheet; no placement of this type id on any level; need-flag owner not resolved'
            elif inscope and port.startswith('weak'):
                cls='used?'
            elif inscope: cls='c?'
            elif c in PH6: cls='a6'
            elif c in PH5: cls='a5'
            elif 'later' in reachL: cls='a (later levels)'
            elif 'boot' in reachL: cls='n (boot load, never displayed in scope)'
    out.append([f,t,str(rid),name,U,reach,port,cls,conf,note])
pickle.dump(out,open('rows2.pkl','wb'))
c=collections.Counter((r[1],r[7]) for r in out)
for k in sorted(c): print(k,c[k])
