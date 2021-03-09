// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Pre-Integrated Skin Shader for Unity3D
//  
// Author:
//       Maciej Kacper Jagiełło <maciej@jagiello.it>
// 
// Copyright (c) 2013 Maciej Kacper Jagiełło
// 
// This file is provided under standard Unity Asset Store EULA
// http://unity3d.com/company/legal/as_terms

#ifndef DEFINED_PREINTEGRATEDSKINSHADER_COMMON
#define DEFINED_PREINTEGRATEDSKINSHADER_COMMON

#include "HLSLSupport.cginc"
#include "UnityShaderVariables.cginc"

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

#define PSS_PI 3.14159265359

#ifndef UNITY_VERSION
	#ifdef UNITY_SHADER_VARIABLES_INCLUDED
		// Unity 4.x
		//#define UNITY_VERSION 400
		#error unsupported unity version
	#else
		// Unity 3.x or earlier...
		// < 3.5 was never supported
		//#define UNITY_VERSION 300
		#error unsupported unity version
	#endif
#elif UNITY_VERSION < 540
	#define MACRO_HACK_CONCAT_BECAUSE_UNITYAPIUPGRADER_IS_OBNOXIOUS(a, b) a ## b
	#define unity_WorldToLight MACRO_HACK_CONCAT_BECAUSE_UNITYAPIUPGRADER_IS_OBNOXIOUS(_Light, Matrix0)
	#define unity_ObjectToWorld MACRO_HACK_CONCAT_BECAUSE_UNITYAPIUPGRADER_IS_OBNOXIOUS(_Object2, World)

	inline float4 UnityObjectToClipPos(float3 pos) {
		return UnityObjectToClipPos(float4(pos, 1.0));
	}
#endif

#define PSS_QUALITY_REFERENCE 3
#define PSS_QUALITY_HIGH 2
#define PSS_QUALITY_MEDIUM 1
#define PSS_QUALITY_LOW 0
#define PSS_QUALITY_UGLY -1

struct SkinSurfaceOutput {
	fixed3 Albedo;
	fixed Scattering;
	fixed3 Normal;
	
	// Will likely reintroduce in the future: multiple specular layers.
	// for below three vectors x is epidermis, y is sebum, z is wetness and a is masked (which replaces epidermis and sebum)
	//half SpecularRoughness[3];
	//half3 SpecularIntensity[3];

	half SpecularRoughness;
	half3 SpecularIntensity;

	fixed SpecularEnvMapIntensity;
		
	fixed3 Emission;
	fixed Alpha;
	fixed3 TranslucencyColor;
	fixed TranslucencyDepth;
	fixed AmbientOcclusion;
	fixed AmbientOcclusionSuppression;
	fixed AmbientOcclusionScattering;
	
	// In future may introduce world scale dependent scattering.
	//float WorldScale;
};

#ifndef SHADOW_COORDS
	#define SHADOW_COORDS(x)
#endif

#define PSS_COORDS(idx1,idx2,idx3,idx4,idx5,idx6) \
	float4 pos			: SV_POSITION; \
	half4 tangentToWorldAndWPos[3] : TEXCOORD##idx1; \
	float4 uv			: TEXCOORD##idx4; \
	fixed4 ambient		: TEXCOORD##idx5; \
	SHADOW_COORDS(idx6)
	// see notes on fog coords in vertex function
	//UNITY_FOG_COORDS(idx7)
	
#if defined(PSS_FORCE_GAMMA_CORRECTION)
	// NB: could use built-in GammaToLinearSpace and LinearToGammaSpace instead of redefining it here, but I want it to
	// work seamlessly for different dimensions vectors and these methods are availably only starting from Unity 5.
	#define PSS_INPUTGAMMACORRECTION(sRGB) (sRGB * (sRGB * (sRGB * 0.305306011 + 0.682171111) + 0.012522878))
	#define PSS_OUTPUTGAMMACORRECTION(linRGB) (max(1.055 * pow(linRGB, 0.416666667) - 0.055, 0))
