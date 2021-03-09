// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/PreIntegratedSkinShader2/SkyboxPreview" {
	Properties {
		_Cube ("Reflection Cubemap", Cube) = "_Skybox" {}
		_Alpha ("Alpha", Float) = 1.0
		_Radius ("_Radius", Float) = 0.5
		_Rotation ("_Rotation", Float) = 0.5
	}
	
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		Pass {		
			Tags { "LightMode"="Always"}
			Fog { Mode Off }
			ZTest Always
			Cull Off
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma target 2.0
				#pragma glsl
				
				#include "UnityCG.cginc"
				
				float _Alpha;
				float _Radius;
				float _Rotation;
				samplerCUBE _Cube;
				
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
				
				float intersectRaySphere(float3 rayOrigin, float3 rayDirection, float3 sphereOrigin, float sphereRadius) {
				    float3 oc = rayOrigin - sphereOrigin;
				    float b = 2.0 * dot(rayDirection, oc);
				    float c = dot(oc, oc) - sphereRadius*sphereRadius;
				    float disc = b * b - 4.0 * c;
				 
				    if (disc < 0.0)
				        return -1.0;

					float q =  (sign(b)*sqrt(disc) - b) / 2.0;
				 
				    float t0 = min(q, c/q);
				    float t1 = max(q, c/q);
				 
				    if (t1 < 0.0)
				        return -1.0;
				 
				    return t0 < 0.0 ? t1 : t0;
				}
				
				float4 frag(v2f i) : COLOR {
					//float aspectRatio = (float)_Width / (float)_Height;
					float aspectRatio = 1.0;
					float x = (i.uv.x-0.5)*aspectRatio + 0.5;
					float y = i.uv.y;
					
					float3 sphereOrigin = float3(0.5, 0.5, 0.0);
					float sphereRadius = _Radius;
					
					float3 rayOrigin = float3(x, y, -10.0);
					float3 rayDirection = float3(0.0, 0.0, 1.0);
					
					float d = intersectRaySphere(rayOrigin, rayDirection, sphereOrigin, sphereRadius);
					
					float3 p = rayOrigin + rayDirection*d;
					
					if (d > 0.0) {
						float3 l = normalize(float3(-1.0, 1.0, -2.0));
						float3 n = normalize(p-sphereOrigin);
						
						float3 r = reflect(rayDirection, n);
						
						// rotate reflection around Y axis
						float s = sin(_Rotation * UNITY_PI * 2.0);
						float c = cos(_Rotation * UNITY_PI * 2.0);
						float3 tmp = r;
						r.x = tmp.x*c - tmp.z*s;
						r.z = tmp.x*s + tmp.z*c;

						
						float NdotL = dot(n,l);
						
						float3 reflectionColor = texCUBE(_Cube, r).rgb;

						// Unity's Editor/legacy GUI renders expects gamma space output.
						reflectionColor = LinearToGammaSpace(reflectionColor);

						return float4(reflectionColor, _Alpha);
					} else {
						return float4(0.0, 0.0, 0.0, 0.0);
					}
				}
			ENDCG
		}
	}
	FallBack Off
}
