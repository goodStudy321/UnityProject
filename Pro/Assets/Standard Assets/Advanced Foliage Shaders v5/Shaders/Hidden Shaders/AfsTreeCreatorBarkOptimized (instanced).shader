// Upgrade NOTE: replaced 'UNITY_INSTANCE_ID' with 'UNITY_VERTEX_INPUT_INSTANCE_ID'

Shader "Nature/Afs Tree Creator Bark Optimized" {
	Properties {
		_Color 								("Main Color", Color) = (1,1,1,1)
		_MainTex 							("Base (RGB) Occlusion (A)", 2D) = "white" {}
		[NoScaleOffset] _BumpSpecMap 		("Normal Map(GA)", 2D) = "bump" {}
		[NoScaleOffset] _TranslucencyMap 	("Trans (RGB) Smoothness (A)", 2D) = "white" {}

		[Space(6)]
		_AfsXtraBending 					("Extra Leaf Bending", Range(0,10)) = 0
		[Space(6)]
		[Toggle(EFFECT_BUMP)] _EnableDynamicWetness("Enable Dynamic Wetness", Float) = 0
		// x: max strength /y: max smoothness / z: distribution along y / w: distribution roots
		_AfsWetnessTree ("Wetness Settings", Vector) = (1,0.9,20,1)
		
		// These are here only to provide default values
		[HideInInspector] _SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		[HideInInspector] _TreeInstanceColor("TreeInstanceColor", Vector) = (1,1,1,1)
		[HideInInspector] _TreeInstanceScale ("TreeInstanceScale", Vector) = (1,1,1,1)
		[HideInInspector] _SquashAmount ("Squash", Float) = 1
	}
	SubShader {
		Tags { "RenderType"="AfsTreeBark" }
		LOD 200
	
		CGPROGRAM
			#pragma surface surf StandardSpecular vertex:AfsTreeVertBark_Surface fullforwardshadows nolightmap
			#pragma target 3.0

			// Enable instancing for this shader
			#pragma multi_compile_instancing
			#pragma shader_feature EFFECT_BUMP

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpSpecMap;
			sampler2D _TranslucencyMap;
			// AFS Tree Color
			fixed4 _AfsTreeColor;

			// Global vars
			float _AfsRainamount;	


			struct Input {
				float4 AFSuv_MainTex;
				fixed4 color : COLOR;
				float4 screenPos;
				float3 worldNormal;
				half2 Wetness;
				INTERNAL_DATA
			};

			#define SURFACESHADER
			#include "../Includes/AfsTreeLibraryInstanced.cginc"

			void surf (Input IN, inout SurfaceOutputStandardSpecular o) {
				fixed4 c = tex2D(_MainTex, IN.AFSuv_MainTex.xy);
				o.Albedo = c.rgb * IN.color.rgb;
				o.Alpha = 1;

				fixed4 trngls = tex2D (_TranslucencyMap, IN.AFSuv_MainTex.xy);
				o.Smoothness = trngls.a * _Color.r;
				half4 norspc = tex2D (_BumpSpecMap, IN.AFSuv_MainTex.xy);
				o.Specular = unity_ColorSpaceDielectricSpec.rgb;
				o.Normal = UnpackNormalDXT5nm(norspc);

				#if defined(EFFECT_BUMP)
					if (_AfsRainamount > 0.0f) {
						#define MaxWetness _AfsWetnessTree.x
						#define MaxSmoothness _AfsWetnessTree.y

						float porosity = saturate( ((1-o.Smoothness) - 0.5) / 0.4 );
						
						half Rainamount = _AfsRainamount
										// take smoothed world normal up – or ignore it around the roots
										* lerp(saturate( WorldNormalVector(IN, o.Normal).y * 0.6 + 0.4 ), 1, IN.Wetness.y)
										// dampen by ambient occlusion (.a) 
										// check this as it goes > 1
										* IN.color.a * ( 1.0 + 1.0 - c.a * c.a)
										* porosity
										// dampen towards upper parts of the trunk
										* IN.Wetness.x
										// fade out towards billboard
										* IN.AFSuv_MainTex.w;
						Rainamount = saturate(Rainamount * MaxWetness);
						// Calc diffuse factor
						float factor = lerp(1.0, 0.2, porosity);
						// Water influence on material BRDF
						o.Albedo *= lerp(1.0, factor, Rainamount); // Attenuate diffuse
						o.Smoothness = lerp(o.Smoothness, MaxSmoothness, Rainamount);
						// Lerp specular Color towards IOR of Water
						o.Specular = lerp(o.Specular, unity_ColorSpaceDielectricSpec.rgb * 0.5, Rainamount); // unity_ColorSpaceDielectricSpec.rgb = 0.04 / we need 0.02
						o.Normal = lerp(o.Normal, half3(0,0,1), Rainamount * Rainamount * 0.5 );
					}
				#endif		

			//	Fade towards billboard
				if (IN.AFSuv_MainTex.w < 0.9375) { // it never gets 1.0?
					o.Normal = lerp(float3(0,0,1), o.Normal, IN.AFSuv_MainTex.w); //_SquashAmount);	// Fade in normal
					o.Smoothness *= IN.AFSuv_MainTex.w;
					// Stipple in/out Specular
					IN.screenPos.xy /= IN.screenPos.z;
					float2 screenPos = floor( IN.screenPos.xy * _ScreenParams.xy);
					// Interleaved Gradient Noise from http://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare (slide 122)
					half3 magic = float3(0.06711056, 0.00583715, 52.9829189);
					half gradient = frac(magic.z * frac(dot(screenPos.xy, magic.xy)));
					o.Specular *= IN.AFSuv_MainTex.w * (IN.AFSuv_MainTex.w + gradient > 1) ? 1 : 0;
				}

			//	Combine AO from texture input and vertex colors
				o.Occlusion = IN.color.a * c.a;

			//	Valve's Geometric roughness
				/*
				float3 vGeometricNormalWs = WorldNormalVector(IN, half3(0,0,1));
				float3 vNormalWsDdx = ddx( vGeometricNormalWs.xyz );
				float3 vNormalWsDdy = ddy( vGeometricNormalWs.xyz );
				float flGeometricRoughnessFactor = pow( saturate( max( dot( vNormalWsDdx.xyz, vNormalWsDdx.xyz ), dot( vNormalWsDdy.xyz, vNormalWsDdy.xyz ) ) ), 0.333 );
				o.Smoothness *= 1.0 - flGeometricRoughnessFactor; // min(1 - flGeometricRoughnessFactor, o.Smoothness);
				*/

			}
		ENDCG

		// Pass to render object as a shadow caster
		Pass {
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			
			CGPROGRAM
				#pragma vertex vertShadowCaster
				#pragma fragment fragShadowCaster
				#pragma multi_compile_shadowcaster
				// Enable instancing for this shader
				#pragma multi_compile_instancing

				#include "HLSLSupport.cginc"
				#include "UnityCG.cginc"
				#include "Lighting.cginc"

				#define XLEAFBENDING
				//#define LEAFTUMBLING
				#include "../Includes/AfsTreeLibraryInstanced.cginc"

				#if !(defined (SHADER_API_MOBILE) || defined(SHADER_API_GLES) || defined(SHADER_API_D3D11_9X) || defined (SHADER_API_PSP2) || defined (SHADER_API_PSM))
					#define USE_DITHER_MASK 1
				#endif

				// Has a non-empty shadow caster output struct (it's an error to have empty structs on some platforms...)
				#define UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT 1

				#ifdef USE_DITHER_MASK
					sampler3D _DitherMaskLOD;
				#endif
				
				struct VertexInput
				{
					float4 vertex	: POSITION;
					float3 normal	: NORMAL;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
					struct VertexOutputShadowCaster
					{
						V2F_SHADOW_CASTER_NOPOS
						fixed4 color : COLOR;
					};
				#endif

				void vertShadowCaster (appdata_full v,
					#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
						out VertexOutputShadowCaster o,
					#endif
					out float4 opos : SV_POSITION)
				{
					UNITY_SETUP_INSTANCE_ID(v);
					AfsTreeVertBark_DepthNormal (v);
					TRANSFER_SHADOW_CASTER_NOPOS(o,opos)
					o.color = smoothstep(0.0, 0.9375, v.color);
				}


				half4 fragShadowCaster (
					#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
					VertexOutputShadowCaster i
				#endif
				#ifdef USE_DITHER_MASK
					, UNITY_VPOS_TYPE vpos : VPOS
				#endif
				) : SV_Target
				{
					#if defined(USE_DITHER_MASK)
						// NOTE:1.0 was 0.9375

						// from INSIDE
						#if defined(SHADER_API_D3D9)
							float2 uniqueSeed = 0; // As in DX9 vpos is only float2...
						#else
							float2 uniqueSeed = (0.6849 + vpos.z).xx;
						#endif
						half alphaRef = tex3D(_DitherMaskLOD, float3( vpos.xy * 0.25 + uniqueSeed, i.color.r) ).a;
						// Needed to distinguish bewteen shadow and depth pass in forward or mixed mode
						if (i.color.r < 1.0 && unity_LightShadowBias.z != 0.0) {
							// Use dither mask for alpha blended shadows, based on pixel position xy
							// and alpha level. Our dither texture is 4x4x16.
							clip (alphaRef - 0.01);
						}
						else {
							clip (i.color.r - 0.01);
						}
					#else
						clip (i.color.r - 0.01);
					#endif
					SHADOW_CASTER_FRAGMENT(i)
				}
			ENDCG
		}
	}
	Dependency "BillboardShader" = "Hidden/Nature/Afs Tree Creator Bark Rendertex"
	FallBack "Diffuse"
}
