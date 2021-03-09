// Toony Colors Pro+Mobile 2
// (c) 2014-2017 Jean Moreno

Shader "Toony Colors Pro 2/User/My TCP2 Shader"
{
	Properties
	{
	[TCP2HeaderHelp(BASE, Base Properties)]
		//TOONY COLORS
		_Color ("Color", Color) = (1,1,1,1)
		_HColor ("Highlight Color", Color) = (0.785,0.785,0.785,1.0)
		_SColor ("Shadow Color", Color) = (0.195,0.195,0.195,1.0)
		
		//DIFFUSE
		_MainTex ("Main Texture", 2D) = "white" {}
	[TCP2Separator]
		
		//TOONY COLORS RAMP
		[TCP2Header(RAMP SETTINGS)]
		
		_RampThreshold ("Ramp Threshold", Range(0,1)) = 0.5
		_RampSmooth ("Ramp Smoothing", Range(0.001,1)) = 0.1
	[TCP2Separator]
	
	[Header(Masks)]
		[NoScaleOffset]
		_Mask1 ("Mask 1 (Specular,Reflection)", 2D) = "black" {}
	[TCP2Separator]
	
	[TCP2HeaderHelp(SPECULAR, Specular)]
		//SPECULAR
		_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_Shininess ("Shininess", Range(0.0,2)) = 0.1
	[TCP2Separator]
	
	[TCP2HeaderHelp(REFLECTION, Reflection)]
		//REFLECTION
		[NoScaleOffset] _Cube ("Reflection Cubemap", Cube) = "_Skybox" {}
		_ReflSmoothness ("Reflection Smoothness", Range(0.0,1.0)) = 1
	[TCP2Separator]
	
	[TCP2HeaderHelp(RIM, Rim)]
		//RIM LIGHT
		_RimColor ("Rim Color", Color) = (0.8,0.8,0.8,0.6)
		_RimMin ("Rim Min", Range(0,1)) = 0.5
		_RimMax ("Rim Max", Range(0,1)) = 1.0
	[TCP2Separator]
	
	[TCP2HeaderHelp(DISSOLVE)]
		[NoScaleOffset]
		_DissolveMap ("Dissolve Map", 2D) = "white" {}
		_DissolveValue ("Dissolve Value", Range(0,1)) = 0.5
		[TCP2Gradient] _DissolveRamp ("Dissolve Ramp", 2D) = "white" {}
		_DissolveGradientWidth ("Ramp Width", Range(0,1)) = 0.2
	[TCP2Separator]
		
		//Avoid compile error if the properties are ending with a drawer
		[HideInInspector] __dummy__ ("unused", Float) = 0
	}
	
	SubShader
	{
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		
		CGPROGRAM
		
		#pragma surface surf ToonyColorsCustom vertex:vert exclude_path:deferred exclude_path:prepass
		#pragma target 3.0
		
		//================================================================
		// VARIABLES
		
		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _Mask1;
		sampler2D _DissolveMap;
		half _DissolveValue;
		sampler2D _DissolveRamp;
		half _DissolveGradientWidth;
		fixed _ReflSmoothness;
		fixed _Shininess;
		fixed4 _RimColor;
		fixed _RimMin;
		fixed _RimMax;
		float4 _RimDir;
		
		struct Input
		{
			half2 uv_MainTex;
			float3 worldPos;
			float3 worldRefl;
			float3 worldNormal;
			fixed rim;
		};
		
		//================================================================
		// CUSTOM LIGHTING
		
		//Lighting-related variables
		fixed4 _HColor;
		fixed4 _SColor;
		half _RampThreshold;
		half _RampSmooth;
		
		//Custom SurfaceOutput
		struct SurfaceOutputCustom
		{
			half atten;
			fixed3 Albedo;
			fixed3 Normal;
			fixed3 Emission;
			half Specular;
			fixed Gloss;
			fixed Alpha;
		};
		
		inline half4 LightingToonyColorsCustom (inout SurfaceOutputCustom s, half3 viewDir, UnityGI gi)
		{
			half3 lightDir = gi.light.dir;
		#if defined(UNITY_PASS_FORWARDBASE)
			half3 lightColor = _LightColor0.rgb;
			half atten = s.atten;
		#else
			half3 lightColor = gi.light.color.rgb;
			half atten = 1;
		#endif
			
			s.Normal = normalize(s.Normal);
			fixed ndl = max(0, dot(s.Normal, lightDir));
			#define NDL ndl
	
			#define		RAMP_THRESHOLD	_RampThreshold
			#define		RAMP_SMOOTH		_RampSmooth
			
			fixed3 ramp = smoothstep(RAMP_THRESHOLD - RAMP_SMOOTH*0.5, RAMP_THRESHOLD + RAMP_SMOOTH*0.5, NDL);
		#if !(POINT) && !(SPOT)
			ramp *= atten;
		#endif
		#if !defined(UNITY_PASS_FORWARDBASE)
			_SColor = fixed4(0,0,0,1);
		#endif
			_SColor = lerp(_HColor, _SColor, _SColor.a);	//Shadows intensity through alpha
			ramp = lerp(_SColor.rgb, _HColor.rgb, ramp);
			//Specular
			half3 h = normalize(lightDir + viewDir);
			float ndh = max(0, dot (s.Normal, h));
			float spec = pow(ndh, s.Specular*128.0) * s.Gloss * 2.0;
			spec *= atten;
			fixed4 c;
			c.rgb = s.Albedo * lightColor.rgb * ramp;
		#if (POINT || SPOT)
			c.rgb *= atten;
		#endif
			c.rgb += lightColor.rgb * _SpecColor.rgb * spec;
			c.a = s.Alpha * _SpecColor.a * spec;
			
		#ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
			c.rgb += s.Albedo * gi.indirect.diffuse;
		#endif
			
			return c;
		}
		
		void LightingToonyColorsCustom_GI(inout SurfaceOutputCustom s, UnityGIInput data, inout UnityGI gi)
		{
			gi = UnityGlobalIllumination(data, 1.0, s.Normal);
			
			gi.light.color = _LightColor0.rgb;	//remove attenuation
			s.atten = data.atten;	//transfer attenuation to lighting function
		}
		
		//================================================================
		// VERTEX FUNCTION
		
		struct appdata_tcp2
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 texcoord : TEXCOORD0;
			float4 texcoord1 : TEXCOORD1;
			float4 texcoord2 : TEXCOORD2;
		};
		
		void vert(inout appdata_tcp2 v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
			half rim = 1.0f - saturate( dot(viewDir, v.normal) );
			o.rim = smoothstep(_RimMin, _RimMax, rim) * _RimColor.a;
		}

		//================================================================
		// SURFACE FUNCTION

		void surf(Input IN, inout SurfaceOutputCustom o)
		{
			fixed4 mainTex = tex2D(_MainTex, IN.uv_MainTex);
			
			//Masks
			fixed4 mask1 = tex2D(_Mask1, IN.uv_MainTex);
			
			o.Albedo = mainTex.rgb * _Color.rgb;
			o.Alpha = mainTex.a * _Color.a;
			
			//Dissolve
			fixed4 dslv = tex2D(_DissolveMap, IN.uv_MainTex.xy);
			#define DSLV dslv.b
			clip(dslv.b - _DissolveValue);
			float dissValue = lerp(-_DissolveGradientWidth, 1, _DissolveValue);
			float dissolveUV = smoothstep(DSLV - _DissolveGradientWidth, DSLV + _DissolveGradientWidth, dissValue);
			half4 dissolveColor = tex2D(_DissolveRamp, dissolveUV.xx);
			dissolveColor *= lerp(0, 20.0, dissolveUV);
			o.Emission += dissolveColor.rgb;
			
			o.Alpha *= DSLV - dissValue;
			
			//Specular
			o.Gloss = mask1.g;
			o.Specular = _Shininess;
			
			//Reflection
			half3 eyeVec = IN.worldPos.xyz - _WorldSpaceCameraPos.xyz;
			half3 worldNormal = reflect(eyeVec, IN.worldNormal);
			float oneMinusRoughness = _ReflSmoothness;
			fixed3 reflColor = fixed3(0,0,0);
		#if UNITY_SPECCUBE_BOX_PROJECTION
			half3 worldNormal0 = BoxProjectedCubemapDirection (worldNormal, IN.worldPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
		#else
			half3 worldNormal0 = worldNormal;
		#endif
			half3 env0 = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, worldNormal0, 1-oneMinusRoughness);

		#if UNITY_SPECCUBE_BLENDING
			const float kBlendFactor = 0.99999;
			float blendLerp = unity_SpecCube0_BoxMin.w;
			UNITY_BRANCH
			if (blendLerp < kBlendFactor)
			{
			#if UNITY_SPECCUBE_BOX_PROJECTION
				half3 worldNormal1 = BoxProjectedCubemapDirection (worldNormal, IN.worldPos, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
			#else
				half3 worldNormal1 = worldNormal;
			#endif
				
				half3 env1 = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0), unity_SpecCube1_HDR, worldNormal1, 1-oneMinusRoughness);
				reflColor = lerp(env1, env0, blendLerp);
			}
			else
			{
				reflColor = env0;
			}
		#else
			reflColor = env0;
		#endif
			reflColor *= 0.5;
			reflColor *= mask1.r;
			o.Emission += reflColor.rgb;
			
			//Rim
			o.Albedo = lerp(o.Albedo.rgb, _RimColor.rgb, IN.rim);
		}
		
		ENDCG
	}
	
	Fallback "Diffuse"
	CustomEditor "TCP2_MaterialInspector_SG"
}
