Shader "Hidden/PreIntegratedSkinShader/ComputeLookup/VisualizeSphere" {
	Properties {
		_MipLevel ("_MipLevel", Float) = 0.0
		_MipCount ("_MipCount", Float) = 0.0
		_MipLevelNormalized ("_MipLevelNormalized", Float) = 0.0
		_TextureWidth ("_TextureWidth", Float) = 0.0
		_TextureHeight ("_TextureHeight", Float) = 0.0
		
		_PreviewScatteringPower ("_PreviewScatteringPower", Float) = 0.0
		
		_PSSProfileHigh_weighths1_var1 ("_PSSProfileHigh_weighths1_var1", Vector) = (0.234, 0.562, 0.644, 0.006)
		_PSSProfileHigh_weighths2_var2 ("_PSSProfileHigh_weighths2_var2", Vector) = (0.101, 0.415, 0.341, 0.048)
		_PSSProfileHigh_weighths3_var3 ("_PSSProfileHigh_weighths3_var3", Vector) = (0.113, 0.009, 0.007, 0.187)
		_PSSProfileHigh_weighths4_var4 ("_PSSProfileHigh_weighths4_var4", Vector) = (0.113, 0.009, 0.007, 0.567)
		_PSSProfileHigh_weighths5_var5 ("_PSSProfileHigh_weighths5_var5", Vector) = (0.359, 0.005, 0.000, 1.990)
		_PSSProfileHigh_weighths6_var6 ("_PSSProfileHigh_weighths6_var6", Vector) = (0.078, 0.000, 0.000, 7.410)
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
				
				float _PreviewScatteringPower;
				
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
					float aspectRatio = (float)_TextureWidth / (float)_TextureHeight;
					float x = (i.uv.x-0.5)*aspectRatio + 0.5;
					float y = i.uv.y;
					
					float3 sphereOrigin = float3(0.5, 0.5, 0.0);
					float sphereRadius = 0.4;
					
					float3 rayOrigin = float3(x, y, -10.0);
					float3 rayDirection = float3(0.0, 0.0, 1.0);
					
					float d = intersectRaySphere(rayOrigin, rayDirection, sphereOrigin, sphereRadius);
					
					float3 p = rayOrigin + rayDirection*d;
					
					if (d > 0.0) {
						float3 lightPos = float3(-1.0, 1.0, -0.5);
						float3 l = normalize(lightPos);
						float3 n = normalize(p-sphereOrigin);
						
						float scatteringPower = _PreviewScatteringPower != 0.0 ? _PreviewScatteringPower : 0.25f; // uniform is not set in case of static preview, so use the default to see some scattering

						scatteringPower = GammaToLinearSpace(scatteringPower.xxx).x;

						float skinRadius = 1.0/max(0.05, scatteringPower);
					
						float NdotL = dot(n,l);
						float3 diff = 0;
						
						int numTerms = 32;
						
						diff += PSS_PROFILE_WEIGHTS_1.rgb * IntegrateDiffuseScatteringOnRingComponent(NdotL, skinRadius/sqrt(PSS_PROFILE_VARIANCE_1), 1.0, 1.0, numTerms);
						diff += PSS_PROFILE_WEIGHTS_2.rgb * IntegrateDiffuseScatteringOnRingComponent(NdotL, skinRadius/sqrt(PSS_PROFILE_VARIANCE_2), 1.0, 1.0, numTerms);
						diff += PSS_PROFILE_WEIGHTS_3.rgb * IntegrateDiffuseScatteringOnRingComponent(NdotL, skinRadius/sqrt(PSS_PROFILE_VARIANCE_3), 1.0, 1.0, numTerms);
						diff += PSS_PROFILE_WEIGHTS_4.rgb * IntegrateDiffuseScatteringOnRingComponent(NdotL, skinRadius/sqrt(PSS_PROFILE_VARIANCE_4), 1.0, 1.0, numTerms);
						diff += PSS_PROFILE_WEIGHTS_5.rgb * IntegrateDiffuseScatteringOnRingComponent(NdotL, skinRadius/sqrt(PSS_PROFILE_VARIANCE_5), 1.0, 1.0, numTerms);
						diff += PSS_PROFILE_WEIGHTS_6.rgb * IntegrateDiffuseScatteringOnRingComponent(NdotL, skinRadius/sqrt(PSS_PROFILE_VARIANCE_6), 1.0, 1.0, numTerms);

						// Unity's Editor/legacy GUI renders expects gamma space output.
						diff = LinearToGammaSpace(diff);

						return float4(diff.rgb, 1.0);
					} else {
						return float4(0,0,0, 0.0);
					}
				}
			ENDCG
		}
	}
	FallBack Off
}