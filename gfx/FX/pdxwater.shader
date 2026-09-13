# Sharp Terrain & Better Water: A Game of Thrones Patch - modified copy of
# gfx/FX/pdxwater.shader from A Game of Thrones 0.5.2.1 (Workshop id 2962333032),
# itself a modified copy of game/gfx/FX/pdxwater.shader from CK3 1.19.0.6 (Scribe).
#
# AGOT's water shader is kept as is (its atmospheric fog and the skybox discard), and
# the changes of "Better Water Without Advanced Shaders" are added on top, exactly as
# in that mod:
#   * "better_water_options.fxh" is included first (it comes from Better Water)
#   * PixelShaderLowSpec (the ocean) draws CalcWaterCheap under WATEROPT_CHEAP_WAVES
#   * PixelShader (lakes) draws CalcWaterCheap when LOW_SPEC_SHADERS is defined,
#     under WATEROPT_CHEAP_LAKES
# CalcWaterCheap itself lives in Better Water's gfx/FX/jomini/jomini_water_default.fxh,
# a file AGOT does not override, so it is not duplicated here.
#
# Load order: A Game of Thrones, Sharp Terrain Without Advanced Shaders, (Real Snow),
# Better Water Without Advanced Shaders, then this mod below all of them.

Includes = {
	"better_water_options.fxh"
	"cw/heightmap.fxh"
	"bordercolor.fxh"
	"jomini/jomini_water_default.fxh"
	"jomini/jomini_water_pdxmesh.fxh"
	"jomini/jomini_water.fxh"
	# MOD(agot)
	#"jomini/jomini_fog_of_war.fxh"
	"agot_atmospheric.fxh"
	"agot_dynamic_terrain.fxh"
	# END MOD
	"jomini/jomini_mapobject.fxh"
	"standardfuncsgfx.fxh"
	"paper_transition.fxh"
	"clouds.fxh"
	"utility_game.fxh"
}

