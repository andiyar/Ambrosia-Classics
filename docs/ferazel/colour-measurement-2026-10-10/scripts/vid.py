import numpy as np, subprocess, os, sys
V=os.path.expanduser("~/Let's Play Ferazel's Wand! Part 1： A Scent of Peril [ESuyxMUEzDw].mkv")
VF="crop=1440:1080:240:0,scale=640:480:flags=area:in_range=tv:out_range=pc:in_color_matrix=bt709:out_color_matrix=bt709,format=rgb24"
def frames(t, n):
    """n consecutive frames starting at time t (accurate seek), RGB full range, 640x480"""
    p=subprocess.run(['/opt/homebrew/bin/ffmpeg','-v','error','-ss',f'{t:.3f}','-i',V,'-frames:v',str(n),'-vf',VF,'-f','rawvideo','-pix_fmt','rgb24','-'],capture_output=True,check=True)
    return np.frombuffer(p.stdout,np.uint8).reshape(-1,480,640,3)
if __name__=='__main__':
    from PIL import Image
    for t in map(float,sys.argv[1:]):
        f=frames(t,15).astype(np.int16)
        view=f[:,8:392,16:624]
        mot=[(np.abs(view[i+1]-view[i]).max(2)>24).mean() for i in range(len(f)-1)]
        print(t, 'motion frac/frame median %.4f max %.4f'%(np.median(mot),max(mot)))
        Image.fromarray(np.median(f[5:10],0).astype(np.uint8)).save(f'{os.path.dirname(os.path.dirname(os.path.abspath(__file__)))}/v/c{t:g}.png')
