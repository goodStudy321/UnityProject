Shader "Hidden/PreIntegratedSkinShader/ComputeLookup/Direct" {
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
					float4 result;
					
					{
						// x is cos(theta)*0.5+0.5, where cos(theta)=dot(normal, light)
						// y is skinRadius*sqrt(variance) where skin radius is 1/curvature and variance is the amount of blur due to scattering in a "layer" of skin
						float cosTheta = saturate(i.uv.x)*2.0-1.0;
						float scattering = 1.0/max(i.uv.y, 0.01);
						float penumbraWidth = 0.5;
						float penumbraLocation = saturate(1.0-_MipLevelNormalized);
						int numTerms = MAXITERATIONS-2;
						
						// Last mip needs means fully shadowed. It needs to be black no mather what.
						float diffuseScattering;
						if (_MipLevelNormalized >= 0.99) {
							diffuseScattering = 0;
						} else {
							diffuseScattering = IntegrateDiffuseScatteringOnRingComponent(cosTheta, scattering, penumbraWidth, penumbraLocation, numTerms);
						}
						result.x = diffuseScattering;
					}
					
					{
						// GGX specular approximation with L.H and N.H by John Hable, see
						// http://www.filmicworlds.com/2014/04/21/optimizing-ggx-shaders-with-dotlh
						// Additionally I took a slightly different approach and squeezed everything into a single lookup
						// with x=L.H, y=N.H and roughness in mip chain.
						// 
						float LdotH = i.uv.x;
						float NdotH = i.uv.y;

						// lookup is non linear for better accuracy where it matters
						LdotH = pow(saturate(LdotH), 2.0);
						NdotH = pow(saturate(NdotH), 1.0/3.0);
						
						float roughness = max(0.001, _MipLevelNormalized);
		
						float D = LightingFuncGGX_D(NdotH, roughness);
						float2 FV_helper = LightingFuncGGX_FV(LdotH,roughness);
						
						result.y = D*FV_helper.x;
						result.z = D*FV_helper.y;
						
						// Compress to a non linear range for LDR storage.
						result.yz = pow(abs(result.yz),1.0/2.0);
						result.yz /= 16.0;
					}
					
					
					
					// Proper energy conservation. May one day return to it, but for now decided to do a simple
					// implementation since the effect is not very noticable for specular intensity and roughness
					// typical to human skin.
					//{
					//	// Integrate specular for energy conservation between specular and diffuse.
					//	// x is cos(theta)*0.5+0.5, where cos(theta)=dot(normal, light). Same as diffuse.
					//	// y is F0
					//	// and roughness in mip chain.
					//	//
					//	// Other way of approaching it would be splitting integral in part that depends on F0 and the
					//	// one that does not. Just like with specular lookup, but this way I can fit into just one
					//	// channel.
					//	
					//	float cosTheta = saturate(i.uv.x)*2.0-1.0;
					//	float F0 = i.uv.y;
					//	float roughness = max(0.001, _MipLevelNormalized);
					//	
					//	float specularEnergy = IntegrateGGX(cosTheta, roughness, F0);
					//	
					//	// store the inverse, ready to by simply multiplied by diffuse at runtime
					//	result.w = 1.0 - specularEnergy;
					//}
					
					result.w = 1.0;
					
					return result;
				}
			ENDCG
		}
	}
	FallBack Off
}