#else
	#define PSS_INPUTGAMMACORRECTION(x) x
	#define PSS_OUTPUTGAMMACORRECTION(x) x
#endif

int CALC_MIP_COUNT_IMPL(float4 texTexelSize) {
	#if SHADER_TARGET >= 30
		// NB: decided not to use GetDimensions in SM>=4 because it's a pain AND it's inefficent because of an
		// additional memory access.
		// If you're looking for things to optimize, you may want to use only one dimension like in SM or
		// precalculate it to get rid of log2 entirely.
		return floor(log2(max(texTexelSize.z, texTexelSize.w)));
	#else
		// SM2, cheat..
		// Only consider width.
		// Don't floor, we're gonna feed it into tex2Dbias instead of tex2Dlod anyway.
		return log2(texTexelSize.z);
	#endif
}
#define CALC_MIP_COUNT(texname) CALC_MIP_COUNT_IMPL(texname##_TexelSize)

fixed4 PSS_SAMPLE_BLURRED_IMPL(sampler2D tex, float2 uv, float blur, int mipLevels);
#define PSS_SAMPLE_BLURRED(texname, uv, blur) PSS_SAMPLE_BLURRED_IMPL(texname, uv, blur, CALC_MIP_COUNT(texname))

// Reverses unity's penumbra function and converts it to a narrower one to the scattering effect.
float newPenumbra(float penumbraLocation) {
	// For now blindly assuming box filtering. Unity's screen space shadows are a total mess anyway.
	// Should investigate how to reverse penumbra properly for Unity5's PCF5 filter.
	return saturate(penumbraLocation*3.0-2.0);
}

#define Pow2(x) (x*x)
#define Pow3(x) (x*x*x)
#define Pow4(x) ((x*x)*(x*x))
#define Root4(x) sqrt(sqrt(x))

#if defined(UNITY_COMPILER_HLSL)
	#define PSS_LOOP [loop]
	#define PSS_UNROLL(max_iterations) [unroll(max_iterations)]
#else
	#define PSS_LOOP
	#define PSS_UNROLL(max_iterations)
#endif

// GGX specular implementation by John Hable (public domain)

#if(defined(SHADER_API_GLCORE) || defined(UNITY_COMPILER_HLSL)) && SHADER_TARGET >= 30
	#define RCP(x) rcp(x)
#else
	#define RCP(x) (1.0 / (x))
#endif

inline float SchlickFresnel(float u) {
    float m = saturate(1-u);
    float m2 = m*m;
    return m2*m2*m; // pow(m,5)
}

float G1V(float dotNV, float k) {
	return 1.0/(dotNV*(1.0-k)+k);
}

float GGXSpecularRef(float3 N, float3 V, float3 L, float roughness, float F0) {
	float alpha = roughness*roughness;

	float3 H = normalize(V+L);

	float dotNL = saturate(dot(N,L));
	float dotNV = saturate(dot(N,V));
	float dotNH = saturate(dot(N,H));
	float dotLH = saturate(dot(L,H));

	float F, D, vis;

	// D
	float alphaSqr = alpha*alpha;
	float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0;
	D = alphaSqr/(PSS_PI * denom * denom);

	// F
	float dotLH5 = pow(1.0-dotLH,5);
	F = F0 + (1.0-F0)*(dotLH5);

	// V
	float k = alpha/2.0;
	vis = G1V(dotNL,k)*G1V(dotNV,k);

	return max(0.0, dotNL * D * F * vis);
}

float2 LightingFuncGGX_FV(float dotLH, float roughness)
{
	float alpha = roughness*roughness;

	// F
	float F_a, F_b;
	float dotLH5 = pow(1.0f-dotLH,5);
	F_a = 1.0f;
	F_b = dotLH5;

	// V
	float vis;
	float k = alpha/2.0f;
	float k2 = k*k;
	float invK2 = 1.0f-k2;
	vis = RCP(dotLH*dotLH*invK2 + k2);

	return float2(F_a*vis,F_b*vis);
}

float LightingFuncGGX_D(float dotNH, float roughness)
{
	float alpha = roughness*roughness;
	float alphaSqr = alpha*alpha;
	float pi = 3.14159f;
	float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0f;

	float D = alphaSqr/(pi * denom * denom);
	return D;
}

