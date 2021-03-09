Shader "AFS/Foliage Shader" {
	Properties {

		[Space(6)]
		[Enum(UnityEngine.Rendering.CullMode)] _Culling ("Culling", Float) = 0

		[Header(Base Settings)]
		[Space(4)]
		_Color 								("Color", Color) = (1,1,1,1)
		_ColorVariation 					("Color Variation", Color) = (1,1,1,0)
		_MainTex 							("Albedo (RGB) Alpha (A)", 2D) = "white" {}
		_Cutoff 							("Alpha Cutoff", Range(0,1)) = 0.3
		[NoScaleOffset] _BumpTransSpecMap	("Normal (GA) Trans(R) Smoothness(B)", 2D) = "bump" {}
		_SpecularReflectivity				("Specular Reflectivity", Color) = (0.2,0.2,0.2)
		_TranslucencyStrength 				("Translucency", Range(0,1)) = 0.5
		_BackfaceSmoothness 				("Backface Smoothness", Range(0,2)) = 1
		_BouncedLighting					("Bounced Lighting", Range(0.0, 5.0)) = 0.0
		_HorizonFade						("Horizon Fade", Range(0.0, 5.0)) = 1.0
		
		[Header(Wind Settings)]
		[Space(4)]
		_LeafTurbulence 					("Leaf Turbulence", Range(0,1)) = 0.2
		[KeywordEnum(Legacy Vertex Colors, UV4 And Vertex Colors, Vertex Colors)]
		_BendingControls 					("Bending Parameters", Float) = 0 // 0 = legacy vertex colors, 1 = uv4, 2 = vertex colors

		[Space(6)]
		[Toggle(AFS_TOUCHBENDING)]
		_TouchBending 						("Enable Touch Bending", Float) = 0
		[HideInInspector] _TouchBendingPosition ("TouchBendingPosition", Vector) = (0,0,0,0)
		[HideInInspector] _TouchBendingForce ("TouchBendingForce", Vector) = (0,0,0,0)

		[Header(Rain Detail Settings)]
		[Space(4)]
		[Toggle(EFFECT_BUMP)] _RainDetails	("Enable Rain Details", Float) = 0
		[NoScaleOffset] _RainBumpMask 		("Rain Normal (GA) Mask (B)", 2D) = "bump" {}
		_RainTexScale 						("Rain Texture Scale", Float) = 4

		[Space(8)]
	//	[HideInInspector] 
		[Toggle(GEOM_TYPE_BRANCH)] _Pivots ("Baked Pivots", Float) = 0
		[HideInInspector] _DebugMode ("Debug Mode", Float) = 1

	}


	SubShader {
		Tags {
			"Queue"="AlphaTest"
			"IgnoreProjector"="True"
			"RenderType"="AFSFoliageBendingInstanced"
			"AfsMode"="Foliage"
		}

		LOD 200
		Cull [_Culling]
		
		CGPROGRAM
			#pragma surface surf AFSSpecular vertex:AfsFoligeBendingGSFull addshadow fullforwardshadows 
			#pragma target 3.0

			#pragma multi_compile_instancing
			// #pragma instancing_options maxcount:50
			// if pivot is baked
			#pragma multi_compile _ GEOM_TYPE_BRANCH
			#pragma shader_feature AFS_TOUCHBENDING
			#pragma shader_feature EFFECT_BUMP

			#include "Includes/AfsPBSLighting.cginc"
			// Vertex Functions
			#include "TerrainEngine.cginc"
			#include "Includes/AfsFoliageBendingInstanced.cginc"

			fixed4 _Color;
			fixed4 _ColorVariation;
			sampler2D _MainTex;
			sampler2D _BumpTransSpecMap;
			fixed3 _SpecularReflectivity;
			fixed _BackfaceSmoothness;
			fixed _Cutoff;

			half _TranslucencyStrength;

	  		#if defined(EFFECT_BUMP)
				sampler2D _RainBumpMask;
				float _RainTexScale;
			#endif

			// Global vars
			float _AfsRainamount;
			float2 _AfsSpecFade;

			struct Input {
				float2 uv_MainTex;
				fixed4 color : COLOR0;	// color.a = AO
				float3 worldNormal;
				float facingSign : VFACE;
				INTERNAL_DATA
			};


			void AfsFoligeBendingGSFull (inout appdata_full v) 
			{
				float4 bendingCoords;
			
				bendingCoords.rg = v.color.rg;
			//	Legacy Bending:		Primary and secondary bending stored in vertex color blue
			//	New Bending:		Primary and secondary bending stored in uv4: x = primary bending / y = secondary
			//	VeretxColors Only: 	Primary in vertex color A, secondary bending in vertex color blue
				bendingCoords.ba = (_BendingControls == 2) ? v.color.ab : v.texcoord3.xy;
				bendingCoords.ba = (_BendingControls == 0) ? v.color.bb : bendingCoords.ba;

			//	Add variation only if the shader uses UV4
				float variation = (_BendingControls == 1) ? v.color.b * 2 : 0;
				float storedVariation = variation;
	
			//	Baked pivot
				#if defined(GEOM_TYPE_BRANCH)
					//float2 pivotLength = (_BendingControls == 0) ? v.texcoord3.xy : v.texcoord3.zw;
					float2 pivotLength = (_BendingControls == 1) ? v.texcoord3.zw : v.texcoord3.xy;
					float3 normalToPivot = frac(pivotLength.xxx * float3(1.0, 256.0f, 65536.0f) );
					normalToPivot = normalToPivot * 2.0 - 1.0;
					float3 pivot = normalToPivot * pivotLength.y;
					float originalLength = pivotLength.y;
					AfsAnimateVertex (v.vertex, v.normal, v.tangent, pivot, originalLength, bendingCoords, variation);
				#else
					AfsAnimateVertex (v.vertex, v.normal, v.tangent, float3(0,0,0), 0.0f, bendingCoords, variation);
				#endif

			//	Store Fade for specular highlights
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				v.color.r = variation; // (_BendingControls == 2) ? 1.0 - saturate(storedVariation) : variation;
				v.color.b = saturate( ( _AfsSpecFade.x - distance(_WorldSpaceCameraPos, worldPos)) / _AfsSpecFade.y);
				v.normal = normalize(v.normal);
				v.tangent.xyz = normalize(v.tangent.xyz);

			//	Set proper v.color.a
				v.color.a = (_BendingControls == 2) ? 1 : v.color.a;
			}


			void surf (Input IN, inout SurfaceOutputAFSSpecular o) {
				half4 c = tex2D (_MainTex, IN.uv_MainTex.xy) * _Color;
			//	Do early alpha test
				clip(c.a - _Cutoff);
				
			//	Add Color Variation
				o.Albedo = lerp(c.rgb, (c.rgb * _ColorVariation.rgb), IN.color.r * _ColorVariation.a);
				o.Alpha = c.a;

				fixed4 trngls = tex2D(_BumpTransSpecMap, IN.uv_MainTex.xy);
				o.Smoothness = trngls.b;
				o.Specular = _SpecularReflectivity;

			//	Backface Smoothness
				o.Smoothness = (IN.facingSign > 0) ? o.Smoothness : o.Smoothness * _BackfaceSmoothness;
				
				o.Normal = UnpackNormalDXT5nm(trngls) * half3(1,1,IN.facingSign);
				o.VertexNormal = WorldNormalVector(IN, half3(0,0,IN.facingSign) );
				
				o.Occlusion = IN.color.a;

			// 	Get Rain Detail Texture
				#if defined(EFFECT_BUMP)
					fixed4 RainTexSample = tex2D(_RainBumpMask, IN.uv_MainTex.xy * _RainTexScale);
				#endif
				
			//	Add Rain
				if (_AfsRainamount > 0.0f) {
					float3 worldNormal = WorldNormalVector (IN, o.Normal);
				 	float Rainamount = saturate(_AfsRainamount * worldNormal.y);
					float porosity = saturate( ((1-o.Smoothness) - 0.5) / 0.4 );
					// Calc diffuse factor
					float factor = lerp(1.0, 0.2, porosity);
					// Water influence on material BRDF
					o.Albedo *= lerp(1.0, factor, Rainamount); // Attenuate diffuse
					o.Smoothness = lerp(o.Smoothness, 0.9, Rainamount);
					// Lerp specular Color towards IOR of Water
					o.Specular = lerp(o.Specular, unity_ColorSpaceDielectricSpec.rgb * 0.5, Rainamount);
					// Add rain drop normal
					#if defined(EFFECT_BUMP)
						fixed Mask = RainTexSample.g;
						float wetBlend = saturate(Mask + Rainamount - 1);
						float3 Normal = UnpackNormalDXT5nm(RainTexSample);
						Normal = lerp(half3(0,0,1), Normal, saturate(wetBlend * 10) );
						o.Normal = BlendNormals(o.Normal, Normal);
					#endif
				}
			//	Fade out smoothness and translucency
				o.Smoothness *= IN.color.b;
				o.Translucency = trngls.r * _TranslucencyStrength * IN.color.b;
			}
		ENDCG
	}
}
