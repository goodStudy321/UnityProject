// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/Nature/Afs Tree Creator Leaves Rendertex" {
Properties {
	_Cutoff ("Alpha cutoff", Range(0,1)) = 0.25
	_HalfOverCutoff ("0.5 / alpha cutoff", Range(0,1)) = 1.0
	_MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
}

SubShader {  

	Pass {

		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile AFS_SH_AMBIENT AFS_GRADIENT_AMBIENT AFS_COLOR_AMBIENT
		// #pragma multi_compile UNITY_NO_LINEAR_COLORSPACE
		#include "UnityCG.cginc"
		#include "UnityBuiltin3xTreeLibrary.cginc"

		struct v2f {
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float4 color : TEXCOORD1; 
			float3 nl : TEXCOORD3;
			half3 vlight : TEXCOORD5;
		};

		CBUFFER_START(AfsTerrainImposter)
			float3 _TerrainTreeLightDirections[4];
			float4 _TerrainTreeLightColors[4];
			fixed4 _AfsSkyColor;
			fixed4 _AfsGroundColor;
			fixed4 _AfsEquatorColor;
			half4 afs_SHAr;
			half4 afs_SHAg;
			half4 afs_SHAb;
			half4 afs_SHBr;
			half4 afs_SHBg;
			half4 afs_SHBb;
			half4 afs_SHC;
		CBUFFER_END

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

		// The Trilight Model: res = colour0 * clamp(N.L) + colour1 * (1-abs(N.L)) + colour2 * clamp(-N.L)
		half3 AFSTrilight (float3 normal) {
			return (_AfsSkyColor * saturate(normal.y) + _AfsGroundColor * saturate(normal.y*(-1)) + _AfsEquatorColor * (1-abs(normal.y)) ) ; // * 0.5
		}

		float getNdotL(float3 lightDir, float3 normal, float3 viewDir, float nv) {
				half wrap1 = 0.4;
				half nl = saturate( ( dot(normal, lightDir) + wrap1 ) / ( (1 + wrap1) * (1 + wrap1) ) );
			//	Disney Diffuse
				half3 halfDir = Unity_SafeNormalize (lightDir + viewDir);
				half lh = saturate(dot(lightDir, halfDir));
				//half nv = saturate(dot(v.normal, viewDir));
				half fd90 = 0.5 + 2 * lh * lh;
				half lightScatter	= (1 + (fd90 - 1) * Pow5(1 - nl));
				half viewScatter	= (1 + (fd90 - 1) * Pow5(1 - nv));
				return nl * lightScatter * viewScatter;
		}

		v2f vert (appdata_full v) {	
			v2f o;
			ExpandBillboard (UNITY_MATRIX_IT_MV, v.vertex, v.normal, v.tangent);
			o.pos = UnityObjectToClipPos (v.vertex);
			o.uv = v.texcoord.xy;
			
			float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
			half nv = saturate(dot(v.normal, viewDir));

		//	As DX11 did not like the loop (?) we simply unrolled it
			o.nl.x = getNdotL(_TerrainTreeLightDirections[0], v.normal, viewDir, nv);
			o.nl.y = getNdotL(_TerrainTreeLightDirections[1], v.normal, viewDir, nv);
			o.nl.z = getNdotL(_TerrainTreeLightDirections[2], v.normal, viewDir, nv);
			
			o.color = v.color;
			#if defined(AFS_SH_AMBIENT)
				o.vlight = AFSShadeSH9(half4(v.normal * float3(-1,-1,1), 1.0)) * 4.0 * UNITY_PI; //10;
				o.vlight = IsGammaSpace()? pow(o.vlight, 1.0 /2.2) : o.vlight;
				o.vlight = max(half3(0,0,0), o.vlight); // as it might get negativ...
			#elif defined (AFS_GRADIENT_AMBIENT)
				o.vlight = AFSTrilight (normalize(v.normal)); // * 2.0;
				o.vlight = IsGammaSpace()? pow(o.vlight, 1.0 /2.33) : o.vlight;
				o.vlight = max(half3(0,0,0), o.vlight); // as it might get negativ...
			#elif defined (AFS_COLOR_AMBIENT)
				o.vlight = UNITY_LIGHTMODEL_AMBIENT;
			#endif
			return o;

		}

		sampler2D _MainTex;
		fixed _Cutoff;

		fixed4 frag (v2f i) : SV_Target {
			fixed4 col = tex2D (_MainTex, i.uv);
			clip (col.a - _Cutoff);
			fixed3 albedo = col.rgb; // Do not add AO here

			// EnergyConservationBetweenDiffuseAndSpecular
			// col.rgb = col.rgb * ( 1 - unity_ColorSpaceDielectricSpec.r); // not needed as we fade out specular on mesh trees

			fixed3 light = albedo * i.vlight * i.color.a; // ambient lighting
			for (int j = 0; j < 3; j++)
			{
				half3 lightColor = _TerrainTreeLightColors[j].rgb;
				half3 nl = i.nl[j];
				light += albedo * nl * lightColor;
			}

			fixed4 c;
			c.rgb = light;
			c.a = 1;
			return c;
		}
	ENDCG
	}
}
FallBack Off
}

