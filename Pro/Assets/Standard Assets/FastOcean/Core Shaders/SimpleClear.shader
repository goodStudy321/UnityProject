// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'



Shader "Hidden/FastOcean/SimpleClear" {
Properties {
	_Color ("Color", COLOR) = (0, 0, 0, 0)
}

SubShader {
	Pass {
		ZTest Always Cull Off ZWrite Off
		Fog { Mode off }

CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma fragmentoption ARB_precision_hint_fastest 
#include "UnityCG.cginc"

fixed4 _Color;
 
struct v2f {
	float4 pos : SV_POSITION;
};

v2f vert( appdata_img v )
{
	v2f o;
	o.pos = UnityObjectToClipPos(v.vertex);
	return o;
}

fixed4 frag (v2f i) : SV_Target
{
	return _Color;
}
ENDCG
	}
}

Fallback off

}