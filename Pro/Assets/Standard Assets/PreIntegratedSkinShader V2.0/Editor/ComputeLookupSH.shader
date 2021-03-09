Shader "Hidden/PreIntegratedSkinShader/ComputeLookup/SH" {
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
					// diffusion profile integrated in SH domain
					// x is skinRadius*sqrt(variance) where skin radius is 1/curvature and variance is the amount of blur due to scattering in a "layer" of skin
					// y is ignored since the texture is 1px high. Can use it for something in the future.
					//int numterms = sqrt(MAXITERATIONS) - 1;
					int numterms = 32;
					float incr = PSS_PI / (float)numterms;
					
					float3 diffuseScattering = 0; // x,y,z,w stand for order 0,1,2,3 respectively
					
					float scattering = 1.0/max(i.uv.x, 0.01);
					
					//float roughness = max(0.001, _MipLevelNormalized);
					//float F0 = i.uv.y;
					
					PSS_LOOP
					for (float theta=0.0; theta<=PSS_PI; theta += incr) {
						float cosTheta = cos(theta);
						
						// SH basis functions defined as K(l, 0)*P(l,m,cosTheta)
						// m and phi are zero in our case (isotropic)
						// again, x,y,z stand for band index l 0,1,2 respectively.
						float3 sh;
						sh.x = 1.0;
						sh.y = cosTheta;
						sh.z = (3.0*cosTheta*cosTheta-1.0);
						
						// Note that the basis function with coefficients would look something like below.
						// I removed the coefficients that are already in Unity's SH fed to the shader and
						// normalized.
						//sh.x = sqrt(1.0/(4.0*PSS_PI));
						//sh.y = sqrt(3.0/(4.0*PSS_PI))*cosTheta;
						//sh.z = sqrt(5.0/(4.0*PSS_PI))/2.0 * (3.0*cosTheta*cosTheta-1.0);

						float light = IntegrateDiffuseScatteringOnRingComponent(cosTheta, scattering, 1.0, 1.0, 32);
						
						// for testing
						//light = max(0,cosTheta);
						
						// Proper energy conservation. May one day return to it, but for now decided to do a simple
						// implementation since the effect is not very noticable for specular intensity and roughness
						// typical to human skin.
						//float specularEnergy = IntegrateGGX(cosTheta, roughness, F0);
						
						// simpler conservation
						// specularEnergy = F0+(1.0-F0)*pow(cosTheta, 5.0);

						//light = max(0, light*(1.0 - saturate(specularEnergy)));
						
						diffuseScattering += (sh * max(0,light) * sin(theta) / numterms);
					}
					
					// constant term outside of integral
					diffuseScattering *= PSS_PI;
					// normalization factors
					diffuseScattering.x *= 2.0;
					diffuseScattering.y *= 3.0;
					diffuseScattering.z *= 4.0;
					
					// fit into 0..1 range of LDR lookup texture
					diffuseScattering /= 2.0;
					
					// check for overflows
					//if (diffuseScattering.x<0 || diffuseScattering.y<0 || diffuseScattering.z<0)
					//	return float4(1,0,1,1); // the dreaded pinky
					//if (diffuseScattering.x>1 || diffuseScattering.y>1 || diffuseScattering.z>1)
					//	return float4(1,0,1,1); // the dreaded pinky
							
					return float4(diffuseScattering, 1.0);
				}
			ENDCG
		}
	}
	FallBack Off
}