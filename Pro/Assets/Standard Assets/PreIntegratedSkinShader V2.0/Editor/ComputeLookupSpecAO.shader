Shader "Hidden/PreIntegratedSkinShader/ComputeLookup/SpecAO" {
	Properties {
		_MipLevel ("_MipLevel", Float) = 0.0
		_MipCount ("_MipCount", Float) = 0.0
		_MipLevelNormalized ("_MipLevelNormalized", Float) = 0.0
		_TextureWidth ("_TextureWidth", Float) = 0.0
		_TextureHeight ("_TextureHeight", Float) = 0.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		Pass {		
			Tags { "LightMode"="Always"}
			ZTest Always
			Cull Off
			ZWrite Off
			Blend Off
			
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma target 3.0
				#pragma glsl
				
				// only compile for traditional desktop renderers to avoid strange warnings
				#pragma only_renderers d3d9 d3d11 opengl glcore
				
				#include "./ComputeLookups.cginc"
				
				struct v2f {
					float4 pos : SV_POSITION;
					float4 uv : TEXCOORD0;
				};

				v2f vert(appdata_base v) {
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv = v.texcoord;
					return o;
				}
				
				float4 frag(v2f i) : COLOR {
					float4 result = 0;
					
					float NdotE = i.uv.x;
					float ao = i.uv.y;
					
					float specularOcclusion = saturate(pow(NdotE+ao, 2.0) - 1.0 + ao/2.0);
					result = specularOcclusion;
					
					return result;
				}
			ENDCG
		}
	}
	FallBack Off
}
