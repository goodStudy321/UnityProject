// Upgrade NOTE: commented out 'float4 unity_LightmapST', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable


Shader "PolyboxHeightfog"
{
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_AmbientColor("AmbientColor",Color) = (0,0,0,0)
		_MainTex("Albedo", 2D) = "white" {}
		_HeightFogStart("Height Fog Start",Float) = 0.0
		_HeightFogEnd("Height Fog End", Float) = 0.0
		_HeightFogColor("Height Fog Color", Color) = (0,0,0,0)
	}
	SubShader{
		Pass{
			Tags{"LightMode" = "ForwardBase" "RenderType"="Opaque"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
			#pragma target 2.0
			#include"UnityCG.cginc"
			#include"Lighting.cginc"
			#include"AutoLight.cginc"

			uniform fixed4 _Color;
			uniform fixed4 _AmbientColor;
			uniform sampler2D _MainTex;
			uniform half4 _MainTex_ST;
			uniform float _HeightFogStart;
			uniform float _HeightFogEnd;
			uniform fixed4 _HeightFogColor;


			struct v2f {
				half4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
				half3 worldPos : TEXCOORD1;
				half3 worldNormal : TEXCOORD2;
				#ifndef LIGHTMAP_OFF
					half2 lmap : TEXCOORD3;
				#endif
				UNITY_FOG_COORDS(4)
				SHADOW_COORDS(5)
			};

			v2f vert(appdata_full v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.worldPos = mul(unity_ObjectToWorld,v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				#ifndef LIGHTMAP_OFF
					o.lmap = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif
				UNITY_TRANSFER_FOG(o,o.pos);
				TRANSFER_SHADOW(o);
				return o;
			}

			fixed4 frag(v2f i):SV_Target{
				fixed4 albedo = tex2D(_MainTex,i.uv);
				half3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				half3 worldNormal = normalize(i.worldNormal);
				//fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo.rgb;
				fixed3 ambient = albedo * _AmbientColor;
				fixed3 finalColor = albedo.rgb;

				#ifndef LIGHTMAP_OFF
					fixed3 lm = DecodeLightmap (UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lmap));
					finalColor = lm * finalColor * 0.58 +  ambient * lm;
				#else
					UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
					finalColor = albedo.rgb * _LightColor0.rgb * saturate(dot(worldNormal,worldLightDir)) * atten + ambient;
				#endif
				finalColor *= _Color;
				//Polybox heightFog
				half heightFog = saturate((_HeightFogEnd - i.worldPos.y)/(_HeightFogEnd - _HeightFogStart));
				heightFog = pow(heightFog,2.2);
				finalColor = lerp(finalColor,_HeightFogColor,heightFog);

				UNITY_APPLY_FOG(i.fogCoord,finalColor);

				return fixed4(finalColor,1);
			}

			ENDCG
		}
	}
	FallBack "Diffuse"
}
