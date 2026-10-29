import re,sys,collections
G='/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/ghidra/ferazel/'
# loader -> (kind, argindex)
L={'_LoadEncFaceSetFromPICT':('PICT',0),'_CacheEncFaceSetFromPICT':('PICT',1),'_Load1EncFaceFromPICT':('PICT',0),
'_Load1LightFaceFromPICT':('PICT',0),'_Load1PlainFaceFromPICT':('PICT',0),'_Load1FlipFaceFromPICT':('PICT',0),
'_LoadPlainFaceSetFromPICT':('PICT',0),'_LoadFlipFaceSetFromPICT':('PICT',0),'_LoadEncWaterFaceSetFromPICT':('PICT',0),
'GetPicture':('PICT',0),'_MTGetandDrawPICTResInRect':('PICT',0),'_DrawPICTToBackScreen':('PICT',0),
'GetCTable':('clut',0),'GetNewDialog':('DLOG',0),'FUN_10091748':('snd ',0),'_SetAIFFMusic':('music',0),
'GetIndString':('STR#',1),'Alert':('ALRT',0),'StopAlert':('ALRT',0),'NoteAlert':('ALRT',0),'CautionAlert':('ALRT',0),
'GetResource':('RES',0),'Get1Resource':('RES',0),'GetMenu':('MENU',0),'GetNewMBar':('MBAR',0),'GetNewControl':('CNTL',0),'GetNewCWindow':('WIND',0),'GetNewWindow':('WIND',0),'GetCIcon':('cicn',0),'GetMenuHandle':('MENU',0),'_LoadCachedSpriteFaces':('X',0),'_DrawPicInGWorld':('PICT',0),'_DrawPicInRect':('PICT',0),'_CreditScreen':('PICT',0),'_DoAboutDialog':('PICT',1),'_Cache1EncFaceFromPICT':('PICT',1)}
def splitargs(s):
    out=[];depth=0;cur=''
    for ch in s:
        if ch=='(' : depth+=1
        if ch==')':
            if depth==0: out.append(cur); return out
            depth-=1
        if ch==',' and depth==0: out.append(cur);cur='';continue
        cur+=ch
    out.append(cur); return out
def num(a):
    a=a.strip()
    a=re.sub(r'^\((?:short|int|uint|ushort|undefined\d?)\)','',a).strip()
    try: return int(a,0) if not a.startswith('0x') else int(a,16)
    except: return None
pat=re.compile(r'(?:\.glue::|\.debug::)?\b('+'|'.join(map(re.escape,L))+r')\(')
for fn in ['Ferazel_pef.decompiled.c','Ferazel_handlers.decompiled.c']:
    func='?'; lines=open(G+fn,errors='replace').read().split('\n')
    for i,l in enumerate(lines):
        m=re.match(r'// ==== (.*) ====',l)
        if m: func=m.group(1); continue
        for m in pat.finditer(l):
            name=m.group(1)
            if re.match(r'\s*(undefined|void|int|short)',l) and ' '+name in l and '.debug::' in l: continue
            rest=l[m.end():]
            if rest.count('(')<rest.count(')')-0 and False: pass
            j=i
            while rest.count('(')>=rest.count(')') and j<i+4: j+=1; rest+=lines[j]
            args=splitargs(rest)
            kind,ai=L[name]
            a=args[ai] if ai<len(args) else ''
            v=num(a)
            if name in('GetResource','Get1Resource'):
                t=num(args[0]); kind=t.to_bytes(4,'big').decode('mac_roman') if t is not None else '?'
                v=num(args[1]) if len(args)>1 else None; a=args[1] if len(args)>1 else ''
            print('\t'.join([fn[:3],str(i+1),func,name,kind,str(v) if v is not None else 'EXPR:'+a.strip()[:60]]))
