// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/FastOcean/BlendForGlare" {
	CGINCLUDE

	#include "UnityCG.cginc"
	#define FO_OCEANMAP
	#define FO_DEPTHBLEND_ON
	#include "FOceanCommon.cginc"

	#define NUM_SAMPLES 4

	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
	};
	struct v2f_mt {
		float4 pos : SV_POSITION;
		float2 uv[5] : TEXCOORD0;
	};
			
	sampler2D _MainTex;

	half4 _TexelSize;

    half4        _Direction;
    half         _Attenuation;
	half         _CutOff;

	v2f vert( appdata_img v ) {
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv =  v.texcoord.xy;
		return o;
	}

	v2f_mt vertMultiTap( appdata_img v ) {
		v2f_mt o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv[4] = v.texcoord.xy;
		o.uv[0] = v.texcoord.xy + _TexelSize.xy * 0.5;
		o.uv[1] = v.texcoord.xy - _TexelSize.xy * 0.5;	
		o.uv[2] = v.texcoord.xy - _TexelSize.xy * half2(1,-1) * 0.5;	
		o.uv[3] = v.texcoord.xy + _TexelSize.xy * half2(1,-1) * 0.5;	
		return o;
	}
	
	fixed4 streak (v2f i) : SV_Target {
			fixed4 cOut = 0;

			// sample weight = a^(b*s)
			// a = attenuation
			// b = 4^(pass-1)
			// s = sample number

			half2 pxSize = _TexelSize.zw;

			half b = pow( half(NUM_SAMPLES), _Direction.z);

			pxSize *= _Direction.xy * b;

			for (int s = 0; s < NUM_SAMPLES; s++)
			{
				half sf = half(s);
				half weight = pow(_Attenuation, b * sf);
				half2 sampleCoord = i.uv + sf * pxSize;
				cOut += clamp(weight,0.0,1.0) * tex2D(_MainTex, sampleCoord);
			}

			return saturate(cOut);
	}

	fixed4 downsample (v2f_mt i) : SV_Target {
		fixed4 outColor = 0;	
		
		outColor += tex2D(_MainTex, i.uv[0].xy);
		outColor += tex2D(_MainTex, i.uv[1].xy);
		outColor += tex2D(_MainTex, i.uv[2].xy);
		outColor += tex2D(_MainTex, i.uv[3].xy);

		half depthSample = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[4].xy);
		depthSample = Linear01Depth (depthSample);

		return lerp(0, outColor*0.25, step(tex2D(_OceanMap, i.uv[4].xy).r, depthSample * _CutOff));
	}

	ENDCG 
	
Subshader {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }  

 // 0: downsample blend mode	  		  	
 Pass {    

      CGPROGRAM
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vertMultiTap
      #pragma fragment downsample
      #pragma exclude_renderers gles
      ENDCG
  }

 // 1: streak
 Pass {    

      CGPROGRAM
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vert
      #pragma fragment streak
      #pragma exclude_renderers gles
      ENDCG
  }
}

Fallback off
	
} // shader