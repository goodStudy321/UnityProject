// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "Instanced/RockFuzz" {
	Properties {
		_Color 								("Color", Color) = (1,1,1,1)
		_MainTex 							("Albedo (RGB) Smoothness (A)", 2D) = "white" {}
		[NoScaleOffset]_BumpMap 			("Normal", 2D) = "bump" {}
		_SpecularReflectivity				("Specular Reflectivity", Color) = (0.2,0.2,0.2)

		[Space(8)]
		[NoScaleOffset]_FuzzTex 			("Fuzz Mask (G)", 2D) = "black" {}
		_DiffuseScatteringContraction 		("Scatter Power", Range(0,10)) = 8
		_DiffuseScatteringBias 				("Scatter Bias", Range(0,1)) = 0

	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		// And generate the shadow pass with instancing support
		#pragma surface surf StandardSpecular fullforwardshadows addshadow

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		// Enable instancing for this shader
		#pragma multi_compile_instancing

		// Config maxcount. See manual page.
		// #pragma instancing_options

		sampler2D _MainTex;
		
		struct Input {
			float2 uv_MainTex;
			float3 viewDir;
		};

		sampler2D _BumpMap;
		half3 _SpecularReflectivity;

		sampler2D _FuzzTex;
		half _DiffuseScatteringContraction;
		half _DiffuseScatteringBias;

		// Declare instanced properties inside a cbuffer.
		// Each instanced property is an array of by default 500(D3D)/128(GL) elements. Since D3D and GL imposes a certain limitation
		// of 64KB and 16KB respectively on the size of a cubffer, the default array size thus allows two matrix arrays in one cbuffer.
		// Use maxcount option on #pragma instancing_options directive to specify array size other than default (divided by 4 when used
		// for GL).
		UNITY_INSTANCING_BUFFER_START(Props)
			UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)	// Make _Color an instanced property (i.e. an array)
#define _Color_arr Props
		UNITY_INSTANCING_BUFFER_END(Props)

		void surf (Input IN, inout SurfaceOutputStandardSpecular o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * UNITY_ACCESS_INSTANCED_PROP(_Color_arr, _Color);
			o.Albedo = c.rgb;
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));

			o.Specular = _SpecularReflectivity;
			o.Smoothness = c.a;
			o.Alpha = 1;

			// Scatter
			half NdotV = dot(o.Normal, normalize(IN.viewDir));
			NdotV *= NdotV;
			half fuzz = tex2D(_FuzzTex, IN.uv_MainTex).g;
			o.Albedo += o.Albedo * (exp2(-(NdotV * _DiffuseScatteringContraction)) + _DiffuseScatteringBias) * fuzz;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
