# Q4 in the video's own 1440x1080 domain (no downscale): visual crops + energy at the original-pixel Nyquist.
from common import *
import numpy as np, json, subprocess
from PIL import Image
FF='/opt/homebrew/bin/ffmpeg'
V=os.path.expanduser("~/Let's Play Ferazel's Wand! Part 1： A Scent of Peril [ESuyxMUEzDw].mkv")
DEC="crop=1440:1080:240:0,scale=in_range=tv:out_range=pc:in_color_matrix=bt709:out_color_matrix=bt709,format=rgb24"
def vid_full(t,n=5):
    p=subprocess.run([FF,'-v','error','-ss',f'{t:.3f}','-i',V,'-frames:v',str(n),'-vf',DEC,'-f','rawvideo','-pix_fmt','rgb24','-'],capture_output=True,check=True)
    return np.median(np.frombuffer(p.stdout,np.uint8).reshape(-1,1080,1440,3),0).astype(np.uint8)
def sim_full(rgb,flags):
    p=subprocess.run([FF,'-v','error','-f','rawvideo','-pix_fmt','rgb24','-s','640x480','-r','30','-i','-',
        '-vf',f'loop=59:1:0,scale=1440:1080:flags={flags},pad=1920:1080:240:0,format=yuv420p',
        '-c:v','libx264','-b:v','2200k','-f','matroska','-'],input=rgb.tobytes(),capture_output=True,check=True)
    q=subprocess.run([FF,'-v','error','-i','-','-vf',DEC,'-f','rawvideo','-pix_fmt','rgb24','-'],input=p.stdout,capture_output=True,check=True)
    return np.frombuffer(q.stdout,np.uint8).reshape(-1,1080,1440,3)[-1]
def nyq_energy(img,box):
    # fraction of luminance+chroma spectral energy at periods 2..3 original px (4.5..6.75 video px), in box (video coords)
    x0,y0,x1,y1=box; a=srgb2lab(img[y0:y1,x0:x1].astype(float))
    res=[]
    for c in range(3):
        f=a[...,c]-a[...,c].mean(); F=np.abs(np.fft.fft2(f*np.outer(np.hanning(f.shape[0]),np.hanning(f.shape[1]))))**2
        fy=np.fft.fftfreq(f.shape[0])[:,None]; fx=np.fft.fftfreq(f.shape[1])[None,:]; r=np.hypot(fx,fy)
        band=(r>1/6.75)&(r<1/4.5); low=(r>1/40)&(r<=1/6.75)
        res.append(round(float(F[band].sum()/F[low].sum()),3))
    return res
if __name__=='__main__':
    t=132.2; v=vid_full(t)
    a_fs=load_rgb(f'{S}/combos/exact_highest_fs_e3/0_0.rgb'); a_no=load_rgb(f'{S}/combos/exact_highest_none_e3/0_0.rgb')
    sims={'fs bilinear':sim_full(a_fs,'bilinear'),'none bilinear':sim_full(a_no,'bilinear'),'fs neighbor':sim_full(a_fs,'neighbor'),'none neighbor':sim_full(a_no,'neighbor')}
    # table top box in 640 coords (270..350, 140..165) -> video coords x2.25
    B640={'tabletop':(268,142,350,165),'chair':(355,135,390,185),'books L':(85,185,135,230)}
    rep={}
    for nm,(x0,y0,x1,y1) in B640.items():
        box=tuple(int(round(z*2.25)) for z in (x0,y0,x1,y1))
        rep[nm]={'video':nyq_energy(v,box)}
        for k,s in sims.items(): rep[nm][k]=nyq_energy(s,box)
        print(nm,json.dumps(rep[nm]))
    json.dump(rep,open(S+'/q4full.json','w'),indent=1)
    x0,y0,x1,y1=(int(260*2.25),int(115*2.25),int(400*2.25),int(200*2.25))
    tiles=[('video',v)]+list(sims.items())
    W=Image.new('RGB',((x1-x0)*len(tiles)//1,(y1-y0)))
    for i,(n,im) in enumerate(tiles): W.paste(Image.fromarray(im[y0:y1,x0:x1]),((x1-x0)*i,0))
    W.save(S+'/out/q4_table_fullres.png')
