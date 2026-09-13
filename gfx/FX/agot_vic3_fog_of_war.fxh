# Sharp Terrain & Better Water: A Game of Thrones Patch - modified copy of
# gfx/FX/agot_vic3_fog_of_war.fxh from A Game of Thrones 0.5.2.1 (Workshop id 2962333032).
# This file is included (through agot_atmospheric.fxh) by every AGOT map shader: terrain,
# water, trees, map meshes, decals, borders, rivers and map names, so the switches below
# reach all of them.
#
# Changes vs AGOT, all inside GameApplyFogOfWar and guarded by AGOTOPT_* switches from
# gfx/FX/agot_patch_options.fxh (included first; by default that file switches the
# clouds and the cloud shadows off and keeps the fog of war darkness):
#   AGOTOPT_FOW_2TAP           clouds and cloud shadow from one noise layer each (AGOT's own
#                              LOW_QUALITY_SHADERS path): 2 taps of the 4096x4096 cloud
#                              texture per pixel instead of 6
#   AGOTOPT_NO_CLOUD_SHADOW    no cloud shadows on the map (3 taps saved); the fog of war
#                              darkness and the clouds themselves stay
#   AGOTOPT_NO_CLOUDS          no cloud layer (3 taps saved); fog of war darkness and cloud
#                              shadows stay
#   AGOTOPT_DIAG_NO_FOW        diagnostic: the whole pass returns the input colour
# The defaults can be undone live from the console, see the options file:
#   shader_debug AGOTOPT_VANILLA_FOW / AGOTOPT_KEEP_CLOUDS / AGOTOPT_KEEP_CLOUD_SHADOW
#
# This file is based on fog_of_war.fxh from Victoria 3 v1.0.3.
# It replaces the standard Jomini fog of war shader.
Includes = {
	"agot_patch_options.fxh"
	#"fog_of_war_impl.fxh"
	"jomini/jomini.fxh"
	"jomini/jomini_fog_of_war.fxh"
	"cw/utility.fxh"
	# MOD(agot)
	"agot_vic3_fog_of_war_settings.fxh"
	"cw/random.fxh"
	# END MOD
}

