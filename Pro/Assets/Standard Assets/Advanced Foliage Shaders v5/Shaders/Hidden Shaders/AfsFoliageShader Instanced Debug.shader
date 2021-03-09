Shader "Hidden/Foliage Shader Debug" {
	Properties {

		[Space(6)]
		[Enum(UnityEngine.Rendering.CullMode)] _Culling ("Culling", Float) = 0

		[Header(Base Settings)]
		[Space(4)]
		_MainTex ("     Albedo (RGB) Alpha (A)", 2D) = "white" {}
		_Cutoff ("     Alpha cutoff", Range(0,1)) = 0.3
		[NoScaleOffset] _BumpTransSpecMap ("     Normal (GA) Trans(R) Smoothness(B)", 2D) = "bump" {}
		_SpecularReflectivity("     Specular Reflectivity", Color) = (0.2,0.2,0.2)
		//_TranslucencyViewDependency ("Translucency View Dependency", Range(0,1)) = 0.5
		_TranslucencyStrength ("     Translucency", Range(0,1)) = 0.5
		
		[Header(Wind Settings)]
		[Space(4)]
		_LeafTurbulence ("     Leaf Turbulence", Range(0,4)) = 1
		[KeywordEnum(Legacy Vertex Colors, UV4 And Vertex Colors, Vertex Colors)] _BendingControls ("     Bending Parameters", Float) = 0 // 0 = legacy vertex colors, 1 = uv4, 2 = vertex colors

		[Space(6)]
		[Toggle(AFS_TOUCHBENDING)] _TouchBending ("     Enable Touchbending", Float) = 0
		[HideInInspector] _TouchBendingPosition ("TouchBendingPosition", Vector) = (0,0,0,0)
		[HideInInspector] _TouchBendingForce ("TouchBendingForce", Vector) = (0,0,0,0)

		[Header(Rain Detail Settings)]
		[Space(4)]
		[Toggle(EFFECT_BUMP)] _RainDetails ("     Enable Rain Details", Float) = 0
		[NoScaleOffset] _RainBumpMask ("     Rain Normal (GA) Mask (B)", 2D) = "bump" {}
		_RainTexScale ("     Rain Texture Scale", Float) = 4


		_IsCombined ("Combined Mesh", Float) = 0

		_DebugMode ("Debug Mode", Float) = 1
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
		#pragma surface surf AFSUnlit vertex:AfsFoligeBendingGSFull addshadow fullforwardshadows 
		#pragma target 3.0

		#pragma multi_compile_instancing
		#pragma shader_feature AFS_TOUCHBENDING

		#include "../Includes/AfsPBSLighting.cginc"

		// Vertex Functions
		#include "TerrainEngine.cginc"
		#include "../Includes/AfsFoliageBendingInstanced.cginc"

		sampler2D _MainTex;
		fixed _Cutoff;


		half _DebugMode;

		struct Input {
			float2 uv_MainTex;
			fixed4 color : COLOR0;	// color.a = AO
			fixed4 origColors;
			float facingSign : VFACE;
		};


		void AfsFoligeBendingGSFull (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input,o);
			
			o.origColors = v.color;

			float4 bendingCoords;
			bendingCoords.rg = v.color.rg;
		//	Legacy Bending:		Primary and secondary bending stored in vertex color blue
		//	New Bending:		Primary and secondary bending stored in uv4
		//	x = primary bending = blue
		//	y = secondary = alpha
		//	VeretxColors Only: 	Primary in A, secondary bending stored in B
			bendingCoords.ba = (_BendingControls == 2) ? v.color.ab : v.texcoord3.xy;
			bendingCoords.ba = (_BendingControls == 0) ? v.color.bb : bendingCoords.ba;

		//	Add variation only if the shader uses UV4
			float variation = (_BendingControls == 1) ? v.color.b * 2 : 0;
			
			AfsAnimateVertex (v.vertex, v.normal, v.tangent, float3(0,0,0), float(0), bendingCoords, variation);

			#if !defined(UNITY_PASS_SHADOWCASTER)
				v.normal = normalize(v.normal);
				v.tangent.xyz = normalize(v.tangent.xyz);
			#endif
		}


		void surf (Input IN, inout SurfaceOutputAFSUnlit o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex.xy);
			// Do early alpha test
			clip(c.a - _Cutoff);
			o.Albedo = IN.origColors.rgb;
			o.Alpha = c.a;
			// red
			if (_DebugMode == 1) {
				o.Albedo = half3(IN.origColors.r, 0, 0);
			}
			// green
			if (_DebugMode == 2) {
				o.Albedo = half3(0, IN.origColors.g, 0);
			}
			// blue
			if (_DebugMode == 3) {
				o.Albedo = half3(0, 0, IN.origColors.b);
			}
			// alpha
			if (_DebugMode == 4) {
				o.Albedo = IN.origColors.a;
			}
		}
		ENDCG
	}
}
