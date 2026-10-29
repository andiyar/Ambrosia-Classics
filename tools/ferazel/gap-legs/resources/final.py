import pickle,collections
OUT='/private/tmp/claude-504/-Users-andiyar-Developer-Ambrosia-Classics/3bba0f30-b169-412b-825f-0332f01d5b6b/scratchpad/out-resources.tsv'
rows=pickle.load(open('rows2.pkl','rb'))
HAND={  # (type,id): (users, reach, port, cls, conf, note)
('DLOG',6900):('.PreferencesDialog @100760dc (+DITL 6901-6903 via .SwitchPrefsPanel AppendDITL)','front end/L1-4 (Options)','yes PrefsDialogView / WinPrefsDialog','used','HIGH',''),
('Mwld',0):('.OpenDefaultWorld @10048fb8','boot','yes WorldFile.swift','used','HIGH',''),
('DLOG',200):('.GenericMessage @1003cf04 (.ReportDialog)','front end/L1-4','yes FerazelDialogs.report','used','HIGH',''),
('DLOG',201):('.DebugMessage @1003d0f0 (alloc-failure debug path)','never (out-of-memory only)','no','b','HIGH','memory-failure report only'),
('DLOG',202):('.ConfirmAbortGameDialog @10006784','front end/map/L1-4','yes FerazelDialogs.confirm','used','HIGH',''),
('DLOG',400):('.WarpDialog @1000a4c8 (NewGame, debug flag _DAT_100a0064 only)','never (debug build flag)','no','d','HIGH','world-data-format §: debug-only warp'),
('DLOG',600):('.Credits → .DoAboutDialog(600,4803)','front end (Credits)','yes CreditsDialog / WinCreditsDialog','used','HIGH',''),
('DLOG',1003):('.PromptPutFile → CustomPutFile (save game)','L1-4 (save point)','partial — native save panel, DITL 1003 item 13 text only (SaveGame.swift:135; D35 known deviation)','used','HIGH','D35 deviation'),
('DLOG',1300):('.ResSwitchDialog @1000f7b0','never in replica (design §7.1)','no','d','HIGH','resolution switch; replica fixed 640×480'),
('DLOG',1500):('.PromptGetFile → CustomGetFile(dlg 0x5dc) (Restore Game)','front end','no — native open panel (D35 known deviation)','used','HIGH','D35 deviation'),
('DLOG',1600):('.main @1000ffc0 GetNewDialog(0x640) "CD Request"','never with shipped data present','no','b','HIGH','shown only when the CD check fails'),
('MBAR',128):('.LoadMenuBar @10030194','boot','yes FerazelMenus','used','HIGH',''),
('MENU',128):('.LoadMenuBar','boot','yes FerazelMenus','used','HIGH',''),('MENU',129):('.LoadMenuBar','boot','yes FerazelMenus','used','HIGH',''),('MENU',130):('.LoadMenuBar','boot','yes FerazelMenus','used','HIGH',''),
('WIND',128):('.MTInit @10032160 GetNewCWindow','boot','yes (game window; HIGH for id only)','used','MED',''),
('STR#',500):('.HitPlayerSprite sign text (.SimpleConv)','L1-4 (signs L1/L2)','yes StringList','used','HIGH',''),
('STR#',1000):('.InitMapLevelNames @1007ad84','map','yes StringList / WorldMapRun','used','HIGH',''),
('STR#',300):('no GetIndString site','never','no','n','MED','QuickTime warning strings; no reader in dump'),
('STR#',400):('no GetIndString site','never','no','n','MED','fatal error strings; no reader in dump'),
('Mmap',200):('.OpenDefaultWorldMap @10048940','map','yes WorldMap.swift / WorldMapRun','used','HIGH',''),
('Msct',0):('Finder signature','out of scope','n/a','n','HIGH',''),
('Tune',6900):('none (no GetResource Tune)','never','no','n','HIGH','rendering-omnipx-titles §6.5'),
('TEXT',128):('none','never','no','n','HIGH','"Palette EC2" editor note'),
('wctb',128):('Window Manager (WIND 128 colour table, implicit)','boot','no (shell window)','n','MED','implicit; no visible effect'),
}
for i in range(600,606): HAND[('CNTL',i)]=('DITL 6900-6903 control items (Options popups)' if i<605 else 'none (CNTL 605 referenced by no DITL)','front end (Options)' if i<605 else 'never','yes FerazelCarbonDialog / DialogWindow (ControlTemplate)' if i<605 else 'no','used' if i<605 else 'n','HIGH','604 Px popup always 2' if i==604 else '')
HAND[('CNTL',128)]=('none (old graphics popup)','never','no','n','HIGH','')
for i in range(600,606): HAND[('MENU',i)]=('CNTL %d menu'%i if i<605 else 'none (CNTL 605 points at MENU 601)','front end (Options)' if i<605 else 'never','yes via ControlTemplate.menuID' if i<605 else 'no','used' if i<605 else 'n','HIGH','')
DITLU={200:'DLOG 200',202:'DLOG 202',600:'DLOG 600',6900:'DLOG 6900',6901:'prefs panel 1',6902:'prefs panel 2 (Controls)',6903:'prefs panel 3 (Sound)',1003:'CustomPutFile',1500:'CustomGetFile'}
for i,u in DITLU.items(): HAND[('DITL',i)]=(u,'front end/L1-4','yes DialogItemList' if i not in (1500,) else 'no (D35 native panel)','used','HIGH','')
HAND[('DITL',201)]=('DLOG 201 debug','never (OOM)','no','b','HIGH','');HAND[('DITL',400)]=('DLOG 400 warp (debug)','never','no','d','HIGH','');HAND[('DITL',1300)]=('DLOG 1300','never in replica','no','d','HIGH','');HAND[('DITL',1600)]=('DLOG 1600 CD request','never with data present','no','b','HIGH','')
for i in (200,202,600,1600,6900): HAND[('dctb',i)]=('DLOG %d colour table'%i,'front end/L1-4','yes contentColor(dctb:)' if i!=1600 else 'no','used' if i!=1600 else 'b','HIGH','')
lines=[]
cnt=collections.defaultdict(collections.Counter)
for f,t,rid,name,users,reach,port,cls,conf,note in rows:
    k=(t,int(rid))
    if k in HAND: users,reach,port,cls,conf,note=HAND[k]
    elif t in ('DLOG','DITL','dctb','ALRT','MENU','CNTL') and cls=='n':
        users=users or 'no GetNewDialog/Alert/AppendDITL site'; reach='never'; port='no'; note=note or 'unused dialog-family resource (no code site)'
    if t=='clut' and rid=='260': cls='a (end of game: .Victory)'; reach='later (victory)'
    if t in ('PICT','clut') and rid=='198': cls='a (flame levels 52/55)'; reach='boot; drawn only on flame levels 52/55'
    if t=='PICT' and int(rid) in (159,161,162) or (t=='PICT' and 4600<=int(rid)<=4607): 
        if cls!='used': cls='a (end of game)'
    if cls=='n' and not users: users='no reference in either dump'; reach='never'
    lines.append([f,t,rid,name,users,reach,port,cls,conf,note])
