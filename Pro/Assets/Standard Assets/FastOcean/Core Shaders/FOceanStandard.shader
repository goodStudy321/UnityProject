
Shader "FastOcean/Standard" { 
Properties {

	[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 1
	[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 0

	[HideInInspector][Enum(UnityEngine.Rendering.CullMode)] _CullAbove ("Cull Above", Float) = 0
	[HideInInspector][Enum(UnityEngine.Rendering.CullMode)] _CullUnder ("Cull Under", Float) = 0
			
	[Header(Colors)]
	[Space]
	_FoBaseColor ("Base Color", COLOR)  = (0, .49, .78, 1)	
	_FoDeepColor("Deep Color", COLOR) = (.12, .43, .27, 0.7)
	
	_nSnell("Snell", Range(1.01, 3)) = 2.5
	
	_FoReflAmb2Scene("Ambient Factor", Range(0.1, 0.99)) = 0.86

	[Space]
	_ExtinctScale ("Extinct Scale", Float) = 10.0
	_ExtinctColor ("Extinct Color", COLOR) = (0.05, 0.84, 0.15, 1)
		
	[Header(Normals)]

	[Space(10)]
	_DistortParams("Distortions(Refract, Reflect, Bump, Sun)", Vector) = (0.03 ,0.05, 1.0, 3)

	_FresnelScale ("Fresnel Scale", Range (0.15, 4.0)) = 1	
	_FoFade ("Fade", Range (0.01, 0.1)) = 0.08

	[Space]
	[KeywordEnum(Phong, BlinnPhong)] _FoSunMode("Sun Mode", Float) = 0
	_FoSunIntensity ("Sun Intensity", Range (0, 2)) = 1
	_FoShininess ("Shininess", Range (2.0, 500.0)) = 436.0	
	
	[Header(Transparents)]
	[Space(10)]
	_FoShallowColor ("Transparents Color", COLOR)  = ( .01, .51, .01, 1)
	_AboveDepth("Above Depth", Range(0.1, 10)) = 5
	_ShallowDepth("Shallow Depth", Range(0.01, 1)) = 1
		
	[Header(Foams)]
	[Space(10)]
	_Foam ("Foam(Peak, Intensity, Edge, Distort)", Vector) = (0.9, 0.1, 0.3, 0.01)
	_FoamTiling ("Foam Tiling & Speed", Vector) = (0.1 ,0.1, 0.01, 0.01)
	_FoamBSpeed("Foam Blend Speed", Range(0.01, 1)) = 0.2
		
	[Space]
	[NoScaleOffset] _FoamTex ("Foam Texture ", 2D) = "black" {}

	[Space]
	_FoamMaskScale("Foam Mask Scale", Range(0.01, 1)) = 0.1
	[NoScaleOffset] _FoamMask ("Foam Mask ", 2D) = "black" {}

	[Space]
	_FoamGScale("Foam Gradient Scale", Range(0.01, 1)) = 0.03
	_FoamGSpeed("Foam Gradient Speed", Range(0.01, 1)) = 0.05
	[NoScaleOffset] _FoamGradient ("Foam Gradient ", 2D) = "black" {}

} 

Subshader 
{ 
	Tags {"LightMode"="ForwardBase" "RenderType"="Transparent" "Queue"="Transparent-1"}
	
	Lod 205
	GrabPass
    {
        "_Refraction"
    }

	Pass {
			ZTest LEqual
			ZWrite On
			Cull [_CullAbove]
			Fog { Mode off }

			CGPROGRAM

			#pragma target 3.0

			#pragma vertex vert_FO
			#pragma fragment frag_FO

			#pragma multi_compile_fog

			#pragma exclude_renderers gles

			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile __ FO_PROJECTED_ON
			#pragma multi_compile __ FO_HQWAVES_ON FO_FFTWAVES_ON
			#define FO_FOAM_ON
			#pragma multi_compile __ FO_PHONG_ON
			#pragma multi_compile __ FO_TRAIL_ON
		    #define FO_DEPTHBLEND_ON
			#pragma multi_compile __ FO_SHADOW_ON

			#include "UnityCG.cginc"
			#include "FOceanCore.cginc"
			#include "FOceanInclude.cginc"

			ENDCG
	}
}


Subshader 
{ 
	Tags {"LightMode"="ForwardBase" "RenderType"="Transparent" "Queue"="Transparent-1"}
	
	Lod 204

	Pass {
			Blend [_SrcBlend] [_DstBlend]
			ZTest LEqual
			ZWrite On
			Cull [_CullAbove]
			Fog { Mode off }

			CGPROGRAM

			#pragma target 3.0

			#pragma vertex vert_FO
			#pragma fragment frag_FO

			#pragma multi_compile_fog

			#pragma exclude_renderers gles
			
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile __ FO_PROJECTED_ON
			#pragma multi_compile __ FO_HQWAVES_ON FO_FFTWAVES_ON
			#define FO_FOAM_ON
			#pragma multi_compile __ FO_PHONG_ON
			#pragma multi_compile __ FO_TRAIL_ON
			#pragma multi_compile __ FO_SHADOW_ON

			#include "UnityCG.cginc"
			#include "FOceanCore.cginc"
			#include "FOceanInclude.cginc"

			ENDCG
	}
}

Subshader 
{ 
	Tags {"LightMode"="ForwardBase" "RenderType"="Transparent" "Queue"="Transparent-1"}
	
	Lod 203
	
	Pass {
			Blend [_SrcBlend] [_DstBlend]
			ZTest LEqual
			ZWrite On
			Cull Back
			Fog { Mode off }

			CGPROGRAM

			#pragma target 2.0

			#pragma vertex vert_FO
			#pragma fragment frag_FO

			#pragma multi_compile_fog

			#pragma only_renderers gles gles3 d3d11 metal
			
			//#pragma glsl
			
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile __ FO_PROJECTED_ON
			#define FO_FOAM_ON
			#pragma multi_compile __ FO_PHONG_ON
			#pragma multi_compile __ FO_TRAIL_ON
			
			#include "UnityCG.cginc"
			#include "FOceanCore.cginc"
			#include "FOceanInclude.cginc"	

			ENDCG
	}
}

Subshader 
{ 
	Tags {"LightMode"="ForwardBase" "RenderType"="Transparent" "Queue"="Transparent-1"}
	
	Lod 202
	
	Pass {
			Blend SrcAlpha OneMinusSrcAlpha
			ZTest LEqual
			ZWrite On
			Cull [_CullUnder]
			Fog { Mode off }
			
			CGPROGRAM

			#pragma target 3.0

			//To Show Skirt FOR Debug
			//#define FO_SKIRT

			#pragma vertex vert_UFO
			#pragma fragment frag_UFO

			#pragma exclude_renderers gles
			
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile __ FO_PROJECTED_ON
			#pragma multi_compile __ FO_FFTWAVES_ON	
			#pragma multi_compile __ FO_TRAIL_ON 
			#pragma multi_compile __ FO_DEPTHBLEND_ON
			#pragma multi_compile __ FO_SHADOW_ON
			#pragma multi_compile_fog

			#define FO_UNDERWATER
			#include "UnityCG.cginc"
			#include "FOceanCore.cginc"
			#include "FOceanIncludeUnderWater.cginc"

			ENDCG
	}
}

Subshader 
{ 
	Tags {"LightMode"="ForwardBase" "RenderType"="Transparent" "Queue"="Transparent-1"}
	
	Lod 201

	Pass {
			Blend SrcAlpha OneMinusSrcAlpha
			ZTest LEqual
			ZWrite On
			Cull Front
			Fog { Mode off }
			
			CGPROGRAM

			#pragma target 2.0

			#pragma vertex vert_UFO
			#pragma fragment frag_UFO

			#pragma only_renderers gles gles3 d3d11 metal
			
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma multi_compile __ FO_PROJECTED_ON	
			#pragma multi_compile __ FO_TRAIL_ON
			#pragma multi_compile_fog

			#define FO_UNDERWATER
			#include "UnityCG.cginc"
			#include "FOceanCore.cginc"
			#include "FOceanIncludeUnderWater.cginc"

			ENDCG
	}
}

// for editor
Subshader 
{ 
	Tags {"LightMode"="ForwardBase" "RenderType"="Transparent" "Queue"="Transparent-1"}
	
	Lod 200
	
	Pass {
			Blend [_SrcBlend] [_DstBlend]
			ZTest LEqual
			ZWrite On
			Cull Off
			Fog { Mode off }

			CGPROGRAM
			
			#pragma target 3.0

			#pragma vertex vert_FO
			#pragma fragment frag_FO
			
			#pragma multi_compile_fog

			#pragma only_renderers d3d9 d3d11 glcore d3d11_9x metal

			//#pragma glsl
			
			#pragma fragmentoption ARB_precision_hint_fastest			
			#pragma shader_feature FO_PROJECTED_ON
			#pragma shader_feature _ FO_HQWAVES_ON FO_FFTWAVES_ON
			#define FO_FOAM_ON
			#pragma shader_feature FO_PHONG_ON
			#pragma shader_feature FO_DEPTHBLEND_ON	
			#pragma shader_feature FO_SHADOW_ON

			#include "UnityCG.cginc"
			#include "FOceanCore.cginc"
			#include "FOceanInclude.cginc"

			ENDCG
	}
}

Subshader 
{ 
	Tags {"RenderType"="Transparent" "Queue"="Transparent-1"}
	
	Lod 199
	
	Pass {
			//ZTest LEqual Cull Back ZWrite On
			ZTest Off Cull Back ZWrite Off // Better Performance
			Fog { Mode off }  

			CGPROGRAM
			
			#pragma target 3.0

			#pragma exclude_renderers gles

			#pragma vertex vert_FO_MAP
			#pragma fragment frag_OCEAN_MAP
			
			#pragma fragmentoption ARB_precision_hint_fastest				
			#pragma multi_compile __ FO_PROJECTED_ON

			#include "UnityCG.cginc"
			#include "FOceanCore.cginc"
			#include "FOceanInclude.cginc"

			ENDCG
	}
}

Subshader 
{ 
	Tags {"RenderType"="Transparent" "Queue"="Transparent-1"}
	
	Lod 198
	
	Pass {
			ZTest LEqual Cull Off ZWrite On
			Fog { Mode off }  

			CGPROGRAM

			#pragma target 3.0
			
			#pragma vertex vert_UOCEAN_MAP
			#pragma fragment frag_UOCEAN_MAP
			
			#pragma exclude_renderers gles
			
			#pragma fragmentoption ARB_precision_hint_fastest				
			#pragma multi_compile __ FO_PROJECTED_ON

			#define FO_SKIRT

			#define FO_UNDERWATER
			#include "UnityCG.cginc"
			#include "FOceanCore.cginc"
			#include "FOceanIncludeUnderWater.cginc"

			ENDCG
	}
}

Subshader 
{ 
	Tags {"RenderType"="Transparent" "Queue"="Transparent-1"}
	
	Lod 197
	
	Pass {
			ZTest LEqual Cull Front ZWrite On
			Fog { Mode off }  

			CGPROGRAM

			#pragma target 3.0
			
			#pragma vertex vert_UOCEAN_MAP
			#pragma fragment frag_UOCEAN_MAP
			
			#pragma exclude_renderers gles
			
			#pragma fragmentoption ARB_precision_hint_fastest				
			#pragma multi_compile __ FO_PROJECTED_ON

			#define FO_SKIRT

			#define FO_UNDERWATER
			#include "UnityCG.cginc"
			#include "FOceanCore.cginc"
			#include "FOceanIncludeUnderWater.cginc"

			ENDCG
	}

	Pass {
			ZTest LEqual Cull Back ZWrite On
			Fog { Mode off }  

			CGPROGRAM

			#pragma target 3.0
			
			#pragma vertex vert_FO_MAP
			#pragma fragment frag_OCEAN_MAP_CLEAR
			
			#pragma exclude_renderers gles
			
			#pragma fragmentoption ARB_precision_hint_fastest				
			#pragma multi_compile __ FO_PROJECTED_ON

			#include "UnityCG.cginc"
			#include "FOceanCore.cginc"
			#include "FOceanInclude.cginc"

			ENDCG
	}
}

Subshader 
{ 
	Tags {"RenderType"="Transparent" "Queue"="Transparent-1"}
	
	Lod 196
	
	Pass {
			ZTest Off Cull Back ZWrite Off
			Fog { Mode off }  

			CGPROGRAM

			#pragma target 3.0
			
			#pragma vertex vert_FO
			#pragma fragment frag_GLARE_MAP
			
			#pragma exclude_renderers gles

			#pragma multi_compile_fog
			
			#pragma fragmentoption ARB_precision_hint_fastest				
			#pragma multi_compile __ FO_PROJECTED_ON	
			#pragma multi_compile __ FO_HQWAVES_ON FO_FFTWAVES_ON
			
			#pragma multi_compile __ FO_PHONG_ON
			//just use phong
			//#define FO_PHONG_ON 

			#pragma multi_compile __ FO_TRAIL_ON 
			#pragma multi_compile __ FO_SHADOW_ON

			#include "UnityCG.cginc"
			#include "FOceanCore.cginc"
			#include "FOceanInclude.cginc"

			ENDCG
	}
}
Fallback off
}
