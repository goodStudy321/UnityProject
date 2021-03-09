Shader "Hidden/FastOcean/WTable" {


	SubShader {
	
		Pass {
		ZTest Always Cull Off ZWrite Off
		Fog { Mode off }

		CGPROGRAM
		#include "UnityCG.cginc"
		#pragma vertex vert_img
		#pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest
		#define WAVE_KM 370.0
		#pragma exclude_renderers gles

		float4 inverseWorldSizes;
		float factor;
		float _Offset;

		float4 frag (v2f_img i) : SV_Target {

			float2 uv = i.uv;
            uv.x = uv.x > 0.5 ? uv.x - 1.0 : uv.x;
            uv.y = uv.y > 0.5 ? uv.y - 1.0 : uv.y;
		    uv -= _Offset;
            uv *= factor;

            float k1 = length(uv * inverseWorldSizes.x);
            float k2 = length(uv * inverseWorldSizes.y);
            float k3 = length(uv * inverseWorldSizes.z);
            float k4 = length(uv * inverseWorldSizes.w);

            float r = sqrt(9.81 * k1 * (1.0 + k1 * k1 / (WAVE_KM * WAVE_KM)));
            float g = sqrt(9.81 * k2 * (1.0 + k2 * k2 / (WAVE_KM * WAVE_KM)));
            float b = sqrt(9.81 * k3 * (1.0 + k3 * k3 / (WAVE_KM * WAVE_KM)));
            float a = sqrt(9.81 * k4 * (1.0 + k4 * k4 / (WAVE_KM * WAVE_KM)));

			return float4(r, g, b, a);
		}
		ENDCG
		}
		
	} 

Fallback off
}