PixelShader = {
	# MOD(agot)
	# In Victoria 3 this constant buffer is populated by the game
	# based on the contents of gfx/map/fog_of_war/fog_of_war.settings .
	# For CK3 we must specify these values directly in shader code,
	# which is done in agot_vic3_fog_of_war_settings.fxh that this file includes.
	#ConstantBuffer( GameFogOfWar )
	#{
	#	float4 _FoWShadowColor;
	#	float4 _FoWCloudsColor;
	#	float4 _FoWCloudsColorSecondary;
	#
	#	float _FoWCloudsColorGradientMin;
	#	float _FoWCloudsColorGradientMax;
	#
	#	float _FoWCloudHeight;
	#
	#	float _FoWShadowMult;
	#	float _FoWShadowTexStart;
	#	float _FoWShadowTexStop;
	#
	#	float _FoWShadowAlphaStart;
	#	float _FoWShadowAlphaStop;
	#
	#	float _FowShadowLayer1Min;
	#	float _FowShadowLayer1Max;
	#	float _FowShadowLayer2Min;
	#	float _FowShadowLayer2Max;
	#	float _FowShadowLayer3Min;
	#	float _FowShadowLayer3Max;
	#
	#	float _FoWCloudsAlphaStart;
	#	float _FoWCloudsAlphaStop;
	#
	#	float _FoWMasterStart;
	#	float _FoWMasterStop;
	#	int _FoWMasterUVTiling;
	#	float _FoWMasterUVRotation;
	#	float2 _FoWMasterUVScale;
	#	float2 _FoWMasterUVSpeed;
	#
	#	float _FoWLayer1Min;
	#	float _FoWLayer1Max;
	#	int _FoWLayer1Tiling;
	#
	#	float _FoWLayer2Min;
	#	float _FoWLayer2Max;
	#	float _FoWLayer2Balance;
	#	int _FoWLayer2Tiling;
	#
	#	float _FoWLayer3Min;
	#	float _FoWLayer3Max;
	#	float _FoWLayer3Balance;
	#	int _FoWLayer3Tiling;
	#
	#	float _FoWShowAlphaMask;
	#
	#	float2 _FoWLayer1Speed;
	#	float2 _FoWLayer2Speed;
	#	float2 _FoWLayer3Speed;
	#
	#}
	# END MOD
	
	#// Fog of war fade out on close zoom
	Code [[
		// MOD(agot)
		// #define FowFadeEnd                      150.0
		// #define FowFadeStart            101.0

		// AGOT uses a custom clouds fading logic expressed in AGOT_GetFoWCloudsAlphaMultiplier(),
		// based on low, medium, high and flat map camera height levels (as defined by the height ranges below),
		// and corresponding max alpha values for clouds, specified in agot_vic3_fog_of_war_settings.fxh,
		// between which the clouds fade when camera height is in between 2 height ranges.

		static const float AGOT_FOW_CLOUDS_LOW_HEIGHT_MAX = 86.0f;

		static const float AGOT_FOW_CLOUDS_MEDIUM_HEIGHT_MIN = 110.0f;
		static const float AGOT_FOW_CLOUDS_MEDIUM_HEIGHT_MAX = 300.0f;

		static const float AGOT_FOW_CLOUDS_HIGH_HEIGHT_MIN = 325.0f;
		static const float AGOT_FOW_CLOUDS_HIGH_HEIGHT_MAX = 1100.0f;

		static const float AGOT_FOW_CLOUDS_FLAT_MAP_HEIGHT_MIN = 1200.0f;
		// END MOD
	]]

	# MOD(agot)
	# Unlike in Vic3, in CK3 this sampler is defined in all the game-specific shaders that require it.
	# So we actually don't want this centralied definition here, or we'll get a lot of double definition errors.
	#TextureSampler FogOfWarAlpha
	#{
	#	Ref = JominiFogOfWar
	#	MagFilter = "Linear"
	#	MinFilter = "Linear"
	#	MipFilter = "Linear"
	#	SampleModeU = "Wrap"
	#	SampleModeV = "Wrap"
	#}
	# END MOD
	TextureSampler FogOfWarNoise
	{
		# MOD(agot)
		#Ref = GameFogOfWarNoise
		Index = 36
		# END MOD
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		# MOD(agot)
		File = "gfx/map/fog_of_war/cloud.dds"
		srgb = no
		# END MOD
	}
	Code [[
		float SampleFowNoiseLowSpec( in float3 Coordinate )
		{
				// Uv tiling
				float2 MasterUVTiling = _FoWMasterUVTiling * Coordinate.xz * InverseWorldSize;
				MasterUVTiling.x *= _FoWMasterUVScale.x;
				MasterUVTiling.y *= _FoWMasterUVScale.y;
				float2 UV = MasterUVTiling * _FoWLayer1Tiling;

				// Animation
				float2 AnimUV = float2(_FoWLayer1Speed.x * _FoWMasterUVSpeed.x, _FoWLayer1Speed.y * _FoWMasterUVSpeed.y) * FogOfWarTime * 0.01f;
				UV += AnimUV * _FoWMasterUVScale;

				// Layer sample
				float Layer1 = PdxTex2D( FogOfWarNoise, UV ).r;
				Layer1 = smoothstep( _FoWLayer1Min, _FoWLayer1Max, Layer1 );

				// Detail noise blending
				float Cloud = smoothstep( _FoWLayer1Min, _FoWLayer1Max, Layer1 );
				return Cloud;
		}

		float SampleFowNoise( in float3 Coordinate )
		{

				// Uv tiling and animation
				float2 MasterUVTiling = _FoWMasterUVTiling * Coordinate.xz * InverseWorldSize;

				// Scale
				MasterUVTiling.x *= _FoWMasterUVScale.x;
				MasterUVTiling.y *= _FoWMasterUVScale.y;

				float2 UV = MasterUVTiling * _FoWLayer1Tiling;
				float2 UV2 = MasterUVTiling * _FoWLayer2Tiling;
				float2 UV3 = MasterUVTiling * _FoWLayer3Tiling;

				// Animation
				float2 AnimUV = float2(_FoWLayer1Speed.x * _FoWMasterUVSpeed.x, _FoWLayer1Speed.y * _FoWMasterUVSpeed.y) * FogOfWarTime * 0.01f;
				float2 AnimUV2 = float2(_FoWLayer2Speed.x * _FoWMasterUVSpeed.x, _FoWLayer2Speed.y * _FoWMasterUVSpeed.y) * FogOfWarTime * 0.01f;
				float2 AnimUV3 = float2(_FoWLayer3Speed.x * _FoWMasterUVSpeed.x, _FoWLayer3Speed.y * _FoWMasterUVSpeed.y) * FogOfWarTime * 0.01f;
				UV += AnimUV * _FoWMasterUVScale;
				UV2 += AnimUV2 * _FoWMasterUVScale;
				UV3 +=AnimUV3 * _FoWMasterUVScale;

				// Layers sample
				float Layer1 = PdxTex2D( FogOfWarNoise, UV ).g;
				float Layer2 = PdxTex2D( FogOfWarNoise, UV2 ).g;
				float Layer3 = PdxTex2D( FogOfWarNoise, UV3 ).g;

				// Layers min/max adjustment
				Layer1 = smoothstep( _FoWLayer1Min, _FoWLayer1Max, Layer1 );
				Layer2 = smoothstep( _FoWLayer2Min, _FoWLayer2Max, Layer2 );
				Layer3 = smoothstep( _FoWLayer3Min, _FoWLayer3Max, Layer3 );

				// Detail noise blending
				float Cloud = Overlay(Layer1, Layer2, _FoWLayer2Balance );
				Cloud = Overlay(Cloud, Layer3, _FoWLayer3Balance );

				return Cloud;
		}

		float SampleFowReflection( in float2 Coordinate )
		{
				// Uv tiling and animation
				float2 MasterUVTiling = _FoWMasterUVTiling * Coordinate * InverseWorldSize;

				// Scale
				MasterUVTiling.x *= _FoWMasterUVScale.x;
				MasterUVTiling.y *= _FoWMasterUVScale.y;

				float2 UV = MasterUVTiling * _FoWLayer1Tiling;
				float2 UV2 = MasterUVTiling * _FoWLayer2Tiling;
				float2 UV3 = MasterUVTiling * _FoWLayer3Tiling;

				// Animation
				float2 AnimUV = float2(_FoWLayer1Speed.x * _FoWMasterUVSpeed.x, _FoWLayer1Speed.y * _FoWMasterUVSpeed.y) * FogOfWarTime * 0.01f;
				float2 AnimUV2 = float2(_FoWLayer2Speed.x * _FoWMasterUVSpeed.x, _FoWLayer2Speed.y * _FoWMasterUVSpeed.y) * FogOfWarTime * 0.01f;
				float2 AnimUV3 = float2(_FoWLayer3Speed.x * _FoWMasterUVSpeed.x, _FoWLayer3Speed.y * _FoWMasterUVSpeed.y) * FogOfWarTime * 0.01f;
				UV += AnimUV * _FoWMasterUVScale;
				UV2 += AnimUV2 * _FoWMasterUVScale;
				UV3 +=AnimUV3 * _FoWMasterUVScale;

				// Layers sample
				float Layer1 = PdxTex2D( FogOfWarNoise, UV ).g;
				float Layer2 = PdxTex2D( FogOfWarNoise, UV2 ).g;
				float Layer3 = PdxTex2D( FogOfWarNoise, UV3 ).g;

				// Layers min/max adjustment
				Layer1 = smoothstep( _FoWLayer1Min, _FoWLayer1Max, Layer1 );
				Layer2 = smoothstep( _FoWLayer2Min, _FoWLayer2Max, Layer2 );
				Layer3 = smoothstep( _FoWLayer3Min, _FoWLayer3Max, Layer3 );

				// Detail noise blending
				float Cloud = Overlay(Layer1, Layer2, _FoWLayer2Balance );
				Cloud = Overlay(Cloud, Layer3, _FoWLayer3Balance );

				return Cloud;
		}

		float SampleFowNoiseShadow( in float3 Coordinate )
		{

				// Uv tiling and animation
				float2 MasterUVTiling = _FoWMasterUVTiling * Coordinate.xz * InverseWorldSize;

				// Scale
				MasterUVTiling.x *= _FoWMasterUVScale.x;
				MasterUVTiling.y *= _FoWMasterUVScale.y;

				float2 UV = MasterUVTiling * _FoWLayer1Tiling;
				float2 UV2 = MasterUVTiling * _FoWLayer2Tiling;
				float2 UV3 = MasterUVTiling * _FoWLayer3Tiling;

				// Animation
				float2 AnimUV = float2(_FoWLayer1Speed.x * _FoWMasterUVSpeed.x, _FoWLayer1Speed.y * _FoWMasterUVSpeed.y) * FogOfWarTime * 0.01f;
				float2 AnimUV2 = float2(_FoWLayer2Speed.x * _FoWMasterUVSpeed.x, _FoWLayer2Speed.y * _FoWMasterUVSpeed.y) * FogOfWarTime * 0.01f;
				float2 AnimUV3 = float2(_FoWLayer3Speed.x * _FoWMasterUVSpeed.x, _FoWLayer3Speed.y * _FoWMasterUVSpeed.y) * FogOfWarTime * 0.01f;
				UV += AnimUV * _FoWMasterUVScale;
				UV2 += AnimUV2 * _FoWMasterUVScale;
				UV3 +=AnimUV3 * _FoWMasterUVScale;

				// Layers sample
				float Layer1 = PdxTex2D( FogOfWarNoise, UV ).a;
				float Layer2 = PdxTex2D( FogOfWarNoise, UV2 ).a;
				float Layer3 = PdxTex2D( FogOfWarNoise, UV3 ).a;

				// Layers min/max adjustment
				Layer1 = LevelsScan( Layer1, _FowShadowLayer1Min, _FowShadowLayer1Max);
				Layer2 = LevelsScan( Layer2, _FowShadowLayer2Min, _FowShadowLayer2Max);
				Layer3 = LevelsScan( Layer3, _FowShadowLayer3Min, _FowShadowLayer3Max);

				// Detail noise blending
				float Cloud = Overlay(Layer1, Layer2 );
				Cloud = Overlay(Cloud, Layer3 );

				return Cloud;
		}

		// MOD(agot)
		float AGOT_GetFoWCloudsAlphaMultiplier(float CameraHeight)
		{
			float AlphaMultiplier = AGOT_FOW_CLOUDS_LOW_ALPHA;

			#define AGOT_FOW_CLOUDS_ALPHA_FADE_BETWEEN(FROM, TO)\
			{\
				float HeightRange          = AGOT_FOW_CLOUDS_##TO##_HEIGHT_MIN - AGOT_FOW_CLOUDS_##FROM##_HEIGHT_MAX;\
				float RelativeCameraHeight = saturate((CameraHeight - AGOT_FOW_CLOUDS_##FROM##_HEIGHT_MAX)/HeightRange);\
				float FadedAlphaMultiplier = lerp(AGOT_FOW_CLOUDS_##FROM##_ALPHA, AGOT_FOW_CLOUDS_##TO##_ALPHA, RelativeCameraHeight);\
				float FadeStepValue        = step(AGOT_FOW_CLOUDS_##FROM##_HEIGHT_MAX, CameraHeight);\
				AlphaMultiplier = lerp(AlphaMultiplier, FadedAlphaMultiplier, FadeStepValue);\
			}

			AGOT_FOW_CLOUDS_ALPHA_FADE_BETWEEN(LOW, MEDIUM);
			AGOT_FOW_CLOUDS_ALPHA_FADE_BETWEEN(MEDIUM, HIGH);
			AGOT_FOW_CLOUDS_ALPHA_FADE_BETWEEN(HIGH, FLAT_MAP);

			#undef AGOT_FOW_CLOUDS_ALPHA_FADE_BETWEEN

			return AlphaMultiplier;
		}
		// END MOD

		// MOD(agot)
		// float3 GameApplyFogOfWar( in float3 Color, in float3 Coordinate, float ShadowMultiplier = 1.0 )
		float3 GameApplyFogOfWar( in float3 Color, in float3 Coordinate, PdxTextureSampler2D FogOfWarAlphaMask, float ShadowMultiplier = 1.0 )
		// END MOD
		{
			#ifdef PDX_DEBUG_FOW_OFF
				return Color;
			#endif

			#ifdef JOMINI_DISABLE_FOG_OF_WAR
				return Color;
			#endif

			// PATCH(agotopt)
			#ifdef AGOTOPT_DIAG_NO_FOW
				return Color;
			#endif
			// END PATCH


			// Alpha fade
			// MOD(agot)

			// AGOT uses AGOT_GetFoWCloudsAlphaMultiplier() (see call to it below) instead.

			// float FadeStart = FowFadeEnd - FowFadeStart;
			// float DistanceBlend = FadeStart - CameraPosition.y + FowFadeStart;
			// DistanceBlend = RemapClamped( DistanceBlend, 0.0, FadeStart, 0.0, 1.0 );
			// END MOD

			// MOD(agot)
			//float Alpha = 1.0 - PdxTex2D( FogOfWarAlpha, Coordinate.xz * InverseWorldSize ).r;
			float Alpha = 1.0 - PdxTex2D( FogOfWarAlphaMask, Coordinate.xz * InverseWorldSize ).r;
			//Alpha = lerp( Alpha, 0.0, DistanceBlend );
			// END MOD

			// MOD(agot)
			Alpha *= AGOT_GetFoWCloudsAlphaMultiplier(CameraPosition.y);
			// END MOD

			#ifdef PDX_DEBUG_FOW_MASK
				return float4( Alpha.rrr, 1.0f );
			#endif
			if( _FoWShowAlphaMask > 0.0f ) 
			{
				return vec3( 1.0f - Alpha );
			}

			float ShadowAlpha = smoothstep( _FoWShadowAlphaStart, _FoWShadowAlphaStop, Alpha ) * _FoWShadowColor.a;
			float CloudsAlpha = smoothstep( _FoWCloudsAlphaStart, _FoWCloudsAlphaStop, Alpha ) * _FoWCloudsColor.a;

			// Paralax offset
			float3 ToCam = normalize( CameraPosition - Coordinate );
			float ParalaxDist = ( _FoWCloudHeight - Coordinate.y ) / ToCam.y;
			float3 ParalaxCoord = Coordinate + ToCam * ParalaxDist;

			// Sun shadow offset
			float ShadowCordDist = ( _FoWCloudHeight - Coordinate.y ) / ToSunDir.y;
			Coordinate =  Coordinate + ToSunDir * ShadowCordDist;

			// Cloud and shadow texture
			// PATCH(agotopt): each of the two noise lookups can be reduced to one layer
			// (AGOT's own LOW_QUALITY_SHADERS path) or skipped; a skipped one is 0, i.e.
			// "no cloud here", which is exactly what the lerps below do with a 0.
			float CloudTex = 0.0f;
			float ShadowTex = 0.0f;
			#if !defined( AGOTOPT_NO_CLOUDS )
				#if defined( LOW_QUALITY_SHADERS ) || defined( AGOTOPT_FOW_2TAP )
					CloudTex = smoothstep( _FoWMasterStart, _FoWMasterStop, SampleFowNoiseLowSpec( ParalaxCoord ) );
				#else
					CloudTex = smoothstep( _FoWMasterStart, _FoWMasterStop, SampleFowNoise( ParalaxCoord ) );
				#endif
			#endif
			#if !defined( AGOTOPT_NO_CLOUD_SHADOW )
				#if defined( LOW_QUALITY_SHADERS ) || defined( AGOTOPT_FOW_2TAP )
					ShadowTex = smoothstep( _FoWShadowTexStart, _FoWShadowTexStop, SampleFowNoiseLowSpec( Coordinate ) );
				#else
					ShadowTex = smoothstep( _FoWShadowTexStart, _FoWShadowTexStop, SampleFowNoiseShadow( Coordinate ) );
				#endif
			#endif
			// END PATCH

			// MOD(agot)
			// Prevent clouds from showing up on top of map table & environment
			CloudTex  = lerp(CloudTex, 0.0f, FlatMapLerp);
			ShadowTex = lerp(ShadowTex, 0.0f, FlatMapLerp);
			// END MOD

			// Apply Fog of war and cloud shadow
			float3 FinalColor = lerp( Color, _FoWShadowColor.rgb, _FoWShadowMult * ShadowAlpha );					// Fow darkness
			FinalColor = lerp( FinalColor, _FoWShadowColor.rgb, _FoWShadowMult * ShadowTex * ShadowMultiplier );	// Cloud Shadow

			// Apply clouds
			float GradientControl = smoothstep( _FoWCloudsColorGradientMin, _FoWCloudsColorGradientMax, CloudTex );
			float3 CloudsColor = lerp( _FoWCloudsColorSecondary.rgb, _FoWCloudsColor.rgb, GradientControl );
			FinalColor = lerp( FinalColor, CloudsColor, CloudTex * CloudsAlpha );

			return FinalColor;
		}

		float3 GameApplyFogOfWarMultiSampled( in float3 Color, in float3 Coordinate, PdxTextureSampler2D FogOfWarAlphaMask )
		{
			#ifdef PDX_DEBUG_FOW_OFF
			return Color;
			#endif

			float Alpha = GetFogOfWarAlphaMultiSampled( Coordinate, FogOfWarAlphaMask );
			#ifdef PDX_DEBUG_FOW_MASK
			return float4( Alpha.rrr, 1.0f );
			#endif

			if( _FoWShowAlphaMask > 0.0f ) 
			{
				return vec3( 1.0f - Alpha );
			}
			return FogOfWarBlend( Color, Alpha );
		}

		// Post process
		float4 GameApplyFogOfWar( in float3 WorldSpacePos, PdxTextureSampler2D FogOfWarAlphaMask )
		{
			#ifdef PDX_DEBUG_FOW_OFF
			return vec4(0);
			#endif

			float Alpha = GetFogOfWarAlpha( WorldSpacePos, FogOfWarAlphaMask );

			#ifdef PDX_DEBUG_FOW_MASK
			return float4( Alpha.rrr, 1.0f );
			#endif

			return FOG_OF_WAR_BLEND_FUNCTION( Alpha );
		}

		#undef ApplyFogOfWar
		#undef ApplyFogOfWarMultiSampled
		#define ApplyFogOfWar GameApplyFogOfWar
		#define ApplyFogOfWarMultiSampled GameApplyFogOfWarMultiSampled
	]]
}