# music
lvmusic={1:[1,4],2:[3],3:[2]}
import pickle as P; lv=P.load(open('lv.pkl','rb'))
tracks=collections.defaultdict(list)
for k,(n,u) in lv.items():
    for t,i,why in u:
        if t=='music': tracks[i].append(k)
import os
for fn in sorted(os.listdir("/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/Resources/Ferazel/Ferazel's Wand Music")):
    n=int(fn); L=sorted(tracks.get(n,[]))
    users=[]; reach=[]; port='no'; cls='n'; note=''
    if L: users.append('Mlvl+0x284a of levels %s → .GameLoop .SetAIFFMusic'%L); port='yes LevelRun (h.music) / MusicTrack'
    if n==24: users.append('.main/.NewGame/.ContinueGame SetAIFFMusic(24)'); reach.append('front end'); port='yes BootSequence.bootTrack / NewGame.menuTrack'
    if n==25: users.append('.ShowWorldMap SetAIFFMusic(25)'); reach.append('map'); port='yes WorldMapRun.mapTrack'
    if n==29: users.append('.Victory SetAIFFMusic(29)'); reach.append('later (victory)')
    if n==30: users.append('.GameLoop boss-arena override (hdr 0x2724)'); reach.append('later (boss levels 5,18,25,55)'); port='yes LevelRun:511 (0x1e)'
    inl=[x for x in L if x<=4]
    if inl: reach.append('L'+','.join(map(str,inl)))
    elif L: reach.append('later levels %s'%L)
    if not users: users=['none (never requested; n−1 fallback only for 21/27 which are absent)']; reach=['never']
    if port.startswith('yes'): cls='used'
    elif n==29: cls='a (end of game)'; port='no constant 29 found (static)'
    elif L or n==30: cls='a (later levels)'
    lines.append(['Music',"AIFC",fn,'',' ; '.join(users),';'.join(reach),port,cls,'HIGH',note])
