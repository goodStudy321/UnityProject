// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/FastOcean/UnderWater" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}

	CGINCLUDE
	
	#include "UnityCG.cginc"
	#define FO_OCEANMAP
	#define FO_DEPTHBLEND_ON
	#include "FOceanCommon.cginc"

struct v2f_s {
		float4 pos : SV_POSITION;
		float4 uv : TEXCOORD0;
	};

	struct v2f {
		float4 pos : SV_POSITION;
		float4 uv : TEXCOORD0;
		float4 uv01 : TEXCOORD1;
		float4 uv02 : TEXCOORD2;
		float4 uv03 : TEXCOORD3;
		float4 uv04 : TEXCOORD4;
	};
	
	float4 offsets;
	float _DepthFade;
	float _SurFade;
	float _DistortMag;
	float _DistortFrq;

	sampler2D _MainTex;
	sampler2D _DistortMap;

	float4 _MainTex_TexelSize;
	
	v2f_s vert_s (appdata_img v) {
		v2f_s o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xyxy;
#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			o.uv.w =  1 - o.uv.w;
#endif
		return o;  
	}

	v2f vert (appdata_img v) {
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xyxy;
		float4 voffsets = offsets * _MainTex_TexelSize.xyxy;
		o.uv02 =  v.texcoord.xyxy + voffsets;
		o.uv03 =  v.texcoord.xyxy + voffsets * 2;
		o.uv04 =  v.texcoord.xyxy + voffsets * 3;	
		o.uv01 =  v.texcoord.xyxy + voffsets * _DistortFrq;
		return o;  
	}
		
	fixed4 frag (v2f_s i) : SV_Target {

		fixed4 color = tex2D (_MainTex, i.uv.xy);
		
		#if UNITY_UV_STARTS_AT_TOP
			half depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv.zw).r;
			half depthWater = tex2D(_OceanMap, i.uv.zw).r;
		#else
			half depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv.xy).r;	
			half depthWater = tex2D(_OceanMap, i.uv.xy).r;
		#endif

		depth = Linear01Depth (depth);

		if(depthWater > 0 && depthWater < depth)
		{
		   depth = depthWater * _SurFade;
		}
		else
		{
		   depth *= _DepthFade;
		}

		float fadeAway = 1 / exp2(depth);
		color = lerp(lerp(_FoBaseColor, color, saturate(fadeAway)), color, step(depthWater, 0));
		color.a = 1.0;

		return color;
	} 

	fixed4 blur (v2f i) : SV_Target {

		fixed4 color;
		half depthWater = tex2D(_OceanMap, i.uv.xy).r;
		float a = step(depthWater, 0);
		half3 distort = PerPixelBump(_DistortMap, i.uv01.xyxy, _DistortMag) * (1 - a);
		fixed4 ocolor = tex2D (_MainTex, i.uv.xy - distort.rg);
		color = ocolor * 2;
		half4 uvdis02 = i.uv02 - distort.rgrg;
		half4 uvdis03 = i.uv03 - distort.rgrg;
		half4 uvdis04 = i.uv04 - distort.rgrg;
		color += tex2D (_MainTex, uvdis02.xy);
		color += tex2D (_MainTex, uvdis02.zw);
		color += tex2D (_MainTex, uvdis03.xy);
		color += tex2D (_MainTex, uvdis03.zw);
		color += tex2D (_MainTex, uvdis04.xy);
		color += tex2D (_MainTex, uvdis04.zw);
		color /= 8.0;
		color.a = 1.0;

		color = lerp(color, ocolor, a);

		return color;
	} 

	ENDCG
	
Subshader {
	//0
	Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

	  CGPROGRAM
	  #pragma fragmentoption ARB_precision_hint_fastest
	  #pragma vertex vert_s
	  #pragma fragment frag
	  #pragma exclude_renderers gles

	  #pragma target 3.0 
			
	  ENDCG
	}

   //1
   Pass {
		  ZTest Always Cull Off ZWrite Off
		  Fog { Mode off }      

		  CGPROGRAM
		  #pragma fragmentoption ARB_precision_hint_fastest
		  #pragma vertex vert
		  #pragma fragment blur
		  #pragma exclude_renderers gles

		  #pragma target 3.0 
			
		  ENDCG
	}
}

Fallback off

	
} // shader