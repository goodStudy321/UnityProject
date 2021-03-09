// Upgrade NOTE: replaced 'UNITY_INSTANCE_ID' with 'UNITY_VERTEX_INPUT_INSTANCE_ID'

Shader "Hidden/AfsCamera-DepthNormalTexture" {
Properties {
	_MainTex ("", 2D) = "white" {}
	_Cutoff ("", Float) = 0.5
	_Color ("", Color) = (1,1,1,1)

	_BendingControls ("Bending Parameters", Float) = 0
}

SubShader {
	Tags { "RenderType"="AFSTreeLeafCTI" }
	Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile_instancing

//#define XLEAFBENDING
#define LEAFTUMBLING
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "../Includes/AfsTreeLibraryInstanced.cginc"

struct v2f {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

v2f vert( appdata_full v ) {
    v2f o;
    UNITY_SETUP_INSTANCE_ID (v);
    AfsTreeVertLeaf_DepthNormal(v);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord.xy;
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
    return o;
}
uniform sampler2D _MainTex;
uniform fixed _Cutoff;

fixed4 frag( v2f i ) : SV_Target {
	half alpha = tex2D(_MainTex, i.uv).a;

	clip (alpha - _Cutoff);
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}

SubShader {
	Tags { "RenderType"="AFSTreeLeaf" }
	Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile_instancing

#define XLEAFBENDING
//#define LEAFTUMBLING
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "../Includes/AfsTreeLibraryInstanced.cginc"

struct v2f {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

v2f vert( appdata_full v ) {
    v2f o;
    UNITY_SETUP_INSTANCE_ID (v);
    AfsTreeVertLeaf_DepthNormal(v);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord.xy;
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
    return o;
}
uniform sampler2D _MainTex;
uniform fixed _Cutoff;

fixed4 frag( v2f i ) : SV_Target {
	half alpha = tex2D(_MainTex, i.uv).a;

	clip (alpha - _Cutoff);
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}

SubShader {
	Tags { "RenderType"="AfsTreeBark" }
	Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile_instancing

#define XLEAFBENDING
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "../Includes/AfsTreeLibraryInstanced.cginc"

struct v2f {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};
v2f vert( appdata_full v ) {
    v2f o;
    UNITY_SETUP_INSTANCE_ID (v);
    AfsTreeVertBark_DepthNormal(v);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord.xy;
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
    return o;
}
fixed4 frag( v2f i ) : SV_Target {
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}


SubShader {
	Tags { "RenderType"="AFSTreeSimple" }
	Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag

#define XLEAFBENDING
//#define LEAFTUMBLING

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "../Includes/AfsTreeLibraryInstanced.cginc"
struct v2f {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
};
v2f vert( appdata_full v ) {
    v2f o;
    AfsTreeVertLeaf_DepthNormal(v);
	
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord.xy;
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
    return o;
}
uniform sampler2D _MainTex;
uniform fixed _Cutoff;
fixed4 frag( v2f i ) : SV_Target {
	half alpha = tex2D(_MainTex, i.uv).a;

	clip (alpha - _Cutoff);
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}


SubShader {
	Tags { "RenderType"="AFSTreeBillboard" }
	Pass {
		Cull Off
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
#include "TerrainEngine.cginc"
#include "../Includes/AfsBillboardShadow.cginc"
struct v2f {
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
};
v2f vert (appdata_tree_billboard v) {
	v2f o;
	AfsTerrainBillboardTree(v.vertex, v.texcoord1.xy, v.texcoord.y);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv.x = v.texcoord.x;
	o.uv.y = v.texcoord.y > 0;
    o.nz.xyz = float3(0,0,1);
    o.nz.w = COMPUTE_DEPTH_01;
	return o;
}
uniform sampler2D _MainTex;
fixed4 frag(v2f i) : SV_Target {
	fixed4 texcol = tex2D( _MainTex, i.uv );
// Has to match ShadowCaster Pass
	clip( texcol.a - 0.5 );
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}

SubShader {
	Tags { "RenderType"="AFSFoliageBending" }
	Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag

//#undef AFS_TOUCHBENDING

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "TerrainEngine.cginc"
#include "../Includes/AfsFoliageBendingInstanced.cginc"
struct v2f {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
};
v2f vert( appdata_full v ) {
    v2f o;
    AfsFoligeBending_DepthNormal(v);
	
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord.xy;
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
    return o;
}
uniform sampler2D _MainTex;
uniform fixed _Cutoff;
fixed4 frag( v2f i ) : SV_Target {
	half alpha = tex2D(_MainTex, i.uv).a;

	clip (alpha - _Cutoff);
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}

/////////////////////////////////////////////////////////

SubShader {
	Tags { "RenderType"="AFSFoliageBendingInstanced" }
	Pass {
	Cull Off
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile_instancing
// instancing is ignored here!!!!!!!!!!!!!!

// We always activate touch bending – optimization in the vertex animation is only done by (TouchBendingForce.w != 0)
#define AFS_TOUCHBENDING

// As Unity ignores multi_compile_instancing we have to declare it manually - otherwise AfsFoligeBending_DepthNormal does not pick up the correct object phase 
#if defined (SHADER_API_D3D11) || defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE) || defined(SHADER_API_XBOXONE) || defined(SHADER_API_VULKAN) || (defined(SHADER_API_METAL) && defined(UNITY_COMPILER_HLSLCC)) || defined(SHADER_API_PSSL)
	#define INSTANCEDDEPTHPASSAFS
#endif

// if pivot is baked
#pragma multi_compile _ GEOM_TYPE_BRANCH

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "TerrainEngine.cginc"
#include "../Includes/AfsFoliageBendingInstanced.cginc"
struct v2f {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};
v2f vert( appdata_full v ) {
    v2f o;
    UNITY_SETUP_INSTANCE_ID (v);
    UNITY_TRANSFER_INSTANCE_ID (v, o);

    AfsFoligeBending_DepthNormal(v);
	
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord.xy;
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
    return o;
}
uniform sampler2D _MainTex;
uniform fixed _Cutoff;
fixed4 frag( v2f i, float facing : VFACE ) : SV_Target {
	half alpha = tex2D(_MainTex, i.uv).a;
	clip (alpha - _Cutoff);
	// Apply correct normals
	#if UNITY_VFACE_FLIPPED
		facing = -facing;
	#endif
	#if UNITY_VFACE_AFFECTED_BY_PROJECTION
		facing *= _ProjectionParams.x; // take possible upside down rendering into account
  	#endif
 	i.nz.xyz *= facing;
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}


////
SubShader {
	Tags { "RenderType"="AFSFoliageBendingVertexLit" }
	Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag

//#undef AFS_TOUCHBENDING
#define VERTEXLIT
#pragma shader_feature _LEGACYBENDING

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "TerrainEngine.cginc"
#include "../Includes/AfsFoliageBendingInstanced.cginc"
struct v2f {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
	fixed4 color : COLOR0;
};
v2f vert( appdata_full v ) {
    v2f o;
    AfsFoligeBending_DepthNormal(v);
	
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord.xy;
	o.color = v.color;
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
    return o;
}
uniform sampler2D _MainTex;
uniform fixed _Cutoff;
fixed4 frag( v2f i ) : SV_Target {
	half alpha = tex2D(_MainTex, i.uv).a * i.color.a;

	clip (alpha - _Cutoff);
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}

SubShader {
	Tags { "RenderType"="AFSFoliageBendingSingleSided" }
	Pass {
Cull Off
CGPROGRAM
#pragma vertex vert
#pragma fragment frag

//#undef AFS_TOUCHBENDING

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "TerrainEngine.cginc"
#include "../Includes/AfsFoliageBendingInstanced.cginc"
struct v2f {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
};
v2f vert( appdata_full v ) {
    v2f o;
    AfsFoligeBending_DepthNormal(v);
	
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord.xy;
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
    return o;
}
uniform sampler2D _MainTex;
uniform fixed _Cutoff;
fixed4 frag( v2f i ) : SV_Target {
	half alpha = tex2D(_MainTex, i.uv).a;

	clip (alpha - _Cutoff);
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}

SubShader {
	Tags { "RenderType"="AFSFoliageTouchBending" }
	Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag

#define AFS_TOUCHBENDING

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "TerrainEngine.cginc"
#include "../Includes/AfsFoliageBendingInstanced.cginc"
struct v2f {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
};
v2f vert( appdata_full v ) {
    v2f o;
    AfsFoligeBending_DepthNormal(v);
	
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord.xy;
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
    return o;
}
uniform sampler2D _MainTex;
uniform fixed _Cutoff;
fixed4 frag( v2f i ) : SV_Target {
	half alpha = tex2D(_MainTex, i.uv).a;

	clip (alpha - _Cutoff);
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}

SubShader {
	Tags { 
		"RenderType"="AFSGrassTerrain"
		"DisableBatching"="True"
	}
	Pass {
		Cull Off
CGPROGRAM
#pragma vertex vert
#pragma fragment frag

//#pragma multi_compile_instancing // does not help here???

#include "UnityCG.cginc"

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
struct v2f {
	float4 pos : SV_POSITION;
	fixed4 color : COLOR;
	float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
};

v2f vert (appdata_grass v) {
	v2f o;
	UNITY_SETUP_INSTANCE_ID(v);
	AfsWavingGrassVert_DepthNormal (v);
	o.color = v.color;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord;
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
	return o;
}
uniform sampler2D _MainTex;
uniform fixed _Cutoff;
fixed4 frag(v2f i) : SV_Target {
	fixed4 texcol = tex2D( _MainTex, i.uv );
	fixed alpha = texcol.a * i.color.a;
	clip( alpha - _Cutoff );
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}

SubShader {
	Tags { "RenderType"="AFSGrass"
		//"DisableBatching"="True"
	}
	Pass {
		Cull Off
CGPROGRAM
#pragma vertex vert
#pragma fragment frag

#include "UnityCG.cginc"

#define AFSMANUALGRASS

struct appdata_grass {
	float4 vertex : POSITION;
	// float4 tangent : TANGENT;
	float3 normal : NORMAL;
	float3 texcoord : TEXCOORD0;
	float2 texcoord1 : TEXCOORD1;
	fixed4 color : COLOR;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

#include "TerrainEngine.cginc"
#include "../Includes/AfsWavingGrass.cginc"
struct v2f {
	float4 pos : SV_POSITION;
	fixed4 color : COLOR;
	float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
};

v2f vert (appdata_grass v) {
	v2f o;
	AfsWavingGrassVert_DepthNormal (v);
	o.color = v.color;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord;
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
	return o;
}
uniform sampler2D _MainTex;
uniform fixed _Cutoff;
fixed4 frag(v2f i) : SV_Target {
	fixed4 texcol = tex2D( _MainTex, i.uv );
	fixed alpha = texcol.a * i.color.a;
	clip( alpha - _Cutoff );
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}

// ////////////////////////////////
// ORIGINAL UNITY SHADERS

SubShader {
	Tags { "RenderType"="Opaque" }
	Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
struct v2f {
    float4 pos : SV_POSITION;
    float4 nz : TEXCOORD0;
};
v2f vert( appdata_base v ) {
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
    return o;
}
fixed4 frag(v2f i) : SV_Target {
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}

SubShader {
	Tags { "RenderType"="TransparentCutout" }
	Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
struct v2f {
    float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
    float4 nz : TEXCOORD1;
};
uniform float4 _MainTex_ST;
v2f vert( appdata_base v ) {
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
    return o;
}
uniform sampler2D _MainTex;
uniform fixed _Cutoff;
uniform fixed4 _Color;
fixed4 frag(v2f i) : SV_Target {
	fixed4 texcol = tex2D( _MainTex, i.uv );
	clip( texcol.a*_Color.a - _Cutoff );
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}

SubShader {
	Tags { "RenderType"="TreeBark" }
	Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "UnityBuiltin3xTreeLibrary.cginc"
struct v2f {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
};
v2f vert( appdata_full v ) {
    v2f o;
    TreeVertBark(v);
	
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord.xy;
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
    return o;
}
fixed4 frag( v2f i ) : SV_Target {
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}

SubShader {
	Tags { "RenderType"="TreeLeaf" }
	Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "UnityBuiltin3xTreeLibrary.cginc"
struct v2f {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
};
v2f vert( appdata_full v ) {
    v2f o;
    TreeVertLeaf(v);
	
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord.xy;
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
    return o;
}
uniform sampler2D _MainTex;
uniform fixed _Cutoff;
fixed4 frag( v2f i ) : SV_Target {
	half alpha = tex2D(_MainTex, i.uv).a;

	clip (alpha - _Cutoff);
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}

SubShader {
	Tags { "RenderType"="TreeOpaque" "DisableBatching"="True" }
	Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
#include "TerrainEngine.cginc"
struct v2f {
	float4 pos : SV_POSITION;
	float4 nz : TEXCOORD0;
};
struct appdata {
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    fixed4 color : COLOR;
};
v2f vert( appdata v ) {
	v2f o;
	TerrainAnimateTree(v.vertex, v.color.w);
	o.pos = UnityObjectToClipPos(v.vertex);
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
	return o;
}
fixed4 frag(v2f i) : SV_Target {
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
} 

SubShader {
	Tags { "RenderType"="TreeTransparentCutout" "DisableBatching"="True" }
	Pass {
		Cull Back
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
#include "TerrainEngine.cginc"

struct v2f {
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
};
struct appdata {
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    fixed4 color : COLOR;
    float4 texcoord : TEXCOORD0;
};
v2f vert( appdata v ) {
	v2f o;
	TerrainAnimateTree(v.vertex, v.color.w);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord.xy;
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
	return o;
}
uniform sampler2D _MainTex;
uniform fixed _Cutoff;
fixed4 frag(v2f i) : SV_Target {
	half alpha = tex2D(_MainTex, i.uv).a;

	clip (alpha - _Cutoff);
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
	Pass {
		Cull Front
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
#include "TerrainEngine.cginc"

struct v2f {
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
};
struct appdata {
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    fixed4 color : COLOR;
    float4 texcoord : TEXCOORD0;
};
v2f vert( appdata v ) {
	v2f o;
	TerrainAnimateTree(v.vertex, v.color.w);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord.xy;
    o.nz.xyz = -COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
	return o;
}
uniform sampler2D _MainTex;
uniform fixed _Cutoff;
fixed4 frag(v2f i) : SV_Target {
	fixed4 texcol = tex2D( _MainTex, i.uv );
	clip( texcol.a - _Cutoff );
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}

}

SubShader {
	Tags { "RenderType"="TreeBillboard" }
	Pass {
		Cull Off
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
#include "TerrainEngine.cginc"
struct v2f {
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
};
v2f vert (appdata_tree_billboard v) {
	v2f o;
	TerrainBillboardTree(v.vertex, v.texcoord1.xy, v.texcoord.y);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv.x = v.texcoord.x;
	o.uv.y = v.texcoord.y > 0;
    o.nz.xyz = float3(0,0,1);
    o.nz.w = COMPUTE_DEPTH_01;
	return o;
}
uniform sampler2D _MainTex;
fixed4 frag(v2f i) : SV_Target {
	fixed4 texcol = tex2D( _MainTex, i.uv );
	clip( texcol.a - 0.001 );
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}

SubShader {
	Tags { "RenderType"="GrassBillboard" }
	Pass {
		Cull Off		
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
#include "TerrainEngine.cginc"

struct v2f {
	float4 pos : SV_POSITION;
	fixed4 color : COLOR;
	float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
};

v2f vert (appdata_full v) {
	v2f o;
	WavingGrassBillboardVert (v);
	o.color = v.color;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord.xy;
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
	return o;
}
uniform sampler2D _MainTex;
uniform fixed _Cutoff;
fixed4 frag(v2f i) : SV_Target {
	fixed4 texcol = tex2D( _MainTex, i.uv );
	fixed alpha = texcol.a * i.color.a;
	clip( alpha - _Cutoff );
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}

SubShader {
	Tags { "RenderType"="Grass" }
	Pass {
		Cull Off
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
#include "TerrainEngine.cginc"
struct v2f {
	float4 pos : SV_POSITION;
	fixed4 color : COLOR;
	float2 uv : TEXCOORD0;
	float4 nz : TEXCOORD1;
};

v2f vert (appdata_full v) {
	v2f o;
	WavingGrassVert (v);
	o.color = v.color;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord;
    o.nz.xyz = COMPUTE_VIEW_NORMAL;
    o.nz.w = COMPUTE_DEPTH_01;
	return o;
}
uniform sampler2D _MainTex;
uniform fixed _Cutoff;
fixed4 frag(v2f i) : SV_Target {
	fixed4 texcol = tex2D( _MainTex, i.uv );
	fixed alpha = texcol.a * i.color.a;
	clip( alpha - _Cutoff );
	return EncodeDepthNormal (i.nz.w, i.nz.xyz);
}
ENDCG
	}
}
Fallback Off
}
