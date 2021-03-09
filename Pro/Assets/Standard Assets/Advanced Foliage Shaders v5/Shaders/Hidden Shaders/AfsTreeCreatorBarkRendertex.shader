// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


// Double pass shader to avoid bright outlines around the billboards


Shader "Hidden/Nature/Afs Tree Creator Bark Rendertex" {
Properties {
	_MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
	_BumpSpecMap ("Normalmap (GA) Spec (R)", 2D) = "bump" {}
	_TranslucencyMap ("Trans (RGB) Gloss(A)", 2D) = "white" {}
	
	// These are here only to provide default values
	_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
}

SubShader {  
	

//	First pass wich renders a normal extruded version of the treee into the background

/*	Pass {

		// We do not need alpha here
		ColorMask RGB
		// Make sure that the second apss will always be rendered on top
		Zwrite Off

		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile AFS_SH_AMBIENT AFS_GRADIENT_AMBIENT AFS_COLOR_AMBIENT
		#include "UnityCG.cginc"

		// Include this to be able to use "Unity_GlossyEnvironment"
		//			#include "UnityPBSLighting.cginc"
		//			#include "UnityStandardUtils.cginc"
		//			#include "UnityStandardBRDF.cginc"

		struct v2f {
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float4 color : TEXCOORD1;
			//float2 params[3]: TEXCOORD2;
			float3 params[3]: TEXCOORD2;

			//float3 viewDir : TEXCOORD3;
			//float3 normal : TEXCOORD4;
			half3 vlight : TEXCOORD5;
			//fixed4 wNormalNV : TEXCOORD6;
			//float3 lh : TEXCOORD7;
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

		v2f vert (appdata_full v) {
			v2f o;
			v.vertex.xyz += v.normal * 0.5;
			o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord.xy;
			float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
			//o.viewDir = viewDir;
			//o.normal = v.normal;
			for (int j = 0; j < 3; j++)
			{
				float3 lightDir = _TerrainTreeLightDirections[j];
				half nl = dot (v.normal, lightDir);
				o.params[j].r = max (0, nl);
				half3 h = normalize (lightDir + viewDir);
				float nh = max (0, dot (v.normal, h));
				o.params[j].g = nh;
				half nv = max(0, dot(v.normal, viewDir));
				o.params[j].b = nv;

				//o.lh[j] = DotClamped (lightDir, h);

			}
			o.color = v.color;
			#if defined(AFS_SH_AMBIENT)
				o.vlight = AFSShadeSH9(half4(v.normal * float3(-1,-1,1), 1.0)) * 10;
				o.vlight = IsGammaSpace()? pow(o.vlight, 1.0 /2.2) : o.vlight;
				o.vlight = max(half3(0,0,0), o.vlight); // as it might get negativ...
			#elif defined (AFS_GRADIENT_AMBIENT)
				o.vlight = AFSTrilight (normalize(v.normal)); // * 2.0;
				o.vlight = IsGammaSpace()? pow(o.vlight, 1.0 /2.33) : o.vlight;
				o.vlight = max(half3(0,0,0), o.vlight); // as it might get negativ...
			#elif defined (AFS_COLOR_AMBIENT)
				o.vlight = UNITY_LIGHTMODEL_AMBIENT;
			#endif

			//o.wNormalNV.xyz = normalize(v.normal);
			//o.wNormalNV.w = saturate(dot(v.normal, viewDir));

			return o;
		}

		sampler2D _MainTex;

	//	We do not do any view depended calculations here (no translucency, no specular lighting) as it does not fit billboards in general
		fixed4 frag (v2f i) : SV_Target
		{
			fixed4 c = tex2D (_MainTex, i.uv);
			fixed3 albedo = c.rgb; // * i.color;
			half3 light = i.vlight * albedo * i.color.a * c.a; // Ambient lighting and AO 
			for (int j = 0; j < 3; j++)
			{
				half3 lightColor = _TerrainTreeLightColors[j].rgb;
				half nl = i.params[j].r;
				light += albedo * lightColor * nl;
			}
			c.rgb = light;
			c.a = 1.0;	
			return c;
		}
	ENDCG
	}
*/

//	Second pass wich renders the proper treee into the forground and alpha

	Pass {

		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile AFS_SH_AMBIENT AFS_GRADIENT_AMBIENT AFS_COLOR_AMBIENT
		#include "UnityCG.cginc"
		#include "UnityBuiltin3xTreeLibrary.cginc"

		// Include this to be able to use "Unity_GlossyEnvironment"
		//			#include "UnityPBSLighting.cginc"
		//			#include "UnityStandardUtils.cginc"
		//			#include "UnityStandardBRDF.cginc"

		struct v2f {
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float4 color : TEXCOORD1;
			//float2 params[3]: TEXCOORD2;
			float3 params[3]: TEXCOORD2;

			//float3 viewDir : TEXCOORD3;
			//float3 normal : TEXCOORD4;
			half3 vlight : TEXCOORD5;
			//fixed4 wNormalNV : TEXCOORD6;
			//float3 lh : TEXCOORD7;
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

		v2f vert (appdata_full v) {
			v2f o;
			o.pos = UnityObjectToClipPos (v.vertex);
			o.uv = v.texcoord.xy;
			float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
			//o.viewDir = viewDir;
			//o.normal = v.normal;
			for (int j = 0; j < 3; j++)
			{
				float3 lightDir = _TerrainTreeLightDirections[j];
				half nl = dot (v.normal, lightDir);
				o.params[j].r = max (0, nl);
				half3 h = normalize (lightDir + viewDir);
				float nh = max (0, dot (v.normal, h));
				o.params[j].g = nh;
				half nv = max(0, dot(v.normal, viewDir));
				o.params[j].b = nv;

				//o.lh[j] = DotClamped (lightDir, h);

			}
			o.color = v.color;
			#if defined(AFS_SH_AMBIENT)
				o.vlight = AFSShadeSH9(half4(v.normal * float3(-1,-1,1), 1.0)) * 10;
				o.vlight = IsGammaSpace()? pow(o.vlight, 1.0 /2.2) : o.vlight;
				o.vlight = max(half3(0,0,0), o.vlight); // as it might get negativ...
			#elif defined (AFS_GRADIENT_AMBIENT)
				o.vlight = AFSTrilight (normalize(v.normal)); // * 2.0;
				o.vlight = IsGammaSpace()? pow(o.vlight, 1.0 /2.33) : o.vlight;
				o.vlight = max(half3(0,0,0), o.vlight); // as it might get negativ...
			#elif defined (AFS_COLOR_AMBIENT)
				o.vlight = UNITY_LIGHTMODEL_AMBIENT;
			#endif

			//o.wNormalNV.xyz = normalize(v.normal);
			//o.wNormalNV.w = saturate(dot(v.normal, viewDir));

			return o;
		}

		sampler2D _MainTex;

	//	We do not do any view depended calculations here (no translucency, no specular lighting) as it does not fit billboards in general
		fixed4 frag (v2f i) : SV_Target
		{
			fixed4 c = tex2D (_MainTex, i.uv);
			fixed3 albedo = c.rgb; // * i.color;
			half3 light = i.vlight * albedo * i.color.a * c.a; // Ambient lighting and AO 
			for (int j = 0; j < 3; j++)
			{
				half3 lightColor = _TerrainTreeLightColors[j].rgb;
				half nl = i.params[j].r;
				light += albedo * lightColor * nl;
			}
			c.rgb = light;
			c.a = 1.0;	
			return c;
		}
	ENDCG
	}

}
FallBack Off
}
