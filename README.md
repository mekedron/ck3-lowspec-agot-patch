# Sharp Terrain & Better Water: A Game of Thrones Patch (CK3)

A compatibility patch that makes
[Sharp Terrain Without Advanced Shaders](https://github.com/mekedron/ck3-lowspec-terrain-fix)
(with its [Real Snow](https://github.com/mekedron/ck3-lowspec-real-snow) add-on) and
[Better Water Without Advanced Shaders](https://github.com/mekedron/ck3-lowspec-water)
work on the map of the
[A Game of Thrones](https://steamcommunity.com/sharedfiles/filedetails/?id=2962333032)
total conversion. Without it the two mods either do nothing under AGOT or break its
terrain, depending on the load order.

## Why AGOT needs a patch

AGOT ships its own copies of most map shaders, `pdxterrain.shader` and `pdxwater.shader`
among them, and rewrites the include files they share: its snow functions take extra
"terrain variant" arguments, the vanilla fog of war is replaced by an atmospheric
effects pass (fog of war plus falling snow), and the water discards everything outside
the map so AGOT's skybox shows there. Sharp Terrain and Better Water replace the same
two shader files wholesale, built on the vanilla ones. So:

* with AGOT **below** them in the load order, AGOT's files win and the two mods have no
  effect at all;
* with AGOT **above** them, their files win, but they are compiled against AGOT's
  include files: Sharp Terrain's low spec pixel shader calls the vanilla three argument
  `ApplyDynamicMasksDiffuse`, which no longer exists, so the terrain fails to compile and
  is not drawn, and the water loses AGOT's atmospheric pass and skybox cut-out.

The options mechanism of the two mods is not affected: AGOT does not ship
`sharp_terrain_options.fxh`, `better_water_options.fxh` or `jomini_water_default.fxh`.

## What the patch is

Two files, AGOT's `pdxterrain.shader` and `pdxwater.shader` with the two mods' changes
applied on top, exactly as in the mods themselves:

| file | AGOT kept | added from the mods |
| --- | --- | --- |
| `gfx/FX/pdxterrain.shader` | atmospheric effects, snowfall, its snow function arguments, the `ReorientedNormal` fix | `PixelShaderLowSpecSharp` (per pixel detail textures in low spec) and the low spec effects rewired to it; the `sharp_terrain_options.fxh` include, so `TERRAINOPT_SNOW_MATERIAL` from the Real Snow add-on works; two calls inside the new shader use AGOT's versions: `ApplyDynamicMasksDiffuse( ..., 0, 0, 0.0f )` and `AGOT_ApplyAtmosphericEffects` in place of `ApplyFogOfWar` |
| `gfx/FX/pdxwater.shader` | atmospheric effects on the water, the skybox discard | `CalcWaterCheap` for the ocean under `WATEROPT_CHEAP_WAVES` and for lakes under `WATEROPT_CHEAP_LAKES`; the `better_water_options.fxh` include |

`CalcWaterCheap` itself and both option files are not duplicated: they come from the
base mods, which is why those mods must stay enabled. The Real Snow add-on needs no
patch of its own, it only overrides the options file.

Each file starts with a `#` banner listing the changes; AGOT's own low spec blocks are
left in place, unreferenced, so `tools/diff_agot.sh` stays readable after an AGOT
update.

## Options: AGOT's fog of war and clouds

AGOT's fog of war is a Victoria 3 port. Its `GameApplyFogOfWar` runs on every map pixel
of every surface (terrain, water, trees, meshes, borders, rivers, map names) at every
zoom, and reads AGOT's 4096x4096 cloud texture six times per pixel: three noise layers
for the clouds and three for their shadows. The clouds are most visible zoomed out (60 %
alpha at the "high" camera range), and the cloud shadows are always on - AGOT sets CK3's
own cloud opacity to 0 and does its clouds here, so CK3's Cloud Shadows setting no
longer switches them off.

The patch ships AGOT's `agot_vic3_fog_of_war.fxh` with four switches, all off by
default, in `gfx/FX/agot_patch_options.fxh`:

| switch | what it does |
| --- | --- |
| `AGOTOPT_FOW_2TAP` | one noise layer each for clouds and cloud shadows (AGOT's own `LOW_QUALITY_SHADERS` path): 2 taps instead of 6, coarser cloud shapes |
| `AGOTOPT_NO_CLOUD_SHADOW` | no cloud shadows on the map, 3 taps saved; fog of war darkness and clouds stay |
| `AGOTOPT_NO_CLOUDS` | no cloud layer, 3 taps saved; fog of war darkness and cloud shadows stay |
| `AGOTOPT_DIAG_NO_FOW` | diagnostic: the whole pass returns its input, for measuring what it costs |

Try one live from the console (`-debug_mode` launch option): `shader_debug
AGOTOPT_NO_CLOUDS`; make it permanent by uncommenting its `#define` in the options file.

## Load order

The patch must be the lowest of the group:

    A Game of Thrones
    Sharp Terrain Without Advanced Shaders
    Real Snow Without Advanced Shaders            (optional)
    Better Water Without Advanced Shaders
    Sharp Terrain & Better Water: A Game of Thrones Patch

Requires all three of AGOT, Sharp Terrain and Better Water. The launcher's list is
sorted by load order, first entry loads first; for files present in several mods the
lowest one wins.

Keep the **Advanced Shaders** graphics option off, as with the base mods. With it on the
game uses AGOT's high spec effects and the patch changes nothing.

**Fast Advanced Shaders** (the debugging mod of the same family) is not compatible with
AGOT and is not covered here: it overrides `jomini/jomini_province_overlays.fxh`,
`pdxmesh.shader` and other files AGOT depends on. Disable it in AGOT playsets.

## Cost

The same as the base mods: Sharp Terrain's per pixel detail sampling, about 4 ms in
winter with Real Snow, and Better Water's six taps per water pixel (fewer than the flat
vanilla low spec water). AGOT's own extra work, its atmospheric pass and snowfall, stays
what it is.

## Layout

    descriptor.mod                 mod metadata
    thumbnail.png                  Workshop preview, must sit in the mod root
    gfx/FX/pdxterrain.shader       AGOT terrain + Sharp Terrain's low spec path
    gfx/FX/pdxwater.shader         AGOT water + Better Water's cheap water
    gfx/FX/agot_vic3_fog_of_war.fxh  AGOT fog of war + the AGOTOPT_* switches
    gfx/FX/agot_patch_options.fxh  the switches, all off
    install.sh                     copies the mod into the Proton prefix
    tools/check_log.sh             mount order + shader error check after a game start
    tools/compile_check.py         offline compile check with DXC
    tools/diff_agot.sh             re-diff against the installed AGOT after an AGOT update
    tools/bbcode_to_plain.py       Paradox Mods descriptions from the Steam ones
    steam-workshop/                listing texts and the thumbnail generator

## Installing

Run `./install.sh`. It copies the mod into the CK3 mod directory inside the Proton
prefix. Then enable it in the launcher playset, below the mods listed above. The first
map load is slower while the two shaders recompile.

## Checking that it works

    tools/check_log.sh

prints the mount order from `debug.log` (this mod must come after AGOT, Sharp Terrain
and Better Water) and any shader failure from `error.log`. DirectX 11 logs a failure as
`Compile error:` followed by `Failed creating shader state`, Vulkan as `Failed to
compile shader`; the script looks for both. A shader that fails to compile simply does
not draw its surface, so a missing terrain or sea is the visible symptom.

Before starting the game at all:

    tools/compile_check.py --dxc <dir with bin/dxc and lib/libdxcompiler.so>

takes a cache entry of every touched effect that was expanded from AGOT's shaders
(AGOT must have been run once with Advanced Shaders off), swaps in this mod's code
blocks, prepends the option files of Sharp Terrain and Better Water from the sibling
repositories, and compiles the result with DXC in six variants: options as shipped,
`TERRAINOPT_SNOW_MATERIAL` (Real Snow), all options off, and the three AGOTOPT groups. This is how the patch was
verified: 9 effects x 6 variants.

## Versions

Built against CK3 **1.19.0.6 (Scribe)**, AGOT **0.5.2.1**, Sharp Terrain 1.1 and Better
Water 1.0. An AGOT release that changes `pdxterrain.shader`, `pdxwater.shader` or
`agot_vic3_fog_of_war.fxh` needs
the patch rebuilt: run `tools/diff_agot.sh`, everything in the output that is not one of
the changes named in the file banners is AGOT's, and has to be carried over onto the new
AGOT copy. The include files AGOT changes (`dynamic_masks.fxh`, `agot_atmospheric.fxh`
and the rest) are not shipped here, so changes there apply automatically.

## Multiplayer / achievements

Shader files are not checksummed content, but the launcher still marks any mod as a
mod. Treat it like any other graphics mod.