//float LightingFuncGGX_OPT1(float3 N, float3 V, float3 L, float roughness, float F0)
//{
//	float alpha = roughness*roughness;
//
//	float3 H = normalize(V+L);
//
//	float dotNL = saturate(dot(N,L));
//	float dotLH = saturate(dot(L,H));
//	float dotNH = saturate(dot(N,H));
//
//	float F, D, vis;
//
//	// D
//	float alphaSqr = alpha*alpha;
//	float pi = 3.14159f;
//	float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0f;
//	D = alphaSqr/(pi * denom * denom);
//
//	// F
//	float dotLH5 = pow(1.0f-dotLH,5);
//	F = F0 + (1.0-F0)*(dotLH5);
//
//	// V
//	float k = alpha/2.0f;
//	vis = G1V(dotLH,k)*G1V(dotLH,k);
//
//	float specular = dotNL * D * F * vis;
//	return specular;
//}
//
//
//float LightingFuncGGX_OPT2(float3 N, float3 V, float3 L, float roughness, float F0)
//{
//	float alpha = roughness*roughness;
//
//	float3 H = normalize(V+L);
//
//	float dotNL = saturate(dot(N,L));
//
//	float dotLH = saturate(dot(L,H));
//	float dotNH = saturate(dot(N,H));
//
//	float F, D, vis;
//
//	// D
//	float alphaSqr = alpha*alpha;
//	float pi = 3.14159f;
//	float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0f;
//	D = alphaSqr/(pi * denom * denom);
//
//	// F
//	float dotLH5 = pow(1.0f-dotLH,5);
//	F = F0 + (1.0-F0)*(dotLH5);
//
//	// V
//	float k = alpha/2.0f;
//	float k2 = k*k;
//	float invK2 = 1.0f-k2;
//	vis = RCP(dotLH*dotLH*invK2 + k2);
//
//	float specular = dotNL * D * F * vis;
//	return specular;
//}
//
//float LightingFuncGGX_OPT3(float3 N, float3 V, float3 L, float roughness, float F0)
//{
//	float3 H = normalize(V+L);
//
//	float dotNL = saturate(dot(N,L));
//	float dotLH = saturate(dot(L,H));
//	float dotNH = saturate(dot(N,H));
//
//	float D = LightingFuncGGX_D(dotNH,roughness);
//	float2 FV_helper = LightingFuncGGX_FV(dotLH,roughness);
//	float FV = F0*FV_helper.x + (1.0f-F0)*FV_helper.y;
//	float specular = dotNL * D * FV;
//
//	return specular;
//}
//
//float LightingFuncGGX_OPT4(float3 N, float3 V, float3 L, float roughness, float F0)
//{
//	float3 H = normalize(V+L);
//
//	float dotNL = saturate(dot(N,L));
//	float dotLH = saturate(dot(L,H));
//	float dotNH = saturate(dot(N,H));
//
//	float D = LightingFuncGGX_D(dotNH,roughness);
//	float2 FV_helper = LightingFuncGGX_FV(dotLH,roughness);
//
//	float FV = F0*FV_helper.x + (1.0f-F0)*FV_helper.y;
//	float specular = dotNL * D * FV;
//
//	return specular;
//}
//
//// This version includes Stephen Hill's optimization
//float LightingFuncGGX_OPT5(float3 N, float3 V, float3 L, float roughness, float F0)
//{
//	float3 H = normalize(V+L);
//
//	float dotNL = saturate(dot(N,L));
//	float dotLH = saturate(dot(L,H));
//	float dotNH = saturate(dot(N,H));
//
//	float D = LightingFuncGGX_D(dotNH,roughness);
//	float2 FV_helper = LightingFuncGGX_FV(dotLH,roughness);
//
//	float FV = F0*FV_helper.x + FV_helper.y;
//	float specular = dotNL * D * FV;
//
//	return specular;
//}



#endif // DEFINED_PREINTEGRATEDSKINSHADER_COMMON