# requested but absent
ABS=[('PICT','751-755,757-767,769,770,772-776','.InitPlayerSprite held-item singles 0x2ee+i','boot; held items 1-5,7-17,19,20,22-26 would draw nil','yes BootFaces (as asked; loads none)','b','HIGH','Load1EncFaceFromPICT returns nil; any draw of these faces = nil face in the original too'),
('PICT','1500-1503','.InitCrawlerSprite 0x5dc+i','boot','yes BootFaces (loads none)','b','HIGH','absent in every file'),
('PICT','1489','.InitBackgroundSprite cache 0x5c8+9','placed on no level','yes SetupFaces.backgroundSheets (placeholder)','d','HIGH',''),
('PICT','1790-1791','.InitFloaterSprite','later (Floater, Phase 5)','—','a5','HIGH','absent'),
('PICT','2718-2729','.InitBackgroundSprite cache 0xa8c+i (plants)','placed types?','—','d','MED','check placements-all for types 2718..2729'),
('PICT','2805-2807','.InitBoxSprite cache 0xaf5+i','—','—','d','MED',''),
('PICT','2908-2909','.InitBoxSprite 0xb56+i signs','boot','yes BootFaces (loads none)','b','HIGH',''),
('PICT','2950,2966-2969','.InitBoxSprite cache 0xb86+i NPCs','—','—','d','MED',''),
('PICT','3109','.InitBonusSprite 0xc1c+9','boot','yes BootFaces','b','HIGH',''),
('PICT','3200','.InitBonusSprite 0xc80+0 (item 0 face)','boot','yes BootFaces','b','HIGH','item 0 picture'),
('snd ','199','.TrackClickOnCommandButton SndPlay(GetResource(snd 199)) after >9 slide-outs','front end','yes (silent, F1a BC19)','b','HIGH','no fork holds snd 199'),
]
pl=collections.defaultdict(set)
for l in open('/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/docs/ferazel/gap-ledger/placements-all.tsv'):
    x=l.split('\t')
    if x[0]!='level': pl[int(x[1])].add(int(x[0]))
for t,ids,u,reach,port,cls,conf,note in ABS:
    if ids in ('2718-2729','2805-2807','2950,2966-2969'):
        ex=[]
        for part in ids.split(','):
            a,b=(part.split('-')+[part])[:2] if '-' in part else (part,part)
            for i in range(int(a),int(b)+1):
                if pl.get(i): ex.append(f'{i}:L{sorted(pl[i])}')
        reach='placed: '+(' '.join(ex) if ex else 'none'); 
        if any(min(pl[int(e.split(':')[0])])<=4 for e in ex): cls='c?'
    lines.append(['(absent)',t,ids,'',u,reach,port,cls,conf,'REQUESTED BUT NOT IN ANY FILE; '+note])
with open(OUT,'a') as fo:
    fo.write('file\ttype\tid\tname\toriginal-user\treached-in-scope\tport-asks\tclass\tconfidence\tnote\n')
    for l in lines: fo.write('\t'.join(str(x).replace('\t',' ') for x in l)+'\n')
for l in lines: cnt[l[1]][l[7]]+=1
for t in sorted(cnt): print(t,dict(cnt[t]))
