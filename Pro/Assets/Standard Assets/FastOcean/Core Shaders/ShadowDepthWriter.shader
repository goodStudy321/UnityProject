// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/FastOcean/ShadowDepthWriter" {

	CGINCLUDE
	#include "UnityCG.cginc"
	
	struct v2f {
		float4 pos : SV_POSITION;
		float4 hpos : TEXCOORD0;
		float2 uv: TEXCOORD1;
	};
	
	sampler2D _MainTex;

	v2f vert(appdata_base v) {
		v2f o;
		o.pos = UnityObjectToClipPos (v.vertex);
		o.hpos = o.pos;
		o.uv = v.texcoord;
		return o;
	}
	
	float4 frag(v2f i) : SV_Target {
		fixed4 texcol = tex2D( _MainTex, i.uv );
		clip( texcol.a - 0.01);
		return float4(i.hpos.z, 0, 0, 1); // i.hpos.z / i.hpos.w
	}
	ENDCG
	
	SubShader {
		Tags { "RenderType"="Opaque" }
		
		Cull Front
		pass {
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
			ENDCG
		}
	}
}
