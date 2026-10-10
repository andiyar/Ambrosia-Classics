from common import *
import numpy as np, json
from PIL import Image, ImageDraw
m=json.load(open(S+'/match.json'))
cal=lambda a:(255*(a/255.0)**0.76).round().astype(np.uint8)
BEST='exact_highest_fs_e1'; CUR='ruled_highest_fs_e1'
def lab(im,txt):
    d=ImageDraw.Draw(im); d.rectangle([0,0,len(txt)*6+8,14],fill=(0,0,0)); d.text((4,2),txt,fill=(255,255,0)); return im
os.makedirs(S+'/out',exist_ok=True); paths=[]
for t,dd in m.items():
    s=f"{dd['h']}_{dd['v']}"; v=vframe(float(t)); b=load_rgb(f'{S}/combos/{BEST}/{s}.rgb'); c=load_rgb(f'{S}/combos/{CUR}/{s}.rgb')
    W=Image.new('RGB',(640*3,960))
    for i,(a,n) in enumerate([(v,f'LP {t}s scroll ({dd["h"]},{dd["v"]})'),(b,'best: exactNearest/highest/FS/Effects1'),(c,'current: ruled/highest/FS/Effects1')]):
        W.paste(lab(Image.fromarray(a),n),(640*i,0))
        W.paste(lab(Image.fromarray(a if i==0 else cal(a.astype(float))),n+(' ' if i==0 else ' +HUD gamma 0.76')),(640*i,480))
    p=f'{S}/out/sbs_{t}.png'; W.save(p); paths.append(p)
# 02:12 zoom x3 of table/glow
v=vframe(132); box=(250,105,410,205)
pan=[('LP 132s',v),('best exact/highest/FS/E1',load_rgb(f'{S}/combos/{BEST}/0_0.rgb')),('current ruled/highest/FS/E1',load_rgb(f'{S}/combos/{CUR}/0_0.rgb')),
     ('current minus light 24 (potion)',load_rgb(f'{S}/q3/ruled_drop24/0_0.rgb')),('ruled/highest/FS/Effects3',load_rgb(f'{S}/combos/ruled_highest_fs_e3/0_0.rgb'))]
w,h=(box[2]-box[0])*3,(box[3]-box[1])*3
W=Image.new('RGB',(w*len(pan),h*2))
for i,(n,a) in enumerate(pan):
    cr=a[box[1]:box[3],box[0]:box[2]]
    W.paste(lab(Image.fromarray(cr).resize((w,h),Image.NEAREST),n),(w*i,0))
    W.paste(lab(Image.fromarray(cr if i==0 else cal(cr.astype(float))).resize((w,h),Image.NEAREST),n+('' if i==0 else ' +gamma')),(w*i,h))
W.save(S+'/out/zoom132_table_x3.png'); print(paths)
