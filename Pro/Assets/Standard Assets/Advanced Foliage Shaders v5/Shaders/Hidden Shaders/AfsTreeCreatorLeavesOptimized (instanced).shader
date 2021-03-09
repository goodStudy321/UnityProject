// Upgrade NOTE: replaced 'UNITY_INSTANCE_ID' with 'UNITY_VERTEX_INPUT_INSTANCE_ID'


Shader "Nature/Afs Tree Creator Leaves Optimized" {
Properties {
	_Color 								("Color", Color) = (1,1,1,1)
	_MainTex 							("Base (RGB) Alpha (A)", 2D) = "white" {}
	_Cutoff 							("Alpha cutoff", Range(0,1)) = 0.3
	[NoScaleOffset] _BumpSpecMap		("Normalmap (GA)", 2D) = "bump" {}
	[NoScaleOffset] _TranslucencyMap	("Translucency (B) Smoothness(A)", 2D) = "white" {}
	
	[Header(Flattended trees only)]
	[Space(4)]
	_AfsXtraBending 					("Extra Leaf Bending", Range(0,10)) = 0
	// Needed by flattended Trees
	[Space(6)]
	[Toggle(EFFECT_BUMP)] _EnableDynamicWetness("Enable Dynamic Wetness", Float) = 0
	// x: max strength /y: max smoothness / z: distribution along y / w: distribution roots
	_AfsWetnessTree 					("Wetness Settings", Vector) = (1,0.9,0,0)
	
	[Header(CTI trees only)]
	[Space(4)]
	_TumbleStrength						("Tumble Strength", Range(0,1)) = 0.1
	_TumbleFrequency					("Tumble Frequency", Range(0,2)) = 1

	// These are here only to provide default values
	[HideInInspector] _TreeInstanceColor("TreeInstanceColor", Vector) = (1,1,1,1)
	[HideInInspector] _TreeInstanceScale ("TreeInstanceScale", Vector) = (1,1,1,1)
	[HideInInspector] _SquashAmount ("Squash", Float) = 1

	// These are here only to stop Unity from spamming the console with errors
	[HideInInspector] _TranslucencyColor ("Translucency Color", Color) = (0.73,0.85,0.41,1) // (187,219,106,255)
	[HideInInspector] _TranslucencyViewDependency ("View dependency", Range(0,1)) = 0.7
	[HideInInspector] _ShadowStrength("Shadow Strength", Range(0,1)) = 0.8

	_HorizonFade						("Horizon fade", Range(0.0, 5.0)) = 1.0
}


SubShader { 
	Tags {
		"IgnoreProjector"="True"
		"RenderType"="AFSTreeLeaf"
	}
	LOD 200
	CGPROGRAM
		// Use our own early alpha testing: so no alphatest:_Cutoff
		#pragma surface surf AFSSpecular vertex:AfsTreeVertLeaf nolightmap fullforwardshadows keepalpha
		#pragma target 3.0
		
		#define XLEAFBENDING
		//#define LEAFTUMBLING

		// Use ISTREE to tell the lighting function to fade out point and spot lights as well as shadows (forward only)
		#define ISTREE
		// Use ALWAYSFORWARD to deactivate support for deferred rendering
		// #define ALWAYSFORWARD

		#pragma multi_compile_instancing
		#pragma shader_feature EFFECT_BUMP

		#include "../Includes/AfsPBSLighting.cginc"
		#include "../Includes/AfsTreeLibraryInstanced.cginc"
		
		sampler2D _MainTex;
		float4 _MainTex_ST;
		fixed _Cutoff;
				
		sampler2D _BumpSpecMap;
		sampler2D _TranslucencyMap;
		// AFS Tree Color
		fixed4 _AfsTreeColor;

		// Global vars
		float _AfsRainamount;
		
		struct Input {
			float4 AFSuv_MainTex;
			fixed4 color : COLOR; // color.a = AO
			float4 screenPos;
			float3 worldNormal;
			INTERNAL_DATA
		};


		void AfsTreeVertLeaf (inout appdata_full v, out Input o) 
		{
			UNITY_INITIALIZE_OUTPUT(Input,o);
			o.AFSuv_MainTex.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
			float4 TreeWorldPos = float4(unity_ObjectToWorld[0].w, unity_ObjectToWorld[1].w, unity_ObjectToWorld[2].w, 0);
			float Distance = distance(_WorldSpaceCameraPos.xyz, TreeWorldPos.xyz);
			float fadeState = saturate( ( _AfsTerrainTrees.x - Distance) / _AfsTerrainTrees.y );
			TreeWorldPos.w = clamp(fadeState * UNITY_ACCESS_INSTANCED_PROP(_SquashAmount_arr, _SquashAmount), 0.0, 1.0);
		//	Depricated: Apply Billboard Extrusion (if any)
		//	ExpandBillboard (UNITY_MATRIX_IT_MV, v.vertex, v.normal, v.tangent);
		
		//	Scale
			v.vertex.xyz *= UNITY_ACCESS_INSTANCED_PROP(_TreeInstanceScale_arr, _TreeInstanceScale).xyz;
		//	Decode UV3
			float3 pivot;
			#if defined(LEAFTUMBLING)
				// 15bit compression 2 components only, important: sign of y
				pivot.xz = (frac(float2(1.0f, 32768.0f) * v.texcoord2.xx) * 2) - 1;
				pivot.y = sqrt(1 - saturate(dot(pivot.xz, pivot.xz)));
				pivot *= v.texcoord2.y;
				pivot *= UNITY_ACCESS_INSTANCED_PROP(_TreeInstanceScale_arr, _TreeInstanceScale).xyz;
			#endif
		//	Add extra animation to make it fit speedtree
			TreeWorldPos.xyz = abs(TreeWorldPos.xyz);
			float sinuswave = _SinTime.z;
			float offset = abs(frac((TreeWorldPos.x + TreeWorldPos.z) * 5) - 0.5) * 2; 
			float4 vOscillations = AfsSmoothTriangleWave(float4(offset + sinuswave , offset + sinuswave * 0.8, 0.4 * (sinuswave + offset), 0));
			//vOscillations.z *= sign(vOscillations.z);
			float fOsc = vOscillations.x + (vOscillations.y * vOscillations.z);
			fOsc = (fOsc + 3.0) * 0.33;
		//	Apply Wind
			v.vertex = afsAnimateVertex( float4(v.vertex.xyz, v.color.b), float4(v.normal.xyz,fOsc), float4(v.color.xy, v.texcoord1.xy), float4(pivot,TreeWorldPos.w));
			v.vertex = AfsSquashNew(v.vertex, TreeWorldPos.w);

			v.normal = normalize(v.normal);
			v.tangent.xyz = normalize(v.tangent.xyz);
		//	Apply tree color
			v.color.rgb = lerp(_AfsTreeColor, 1.0, UNITY_ACCESS_INSTANCED_PROP(_TreeInstanceColor_arr, _TreeInstanceColor).g); // * _Color.rgb;
		//	Store fadestate (delayed)
			o.AFSuv_MainTex.z = TreeWorldPos.w;
			fadeState = saturate( ( _AfsTerrainTrees.x - _AfsTerrainTrees.y * 1.5 - Distance) / (_AfsTerrainTrees.y) );
			float shadowState = saturate(fadeState * UNITY_ACCESS_INSTANCED_PROP(_SquashAmount_arr, _SquashAmount));

			o.AFSuv_MainTex.w = shadowState;
		}
 

		void surf (Input IN, inout SurfaceOutputAFSSpecular o) {
			fixed4 c = tex2D(_MainTex, IN.AFSuv_MainTex.xy);
			o.Alpha = c.a;
			// Do early alpha test
			clip(o.Alpha - _Cutoff);

			// Kick off expensive operations up front so that the shader does not stall
			fixed4 trngls = tex2D (_TranslucencyMap, IN.AFSuv_MainTex.xy);
			fixed4 norspc = tex2D (_BumpSpecMap, IN.AFSuv_MainTex.xy);

			o.Albedo = c.rgb * IN.color.rgb;
			o.Specular = unity_ColorSpaceDielectricSpec.rgb;
			o.Occlusion = IN.color.a;
			o.Smoothness = trngls.a; // * _Color.r;
			o.Translucency = trngls.b;
			o.Lighting = IN.AFSuv_MainTex.z;	// this is only relavant for forward lighting
			o.Normal = UnpackNormalDXT5nm(norspc);
			o.VertexNormal = WorldNormalVector(IN, half3(0,0,1));

			#if defined(EFFECT_BUMP)
				if (_AfsRainamount > 0) {
					#define MaxWetness _AfsWetnessTree.x
					#define MaxSmoothness _AfsWetnessTree.y
					half Rainamount = _AfsRainamount
									// take smoothed world normal up 
									* saturate( WorldNormalVector(IN, o.Normal).y * 0.7 + 0.3 )
									// dampen by ambient occlusion (.a) and add variation (.r)
									* IN.color.a // * IN.color.r;
									* MaxWetness
									// fade out towards billboard
									* IN.AFSuv_MainTex.w;
					float porosity = saturate( ((1-o.Smoothness) - 0.5) / 0.4 );
					// Calc diffuse factor
					float factor = lerp(1.0, 0.2, porosity);
					// Water influence on material BRDF
					o.Albedo *= lerp(1.0, factor, Rainamount); // Attenuate diffuse
					o.Smoothness = lerp(o.Smoothness, MaxSmoothness, Rainamount);
					// Lerp specular Color towards IOR of Water
					o.Specular = lerp(o.Specular, unity_ColorSpaceDielectricSpec.rgb * 0.5, Rainamount);
				}
			#endif

			if (IN.AFSuv_MainTex.w < 0.9375) {	// it never gets 1.0?
				o.Smoothness *= IN.AFSuv_MainTex.w;
				// Stipple in Specular
				IN.screenPos.xy /= IN.screenPos.z;
				float2 screenPos = floor( IN.screenPos.xy * _ScreenParams.xy);
				// Interleaved Gradient Noise from http://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare (slide 122)
				half3 magic = float3(0.06711056, 0.00583715, 52.9829189);
				half gradient = frac(magic.z * frac(dot(screenPos.xy, magic.xy)));
				o.Specular *= (IN.AFSuv_MainTex.w + gradient > 1) ? 1 : 0;
				o.Translucency *= IN.AFSuv_MainTex.w;	// Fade in Translucency (delayed)
			}

			if (IN.AFSuv_MainTex.z < 1.0) {
				o.Normal = lerp(float3(0,0,1), o.Normal, IN.AFSuv_MainTex.z); 	// Fade in normal
			}
		}
	ENDCG


// TODO: mixed modus depth mask is broken!

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

		// Need to output UVs in shadow caster, since we need to sample texture and do clip/dithering based on it
		#define UNITY_STANDARD_USE_SHADOW_UVS 1

		// Has a non-empty shadow caster output struct (it's an error to have empty structs on some platforms...)
		#define UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT 1


		sampler2D _MainTex;
		float4 _MainTex_ST;
		#ifdef USE_DITHER_MASK
			sampler3D _DitherMaskLOD;
		#endif
		
		struct VertexInput
		{
			float4 vertex	: POSITION;
			float3 normal	: NORMAL;
			float2 uv0		: TEXCOORD0;
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};

		#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
			struct VertexOutputShadowCaster
			{
				V2F_SHADOW_CASTER_NOPOS
				#if defined(UNITY_STANDARD_USE_SHADOW_UVS)
					float2 tex : TEXCOORD1;
				#endif
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
			AfsTreeVertLeaf_DepthNormal (v);
			TRANSFER_SHADOW_CASTER_NOPOS(o,opos)
			#if defined(UNITY_STANDARD_USE_SHADOW_UVS)
				o.tex = TRANSFORM_TEX(v.texcoord, _MainTex);
			#endif
			// Needed to distinguish between shadow and depth pass in forward or mixed mode
			v.color.r = (unity_LightShadowBias.z == 0.0) ? 1.0 : v.color.r; 
			o.color = v.color;
		}

		fixed _Cutoff;

		half4 fragShadowCaster (
			#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
			VertexOutputShadowCaster i
		#endif
		#ifdef USE_DITHER_MASK
			, UNITY_VPOS_TYPE vpos : VPOS
		#endif
		) : SV_Target
		{
	
			half alpha = tex2D(_MainTex, i.tex).a;
			#if defined(USE_DITHER_MASK)
				// Needed to distinguish between shadow and depth pass in forward or mixed mode
				if (i.color.r < 1.0) {
					// NOTE:1.0 was 0.9375
					// half alphaRef = tex3D( _DitherMaskLOD, float3(vpos.xy * 0.25, smoothstep(0.0, 0.9375, alpha) ) ).a;
					// half alphaRef = tex3D(_DitherMaskLOD, float3( vpos.xy * 0.25 + i.color.bb, i.color.r) ).a * alpha;	// this version suffers from dither on top of dither !!!!			
		
					// from INSIDE
					#if defined(SHADER_API_D3D9)
						float2 uniqueSeed = 0; // As in DX9 vpos is only float2...
					#else
						float2 uniqueSeed = (0.6849 + vpos.z).xx;
					#endif
					half alphaRef = tex3D( _DitherMaskLOD, float4(vpos.xy * 0.25 + uniqueSeed, i.color.r * alpha, 0) ).a;
					alphaRef += i.color.r * alpha;
					// Use dither mask for alpha blended shadows, based on pixel position xy
					// and alpha level. Our dither texture is 4x4x16.
					clip (alphaRef - _Cutoff);
				}
				else {
					clip (alpha - _Cutoff);
				}
			#else
				clip (alpha - _Cutoff);
			#endif
			SHADOW_CASTER_FRAGMENT(i)
		}

		// --------------------------------------------------------
		// version without dithermask

		half4 fragShadowCasterXX (
			#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
			VertexOutputShadowCaster i
		#endif
		#ifdef USE_DITHER_MASK
			, UNITY_VPOS_TYPE vpos : VPOS
		#endif
		) : SV_Target
		{
	

			//half CameraIsRenderingDepth = (dot(unity_LightShadowBias,1) == 0.0) ? 1.0 : i.color.r; 

			half alpha = tex2D(_MainTex, i.tex).a * i.color.r; //* CameraIsRenderingDepth;
		
		// dx11 does not like: clip ((alphaRef + i.color.r) - _Cutoff); // --> + i.color.r 
		// so we simply skip this as it is way faster and still looks fine!
		
		/*	#if defined(USE_DITHER_MASK)
				// Needed to distinguish between shadow and depth pass in forward or mixed mode
				bool CameraIsRenderingDepth = dot(unity_LightShadowBias,1) == 0.0; 
				// NOTE:1.0 was 0.9375
				half alphaRef = tex3D( _DitherMaskLOD, float3(vpos.xy * 0.25, smoothstep(0.0, 0.9375, alpha) ) ).a;
				// half alphaRef = tex3D(_DitherMaskLOD, float3( vpos.xy * 0.25 + i.color.bb, i.color.r) ).a * alpha;	// this version suffers from dither on top of dither !!!!			
				if (i.color.r < 1.0 && !CameraIsRenderingDepth) { 
					// Use dither mask for alpha blended shadows, based on pixel position xy
					// and alpha level. Our dither texture is 4x4x16.
					clip ((alphaRef + i.color.r) - _Cutoff); // sqrt
				}
				else {
					clip (alpha - _Cutoff);
				} */
		//	#else
				clip (alpha - _Cutoff);
		//	#endif
			SHADOW_CASTER_FRAGMENT(i)
		}
		ENDCG
	}
	
}
Dependency "BillboardShader" = "Hidden/Nature/Afs Tree Creator Leaves Rendertex"
Fallback Off
}
