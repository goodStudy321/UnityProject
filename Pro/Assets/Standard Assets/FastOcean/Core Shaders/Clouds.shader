// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/FastOcean/Clouds" {
	Properties {
		_MainTex("", 2D) = "white" {}
	}

	CGINCLUDE
	
	#include "UnityCG.cginc"
	#define FO_OCEANMAP
	#define FO_DEPTHBLEND_ON
	#include "FOceanCommon.cginc"

	sampler2D _MainTex;
	sampler2D _ValueNoise;

	float _MinHeight;
	float _MaxHeight;
	float4 _FadeScaleWind;
	float _Thickness;
	fixed4 _LightColor;
	fixed4 _BaseColor;
	fixed4 _ScatterColor;

	half4 _MainTex_TexelSize;	
	float4x4 _FrustumCornersWS;

	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		#if UNITY_UV_STARTS_AT_TOP
		float2 uv1 : TEXCOORD1;
		#endif	
		float4 ray : TEXCOORD2;
	};

	v2f vert(appdata_img v) {
		v2f o;

		// Vertex.z is populated by Clouds.cs (companion script) with the current frustum corner
		half index = v.vertex.z;
		v.vertex.z = 0.1;

		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;

		#if UNITY_UV_STARTS_AT_TOP
		o.uv1 = v.texcoord.xy;
		if (_MainTex_TexelSize.y < 0)
			o.uv.y = 1-o.uv.y;
		#endif				

		o.ray = _FrustumCornersWS[(int)index];
		o.ray.w = index;

		return o;
	}

	#define NOISEPROC(N, P) 1.75 * N * saturate((_MaxHeight-P.y) * _FadeScaleWind.x)

	ENDCG

	SubShader {
		Lod 200
		Pass {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma exclude_renderers gles
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile __ MAX_ITERATORS_ON MAX_ITERATORS_SCATTER_ON

			inline float noise(in float3 x) {
				x *= _FadeScaleWind.y;
				float3 p = floor(x);
				float3 f = frac(x);
				f = f*f*(3.0 - 2.0*f);
				float2 uv = (p.xy + float2(37.0, -17.0)*p.z) + f.xy;
				float2 rg = tex2D(_ValueNoise, (uv + 0.5) * 0.00390625).rg;
				return -1.0 + 2.0*lerp(rg.g, rg.r, f.z);
			}


			inline float map(in float3 q)
			{
				float3 p = q;
				float f;
				f = 0.50000*noise(q); q = q*2.02;
				f += 0.25000*noise(q); q = q*2.03;
				f += 0.12500*noise(q); q = q*2.01;
				f += 0.06250*noise(q);
				return NOISEPROC(f, p);
			}

			inline fixed4 integrate(in fixed4 sum, in float den, in fixed3 bgcol, in float t)
			{
				// lighting
				fixed3 lin = _LightColor.rgb ;

				fixed4 amb = UNITY_LIGHTMODEL_AMBIENT;
				fixed3 colrgb = lerp(amb.rgb, _BaseColor.rgb, den);
				fixed4 col = fixed4(colrgb.r, colrgb.g, colrgb.b, (fixed)den);
				col.xyz *= lin;
				col.xyz = lerp(col.xyz, bgcol, 1.0 - exp(-_Thickness*t*t));
				// front to back blending    
				col.a *= _ScatterColor.a;
				col.rgb *= col.a;
				return sum + col*(1.0 - sum.a);
			}

			inline fixed4 integrate(in fixed4 sum, in float dif, in float den, in fixed3 bgcol, in float t)
			{
				// lighting
				fixed3 lin = _LightColor.rgb + _ScatterColor.rgb*dif;

				fixed4 amb = UNITY_LIGHTMODEL_AMBIENT;
				fixed3 colrgb = lerp(amb.rgb, _BaseColor.rgb, den);
				fixed4 col = fixed4(colrgb.r, colrgb.g, colrgb.b, (fixed)den);
				col.xyz *= lin;
				col.xyz = lerp(col.xyz, bgcol, 1.0 - exp(-_Thickness*t*t));
				// front to back blending    
				col.a *= _ScatterColor.a;
				col.rgb *= col.a;
				return sum + col*(1.0 - sum.a);
			}
			
			inline fixed4 raymarch(in float3 rd, in fixed3 bgcol)
			{
				fixed4 sum = fixed4(0.0, 0.0, 0.0, 0.0);

				float t = 0.0;

#if defined (MAX_ITERATORS_ON) || defined (MAX_ITERATORS_SCATTER_ON)
				for (int i = 0; i < 6; i++) {
#else
				for (int i = 0; i < 2; i++) {
#endif
					float3 pos = t*rd;
					pos.xz += _FadeScaleWind.zw; // wind
					float den = map(pos);

#if defined (MAX_ITERATORS_SCATTER_ON)
					float dif = saturate((den - map(pos + _FoSunDir)) * 1.67);
					sum = lerp(integrate(sum, dif, den, bgcol, t), sum, step(den, 0));
#else
					sum = lerp(integrate(sum, den, bgcol, t), sum, step(den, 0));
#endif

#if defined (MAX_ITERATORS_ON) || defined (MAX_ITERATORS_SCATTER_ON)
					t += 0.5;
#else
					t += 1.5;
#endif
				}

				float k = clamp(rd.y - _MinHeight, 0, 0.5);
				sum *= k * k * 4;

				return clamp(sum, 0.0, 1.0);
			}

			fixed4 frag(v2f i) : SV_Target {
				half3 eyeVec = normalize(i.ray.xyz);

				fixed3 col = tex2D(_MainTex,i.uv);
				fixed4 add = raymarch(eyeVec, col);
#if UNITY_UV_STARTS_AT_TOP
				half depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv1.xy);
#else
				half depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv.xy);
#endif	
				depth = Linear01Depth (depth);

				return fixed4(lerp(col, col*(1.0-add.w)+add.xyz, depth),1.0);
			}
			ENDCG
		}
	} 

	FallBack Off
}
