import sys,struct; sys.path.insert(0,'/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/docs/ferazel/tools')
import rsrc_census as r
d,m=r.parse('/Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/Resources/Ferazel/Ferazel\'s Wand World Data.rsrc')
F={'music':0x284a,'pxback':0x284c,'pxmid':0x284e,'fg':0x2850,'bg':0x2852,'pat':0x2856,'clutL':0x285c,'clutLB':0x285e,'pxspr':0x2716,'altclut':0x271c,'chap':0x273c,'ownsnd':0x26d0,'pxmidOn':0x3268,'flame':0x2722,'arena':0x2724}
print('id\tname\t'+'\t'.join(F))
for rid,name,b in sorted(m['Mlvl'],key=lambda x:x[0]):
    v=[]
    for k,o in F.items():
        v.append(str(b[o]) if k=='ownsnd' else str(struct.unpack('>h',b[o:o+2])[0]))
    print(f'{rid}\t{name}\t'+'\t'.join(v))
