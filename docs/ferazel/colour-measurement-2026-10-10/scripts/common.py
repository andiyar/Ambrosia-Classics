import numpy as np, os, subprocess, glob
S=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # work dir = parent of scripts/ (holds tool/, v/, out/)
T=S+'/tool/.build/release/fzcolour'
FRAMES=[132,310,408.5,462,578.5,765,907.5]
def load_rgb(p): return np.fromfile(p,np.uint8).reshape(480,640,3)
def render(model,tie,dither,eff,sprites,scrolls,outdir,extra=()):
    os.makedirs(outdir,exist_ok=True)
    todo=[s for s in scrolls if not os.path.exists(f'{outdir}/{s[0]}_{s[1]}.rgb')]
    if todo:
        subprocess.run([T,'render',model,tie,dither,str(eff),'1' if sprites else '0',outdir]+[f'{h},{v}' for h,v in todo]+list(extra),check=True)
    return {s:load_rgb(f'{outdir}/{s[0]}_{s[1]}.rgb') for s in scrolls}
def view(a): return a[8:392,16:624]
def gray(a): return a.astype(np.float64)@[0.299,0.587,0.114]
def vframe(t):
    from PIL import Image
    return np.array(Image.open(f'{S}/v/c{t:g}.png'))
# sRGB -> Lab (D65)
def srgb2lab(rgb):
    c=rgb.astype(np.float64)/255
    c=np.where(c<=0.04045,c/12.92,((c+0.055)/1.055)**2.4)
    M=np.array([[0.4124,0.3576,0.1805],[0.2126,0.7152,0.0722],[0.0193,0.1192,0.9505]])
    xyz=c@M.T/np.array([0.95047,1.0,1.08883])
    f=np.where(xyz>0.008856,np.cbrt(xyz),7.787*xyz+16/116)
    L=116*f[...,1]-16; a=500*(f[...,0]-f[...,1]); b=200*(f[...,1]-f[...,2])
    return np.stack([L,a,b],-1)
def edges(g):
    gx=np.zeros_like(g); gy=np.zeros_like(g)
    gx[:,1:-1]=g[:,2:]-g[:,:-2]; gy[1:-1]=g[2:]-g[:-2]
    return np.hypot(gx,gy)
