Shader "Nature/Afs Tree Creator Bark" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	[HideInInspector] _Shininess ("Shininess", Range (0.01, 1)) = 0.078125
	_MainTex ("Base (RGB) Occlusion (A)", 2D) = "white" {}
	[NoScaleOffset] _BumpMap ("Normal Map", 2D) = "bump" {}
	[NoScaleOffset] _GlossMap ("Smoothness (A)", 2D) = "black" {}
	
	// These are here only to provide default values
	[HideInInspector] _SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
	[HideInInspector] _TreeInstanceColor ("TreeInstanceColor", Vector) = (1,1,1,1)
	[HideInInspector] _TreeInstanceScale ("TreeInstanceScale", Vector) = (1,1,1,1)
	[HideInInspector] _SquashAmount ("Squash", Float) = 1
}

SubShader { 
	Tags { "RenderType"="AfsTreeBark" }
	LOD 200
		
CGPROGRAM
#pragma surface surf StandardSpecular vertex:TreeVertBark addshadow nolightmap
#include "UnityBuiltin3xTreeLibrary.cginc"

sampler2D _MainTex;
sampler2D _BumpMap;
sampler2D _GlossMap;
half _Shininess;

struct Input {
	float2 uv_MainTex;
	fixed4 color : COLOR;
};

void surf (Input IN, inout SurfaceOutputStandardSpecular o) {
	fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
	o.Albedo = c.rgb * IN.color.rgb * IN.color.a;
	o.Smoothness = tex2D(_GlossMap, IN.uv_MainTex).a;
	o.Alpha = c.a;
	o.Specular = _Shininess;
	o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
	o.Occlusion = c.a;
}
ENDCG
}

Dependency "OptimizedShader" = "Nature/Afs Tree Creator Bark Optimized"
FallBack "Diffuse"
}
