def unlz(src):
    out=bytearray(); i=0
    while True:
        b=src[i]
        if not b&0x80:
            b1=src[i+1]; i+=2
            n=(b1>>3)&3; out+=src[i:i+n]; i+=n
            L=(b1&7)+3; dist=1+((b&0x7f)|((b1&0xe0)<<2))
        elif not b&0x40:
            b1=src[i+1]; b2=src[i+2]; i+=3
            n=b2&3; out+=src[i:i+n]; i+=n
            L=(b1&0x1f)+3; dist=1+(((b2&0xfc)<<7)|(b&0x3f)|((b1&0xe0)<<1))
        elif not b&0x20:
            n=((b&0xf)+1)*4 if not b&0x10 else b&0xf
            out+=src[i+1:i+1+n]; i+=1+n; continue
        elif not b&0x10:
            out+=bytes([src[i+1]])*((b&0xf)+3); i+=2; continue
        elif not b&0x08:
            out+=bytes([src[i+2]])*(src[i+1]+3); i+=3; continue
        else:
            return bytes(out), i+1
        s=len(out)-dist
        for k in range(L): out.append(out[s+k])
