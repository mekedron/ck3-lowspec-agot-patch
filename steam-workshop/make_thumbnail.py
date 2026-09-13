"""Rebuilds thumbnail.png (Workshop preview) and thumbnail-200px.png (a legibility check
at Steam's listing size, not uploaded). Layout lives in thumbnail_layout.py.

Needs two F12 screenshots of the same AGOT camera position with Advanced Shaders off:
OLD without the patch (vanilla AGOT low spec: blurry ground, flat sea) and NEW with
Sharp Terrain + Better Water + this patch. Pick a coast in winter so terrain, snow and
water are all in the frame. CROP is in 5120x1440 screenshot coordinates."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from thumbnail_layout import make

OLD = os.path.expanduser("~/Pictures/Screenshots/BEFORE_agot.png")   # AGOT alone
NEW = os.path.expanduser("~/Pictures/Screenshots/AFTER_agot.png")    # AGOT + mods + patch
CROP = (1500, 280, 3620, 1133)   # 2120x853, clear of every UI element
OUT = os.path.join(os.path.dirname(__file__), "..", "thumbnail.png")
make(OUT, "AGOT PATCH", OLD, NEW, CROP, CROP, sub="SHARP TERRAIN + BETTER WATER, SHADERS OFF")
