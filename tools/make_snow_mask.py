#!/usr/bin/env python3
"""Build gfx/map/textures/snow_mask.dds for the AGOT map: vanilla's noise, snow allowed everywhere.

AGOT ships a snow mask that is one colour over the whole map, with the red channel at
255. The terrain and mesh snow material reads `1 - red` as "how much snow is allowed
here" and returns before drawing anything when that is below 0.05, so on the AGOT map
the snow material never runs - Real Snow (and AGOT's own high spec snow material) draws
nothing there. This texture keeps vanilla CK3's noise channels (green, blue, alpha: the
snow edge and cover variation) and sets red to 0, so the material runs everywhere and is
gated only by the winter severity the game computes per province. Needs ImageMagick 7.

    tools/make_snow_mask.py [--game DIR]
"""
import argparse, os, struct, subprocess, tempfile
from PIL import Image
import numpy as np

MOD = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEF_GAME = os.path.expanduser('~/.local/share/Steam/steamapps/common/Crusader Kings III/game')

def mip_dims(w, h):
    out = [(w, h)]
    while w > 1 or h > 1:
        w, h = max(1, w // 2), max(1, h // 2); out.append((w, h))
    return out

def encode(img, tmp, i):
    png = os.path.join(tmp, f'{i}.png'); dds = os.path.join(tmp, f'{i}.dds'); img.save(png)
    subprocess.run(['magick', png, '-define', 'dds:compression=dxt5', '-define', 'dds:mipmaps=0', '-define', 'dds:cluster-fit=true', dds], check=True, capture_output=True)
    return open(dds, 'rb').read()[128:]

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--game', default=DEF_GAME); a = ap.parse_args()
    src = Image.open(os.path.join(a.game, 'gfx/map/textures/snow_mask.dds')); src.load()
    arr = np.asarray(src.convert('RGBA')).copy(); arr[..., 0] = 0
    img = Image.fromarray(arr, 'RGBA'); w, h = img.size
    dims = mip_dims(w, h); levels = []; cur = img
    with tempfile.TemporaryDirectory() as tmp:
        for i, (lw, lh) in enumerate(dims):
            if (lw, lh) != cur.size: cur = cur.resize((lw, lh), Image.BOX)
            levels.append(encode(cur, tmp, i))
    linear = len(levels[0])
    flags = 0x1 | 0x2 | 0x4 | 0x1000 | 0x20000 | 0x80000
    hdr = struct.pack('<4sIIIIIII11I', b'DDS ', 124, flags, h, w, linear, 0, len(dims), *([0] * 11))
    pf = struct.pack('<II4sIIIII', 32, 0x4, b'DXT5', 0, 0, 0, 0, 0)
    caps = struct.pack('<IIIII', 0x1000 | 0x8 | 0x400000, 0, 0, 0, 0)
    out = os.path.join(MOD, 'gfx/map/textures/snow_mask.dds'); os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, 'wb') as f:
        f.write(hdr + pf + caps)
        for l in levels: f.write(l)
    chk = Image.open(out); chk.load(); b = np.asarray(chk.convert('RGBA'))
    print(f'{out}: {w}x{h} DXT5, {len(dims)} mips, {os.path.getsize(out) / 2**20:.1f} MB; red max {b[..., 0].max()}, '
          f'noise MAE G/B/A {np.abs(b[..., 1:].astype(float) - arr[..., 1:].astype(float)).mean(axis=(0, 1)).round(2)}')

if __name__ == '__main__':
    main()
