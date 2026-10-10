# Q4: is the original's 32-bit sprite art error-diffused?  Simulate the LP pipeline on our renders
# (x2.25 upscale -> 1920x1080 canvas -> x264 ~2.2 Mbps still clip -> tv-range bt709 decode -> crop -> area downscale)
# and compare high-frequency energy + high-pass correlation with the real video on static sprite regions.
from common import *
import numpy as np, json, subprocess, os
from scipy.ndimage import gaussian_filter, binary_erosion
FF='/opt/homebrew/bin/ffmpeg'
from vid import VF
def simulate(rgb, flags):
    p=subprocess.run([FF,'-v','error','-f','rawvideo','-pix_fmt','rgb24','-s','640x480','-r','30','-i','-',
        '-vf',f'loop=59:1:0,scale=1440:1080:flags={flags},pad=1920:1080:240:0,format=yuv420p,setparams=range=tv:colorspace=bt709',
        '-c:v','libx264','-b:v','2200k','-colorspace','bt709','-color_range','tv','-f','matroska','-'],input=rgb.tobytes(),capture_output=True,check=True)
    q=subprocess.run([FF,'-v','error','-i','-','-vf',VF,'-f','rawvideo','-pix_fmt','rgb24','-'],input=p.stdout,capture_output=True,check=True)
    f=np.frombuffer(q.stdout,np.uint8).reshape(-1,480,640,3)
    return f[-1]
def hp(img):  # high-pass of L*, a*, b*
    lab=srgb2lab(img.astype(float))
    return lab-np.stack([gaussian_filter(lab[...,i],1.2) for i in range(3)],-1)
m=json.load(open(S+'/match.json'))
# static sprite regions (structurally matched blobs from spritelight.py), screen coords boxes
BOXES={'132':[('table+potion+chair',255,120,405,200),('books L',80,180,140,235),('bodies/books floor',245,285,380,330)],
       '578.5':[('barrels',255,120,330,240)],
       '765':[('mushroom/plant',75,150,130,200)]}
out=[]
for t,boxes in BOXES.items():
    d=m[t]; s=f"{d['h']}_{d['v']}"; v=vframe(float(t))
    sims={}
    for di in ('fs','none'):
        a=load_rgb(f'{S}/combos/exact_highest_{di}_e1/{s}.rgb')
        for fl in ('neighbor','bilinear'):
            sims[(di,fl)]=simulate(a,fl)
        sims[(di,'raw')]=a
    sp=(load_rgb(f'{S}/combos/ruled_highest_fs_e1/{s}.rgb')!=load_rgb(f'{S}/combos/nosprites_e1/{s}.rgb')).any(2)
    sp=binary_erosion(sp,iterations=2)
    hv=hp(v)
    for name,x0,y0,x1,y1 in boxes:
        R=np.zeros_like(sp); R[y0:y1,x0:x1]=True; R&=sp
        row=dict(frame=t,region=name,px=int(R.sum()),video_hf=[round(float(hv[R][:,i].std()),2) for i in range(3)])
        for k,img in sims.items():
            h=hp(img); hf=[round(float(h[R][:,i].std()),2) for i in range(3)]
            a=h[R].ravel(); b=hv[R].ravel(); c=float(np.corrcoef(a,b)[0,1])
            row['/'.join(k)]=dict(hf=hf,hp_corr=round(c,3))
        out.append(row)
        print(json.dumps(row))
json.dump(out,open(S+'/q4.json','w'),indent=1)
