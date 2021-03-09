// Upgrade NOTE: replaced 'UNITY_INSTANCE_ID' with 'UNITY_VERTEX_INPUT_INSTANCE_ID'

// Instancing not supported by engine
// But enabling instancing on the depth/shadow pass fixes disablebatching = true to be ignored (Unity 5.4.0F3)

Shader "Hidden/TerrainEngine/Details/WavingDoublePass"  {
Properties {
	_Cutoff ("Alpha cutoff", Range(0,1)) = 0.3
	_MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
}



SubShader {
	Tags {
		"Queue" = "Geometry+200"
		"IgnoreProjector"="True"
		"RenderType"="AFSGrassTerrain"
		"DisableBatching"="True"
	}
	Cull Off
	LOD 200

CGPROGRAM
#pragma surface surf AFSSpecular vertex:AfsWavingGrassVert 
//addshadow

struct appdata_grass {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float3 texcoord : TEXCOORD0;
	float2 texcoord1 : TEXCOORD1;
	fixed4 color : COLOR;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};


#include "TerrainEngine.cginc"
#include "../Includes/AfsWavingGrass.cginc"
#include "../Includes/AfsPBSLighting.cginc"

sampler2D _MainTex;
float _Cutoff;
sampler2D _TerrianBumpTransSpecMap;
// Global vars
fixed 	_AfsRainamount;
fixed2	_AfsGrassSmoothness;

struct Input {
	float2 myuv_MainTex;
	float4 color : COLOR;
};



void AfsWavingGrassVert (inout appdata_full v, out Input o) 
{
	UNITY_INITIALIZE_OUTPUT(Input,o);
	o.myuv_MainTex.xy = v.texcoord.xy;
	//o.myuv_MainTex.z = max(0.8, v.color.a); // Occlusion from v.color.a
	float waveAmount = v.color.a * _AfsWaveAndDistance.z;
	v.color = WaveGrass (v.vertex, v.normal, waveAmount, v.color, v.texcoord1);
}

void surf (Input IN, inout SurfaceOutputAFSSpecular o) {
	fixed4 c = tex2D(_MainTex, IN.myuv_MainTex.xy);
	o.Alpha = c.a * IN.color.a;
	// Do early alpha test
	clip (o.Alpha - _Cutoff);

	fixed4 d = tex2D(_TerrianBumpTransSpecMap, IN.myuv_MainTex.xy);
	o.Albedo = c.rgb * IN.color.rgb;
	o.Albedo *= lerp(1.0, 0.5, _AfsRainamount); // We do not use the standard value here as grass does not get much reflections

	// o.Specular is inititialized as 0.0 -> lambert lighting
	// o.Specular = (1.0/255.0);
	// o.Specular = 0.04 * d.a;

	o.Translucency = d.g;
	o.Smoothness = lerp(_AfsGrassSmoothness.x, _AfsGrassSmoothness.y, _AfsRainamount) * d.g * IN.color.r; // this brings in some ambient reflections / Unity bug? :-)



	// o.Occlusion = d.b; // interesting but too difficult to author
	o.Occlusion = saturate(IN.color.a + 0.5);
}
ENDCG

	// Pass to render object as a shadow caster
	Pass {
		Name "ShadowCaster"
		Tags { 
			"LightMode" = "ShadowCaster"
			"DisableBatching"="True"
		}

		Cull Off
		
		CGPROGRAM
		#pragma vertex vert_surf
		#pragma fragment frag_surf
		#pragma multi_compile_shadowcaster

// Enable instancing for this shader
// Grass will not be instanced but this prevents grass patches from being batched
// So it is a hacky fix for "DisableBatching"="True" not working properly (Unity 5.4.0F3)
		#pragma multi_compile_instancing

		#include "HLSLSupport.cginc"
		#include "UnityCG.cginc"
		#include "Lighting.cginc"

		struct appdata_grass {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float2 texcoord : TEXCOORD0;
			float2 texcoord1 : TEXCOORD1;
			fixed4 color : COLOR;
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};

		#include "TerrainEngine.cginc"
		#include "../Includes/AfsWavingGrass.cginc"

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
			fixed4 color;
		};


		struct v2f_surf {
			V2F_SHADOW_CASTER;
			float2 hip_pack0 : TEXCOORD1;
			fixed4 color : COLOR;
		};


		float4 _MainTex_ST;
		v2f_surf vert_surf (appdata_grass v) {
			v2f_surf o;
			UNITY_SETUP_INSTANCE_ID(v);
			float waveAmount = v.color.a * _AfsWaveAndDistance.z;
			v.color = WaveGrass (v.vertex, v.normal, waveAmount, v.color, v.texcoord1);
			o.hip_pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.color = v.color;
			TRANSFER_SHADOW_CASTER(o)
			return o;
		}
		fixed _Cutoff;
		float4 frag_surf (v2f_surf IN) : SV_Target {
			half alpha = tex2D(_MainTex, IN.hip_pack0.xy).a * IN.color.a;
			clip (alpha - _Cutoff);
			SHADOW_CASTER_FRAGMENT(IN)
		}
		ENDCG
	}


}
	Fallback Off
}