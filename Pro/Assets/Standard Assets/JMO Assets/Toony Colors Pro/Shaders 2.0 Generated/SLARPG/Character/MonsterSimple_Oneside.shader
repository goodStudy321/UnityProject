// Toony Colors Pro+Mobile 2
// (c) 2014-2017 Jean Moreno

Shader "SLARPG/Character/MonsterSimple_Oneside"
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
		_Mask1 ("Mask 1 (Emission,Shininess,Reflection)", 2D) = "black" {}
	[TCP2Separator]
	
	[TCP2HeaderHelp(EMISSION, Emission)]
		[HDR] _EmissionColor ("Emission Color", Color) = (1,1,1,1.0)
	[TCP2Separator]
	
	[TCP2HeaderHelp(SPECULAR, Specular)]
		//SPECULAR
		_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_Shininess ("Shininess", Range(0.0,2)) = 0.1
	[TCP2Separator]
	
	[TCP2HeaderHelp(REFLECTION, Reflection)]
		//REFLECTION
		[NoScaleOffset] _Cube ("Reflection Cubemap", Cube) = "_Skybox" {}
		_ReflectColor ("Reflection Color (RGB) Strength (Alpha)", Color) = (1,1,1,0.5)
		_ReflectRoughness ("Reflection Roughness", Range(0,9)) = 0
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
	
	[TCP2HeaderHelp(TRANSPARENCY)]
		//Alpha Testing
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		
		//Avoid compile error if the properties are ending with a drawer
		[HideInInspector] __dummy__ ("unused", Float) = 0
	}
	
	SubShader
	{
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		
		CGPROGRAM
		
		#pragma surface surf ToonyColorsCustom addshadow fullforwardshadows noforwardadd exclude_path:deferred exclude_path:prepass
		#pragma target 2.5
		
		//================================================================
		// VARIABLES
		
		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _Mask1;
		sampler2D _DissolveMap;
		half _DissolveValue;
		sampler2D _DissolveRamp;
		half _DissolveGradientWidth;
		samplerCUBE _Cube;
		fixed4 _ReflectColor;
		fixed _ReflectRoughness;
		half4 _EmissionColor;
		fixed _Shininess;
		fixed4 _RimColor;
		fixed _RimMin;
		fixed _RimMax;
		float4 _RimDir;
		fixed _Cutoff;
		
		struct Input
		{
			half2 uv_MainTex;
			float3 worldRefl;
			float3 viewDir;
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
			#define DSLV dslv.r
			float dissValue = lerp(-_DissolveGradientWidth, 1, _DissolveValue);
			float dissolveUV = smoothstep(DSLV - _DissolveGradientWidth, DSLV + _DissolveGradientWidth, dissValue);
			half4 dissolveColor = tex2D(_DissolveRamp, dissolveUV.xx);
			dissolveColor *= lerp(0, 10.0, dissolveUV);
			o.Emission += dissolveColor.rgb;
			
			o.Alpha *= DSLV + _Cutoff - dissValue;
			
			//Cutout (Alpha Testing)
			clip (o.Alpha - _Cutoff);
			
			//Specular
			_Shininess *= mask1.g;
			o.Gloss = mainTex.g;
			o.Specular = _Shininess;
			
			//Reflection
			half3 worldRefl = IN.worldRefl;
			fixed4 reflColor = texCUBElod(_Cube, half4(worldRefl.xyz, _ReflectRoughness));
			reflColor *= mask1.r;
			reflColor.rgb *= _ReflectColor.rgb * _ReflectColor.a;
			o.Emission += reflColor.rgb;
			
			//Rim
			float3 viewDir = normalize(IN.viewDir);
			half rim = 1.0f - saturate( dot(viewDir, o.Normal) );
			rim = smoothstep(_RimMin, _RimMax, rim);
			o.Emission += (_RimColor.rgb * rim) * _RimColor.a;
			
			//Emission
			o.Emission += mainTex.rgb * (mask1.b * _EmissionColor.a) * _EmissionColor.rgb;
		}
		
		ENDCG
	}
	
	Fallback "Diffuse"
	CustomEditor "TCP2_MaterialInspector_SG"
}
