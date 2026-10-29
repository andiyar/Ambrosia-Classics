import sys,struct,pickle; sys.path.insert(0,'/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/docs/ferazel/tools')
import rsrc_census as r
d,m=r.parse("/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/Resources/Ferazel/Ferazel's Wand World Data.rsrc")
lv={}
def h(b,o): return struct.unpack('>h',b[o:o+2])[0]
for rid,name,b in m['Mlvl']:
    u=[]
    pb=h(b,0x284c); pb=5000 if pb<1 else pb; u.append(('PICT',pb,'PxBack .LoadPxBackTileset'))
    pm=h(b,0x284e)
    if pm: u+= [('PICT',pm,'PxMid .LoadPxMidTileset'),('PICT',pm+1,'PxMid mask .LoadPxMidTileset')]
    fg=h(b,0x2850) or 181; u.append(('PICT',fg,'FG+FGwater .LoadFGTileset/.LoadFGWaterTileset'))
    bg=h(b,0x2852) or 180; u.append(('PICT',bg,'BG .LoadBGTileset'))
    pt=h(b,0x2856); pt=206 if pt<1 else pt; u.append(('PICT',pt,'FG pattern .LoadFGPatternTileset'))
    u.append(('clut',h(b,0x285c) or 201,'level CLUT .SetupLevel'))
    u.append(('clut',h(b,0x285e) or 202,'level+base CLUT .SetupLevel'))
    if h(b,0x2716): u.append(('PICT',h(b,0x2716),'parallax sprite .SetupLevel→.MTAddPxSprite'))
    if h(b,0x271c): u.append(('clut',h(b,0x271c),'alt CLUT .AltClutMod'))
    c=h(b,0x273c)
    if c: u+=[('PICT',c*10+4600,'chapter screen .ChapterScreen'),('clut',c+280,'chapter clut .ChapterScreen')]
    u.append(('music',h(b,0x284a),'level music .GameLoop→.SetAIFFMusic'))
    lv[rid]=(name,u)
pickle.dump(lv,open('lv.pkl','wb'))
for k in sorted(lv): print(k,[(t,i) for t,i,_ in lv[k][1]])
