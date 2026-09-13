#!/usr/bin/env python3
"""Compile check for the patch's shaders without starting the game.

The game's shader cache stores every compiled permutation as fully expanded HLSL
(<hash>.scache).  This script takes an entry of each effect the patch touches that was
expanded from A Game of Thrones' own shaders (it must contain AGOT_ApplyAtmosphericEffects
and the LOW_SPEC_SHADERS define - so AGOT must have been run once with Advanced Shaders
off), swaps AGOT's Code blocks for this mod's, prepends the option files of Sharp
Terrain and Better Water, and compiles the result with DXC in every option variant.

The entries in the cache may come from a run where other shader mods were enabled;
their blocks are swapped back (see CONTAMINANTS) before anything is compiled, and the
cleaned entry must compile on its own before the patched one is tried.

It catches syntax errors, undeclared identifiers and wrong overloads.  It cannot
catch a wrong texture register or an engine-side include problem; those need a game
start (see tools/check_log.sh).

usage: compile_check.py --dxc <dxc dir> [--cache <ps_5_0 dir>] [--game <game root>]
                        [--agot <AGOT dir>] [--sharp <repo>] [--water <repo>] [-k]
"""
import argparse, os, re, shutil, subprocess, sys, tempfile

HOME = os.path.expanduser('~')
DEF_CACHE = HOME + '/.local/share/Steam/steamapps/compatdata/1158310/pfx/drive_c/users/steamuser/Documents/Paradox Interactive/Crusader Kings III/shadercache/dx11/ps_5_0'
DEF_GAME = HOME + '/.local/share/Steam/steamapps/common/Crusader Kings III'
DEF_AGOT = HOME + '/.local/share/Steam/steamapps/workshop/content/1158310/2962333032'
MOD = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEF_SHARP = os.path.join(os.path.dirname(MOD), 'ck3-lowspec-terrain-fix')
DEF_WATER = os.path.join(os.path.dirname(MOD), 'ck3-lowspec-water')
DEF_FASTADV = os.path.join(os.path.dirname(MOD), 'ck3-fast-advanced-shaders')

AGOT_MARKER = 'AGOT_ApplyAtmosphericEffects'
# (shader file, effect): every target is a low spec permutation
TARGETS = [
    ('pdxterrain.shader', 'PdxTerrainLowSpec'),
    ('pdxterrain.shader', 'PdxTerrainLowSpecSkirt'),
    ('pdxterrain.shader', 'PdxTerrain'),
    ('pdxwater.shader', 'waterLowSpec'),
    ('pdxwater.shader', 'lake'),
    ('pdxwater.shader', 'water'),
]
MAIN_MAP = {
    ('pdxterrain.shader', 'PdxTerrainLowSpec'): {'PixelShaderLowSpec': 'PixelShaderLowSpecSharp'},
    ('pdxterrain.shader', 'PdxTerrainLowSpecSkirt'): {'PixelShaderLowSpec': 'PixelShaderLowSpecSharp'},
}
# (symbol that proves the block is in the entry, file whose blocks are there, file to put instead)
# Fast Advanced Shaders leaves its switch block and two .fxh files in an AGOT entry when it
# was enabled together with AGOT; Better Water's jomini_water_default.fxh is what the patch
# expects there.
def contaminants(a):
    fa = a.fastadv
    return [
        ('ADVOPT_DISABLE_ALL', os.path.join(fa, 'gfx/FX/fastadv.fxh'), None),
        ('BlurDiseaseIntensity', os.path.join(fa, 'gfx/FX/disease.fxh'), os.path.join(a.game, 'game/gfx/FX/disease.fxh')),
        ('CalcRefraction', os.path.join(fa, 'gfx/FX/jomini/jomini_water_default.fxh'), os.path.join(a.water, 'gfx/FX/jomini/jomini_water_default.fxh')),
    ]

def read(p):
    return open(p, 'rb').read().decode('utf-8', 'replace').replace('\r\n', '\n')

def find_entries(cache, shader, effect):
    out = []
    for name in sorted(os.listdir(cache)):
        if not name.endswith('.scache'):
            continue
        p = os.path.join(cache, name)
        head = read(p)[:4000]
        if f'// Shader file: gfx/FX/{shader}\n' not in head or f'// Effect: {effect}\n' not in head:
            continue
        if '#define LOW_SPEC_SHADERS' not in head:
            continue
        if AGOT_MARKER not in read(p):
            continue
        out.append(p)
    return out

def switch_block(paths):
    out = ''
    for p in paths:
        if os.path.exists(p):
            t = read(p)
            out += t[t.index('[[') + 2: t.index(']]')] + '\n'
    return out

def code_blocks(text):
    """Return {key: [lines]} for every Code [[ ]] block of a Paradox shader file.
    A block that directly follows `MainCode NAME` is keyed ('main', NAME); the other
    (shared) blocks are keyed ('shared', n) in file order."""
    blocks, shared = {}, 0
    mains = [(m.start(), m.group(1)) for m in re.finditer(r'MainCode\s+(\w+)\s*\{', text)]
    claimed = set()
    for m in re.finditer(r'Code\s*\[\[(.*?)\]\]', text, re.S):
        body = m.group(1).split('\n')
        while body and not body[0].strip(): body.pop(0)
        while body and not body[-1].strip(): body.pop()
        owner = None
        for pos, name in mains:
            if pos < m.start() and name not in claimed:
                owner = name
        if owner is not None:
            pos = [p for p in mains if p[1] == owner][0][0]
            if re.search(r'Code\s*\[\[', text[pos:m.start()]) is not None:
                owner = None
        if owner is not None:
            claimed.add(owner); key = ('main', owner)
        else:
            key = ('shared', shared); shared += 1
        blocks[key] = body
    return blocks

