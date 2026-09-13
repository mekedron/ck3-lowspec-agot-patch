# Sharp Terrain & Better Water: A Game of Thrones Patch - options for AGOT's own passes.
#
# This file is new (no AGOT or vanilla counterpart) and is the first include of the
# patch's gfx/FX/agot_vic3_fog_of_war.fxh, which every AGOT map shader includes.
# Nothing is defined here by default: AGOT's fog of war and clouds are drawn as AGOT
# draws them. Uncomment a line, re-run install.sh and restart the game, or try a switch
# live from the console (requires -debug_mode):  shader_debug AGOTOPT_NO_CLOUDS
#
# AGOT's fog of war (a Victoria 3 port) reads its 4096x4096 cloud texture six times per
# map pixel on every surface - terrain, water, trees, meshes, borders - at every zoom:
# three layers for the clouds and three for their shadows. The clouds are most visible
# zoomed out (60 % alpha), the cloud shadows are always on (AGOT sets CK3's own cloud
# opacity to 0 and does its clouds here instead).

Code
[[
	// AGOTOPT_FOW_2TAP
	//   One noise layer each for clouds and cloud shadow instead of three (AGOT's own
	//   LOW_QUALITY_SHADERS path): 2 texture taps per pixel instead of 6. Coarser cloud
	//   shapes, same coverage.
	//#define AGOTOPT_FOW_2TAP

	// AGOTOPT_NO_CLOUD_SHADOW
	//   No cloud shadows on the map (the equivalent of CK3's "Cloud Shadows: off" for
	//   AGOT). Saves 3 taps. The fog of war darkness and the clouds stay.
	//#define AGOTOPT_NO_CLOUD_SHADOW

	// AGOTOPT_NO_CLOUDS
	//   No cloud layer over the map. Saves 3 taps. The fog of war darkness and the
	//   cloud shadows stay.
	//#define AGOTOPT_NO_CLOUDS

	// AGOTOPT_DIAG_NO_FOW
	//   Diagnostic only: AGOT's whole atmospheric pass returns the input colour (no fog
	//   of war darkness either). For measuring what the pass costs, not for playing.
	//#define AGOTOPT_DIAG_NO_FOW
]]
