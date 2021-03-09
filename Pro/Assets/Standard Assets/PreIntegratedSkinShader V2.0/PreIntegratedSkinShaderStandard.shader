// Pre-Integrated Skin Shader for Unity3D
//  
// Author:
//       Maciej Kacper Jagiełło <maciej@jagiello.it>
// 
// Copyright (c) 2013 Maciej Kacper Jagiełło
// 
// This file is provided under standard Unity Asset Store EULA
// http://unity3d.com/company/legal/as_terms

Shader "Skin/PreIntegratedSkinShaderV2.0_Standard" {
	Properties {
		[PSSTitle()] _("Diffuse", Float) = 0.0
		_Color ("Tint Color", Color) = (1,1,1,1)
		_MainTex ("Diffuse Map (RGB)", 2D) = "white" {}
		
		[PSSTitle()] _("Subsurface Scattering", Float) = 0.0
		[PSSProfileReference()] _PSSProfile("Diffusion Profile", 2D) = "black" {}
		[PSSBumpinessBiasSlider()] _BlurRange("Blur range", Vector) = (0.0, 1.0, 0.0, 0.0)
		
		_ScatteringOffset ("Scattering Boost", Range(0,1)) = 0.0
		_ScatteringPower ("Scattering Power", Range(0,2)) = 1.0
		
		//_WorldScale("Avg. world scale", Float) = 1.0
		
		[NoScaleOffset]_DepthMap ("Depth / Thickness Map (R)", 2D) = "white" {}
		
		[PSSTitle()] _("General", Float) = 0.0
		[NoScaleOffset]_BumpMap ("Normal Map", 2D) = "bump" {}
		[NoScaleOffset]_SkinMask ("Skin Mask (R)", 2D) = "white" {}
		
		[PSSTitle()] _("Specular", Float) = 0.0
		
		_SpecBlur ("Bumpiness", Range(0,1)) = 1.0
		_SpecEnvMapIntensity ("Environment Intensity", Range(0,1)) = 0.5
		
		[PowerSlider(2.0)]_SpecIntensity ("F0 (Intensity at 0°)", Range(0,2)) = 0.028
		_SpecGlossiness ("Glossiness", Range(0,2)) = 0.7
		
		[NoScaleOffset]_SpecularMap ("Intensity Map (RGB)", 2D) = "white" {}
		[NoScaleOffset]_GlossinessMap ("Glossiness Map (R)", 2D) = "white" {}

		[PSSTitle()] _("Translucency", Float) = 0.0
		_TranslucencyOffset ("Offset", Range(0,1)) = 0.0
		_TranslucencyScale ("Scale", Range(0,10)) = 3.0
		_TranslucencyPower ("Power", Range(0,2)) = 1
		_TranslucencyRadius ("Radius", Range(0,1)) = 1
		_TranslucencyColor ("Tint Color", Color) = (1,1,1,1)
		[NoScaleOffset]_TranslucencyMap ("Tint / Subsurface Map (RGB)", 2D) = "white" {}
		
		[PSSTitle()] _("Ambient Occlusion", Float) = 0.0
		_AmbientOcclusionStrength ("Strength", Range(0,2)) = 1.0
		_AmbientOcclusionLightSuppression ("Suppression", Range(0,1)) = 1.0
		_AmbientOcclusionScattering ("Scattering", Range(0,2)) = 1.0
		[NoScaleOffset]_AmbientOcclusionTex ("Occlusion Texture (R)", 2D) = "white" {}
		
		[PSSFoldableTitle()] _PSSInternalExpanded("Internal", Float) = 0.0
		
		[PSSInternal]_LookupDirect("_LookupDirect", 2D) = "white" {}
		[PSSInternal]_LookupDirectSM2("_LookupDirectSM2", 2D) = "white" {}
		[PSSInternal]_LookupSH("_LookupSH", 2D) = "white" {}
		[PSSInternal]_LookupSpecAO("_LookupSpecAO", 2D) = "white" {}
		
		// Default values are for the caucasian profile. Decimals truncated to avoid a Unity bug (#686324) that makes shader not work at runtime.
		[PSSInternal]_PSSProfileHigh_weighths1_var1 ("_PSSProfileHigh_weighths1_var1", Vector) = (0.234, 0.562, 0.644, 0.006)
		[PSSInternal]_PSSProfileHigh_weighths2_var2 ("_PSSProfileHigh_weighths2_var2", Vector) = (0.101, 0.415, 0.341, 0.048)
		[PSSInternal]_PSSProfileHigh_weighths3_var3 ("_PSSProfileHigh_weighths3_var3", Vector) = (0.113, 0.009, 0.007, 0.187)
		[PSSInternal]_PSSProfileHigh_weighths4_var4 ("_PSSProfileHigh_weighths4_var4", Vector) = (0.113, 0.009, 0.007, 0.567)
		[PSSInternal]_PSSProfileHigh_weighths5_var5 ("_PSSProfileHigh_weighths5_var5", Vector) = (0.359, 0.005, 0.000, 1.990)
		[PSSInternal]_PSSProfileHigh_weighths6_var6 ("_PSSProfileHigh_weighths6_var6", Vector) = (0.078, 0.000, 0.000, 7.410)
		[PSSInternal]_PSSProfileHigh_sqrtvar1234 ("_PSSProfileHigh_sqrtvar1234", Vector) = (0.08, 0.219, 0.432, 0.753)
		[PSSInternal]_PSSProfileHigh_transl123_sqrtvar5 ("_PSSProfileHigh_transl123_sqrtvar5", Vector) = (-225.421, -29.808, -7.715, 1.410)
		[PSSInternal]_PSSProfileHigh_transl456_sqrtvar6 ("_PSSProfileHigh_transl456_sqrtvar6", Vector) = (-2.544, -0.725, -0.195, 2.722)
		
		[PSSInternal]_PSSProfileMedium_weighths1_var1 ("_PSSProfileMedium_weighths1_var1", Vector) = (0.335, 0.978, 0.986, 0.023)
		[PSSInternal]_PSSProfileMedium_weighths2_var2 ("_PSSProfileMedium_weighths2_var2", Vector) = (0.227, 0.017, 0.014, 0.377)
		[PSSInternal]_PSSProfileMedium_weighths3_var3 ("_PSSProfileMedium_weighths3_var3", Vector) = (0.438, 0.005, 0.000, 2.939)
		[PSSInternal]_PSSProfileMedium_transl123 ("_PSSProfileMedium_transl123", Vector) = (-62.441, -3.827, -0.491, 0.0)
		[PSSInternal]_PSSProfileMedium_sqrtvar123 ("_PSSProfileMedium_sqrtvar123", Vector) = (0.152, 0.614, 1.714, 0.0)
		
		[PSSInternal]_PSSProfileLow_weighths1_var1 ("_PSSProfileLow_weighths1_var1", Vector) = (0.448, 0.986, 0.993, 0.031)
		[PSSInternal]_PSSProfileLow_weighths2_var2 ("_PSSProfileLow_weighths2_var2", Vector) = (0.552, 0.014, 0.007, 2.395)
		[PSSInternal]_PSSProfileLow_sqrtvar12 ("_PSSProfileLow_sqrtvar12", Vector) = (0.176, 1.548, 0.0, 0.0)
		[PSSInternal]_PSSProfileLow_transl ("_PSSProfileLow_transl", Vector) = (-1.0387, -35.927, -55.504, 0.0)
	}
	Category {
		CGINCLUDE
			// quality settings common for all sub-shaders
			#define PSS_ENABLE_DIRECTLIGHT 1
			#define PSS_ENABLE_DIFFUSE 1
			#define PSS_ENABLE_SPECULAR 1

			// Enable this if you're targeting a platform without linear rendering support, including Unity 4 Free.
			// Keep in mind that if enabled the skin shader will shade correctly in linear space, but standard shaders
			// wont't, creating a visual inconsistency. Some third party shaders on the asset store do support forced
			// gamma correction like this.
			// You may also want to personalize the shader in base on which textures are already in linear space.
			// #define PSS_FORCE_GAMMA_CORRECTION 1

			// TODO explore the possibility to adjust quality using HARDWARE TIERs

			#if SHADER_TARGET >= 30
				#define PSS_QUALITY PSS_QUALITY_HIGH

				#define PSS_ENABLE_MASK 1
				#define PSS_AMBIENT_OCCLUSION_ON 1
				#define PSS_AMBIENT_OCCLUSION_DIRECTIONAL 1
				
				// note that some of the following settings get suppressed in various SM2 passes
				#define PSS_PENUMBRA_SCATTERING_ON 1
				
				// For now don't scatter cookies, since it's more likely to cause problems than anything else, since what 
				// the cookie means is totally use dependent.
				// In future may reenable it, but only if under an option separate from soft shadow normal penumbra.
				// (this is one of these things where TSD or SSSSS do a much better job).
				//#define PSS_COOKIE_SCATTERING_ON 1
				
				#define PSS_BLURRED_SAMPLING_ON 1
				#define PSS_ENABLE_TRANSLUCENCY 1
				#define PSS_PERPIXELLIGHTPROBES_ON 1
				#define PSS_REFLECTION_PROBES_ON 1
			#elif SHADER_TARGET >= 25
				#define PSS_QUALITY PSS_QUALITY_MEDIUM

				#define PSS_ENABLE_MASK 1
				#define PSS_AMBIENT_OCCLUSION_ON 1
				#define PSS_AMBIENT_OCCLUSION_DIRECTIONAL 1
				
				#define PSS_BLURRED_SAMPLING_ON 1
				#define PSS_ENABLE_TRANSLUCENCY 1
				#define PSS_PERPIXELLIGHTPROBES_ON 1
				#define PSS_REFLECTION_PROBES_ON 1
			#else
				// When it gets compiled to shader model 2, on Direct3D need to fit into mere
				// 64 instructions, so need to cut on something! :(
				// On OpenGLES2.0, let's take on the risk and try emiting a longer glsl shader
				// anyway, so we get at least fundamental features features.
				// As of writing Unity 5.4 is in beta and Android builds crash on my phone, so
				// I'm not yet sure what'll happen. I suspect it will use SM2.5, so we get the
				// goodies, as long as the opengl es driver handles the larger instruction count,
				// otherwise... will it fallback? I guess it won't and the mesh will render
				// transparent with shadows only. If that's the case we can test for SHADER_API_MOBILE
				// and get the goodies on webgl and limit on mobile, maybe. Or just let SM2 be ugly
				// and don't use 2.5 at all.
				// Also specular is enabled only on main directional light, see the subshaders.
				// I know, this sux. Standard shader manages to do specular, but either specular
				// or SSS.
				#define PSS_QUALITY PSS_QUALITY_LOW
			#endif

			
			fixed4 _Color;

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _BumpMap;

			float2 _BlurRange;

			sampler2D _DepthMap;
			float _ScatteringOffset;
			float _ScatteringPower;
			//float _WorldScale;

			float _TranslucencyOffset;
			float _TranslucencyScale;
			float _TranslucencyPower;
			float _TranslucencyRadius;
			fixed4 _TranslucencyColor;
			sampler2D _TranslucencyMap;

			sampler2D _SkinMask;
			sampler2D _SpecularMap;
			float4 _SpecularMap_TexelSize;
			sampler2D _GlossinessMap;
			float4 _GlossinessMap_TexelSize;

			fixed _AmbientOcclusionStrength;
			fixed _AmbientOcclusionScattering;
			float4 _AmbientOcclusionTex_TexelSize;
			sampler2D _AmbientOcclusionTex;
			float _AmbientOcclusionLightSuppression;

			float4 _MainTex_TexelSize;
			float4 _BumpMap_TexelSize;

			float _SpecBlur;
			float _SpecIntensity;
			float _SpecGlossiness;
			
			float _SpecEnvMapIntensity;

			#define PSS_USEMAINTEXUVTRANSFORM 1
			#define PSS_V2F pss_v2f_standard
			#define PSS_VIN appdata_tan

			#include "./PreIntegratedSkinShaderCommon.cginc"
			
			struct pss_v2f_standard {
				PSS_COORDS(0,1,2,3,4,5)
				float4 texMipCnts : TEXCOORD6;
			};
			
			void pss_vert_post(PSS_VIN i, inout PSS_V2F o) {
				o.texMipCnts.x = CALC_MIP_COUNT(_BumpMap);
				o.texMipCnts.y = CALC_MIP_COUNT(_SpecularMap);
				o.texMipCnts.z = CALC_MIP_COUNT(_GlossinessMap);
				o.texMipCnts.w = CALC_MIP_COUNT(_AmbientOcclusionTex);
			}

			inline void pss_surf(PSS_V2F i, inout SkinSurfaceOutput o, float blur) {
				float2 uv = i.uv.xy;
				
				fixed mask = tex2D(_SkinMask, uv).r; // this was originally multiplied by _Color.a, but I removed it to reduce instruction count
				blur = lerp(0.0, blur, mask);

				float bumpinesBiasMin = _BlurRange.x;
				float bumpinesBiasMax = _BlurRange.y;
				
				if (blur == 0.0) {
					// This is when the function is called for specular:
					// ignore blur range which is intended for diffuse scattering and instead use
					// the blur value specified for specular.
					// NB: On low quality settings the lowest diffuse blur level will be used instead
					// and this [hopefully static] branch won't be used.
					bumpinesBiasMin = _SpecBlur;
					bumpinesBiasMax = _SpecBlur;
				}
				
 				o.Albedo = PSS_INPUTGAMMACORRECTION(tex2D(_MainTex, uv).rgb) * _Color.rgb;
				
				o.Normal = UnpackNormal(PSS_SAMPLE_BLURRED_IMPL(_BumpMap, uv, lerp(bumpinesBiasMax, bumpinesBiasMin, blur), i.texMipCnts.x));
				
				float depth = tex2D(_DepthMap, uv).r; // actually inverse of thickness/depth or curvature of the surface
				o.Scattering = saturate((depth + _ScatteringOffset) * _ScatteringPower);
				
				//o.WorldScale = _WorldScale;
				
				o.TranslucencyDepth = saturate(1.0 - depth + _TranslucencyOffset) * _TranslucencyScale;
				
				// squeeze translucency intensity in the range left by radius
				o.TranslucencyColor = PSS_INPUTGAMMACORRECTION(tex2D(_TranslucencyMap, uv).rgb) *  _TranslucencyColor;
				o.TranslucencyColor *= saturate((depth-1.0) / _TranslucencyRadius + 1.0) * _TranslucencyPower;
				
				o.AmbientOcclusionScattering = saturate(depth + _ScatteringOffset) * _AmbientOcclusionScattering; // TODO combine _TranslucencyColor and _TranslucencyPower? a color with multplier slider would be nice?

				o.AmbientOcclusion = PSS_INPUTGAMMACORRECTION(PSS_SAMPLE_BLURRED_IMPL(_AmbientOcclusionTex, uv, lerp(bumpinesBiasMax, bumpinesBiasMin, blur*o.AmbientOcclusionScattering), i.texMipCnts.w).r);
				o.AmbientOcclusion = saturate(lerp(1, o.AmbientOcclusion, _AmbientOcclusionStrength));
				
				o.AmbientOcclusionSuppression = _AmbientOcclusionLightSuppression;
				
				// Sample the spec&gloss with different blur levels as well to reflect the fact that light coming from an area varying in size affects the fragment.
				// This used both for "bumpiness" of specular itself and energy conservation, so it affects diffuse as well.
				o.SpecularIntensity = saturate(PSS_SAMPLE_BLURRED_IMPL(_SpecularMap, uv, lerp(bumpinesBiasMax, bumpinesBiasMin, blur), i.texMipCnts.y).rgb * _SpecIntensity);

				o.SpecularRoughness = 1.0-PSS_SAMPLE_BLURRED_IMPL(_GlossinessMap, uv, lerp(bumpinesBiasMax, bumpinesBiasMin, blur), i.texMipCnts.z).r * _SpecGlossiness;

				#if SHADER_TARGET >= 25
				// Roughness must not be zero and due to precision issues must be at least 0.02.
				o.SpecularRoughness = max(0.02, o.SpecularRoughness);
				#else
				// Optimization: avoid max(0.02, ...) on SM2.
				// On this code path we use lookup textures that already take care of it.
				o.SpecularRoughness = saturate(o.SpecularRoughness);
				#endif
				
				o.SpecularEnvMapIntensity = _SpecEnvMapIntensity;

				o.Scattering *= mask;
				o.TranslucencyColor *= mask;

				o.Emission = 0;
			}
		ENDCG
		
		SubShader {
			Tags { "RenderType"="Opaque" }
			LOD 500
			
			Pass {
				Name "FORWARD"
				Tags { "LightMode"="ForwardBase" }
				Blend Off
				ZWrite On
				ZTest LEqual 
				
				CGPROGRAM
					#pragma target 3.0

					// Exclude flash target, let it fall back to a low quality version.
					// Probably no one is targeting flash anymore as it's deprecated.
					#pragma exclude_renderers flash
					
					// On OpenGL platforms make CG compile to GLSL instead of archaic
					// ARB assembly shaders, which don't support sampling textures with
					// mip map level bias.
					// Hopefully there's aren't many devices/drivers around not supporting
					// it. If there are some, it's probably better to fall back to a dumb
					// shader anyway.
					#pragma glsl
					
					#pragma vertex pss_vert
		            #pragma fragment pss_frag
					
					#pragma multi_compile_fwdbase nolightmap nodirlightmap
					#pragma multi_compile_fog
					#pragma skip_variants DYNAMICLIGHTMAP_ON LIGHTMAP_ON
					
					#define UNITY_PASS_FORWARDBASE
					
					#include "./PreIntegratedSkinShaderCore.cginc"
				ENDCG
			}
			
			Pass {
				Name "FORWARD"
				Tags { "LightMode" = "ForwardAdd" }
				ZWrite Off
				ZTest LEqual 
				Blend One One
				
				CGPROGRAM
					#pragma target 3.0
					
					//#pragma fragmentoption ARB_precision_hint_fastest
					
					// Exclude flash target, let it fall back to a low quality version.
					// Probably no one is targeting flash anymore as it's deprecated.
					#pragma exclude_renderers flash
					
					// On OpenGL platforms make CG compile to GLSL instead of archaic
					// ARB assembly shaders, which don't support sampling textures with
					// mip map level bias.
					// Hopefully there's aren't many devices/drivers around not supporting
					// it. If there are some, it's probably better to fall back to a dumb
					// shader anyway.
					#pragma glsl
					
					#pragma vertex pss_vert
		            #pragma fragment pss_frag
					
					#pragma multi_compile_fwdadd_fullshadows nolightmap nodirlightmap
					#pragma multi_compile_fog
					#pragma skip_variants DYNAMICLIGHTMAP_ON LIGHTMAP_ON
	
					#define UNITY_PASS_FORWARDADD
					
					#include "./PreIntegratedSkinShaderCore.cginc"
				ENDCG
			}
		} // SubShader-SM3.0

		SubShader {
			Tags { "RenderType"="Opaque" }
			LOD 400
			
			Pass {
				Name "FORWARD"
				Tags { "LightMode"="ForwardBase" }
				Blend Off
				ZWrite On
				ZTest LEqual 
				
				CGPROGRAM
					#pragma target 2.5

					// Exclude consoles because they surely don't need the fallback
					// and it's only creating problems.
					// For now I'm listing consoles that are SM3 capable to my knowledge.
					#pragma exclude_renderers ps3 ps4 xbox360 xboxone wiiu

					//#pragma fragmentoption ARB_precision_hint_fastest

					// Exclude flash target, let it fall back to a low quality version.
					// Probably no one is targeting flash anymore as it's deprecated.
					#pragma exclude_renderers flash
					
					// On OpenGL platforms make CG compile to GLSL instead of archaic
					// ARB assembly shaders, which don't support sampling textures with
					// mip map level bias.
					// Hopefully there's aren't many devices/drivers around not supporting
					// it. If there are some, it's probably better to fall back to a dumb
					// shader anyway.
					#pragma glsl
					
					#pragma vertex pss_vert
		            #pragma fragment pss_frag
					
					#pragma multi_compile_fwdbase nolightmap nodirlightmap
					#pragma multi_compile_fog
					#pragma skip_variants DYNAMICLIGHTMAP_ON LIGHTMAP_ON
					
					#define UNITY_PASS_FORWARDBASE

					#include "./PreIntegratedSkinShaderCore.cginc"
				ENDCG
			}
			
			Pass {
				Name "FORWARD"
				Tags { "LightMode" = "ForwardAdd" }
				ZWrite Off
				ZTest LEqual 
				Blend One One
				
				CGPROGRAM
					#pragma target 2.5

					// Exclude consoles because they surely don't need the fallback
					// and it's only creating problems.
					// For now I'm listing consoles that are SM3 capable to my knowledge.
					#pragma exclude_renderers ps3 ps4 xbox360 xboxone wiiu

					//#pragma fragmentoption ARB_precision_hint_fastest
					
					// Exclude flash target, let it fall back to a low quality version.
					// Probably no one is targeting flash anymore as it's deprecated.
					#pragma exclude_renderers flash
					
					// On OpenGL platforms make CG compile to GLSL instead of archaic
					// ARB assembly shaders, which don't support sampling textures with
					// mip map level bias.
					// Hopefully there's aren't many devices/drivers around not supporting
					// it. If there are some, it's probably better to fall back to a dumb
					// shader anyway.
					#pragma glsl
					
					#pragma vertex pss_vert
		            #pragma fragment pss_frag
					
					#pragma multi_compile_fwdadd_fullshadows nolightmap nodirlightmap
					#pragma multi_compile_fog
					#pragma skip_variants DYNAMICLIGHTMAP_ON LIGHTMAP_ON
	
					#define UNITY_PASS_FORWARDADD

					#if SHADER_TARGET <= 20 && defined(UNITY_PASS_FORWARDADD) && (defined(SHADER_API_D3D11_9X) || defined(SHADER_API_D3D9))
						#undef PSS_ENABLE_SPECULAR
					#endif

					#include "./PreIntegratedSkinShaderCore.cginc"
				ENDCG
			}
		} // SubShader-SM2.5

		SubShader {
			Tags { "RenderType"="Opaque" }
			LOD 300
			
			Pass {
				Name "FORWARD"
				Tags { "LightMode"="ForwardBase" }
				Blend Off
				ZWrite On
				ZTest LEqual 
				
				CGPROGRAM
					#pragma target 2.0

					// Exclude consoles because they surely don't need the fallback
					// and it's only creating problems.
					// For now I'm listing consoles that are SM3 capable to my knowledge.
					#pragma exclude_renderers ps3 ps4 xbox360 xboxone wiiu

					//#pragma fragmentoption ARB_precision_hint_fastest

					// Exclude flash target, let it fall back to a low quality version.
					// Probably no one is targeting flash anymore as it's deprecated.
					#pragma exclude_renderers flash
					
					// On OpenGL platforms make CG compile to GLSL instead of archaic
					// ARB assembly shaders, which don't support sampling textures with
					// mip map level bias.
					// Hopefully there's aren't many devices/drivers around not supporting
					// it. If there are some, it's probably better to fall back to a dumb
					// shader anyway.
					#pragma glsl
					
					#pragma vertex pss_vert
		            #pragma fragment pss_frag
					
					#pragma multi_compile_fwdbase nolightmap nodirlightmap
					#pragma multi_compile_fog
					#pragma skip_variants DYNAMICLIGHTMAP_ON LIGHTMAP_ON
					
					#define UNITY_PASS_FORWARDBASE

					#include "./PreIntegratedSkinShaderCore.cginc"
				ENDCG
			}
			
			Pass {
				Name "FORWARD"
				Tags { "LightMode" = "ForwardAdd" }
				ZWrite Off
				ZTest LEqual 
				Blend One One
				
				CGPROGRAM
					#pragma target 2.0

					// Exclude consoles because they surely don't need the fallback
					// and it's only creating problems.
					// For now I'm listing consoles that are SM3 capable to my knowledge.
					#pragma exclude_renderers ps3 ps4 xbox360 xboxone wiiu
					
					//#pragma fragmentoption ARB_precision_hint_fastest
					
					// Exclude flash target, let it fall back to a low quality version.
					// Probably no one is targeting flash anymore as it's deprecated.
					#pragma exclude_renderers flash
					
					// On OpenGL platforms make CG compile to GLSL instead of archaic
					// ARB assembly shaders, which don't support sampling textures with
					// mip map level bias.
					// Hopefully there's aren't many devices/drivers around not supporting
					// it. If there are some, it's probably better to fall back to a dumb
					// shader anyway.
					#pragma glsl
					
					#pragma vertex pss_vert
		            #pragma fragment pss_frag
					
					#pragma multi_compile_fwdadd_fullshadows nolightmap nodirlightmap
					#pragma multi_compile_fog
					#pragma skip_variants DYNAMICLIGHTMAP_ON LIGHTMAP_ON
	
					#define UNITY_PASS_FORWARDADD

					#if SHADER_TARGET <= 20 && defined(UNITY_PASS_FORWARDADD) && (defined(SHADER_API_D3D11_9X) || defined(SHADER_API_D3D9))
						#undef PSS_ENABLE_SPECULAR
					#endif

					#include "./PreIntegratedSkinShaderCore.cginc"
				ENDCG
			}
		} // SubShader-SM2.0

	} // Category
	
	// NB: no meta pass. Skin shader should not be applied to static objects.

	// Shadow pass.
	SubShader { UsePass "VertexLit/SHADOWCASTER" }
	
	// Shadow collector pass for Unity 3/4.
	// For Unity 5 it's not needed anymore and in fact not present in VertexLit so this subshader gets discarded entirely.
	SubShader { UsePass "VertexLit/SHADOWCOLLECTOR" }
	
	FallBack "VertexLit"
}