SIG = re.compile(r'^\w[\w<>, ]* main\s*\(')
def norm(l):
    l = l.strip()
    # the engine replaces the PDX_MAIN line of a MainCode block with the real entry
    # point signature; treat both spellings as the same line
    if l.startswith('PDX_MAIN') or SIG.match(l):
        return 'PDX_MAIN'
    return l

def apply_blocks(target, base_path, new_path, main_map=None):
    """Replace every Code block of base_path found in the expanded file with new_path's
    block of the same key (or of the mapped main name). new_path None = drop the block.
    Returns (replaced count, notes)."""
    lines = read(target).split('\n')
    base = code_blocks(read(base_path))
    new = code_blocks(read(new_path)) if new_path else {k: [] for k in base}
    for old_main, new_main in (main_map or {}).items():
        if ('main', new_main) in new:
            new[('main', old_main)] = new[('main', new_main)]
    notes, replaced = [], 0
    for key, bb in base.items():
        if key not in new:
            notes.append(f'{key}: no counterpart in the new file'); continue
        pat = [norm(l) for l in bb]
        if not [x for x in pat if x]:
            continue
        nl = [norm(l) for l in lines]
        hits = [k for k in range(len(nl) - len(pat) + 1) if nl[k:k+len(pat)] == pat]
        if not hits:
            continue  # not part of this permutation (another MainCode / stage)
        k = hits[0]
        signature = [l for l in lines[k:k+len(pat)] if norm(l) == 'PDX_MAIN']
        nb = list(new[key])
        if signature:
            nb = [signature[0] if norm(l) == 'PDX_MAIN' else l for l in nb]
        lines[k:k+len(pat)] = nb
        replaced += 1
    open(target, 'wb').write('\n'.join(lines).encode('utf-8'))
    return replaced, notes

def compile_(dxc, env, path, defs=()):
    r = subprocess.run([dxc, '-T', 'ps_6_0', '-E', 'main', '-HV', '2018', '-Fo', os.devnull] + list(defs) + [path],
                       env=env, capture_output=True, text=True)
    return r.returncode == 0, r.stderr

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dxc', required=True)
    ap.add_argument('--cache', default=DEF_CACHE)
    ap.add_argument('--game', default=DEF_GAME)
    ap.add_argument('--agot', default=DEF_AGOT)
    ap.add_argument('--sharp', default=DEF_SHARP, help='Sharp Terrain repo (for its options file)')
    ap.add_argument('--water', default=DEF_WATER, help='Better Water repo (options file + jomini_water_default.fxh)')
    ap.add_argument('--fastadv', default=DEF_FASTADV, help='Fast Advanced Shaders repo, only to clean its blocks out of the cache entries')
    ap.add_argument('-k', '--keep', action='store_true', help='keep the work dir')
    a = ap.parse_args()
    dxc = os.path.join(a.dxc, 'bin', 'dxc')
    env = dict(os.environ, LD_LIBRARY_PATH=os.path.join(a.dxc, 'lib'))
    options = [os.path.join(a.sharp, 'gfx/FX/sharp_terrain_options.fxh'), os.path.join(a.water, 'gfx/FX/better_water_options.fxh')]
    for p in options:
        if not os.path.exists(p):
            print('missing options file:', p); sys.exit(2)
    VARIANTS = [
        ('default', switch_block(options), []),
        ('snow_material', switch_block(options), ['-DTERRAINOPT_SNOW_MATERIAL']),
        ('options_off', '', []),
    ]
    work = tempfile.mkdtemp(prefix='agotpatch_')
    failures = 0
    for shader, effect in TARGETS:
        entries = find_entries(a.cache, shader, effect)
        tag = f'{effect}[lowspec]'
        if not entries:
            print(f'{tag:30} no AGOT cache entry, skipped')
            continue
        entry = entries[0]
        dst = os.path.join(work, tag + '.hlsl')
        open(dst, 'wb').write(read(entry).encode('utf-8'))
        text = read(dst)
        # 1. clean other mods' blocks out of the entry
        for symbol, base, new in contaminants(a):
            if symbol in text and os.path.exists(base):
                n, _ = apply_blocks(dst, base, new)
                text = read(dst)
        ok, err = compile_(dxc, env, dst)
        if not ok:
            print(f'{tag:30} BASELINE (AGOT, cleaned) FAILS - harness problem, not the mod:\n    ' + err.strip().replace('\n', '\n    ')[:2000])
            failures += 1
            continue
        # 2. AGOT's file -> this mod's file
        n, notes = apply_blocks(dst, os.path.join(a.agot, 'gfx/FX', shader), os.path.join(MOD, 'gfx/FX', shader), MAIN_MAP.get((shader, effect)))
        src = read(dst)
        for vname, block, defs in VARIANTS:
            vdst = dst[:-5] + f'.{vname}.hlsl'
            open(vdst, 'w').write(block + '\n' + src)
            ok, err = compile_(dxc, env, vdst, defs)
            if not ok:
                failures += 1
            print(f'{tag:30} {vname:14} {"ok" if ok else "FAIL"}   ({n} blocks swapped, entry {os.path.basename(entry)})')
            if not ok:
                print('    ' + err.strip().replace('\n', '\n    ')[:3000])
        for msg in notes:
            print(f'    note: {msg}')
    if a.keep:
        print('work dir:', work)
    else:
        shutil.rmtree(work)
    sys.exit(1 if failures else 0)

if __name__ == '__main__':
    main()
