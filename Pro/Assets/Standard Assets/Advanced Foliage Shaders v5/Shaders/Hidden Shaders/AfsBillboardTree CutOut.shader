// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Billboard shader which uses alpha testing and writes to depth – needed by e.g. voulumetric lighting or ssao

Shader "Hidden/TerrainEngine/BillboardTree" {
	Properties {
		_MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
	}
	
	SubShader {
		Tags { "Queue" = "AlphaTest" "IgnoreProjector"="True" "RenderType"="AFSTreeBillboard" }
		Pass {

			Cull Off
			ZWrite On
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#include "UnityCG.cginc"

			#include "TerrainEngine.cginc"
			#include "../Includes/AfsBillboardShadow.cginc"

			struct v2f {
				float4 pos : SV_POSITION;
				fixed4 color : COLOR0;
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
			};

			// AFS Billboard Shadow Color
			fixed4 _AfsAmbientBillboardLight;
			// AFS Tree Color
			fixed4 _AfsTreeColor;
			half _AfsBillboardBorder;

half4 afs_SHAr;
			half4 afs_SHAg;
			half4 afs_SHAb;
			half4 afs_SHBr;
			half4 afs_SHBg;
			half4 afs_SHBb;
			half4 afs_SHC;




half3 AFSShadeSH9 (half4 normal)
		{
			normal = normalize(normal);
			half3 x1, x2, x3;
			// Linear + constant polynomial terms
			x1.r = dot(afs_SHAr,normal);
			x1.g = dot(afs_SHAg,normal);
			x1.b = dot(afs_SHAb,normal);
			// 4 of the quadratic polynomials
			half4 vB = normal.xyzz * normal.yzzx;
			x2.r = dot(afs_SHBr,vB);
			x2.g = dot(afs_SHBg,vB);
			x2.b = dot(afs_SHBb,vB);
			// Final quadratic polynomial
			float vC = normal.x*normal.x - normal.y*normal.y;
			x3 = afs_SHC.rgb * vC;
			return x1 + x2 + x3;
		}


			v2f vert (appdata_tree_billboard v) {
				v2f o;
				AfsTerrainBillboardTree(v.vertex, v.texcoord1.xy, v.texcoord.y);
				#if UNITY_VERSION >= 540
					o.pos = UnityObjectToClipPos(v.vertex);
				#else
					o.pos = UnityObjectToClipPos (v.vertex);
				#endif
				o.uv.x = v.texcoord.x;
				o.uv.y = v.texcoord.y > 0;
			//	Apply tree color
				o.color.rgb = lerp(_AfsTreeColor.rgb, 1.0, v.color.g);
				UNITY_TRANSFER_FOG(o,o.pos);

				half ambientIntensity = dot( AFSShadeSH9(half4(0,1,0,1)), 1);

				o.color.a = ambientIntensity;

				return o;
			}

			sampler2D _MainTex;

			fixed4 frag(v2f input) : SV_Target
			{
				fixed4 col = tex2D( _MainTex, input.uv);
				
			//	fix border / accordig to ambient "intensity"
				half boderfix = saturate ( input.color.a * input.color.a * 100 ); 
				col.rgb = lerp(col.rgb * col.a * col.a, col.rgb, boderfix );
				//col.rgb *= col.a * col.a; // darkens too much...
		
			//	apply tree color
				col.rgb = col.rgb * input.color.rgb;

				clip(col.a - 0.6); //5);
				UNITY_APPLY_FOG(input.fogCoord, col);
				return col;
			}
			ENDCG			
		}


		// ///////////
		// This pass is a shadow caster pass but we use it to write to depth only

		Pass {
		
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
		
			Fog {Mode Off}
			ColorMask rgb
			ZWrite On ZTest LEqual Cull Off
			Offset 1, 1
			
			CGPROGRAM
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			#pragma exclude_renderers noshadows
			#pragma glsl_no_auto_normalization
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile_shadowcaster
			
			#include "HLSLSupport.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
	
			#include "TerrainEngine.cginc"
			#include "../Includes/AfsBillboardShadow.cginc"
	
			sampler2D _MainTex;
			
			float4 _CameraForwardVec;
			float4 _AfsTerrainTrees;
	
			struct Input {
				float2 uv_MainTex;
			};

			struct v2f_surf {
				V2F_SHADOW_CASTER;
				float2 hip_pack0 : TEXCOORD2;
			}   ;
			
			float4 _MainTex_ST;
			v2f_surf vert_surf (appdata_full v) {
				v2f_surf o;
				// We have to distinguish between depth and shadow pass / unity_LightShadowBias is (0,0,0,0) when rendering depth in forward
				// We do not want the billboards to cast shadows (as we can't get a nice transition here), so we do not call the vertex function
				if (unity_LightShadowBias.z == 0.0) {
					AfsTerrainBillboardTree(v.vertex, v.texcoord1.xy, v.texcoord.y);
				}
				o.hip_pack0.x = v.texcoord.x;
				o.hip_pack0.y = v.texcoord.y > 0;
				TRANSFER_SHADOW_CASTER(o)
				return o;
			}
			
			float4 frag_surf (v2f_surf IN) : COLOR {
				half alpha = tex2D(_MainTex, IN.hip_pack0.xy).a;
			// Has to match DepthNormal Shader
				clip (alpha - 0.6); //5);
				SHADOW_CASTER_FRAGMENT(IN)
			}
			ENDCG
		}
		// ///////////

	}
	Fallback Off
}
