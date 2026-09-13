# Sharp Terrain & Better Water: A Game of Thrones Patch - options for AGOT's own passes.
#
# This file is new (no AGOT or vanilla counterpart) and is the first include of the
# patch's gfx/FX/agot_vic3_fog_of_war.fxh, which every AGOT map shader includes.
#
# AGOT's fog of war (a Victoria 3 port) reads its 4096x4096 cloud texture six times per
# map pixel on every surface - terrain, water, trees, meshes, borders - at every zoom:
# three layers for the clouds and three for their shadows. The clouds are most visible
# zoomed out (60 % alpha), the cloud shadows are always on (AGOT sets CK3's own cloud
# opacity to 0 and does its clouds here instead).
#
# Default: both the cloud layer and the cloud shadows are off; the fog of war darkness
# over unexplored land stays. The switches are "keep" switches so that every default can
# be undone live from the console (requires -debug_mode), one at a time:
#     shader_debug AGOTOPT_VANILLA_FOW        AGOT's fog of war exactly as shipped (6 taps)
#     shader_debug AGOTOPT_KEEP_CLOUDS        clouds back, from one noise layer (2 taps)
#     shader_debug AGOTOPT_KEEP_CLOUD_SHADOW  cloud shadows back, from one noise layer
#     shader_debug AGOTOPT_DIAG_NO_FOW        diagnostic: the whole pass off, even the darkness
#     shader_debug                            back to this file's defaults
# To make a "keep" permanent, uncomment its #define below.

Code
[[
	//#define AGOTOPT_KEEP_CLOUDS          // the cloud layer, one noise layer instead of three
	//#define AGOTOPT_KEEP_CLOUD_SHADOW    // the cloud shadows, one noise layer instead of three
	//#define AGOTOPT_VANILLA_FOW          // everything as AGOT ships it (overrides the two above)

	#ifndef AGOTOPT_VANILLA_FOW
		#ifndef AGOTOPT_KEEP_CLOUDS
			#define AGOTOPT_NO_CLOUDS
		#endif
		#ifndef AGOTOPT_KEEP_CLOUD_SHADOW
			#define AGOTOPT_NO_CLOUD_SHADOW
		#endif
		// whatever is kept uses AGOT's own single layer (LOW_QUALITY_SHADERS) path
		#define AGOTOPT_FOW_2TAP
	#endif

	// AGOTOPT_DIAG_NO_FOW: diagnostic only - AGOT's whole atmospheric pass returns the
	// input colour, no fog of war darkness either. For measuring, not for playing.
	//#define AGOTOPT_DIAG_NO_FOW
]]
