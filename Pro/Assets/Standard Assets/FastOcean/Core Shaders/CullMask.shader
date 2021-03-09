Shader "Hidden/FastOcean/CullMask" {

SubShader {
	Tags { "RenderType"="Opaque" }
	
	Pass { 

		ZTest Off Cull Front ZWrite On

		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			
			#include "UnityCG.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
			};
			
			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return half4(1, 0, 0, 1);
			}
		ENDCG
	}
}

}
