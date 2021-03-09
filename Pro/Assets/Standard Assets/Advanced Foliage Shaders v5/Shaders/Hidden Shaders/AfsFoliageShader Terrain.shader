// Advanced Foliage shader for the terrain engine replacing the built in vertex lit shader

Shader "Hidden/TerrainEngine/Details/Vertexlit" {
	Properties {
		_MainTex 							("Base (RGB)", 2D) = "white" {}
		_Cutoff 							("Alpha cutoff", Range(0,1)) = 0.3
		_LeafTurbulence 					("Leaf Turbulence", Range(0,4)) = 0.7
		[HideInInspector] _BendingControls 	("Bending Parameters", Float) = 0
		[HideInInspector] _IsCombined 		("Combined Mesh", Float) = 1
		_HorizonFade						("Horizon fade", Range(0.0, 5.0)) = 1.0
		_BouncedLighting					("Bounced Lighting", Range(0.0, 5.0)) = 2.0
	}

	SubShader {
		Tags {
			"Queue"="AlphaTest"
			"IgnoreProjector"="True"
			"RenderType"="AFSFoliageBendingVertexLit"
			"AfsMode"="Foliage"
		}
		LOD 200
		Cull Off
		CGPROGRAM
		
		// Use our own early alpha testing: so no alphatest:_Cutoff
		#pragma surface surf AFSSpecular vertex:AfsFoligeBendingGSFull addshadow fullforwardshadows exclude_path:prepass keepalpha 
		#pragma target 3.0
		#define TANGETFREELIGHTING
		#define VERTEXLIT
		#pragma shader_feature _LEGACYBENDING

		// Lighting Function
		#include "../Includes/AfsPBSLighting.cginc"
		// Vertex Functions
		#include "TerrainEngine.cginc"
		#include "../Includes/AfsFoliageBendingInstanced.cginc"

		sampler2D _MainTex;
		float4 _MainTex_ST;
		fixed _AfsAlphaCutOff;
		fixed _VertexLitBackfaceSmoothness;
		fixed4 _VertexLitColorVariation;
		sampler2D _TerrianBumpTransSpecMap;
		half3 _AfsSpecularReflectivity;
		
		// Global vars
		float _AfsRainamount;
		float2 _AfsSpecFade;


		struct Input {
			float4 myuv_MainTex;	// here we need float4
			fixed4 color : COLOR;	// color.a = AO
			float3 worldNormal;
			float3 worldPos;
			float3 worldViewDir;
			float3 vertexNormal;
			float facingSign : VFACE;
			INTERNAL_DATA
		};

/*		inline float4 createTangentFrame(float3 normal)
		{
			float3 bitangent;
			if(abs(normal.x) > abs(normal.y))
				bitangent = float3(normal.z, 0.f, -normal.x) / length(float2(normal.x, normal.z));
			else
				bitangent = float3(0.f, normal.z, -normal.y) / length(float2(normal.y, normal.z));
			float3 tangent = cross(bitangent, normal);
			float3 bitangent1 = cross(normal, tangent);
			float sign = (dot(bitangent1, bitangent) < 0) ? -1.0 : 1.0;
			return float4(tangent.xyz, sign.x);
		} */


		void AfsFoligeBendingGSFull (inout appdata_vertexlit v, out Input o) 
		{
			UNITY_INITIALIZE_OUTPUT(Input,o);
			o.myuv_MainTex.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
		//	v.tangent = createTangentFrame(v.normal); // nvidia
		//	Supply the shader with "some" tangents	// cm: still better :-)
			#if !defined (TANGETFREELIGHTING)
				float3 newBinormal = cross(float3(1, 0, 1), v.normal);
				float3 newTangent = normalize(cross(v.normal.xyz, newBinormal.xyz));
				float3 newBinormal1 = cross(v.normal, newTangent);
				v.tangent.xyz = normalize(newTangent);
				v.tangent.w = (dot(newBinormal1, newBinormal) < 0) ? -1.0 : 1.0;
			#endif

			float4 bendingCoords;

		//	DX9 "changes" vertex colors... dx11 does not (last checked with Unity 5.4.0f3)
		//	TODO: what happens with alpha on dx 9?????
			#if (SHADER_API_D3D9)
				#if defined(_LEGACYBENDING)
					bendingCoords.xyzw = v.color.zyxx;
				#else
					bendingCoords.xyzw = v.color.rgab;
					v.color.a = 1;
				#endif
			#else
				#if defined(_LEGACYBENDING)
					bendingCoords.xyzw = v.color.rgbb;
				#else
					bendingCoords.xyzw = v.color.rgab;
					v.color.a = 1;
				#endif
			#endif

		//	Terrain engine supports vertex colors only – no uv4
			//float2 variations = frac((v.texcoord2.xy) * _AfsVertexLitVariation);
			float2 variations =  abs ( frac(( v.texcoord1.xy) * _AfsVertexLitVariation) - 0.5); // * 2;
			float variation = (variations.x + variations.y); // * 0.5;

		//	Early exit if there is nothing to animate (pivots or even rocks)
			if (bendingCoords.z + bendingCoords.w > 0) {
				// No baked pivots – but we use it to store uv2 which gives us some variation
				AfsAnimateVertex (v.vertex, v.normal, v.tangent, float3(v.texcoord1.x, 0.0f, v.texcoord1.y) * _AfsVertexLitVariation, 0.0f, bendingCoords, variation);
				v.normal = normalize(v.normal);
				v.tangent.xyz = normalize(v.tangent.xyz);
			}

		//	Store Fade for specular highlights
			float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			o.myuv_MainTex.w = saturate( ( _AfsSpecFade.x - distance(_WorldSpaceCameraPos, worldPos)) / _AfsSpecFade.y);
			v.color.r = variation; //saturate(variation);

		//	From Grass Shader. Needed to fade out Details over distance.
			float3 offset = v.vertex.xyz - _WorldSpaceCameraPos;
			v.color.b = saturate (2 * (_AfsWaveAndDistance.w - dot (offset, offset)) * ( 0.85 /* was 1.0 */ / _AfsWaveAndDistance.w) );

			#if defined (TANGETFREELIGHTING)
				o.vertexNormal = v.normal;
			#endif

		}


		void surf (Input IN, inout SurfaceOutputAFSSpecular o) {
			half4 c = tex2D (_MainTex, IN.myuv_MainTex.xy);
			o.Alpha = c.a * IN.color.b; // IN.color.b: distance fade
			
		//	Do early alpha test
			clip(o.Alpha - _AfsAlphaCutOff);

			// x = smoothness, y = translucency
			fixed4 varation = saturate( fixed4(IN.color.r + 0.75, IN.color.r + 0.75, 1, 1) );

		//	Add Color Variation
			o.Albedo = lerp(c.rgb, (c.rgb * _VertexLitColorVariation.rgb), IN.color.r * _VertexLitColorVariation.a);
			
			fixed4 trngls = tex2D(_TerrianBumpTransSpecMap, IN.myuv_MainTex.xy);
			o.Smoothness = trngls.b * varation.x;
			o.Specular = _AfsSpecularReflectivity;

		//	Backface Smoothness
			o.Smoothness = (IN.facingSign > 0) ? o.Smoothness : o.Smoothness * _VertexLitBackfaceSmoothness;

			#if defined(_LEGACYBENDING)
				o.Occlusion = IN.color.a;
			#endif

			#if defined(TANGETFREELIGHTING)
			//	Needed fix for surface shaders... otherwise IN.worldViewDir.xyz and IN.vertexNormal.xyz won't get compiled out...
				o.Albedo += (IN.worldViewDir.xyz + IN.vertexNormal.xyz) * 0.00001;
			//	Per Pixel Tangent	
				float3x3 TBN = GetCotangentFrame( normalize(IN.vertexNormal), normalize(-IN.worldViewDir), IN.myuv_MainTex.xy);

			//	Less accurate but cheaper
				//o.Albedo += (IN.worldViewDir.xyz + IN.vertexNormal.xyz + IN.worldPos.xyz) * 0.00001;
				//float3x3 TBN = GetCotangentFrameNew( normalize(IN.vertexNormal), IN.worldPos, IN.myuv_MainTex.xy);

			//	Per Pixel WorldNormal
				// Please note: here we have to multiply all component using facingSign!? best match
				o.Normal = UnpackNormalDXT5nm(trngls) * IN.facingSign; // half3(1,1,IN.facingSign);
				o.WorldNormal = mul(o.Normal, TBN); // normalize is done in the lighting function
				o.VertexNormal = mul(half3(0,0,IN.facingSign), TBN);
			#else
				o.Normal = UnpackNormalDXT5nm(trngls) * half3(1,1,IN.facingSign);
				o.VertexNormal = WorldNormalVector (IN, half3(0,0,IN.facingSign) );
			#endif

		//	Add Rain
			if (_AfsRainamount > 0.0f) {
				//	Calc WorldNormal
				#if defined(TANGETFREELIGHTING)
					float3 worldNormal = o.WorldNormal;
				#else
					float3 worldNormal = WorldNormalVector (IN, o.Normal);
			 	#endif
			 	float Rainamount = saturate(_AfsRainamount * worldNormal.y);
				float porosity = saturate( ((1-o.Smoothness) - 0.5) / 0.4 );
				// Calc diffuse factor
				float factor = lerp(1, 0.2, porosity);
				// Water influence on material BRDF
				o.Albedo *= lerp(1.0, factor, Rainamount); // Attenuate diffuse
				o.Smoothness = lerp(o.Smoothness, 0.9, Rainamount);
				// Lerp specular Color towards IOR of Water
				o.Specular = lerp(o.Specular, unity_ColorSpaceDielectricSpec.rgb * 0.5, Rainamount);
			}

		//	Fade out smoothness and translucency
			o.Smoothness *= IN.color.b; // Less "noise" while fading out the mesh  //IN.myuv_MainTex.w; // specfade
			o.Translucency = trngls.r * varation.y
				// as we do not have any selfshadowing
				#if defined(_LEGACYBENDING)
					* saturate( IN.color.a + 0.5)
				#endif
					* _AfsVertexLitTranslucency
					* IN.myuv_MainTex.w // specfade				
			; 
		}
		ENDCG
	}
}