PixelShader =
{
	TextureSampler FogOfWarAlpha
	{
		Ref = JominiFogOfWar
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler FlatMapTexture
	{
		Ref = TerrainFlatMap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	
	TextureSampler ShadowMap
	{
		Ref = PdxShadowmap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
		CompareFunction = less_equal
		SamplerType = "Compare"
	}
	
	MainCode PixelShader
	{
		Input = "VS_OUTPUT_WATER"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				float4 ShadowProj = mul( ShadowMapTextureMatrix, float4( Input.WorldSpacePos, 1.0f ) );
				#if defined( LOW_SPEC_SHADERS ) && defined( WATEROPT_CHEAP_LAKES )
					// Lakes: vanilla draws them with the full water shader even in low spec.
					float4 Water = CalcWaterCheap( Input );
				#else
					float ShadowTerm = CalculateShadow( ShadowProj, ShadowMap );
					float4 Water = CalcWater( Input, ShadowTerm )._Color;
				#endif
				
				#ifdef WATER_COLOR_OVERLAY
					// Not enough texture slots, so use only secondary colors on water.
					#if defined( PDX_OSX ) && defined( PDX_OPENGL )
						ApplySecondaryColorGame( Water.rgb, float2( Input.UV01.x, 1.0f - Input.UV01.y ) );
					#else
						float3 BorderColor;
						float BorderPreLightingBlend;
						float BorderPostLightingBlend;
						GetProvinceOverlayAndBlend( Input.WorldSpacePos.xz, BorderColor, BorderPreLightingBlend, BorderPostLightingBlend );
						GetBorderColorAndBlendGame( Input.WorldSpacePos.xz, Water.rgb, BorderColor, BorderPreLightingBlend, BorderPostLightingBlend );

						// Don't draw too close to the shore to not duplicate the colors with stripes over the land.
						float AccurateHeight = GetHeight( Input.WorldSpacePos.xz );
						BorderPreLightingBlend *= 1.0f - Levels( max( AccurateHeight - ( _WaterHeight - 0.05f ), 0.0f ), 0.0f, 0.05f );

						Water.rgb = lerp( Water.rgb, BorderColor, BorderPreLightingBlend );
					#endif
				#endif
				
				// MOD(agot)
				//Water.rgb = ApplyFogOfWarMultiSampled( Water.rgb, Input.WorldSpacePos, FogOfWarAlpha );
				Water.rgb = AGOT_ApplyAtmosphericEffects(
					Water.rgb,
					Input.WorldSpacePos,
					FogOfWarAlpha,
					AGOT_MakeAtmosphericEffectParamsWater(0.4f, AGOT_GetTerrainVariantIndex(Input.WorldSpacePos.xz))
				);
				// END MOD
				Water.rgb = ApplyMapDistanceFogWithoutFoW( Water.rgb, Input.WorldSpacePos );

				if ( FlatMapLerp > 0.001f )
				{
					float3 FlatMap = PdxTex2D( FlatMapTexture, Input.UV01 ).rgb;
					FlatMap = ApplyFlatMapBrightnessAdjustment( FlatMap );
					float Blend = CalculatePaperTransitionBlend( Input.UV01, FlatMapLerp );
					Water.rgb = lerp( Water.rgb, FlatMap, Blend );
				}

				// MOD(map-skybox)
				 if (Input.WorldSpacePos.x < 0.0 || Input.WorldSpacePos.x >= WorldExtents.x ||
					 Input.WorldSpacePos.z < 0.0 || Input.WorldSpacePos.z >= WorldExtents.y)
				{
					discard;
				}
				// END MOD

				return Water;
			}
		]]
	}

	MainCode PixelShaderLowSpec
	{
		Input = "VS_OUTPUT_WATER"
		Output = "PDX_COLOR"
		Code
		[[			
			// low spec version of CalcWater
			float4 CalcWaterLowSpec( VS_OUTPUT_WATER Input, out float Depth )
			{
				float Height = GetHeightMultisample( Input.WorldSpacePos.xz, 0.65 );
				Depth = Input.WorldSpacePos.y - Height;
				
				float WaterFade = 1.0 - saturate( (_WaterFadeShoreMaskDepth - Depth) * _WaterFadeShoreMaskSharpness );
				float4 WaterColorAndSpec = PdxTex2D( WaterColorTexture, Input.UV01 );
				
				return float4(WaterColorAndSpec.xyz, WaterFade);
			}

			PDX_MAIN
			{
				#ifdef WATEROPT_CHEAP_WAVES
					float4 Water = CalcWaterCheap( Input );
				#else
					float Depth;
					float4 Water = CalcWaterLowSpec( Input, Depth );
				#endif

				#ifdef WATER_COLOR_OVERLAY
						ApplySecondaryColorGame( Water.rgb, float2( Input.UV01.x, 1.0f - Input.UV01.y ) );
				#endif
				
				// MOD(agot)
				//Water.rgb = ApplyFogOfWarMultiSampled( Water.rgb, Input.WorldSpacePos, FogOfWarAlpha );
				Water.rgb = AGOT_ApplyAtmosphericEffects(
					Water.rgb,
					Input.WorldSpacePos,
					FogOfWarAlpha,
					AGOT_MakeAtmosphericEffectParamsWater(0.4f, 0)
				);
				// END MOD
				Water.rgb = ApplyMapDistanceFogWithoutFoW( Water.rgb, Input.WorldSpacePos );

				Water.rgb = FlatMapLerp > 0.0f ? lerp( Water.rgb, PdxTex2D( FlatMapTexture, Input.UV01 ).rgb, FlatMapLerp ) : Water.rgb;

				// MOD(map-skybox)
				 if (Input.WorldSpacePos.x < 0.0 || Input.WorldSpacePos.x >= WorldExtents.x ||
					 Input.WorldSpacePos.z < 0.0 || Input.WorldSpacePos.z >= WorldExtents.y)
				{
					Water.a = 1.0f;
				}
				// END MOD

				return Water;
			}
		]]
	}
}


Effect water
{
	VertexShader = "JominiWaterVertexShader"
	PixelShader = "PixelShader"
}

Effect waterLowSpec
{
	VertexShader = "JominiWaterVertexShader"
	PixelShader = "PixelShaderLowSpec"
}

Effect lake
{
	VertexShader = "VS_jomini_water_mesh"
	PixelShader = "PixelShader"
}
Effect lake_mapobject
{
	VertexShader = "VS_jomini_water_mapobject"
	PixelShader = "PixelShader"
}
