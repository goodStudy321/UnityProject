// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/FastOcean/CombineForGlare"
{
	CGINCLUDE
	
	#include "UnityCG.cginc"
	#define FO_OCEANMAP
	#define FO_DEPTHBLEND_ON
	#include "FOceanCommon.cginc"

	struct v2f 
	{
		float4 pos : SV_POSITION;
		float4 uv : TEXCOORD0;
	};
	
	sampler2D _MainTex;	
	half4 _MainTex_TexelSize;	
	
    sampler2D _StreakBuffer1;
    sampler2D _StreakBuffer2;
    sampler2D _StreakBuffer3;
    sampler2D _StreakBuffer4;

	half _Intensity;
		
	v2f vert( appdata_img v ) 
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xyxy;
#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			o.uv.w =  1 - o.uv.w;
#endif
		return o;
	} 

	fixed4 fragCombine(v2f i) : SV_Target 
	{
		fixed4 color = tex2D(_MainTex, i.uv.xy);
		fixed4 streakColor1 = tex2D(_StreakBuffer1, i.uv.zw );
		fixed4 streakColor2 = tex2D(_StreakBuffer2, i.uv.zw );
		fixed4 streakColor3 = tex2D(_StreakBuffer3, i.uv.zw );
		fixed4 streakColor4 = tex2D(_StreakBuffer4, i.uv.zw );

		fixed4 streak = streakColor1+streakColor2+streakColor3+streakColor4 ;
		//streak.rgb *= 1 / exp(pow(streak.a,2));
		return fixed4(streak.r * _Intensity * _FoSunColor.rgb + color.rgb,1.0);
	}	

	ENDCG 
	
	Subshader 
	{
		Pass 
 		{
			ZTest Always Cull Off ZWrite Off
			Fog { Mode off }      
			
			CGPROGRAM

			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert
			#pragma fragment fragCombine
			#pragma exclude_renderers gles

			ENDCG
		}	
	}
	Fallback off
}