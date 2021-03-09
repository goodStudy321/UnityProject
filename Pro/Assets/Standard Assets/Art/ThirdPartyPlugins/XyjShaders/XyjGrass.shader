// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "XyjGrass" {
	Properties {
		_Color ("Main Color", Color) = (1, 1, 1, 1)
		_MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
		_Cutoff ("Alpha cutoff", Range (0,.9)) = .5
		_NormalUp("Normal Up Fix", Range(0,1)) = 0.5

		_WaveThreshold ("Wave Threshold", Float ) = 0.49
		_WaveAmplitude ("Wave Amplitude", Float) = 0.1
		_WaveFrequency ("Wave Frequency", Float) = 0.3
	}

	SubShader {
		Tags { "Queue"="AlphaTest" "RenderType"="TransparentCutout" }
		ZWrite On

		// first pass:
		//   render any pixels that are more than [_Cutoff] opaque
		CGPROGRAM
			#pragma surface surf Lambert fullforwardshadows exclude_path:prepass exclude_path:deferred vertex:vert addshadow
			//#pragma target 3.0
		   
			struct Input
			{
				float2 uv_MainTex;
			};
		   
			sampler2D _MainTex;
			fixed4 _Color;
			float _Cutoff;
			half _NormalUp;
			float _WaveAmplitude;
			float _WaveFrequency;
			float _WaveThreshold;   

			void vert(inout appdata_full v) {
				half3 up = UnityWorldToObjectDir(half3(0, 1, 0));
				v.normal = lerp(v.normal, up, _NormalUp);

				float wind = _WaveAmplitude * sin(_WaveFrequency * 2 * 3.14 *_Time.y + v.vertex.x);

				v.vertex.x += wind * step(_WaveThreshold, v.texcoord.y) * step(_WaveThreshold, v.texcoord.x); 
				v.vertex.x -= wind * step(_WaveThreshold, v.texcoord.y) * step(v.texcoord.x, _WaveThreshold); 
			}

			void surf (Input IN, inout SurfaceOutput o)
			{
				fixed4 albedo = tex2D(_MainTex, IN.uv_MainTex) * _Color;
				o.Albedo = albedo.rgb;
				o.Alpha = albedo.a;
				clip(albedo.a - _Cutoff);
			}
		ENDCG
 
		// Second pass:
		//   render the semitransparent details.
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off
 
		CGPROGRAM
			#pragma surface surf Lambert fullforwardshadows exclude_path:prepass exclude_path:deferred keepalpha vertex:vert
			//#pragma target 3.0
		   
			struct Input
			{
				float2 uv_MainTex;
			};
		   
			sampler2D _MainTex;
			fixed4 _Color;
			float _Cutoff;
			half _NormalUp;

			void vert(inout appdata_full v) {
				half3 up = UnityWorldToObjectDir(half3(0, 1, 0));
				v.normal = lerp(v.normal, up, _NormalUp);
			}

			void surf (Input IN, inout SurfaceOutput o)
			{
				fixed4 albedo = tex2D(_MainTex, IN.uv_MainTex) * _Color;
				o.Albedo = albedo.rgb;
				o.Alpha = albedo.a;
#ifdef UNITY_PASS_FORWARDADD // HACK, for forward add pass, premul alpha to light
				o.Albedo *= o.Alpha;
#endif
				clip(-(albedo.a - _Cutoff));
			}
		ENDCG
	}
	FallBack "Transparent/Cutout/VertexLit"
/*
	SubShader {
		Tags { "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout" }
		Lighting off
	
		// Render both front and back facing polygons.
		Cull Off
	
		// first pass:
		//   render any pixels that are more than [_Cutoff] opaque
		Pass {  
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
			
				#include "UnityCG.cginc"

				struct appdata_t {
					float4 vertex : POSITION;
					float4 color : COLOR;
					float2 texcoord : TEXCOORD0;
				};

				struct v2f {
					float4 vertex : POSITION;
					float4 color : COLOR;
					float2 texcoord : TEXCOORD0;
				};

				sampler2D _MainTex;
				float4 _MainTex_ST;
				float _Cutoff;
			
				v2f vert (appdata_t v)
				{
					v2f o;
					o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
					o.color = v.color;
					o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
					return o;
				}
			
				float4 _Color;
				half4 frag (v2f i) : COLOR
				{
					half4 col = _Color * tex2D(_MainTex, i.texcoord);
					clip(col.a - _Cutoff);
					return col;
				}
			ENDCG
		}

		// Second pass:
		//   render the semitransparent details.
		Pass {
			Tags { "RequireOption" = "SoftVegetation" }
		
			// Dont write to the depth buffer
			ZWrite off
		
			// Set up alpha blending
			Blend SrcAlpha OneMinusSrcAlpha
		
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
			
				#include "UnityCG.cginc"

				struct appdata_t {
					float4 vertex : POSITION;
					float4 color : COLOR;
					float2 texcoord : TEXCOORD0;
				};

				struct v2f {
					float4 vertex : POSITION;
					float4 color : COLOR;
					float2 texcoord : TEXCOORD0;
				};

				sampler2D _MainTex;
				float4 _MainTex_ST;
				float _Cutoff;
			
				v2f vert (appdata_t v)
				{
					v2f o;
					o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
					o.color = v.color;
					o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
					return o;
				}
			
				float4 _Color;
				half4 frag (v2f i) : COLOR
				{
					half4 col = _Color * tex2D(_MainTex, i.texcoord);
					clip(-(col.a - _Cutoff));
					return col;
				}
			ENDCG
		}
	}
*/
}
