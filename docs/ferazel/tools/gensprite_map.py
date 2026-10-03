# Mechanical transcription of .GenerateSprite @ 10003478 (handler selection only).
# returns (setup_name or None, idle_flag)  idle_flag True => AddIdleSprite (activates near camera), False => MTNewSprite now
N={0x1009ff38:'Bonus',0x1009ff34:'Box',0x1009ff30:'Background',0x1009ff2c:'Platform',0x1009ff28:'Button',
 0x1009ff24:'Walker',0x1009ff20:'Crawler',0x1009ff1c:'Roach',0x1009ff18:'Blob',0x1009ff14:'Bat',0x1009ff10:'Gremlin',
 0x1009ff0c:'Floater',0x1009ff08:'Frog',0x1009ff04:'Salamander',0x1009ff00:'Warrior',0x1009fefc:'Wizard',
 0x1009fef8:'Effect',0x1009fef4:'Dillo',0x1009fef0:'Crab',0x1009feec:'Chief',0x1009fee8:'Demon',0x1009fee4:'Xichra',0x1009fee0:'Rope'}
def gen(t, rec8neg=False):
    B=0x1009ff34; idle=True; iv=0x1009ff38
    s=t
    if (((t-0x41f)&0xffff)<2) or (((t-0x422)&0xffff)<2) or s==0x517 or (0x50a<=s<=0x513):
        return N[0x1009ff38],True   # iVar6 stays _DAT_1009ff38 (initial), bVar1 true
    if ((t-0x438)&0xffff)<2: return N[B],False
    iv=0x1009ff30
    if s==0x4b8: return N[iv],True
    if 0x532<=s<=0x53b: return N[0x1009ff38],False
    if 0x53c<=s<=0x546: return N[0x1009ff38],False
    iv=0x1009ff38
    if s==0x51b: return N[iv],True
    if 0x578<=s<=0x595: return N[0x1009ff2c],False
    if 0x5a0<=s<=0x5a9: return N[B],True
    if 0x5aa<=s<=0x5b3: return N[B],False
    if 0x5b4<=s<=0x5bd: return N[B],True   # (0x5ba also adds idle 0x5bb)
    if 0x5be<=s<=0x5c7: return N[B],True
    if 0x5c8<=s<=0x5d1: return N[0x1009ff30],False
    if 0x47e<=s<=0x487: return N[0x1009ff30],True
    if 0x5d2<=s<=0x5db: return N[B],False
    # big chain, default iv=B
    if ((t-0x424)&0xffff)<3 or s==0x429 or (0x4e2<=s<=0x4ff): return N[B],True
    if 0x528<=s<=0x531: return N[0x1009ff28],True
    if 2000<=s<=0x801: return N[0x1009ff38],True
    if ((t-0x42e)&0xffff)<3 or s==0x433 or s==0xbfe: return N[B],True
    if 0x442<=s<=1099:
        return N[0x1009ff30], (not rec8neg)
    if 0x6a4<=s<=0x72f:
        if s<=0x6ad: return N[0x1009ff24],True
        if s==0x6b0: return N[0x1009ff20],True
        if s==0x6b8: return N[0x1009ff1c],True
        if 0x6c2<=s<=0x6cb: return N[0x1009ff18],True
        if 0x6cc<=s<=0x6d5: return N[0x1009ff14],True
        if 0x6d6<=s<=0x6df: return N[0x1009ff24],True
        if 0x6e0<=s<=0x6e9: return N[0x1009ff24],True
        if 0x6ea<=s<=0x6f3: return N[0x1009ff10],False
        if 0x6f4<=s<=0x6fd: return N[0x1009ff0c],True
        if 0x6fe<=s<=0x707: return N[0x1009ff0c],True
        if 0x708<=s<=0x711: return N[0x1009ff08],True
        if 0x712<=s<=0x71b: return N[0x1009ff04],True
        if 0x71c<=s<=0x725: return N[0x1009ff00],False
        if 0x725<s<0x730: return N[0x1009fefc],True
        return None,True   # 0x6ae,0x6af,0x6b1..0x6b7,0x6b9..0x6c1: iVar6=iVar5=0 => nothing
    iv=0x1009fef8
    if s==0x726: return N[iv],True
    if ((t-0x730)&0xffff)<4: return N[0x1009ff30],False
    if 0x73a<=s<=0x73e: return N[0x1009ff14],True
    if 0x73f<=s<=0x743: return N[0x1009ff30],True
    if 0x744<=s<=0x74d: return N[0x1009ff14],True
    if 0x74e<=s<=0x757: return N[0x1009fef4],True
    if 0x762<=s<=0x76b: return N[0x1009fef0],True
    if 0x76c<=s<=0x775: return N[0x1009ff30],True
    if 0x776<=s<=0x77f: return N[0x1009feec],True
    if 0x780<=s<=0x789: return N[0x1009fee8],False
    if 0x7c6<=s<=1999: return N[0x1009fee4],False
    if 0xa8c<=s<=0xaef: return N[0x1009ff30],True
    if 0xaf5<=s<=0xb35: return N[B],True
    if 0xb36<=s<=0xb49: return N[B],True
    if 0xb4a<=s<=0xb53: return N[0x1009ff30],False
    if 0xc08<=s<=0xc11: return N[0x1009ff30],True
    if 0xc12<=s<=0xc1b: return N[B],True
    if ((t-0xb54)&0xffff)<2: return N[0x1009ff30],True
    if 0xb56<=s<=0xb5d: return N[B],True
    if ((t-0xb5e)&0xffff)<2: return N[B],True
    if s==0x51c or 0xb68<=s<=0xb85: return N[B],True
    if 0xb87<=s<=2999: return N[B],True
    if 3000<=s<=0xbcb: return N[0x1009ff30],True
    if 0xbcc<=s<=0xbdf: return N[0x1009fee0],True
    if s==0xbea: return N[0x1009ff38],True
    if s==0xbf4: return N[0x1009ff30],True
    if 0xc1c<=s<=0xc25: return N[0x1009ff38],True
    if 0xc80<=s<=0xcb0: return N[0x1009ff38],True
    if s==0xcb1: return N[0x1009ff30],True
    return None,True
