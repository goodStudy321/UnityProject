// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/PreIntegratedSkinShader2/ProfilePreview" {
	Properties {
		_Alpha ("Alpha", Float) = 1.0
		_Radius ("_Radius", Float) = 0.5
		_Rotation ("_Rotation", Float) = 0.5
		
		_ScatteringPower ("_ScatteringPower", Float) = 0.2
		
		_LookupDirect("_LookupDirect", 2D) = "white" {}
		_LookupDirectSM2("_LookupDirectSM2", 2D) = "white" {}
		
		// Default values are for the caucasian profile. Decimals truncated to avoid a Unity bug (#686324) that makes shader not work at runtime.
		PSSProfileHigh_weighths1_var1 ("_PSSProfileHigh_weighths1_var1", Vector) = (0.234, 0.562, 0.644, 0.006)
		PSSProfileHigh_weighths2_var2 ("_PSSProfileHigh_weighths2_var2", Vector) = (0.101, 0.415, 0.341, 0.048)
		PSSProfileHigh_weighths3_var3 ("_PSSProfileHigh_weighths3_var3", Vector) = (0.113, 0.009, 0.007, 0.187)
		PSSProfileHigh_weighths4_var4 ("_PSSProfileHigh_weighths4_var4", Vector) = (0.113, 0.009, 0.007, 0.567)
		PSSProfileHigh_weighths5_var5 ("_PSSProfileHigh_weighths5_var5", Vector) = (0.359, 0.005, 0.000, 1.990)
		PSSProfileHigh_weighths6_var6 ("_PSSProfileHigh_weighths6_var6", Vector) = (0.078, 0.000, 0.000, 7.410)
		PSSProfileHigh_sqrtvar1234 ("_PSSProfileHigh_sqrtvar1234", Vector) = (0.08, 0.219, 0.432, 0.753)
		PSSProfileHigh_transl123_sqrtvar5 ("_PSSProfileHigh_transl123_sqrtvar5", Vector) = (-225.421, -29.808, -7.715, 1.410)
		PSSProfileHigh_transl456_sqrtvar6 ("_PSSProfileHigh_transl456_sqrtvar6", Vector) = (-2.544, -0.725, -0.195, 2.722)
		
		PSSProfileMedium_weighths1_var1 ("_PSSProfileMedium_weighths1_var1", Vector) = (0.335, 0.978, 0.986, 0.023)
		PSSProfileMedium_weighths2_var2 ("_PSSProfileMedium_weighths2_var2", Vector) = (0.227, 0.017, 0.014, 0.377)
		PSSProfileMedium_weighths3_var3 ("_PSSProfileMedium_weighths3_var3", Vector) = (0.438, 0.005, 0.000, 2.939)
		PSSProfileMedium_transl123 ("_PSSProfileMedium_transl123", Vector) = (-62.441, -3.827, -0.491, 0.0)
		PSSProfileMedium_sqrtvar123 ("_PSSProfileMedium_sqrtvar123", Vector) = (0.152, 0.614, 1.714, 0.0)
		
		PSSProfileLow_weighths1_var1 ("_PSSProfileLow_weighths1_var1", Vector) = (0.448, 0.986, 0.993, 0.031)
		PSSProfileLow_weighths2_var2 ("_PSSProfileLow_weighths2_var2", Vector) = (0.552, 0.014, 0.007, 2.395)
		PSSProfileLow_sqrtvar12 ("_PSSProfileLow_sqrtvar12", Vector) = (0.176, 1.548, 0.0, 0.0)
		PSSProfileLow_transl ("_PSSProfileLow_transl", Vector) = (-1.0387, -35.927, -55.504, 0.0)
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
				
				float _ScatteringPower;

				sampler2D _LookupDirect;
				sampler2D _LookupDirectSM2;

				half4 _PSSProfileHigh_weighths1_var1; // xyz: rgb weights of profile's first component; w: its respective variance (blur)
				half4 _PSSProfileHigh_weighths2_var2; // idem, but for 2nd component of the profile
				half4 _PSSProfileHigh_weighths3_var3; // ...
				half4 _PSSProfileHigh_weighths4_var4;
				half4 _PSSProfileHigh_weighths5_var5;
				half4 _PSSProfileHigh_weighths6_var6;
				half4 _PSSProfileHigh_sqrtvar1234; // precomputed sqrt(variance) for components 1,2,3,4
				half4 _PSSProfileHigh_transl123_sqrtvar5; // xyz: precomputed translucency factor for profile components 1,2,3; zw: precomputed sqrt(variance) for component 5
				half4 _PSSProfileHigh_transl456_sqrtvar6; // xyz: precomputed translucency factor for profile components 4,5,6; zw: precomputed sqrt(variance) for component 6								
				
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
						float3 lightPos = float3(-1.0, 1.0, -0.5);
						float3 l = normalize(lightPos);
						float3 n = normalize(p-sphereOrigin);
						
						// rotate light around Y axis
						float s = sin(_Rotation * UNITY_PI * 2.0);
						float c = cos(_Rotation * UNITY_PI * 2.0);
						float3 tmp = l;
						l.x = tmp.x*c - tmp.z*s;
						l.z = tmp.x*s + tmp.z*c;

						float NdotL = dot(n,l);
						
						half scattering = _ScatteringPower;

						scattering = GammaToLinearSpace(scattering.xxx).x;

						float diffLookup = (0.5 + 0.5 * NdotL);
						
						float3 diff = 0;

						diff += _PSSProfileHigh_weighths1_var1.rgb * tex2D(_LookupDirectSM2, float2(diffLookup, scattering*_PSSProfileHigh_sqrtvar1234.x)).r;
						diff += _PSSProfileHigh_weighths2_var2.rgb * tex2D(_LookupDirectSM2, float2(diffLookup, scattering*_PSSProfileHigh_sqrtvar1234.y)).r;
						diff += _PSSProfileHigh_weighths3_var3.rgb * tex2D(_LookupDirectSM2, float2(diffLookup, scattering*_PSSProfileHigh_sqrtvar1234.z)).r;
						diff += _PSSProfileHigh_weighths4_var4.rgb * tex2D(_LookupDirectSM2, float2(diffLookup, scattering*_PSSProfileHigh_sqrtvar1234.w)).r;
						diff += _PSSProfileHigh_weighths5_var5.rgb * tex2D(_LookupDirectSM2, float2(diffLookup, scattering*_PSSProfileHigh_transl123_sqrtvar5.w)).r;
						diff += _PSSProfileHigh_weighths6_var6.rgb * tex2D(_LookupDirectSM2, float2(diffLookup, scattering*_PSSProfileHigh_transl456_sqrtvar6.w)).r;

						// Unity's Editor/legacy GUI renders expects gamma space output.
						diff = LinearToGammaSpace(diff);
						
						return float4(diff, _Alpha);
					} else {
						return float4(0.0, 0.0, 0.0, 0.0);
					}
				}
			ENDCG
		}
	}
	FallBack Off
}
