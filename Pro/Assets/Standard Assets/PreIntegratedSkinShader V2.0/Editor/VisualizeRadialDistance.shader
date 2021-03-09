Shader "Hidden/PreIntegratedSkinShader/ComputeLookup/VisualizeRadialDistance" {
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
				
				float4 frag(v2f i) : COLOR {
					// Get coordinates of the viewport that preserve aspect ratio se we can render a circle and not an elipse.
					float aspectRatio = (float)_TextureWidth / (float)_TextureHeight;
					float x = (i.uv.x-0.5)*aspectRatio + 0.5;
					float y = i.uv.y;

					// Get the distance from center of the viewport.
					float r = distance(float2(x,y), float2(0.5, 0.5));

					// Scale the distance to represent 10mm per unit.
					r *= 10.0;

					// Make the distance represent a circe of 1mm radius and not a point for more intuitive look
					r = max(0.0, r - 1.0);

					// The approximate scattering function for the profile. The distance is in millimeters in world space.
					float3 profile = Scatter(r);

					// Unity's Editor/legacy GUI renders expects gamma space output.
					profile = LinearToGammaSpace(profile);
					
					return float4(profile, 1.0);
				}
			ENDCG
		}
	}
	FallBack Off
}