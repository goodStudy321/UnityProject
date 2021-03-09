// Pre-Integrated Skin Shader for Unity3D
//  
// Author:
//       Maciej Kacper Jagiello <maciej@jagiello.it>
// 
// Copyright (c) 2013 Maciej Kacper Jagiello
// 
// This file is provided under standard Unity Asset Store EULA
// http://unity3d.com/company/legal/as_terms

#ifndef DEFINED_PREINTEGRATEDSKINSHADER_BASE
#define DEFINED_PREINTEGRATEDSKINSHADER_BASE

#include "PreIntegratedSkinShaderCommon.cginc"

//#define UNITY_TANGENT_ORTHONORMALIZE 1

// Lookup textures are independent of the profile and never change so they go into a constant buffer, if supported.
#if SHADER_TARGET >= 30
sampler2D _LookupDirect;
sampler2D _LookupSH;
#else
sampler2D _LookupDirectSM2;
sampler2D _LookupSH;
//sampler2D _LookupSHSM2;
sampler2D _LookupSpecAO;
#endif

// Profile parameters get assigned with material, but are very likely to be reused.
#if PSS_QUALITY <= PSS_QUALITY_LOW
	// 2 levels of blur
	CBUFFER_START(PSSProfileParamsLow)
	half4 _PSSProfileLow_weighths1_var1;
	half4 _PSSProfileLow_weighths2_var2;
	half2 _PSSProfileLow_sqrtvar12;
	half3 _PSSProfileLow_transl; // precomputed translucency factor for rgb
	CBUFFER_END
#elif PSS_QUALITY == PSS_QUALITY_MEDIUM
	// 3 levels of blur
	
	CBUFFER_START(PSSProfileParamsMedium)
	half4 _PSSProfileMedium_weighths1_var1;
	half4 _PSSProfileMedium_weighths2_var2;
	half4 _PSSProfileMedium_weighths3_var3;
	half3 _PSSProfileMedium_transl123;
	half3 _PSSProfileMedium_sqrtvar123;
	CBUFFER_END
#else // PSS_QUALITY >= PSS_QUALITY_HIGH
	// full 6 levels of blur
	CBUFFER_START(PSSProfileParamsHigh)
	half4 _PSSProfileHigh_weighths1_var1; // xyz: rgb weights of profile's first component; w: its respective variance (blur)
	half4 _PSSProfileHigh_weighths2_var2; // idem, but for 2nd component of the profile
	half4 _PSSProfileHigh_weighths3_var3; // ...
	half4 _PSSProfileHigh_weighths4_var4;
	half4 _PSSProfileHigh_weighths5_var5;
	half4 _PSSProfileHigh_weighths6_var6;
	half4 _PSSProfileHigh_sqrtvar1234; // precomputed sqrt(variance) for components 1,2,3,4
	half4 _PSSProfileHigh_transl123_sqrtvar5; // xyz: precomputed translucency factor for profile components 1,2,3; zw: precomputed sqrt(variance) for component 5
	half4 _PSSProfileHigh_transl456_sqrtvar6; // xyz: precomputed translucency factor for profile components 4,5,6; zw: precomputed sqrt(variance) for component 6
	CBUFFER_END
#endif

float4 _LightTexture0_TexelSize; // FIXME test

inline fixed4 PSS_SAMPLE_BLURRED_IMPL(sampler2D tex, float2 uv, float blur, int mipLevels) {
	#ifdef PSS_BLURRED_SAMPLING_ON
		#if SHADER_TARGET >= 30
			// NB: decided not to use GetDimensions in SM>=4 because it's a pain AND it's inefficent because of an
			// additional memory access.
			// If you're looking for things to optimize, you may want to use only one dimension like in SM or
			// precalculate it to get rid of log2 entirely.
//			int mipLevels = floor(log2(max(texTexelSize.z, texTexelSize.w)));
			
			// Use derivatives of texture coordinates to get approximate mipmap lod to use.
			// Can only be used in a fragment shader.
			// TODO use CalculateLevelOfDetail/CalculateLevelOfDetailUnclamped in SM5?
		    float2 dx_vtc = ddx(uv);
		    float2 dy_vtc = ddy(uv);
		    float delta_max_sqr = max(dot(dx_vtc, dx_vtc), dot(dy_vtc, dy_vtc));
		    float mipLod = -0.5 * log2(delta_max_sqr);
		    
		    float selLod = min(blur*(mipLevels), mipLod);
			
			return tex2Dlod(tex, float4(uv.x, uv.y, 0.0, mipLevels-selLod));
		#else
			// SM2, cheat..
			// Only consider width.
			// Don't floor, we're gonna feed it into tex2Dbias instead of tex2Dlod anyway.
//			int mipLevels = log2(texTexelSize.z);
			//int mipLevels = (texTexelSize.z);
			
			// this version is the simplest, but suffers from blur amount changing with distance
			//return tex2Dbias(tex, float4(uv, 0.0, (1.0-blur)*mipLevels));
			return tex2Dbias(tex, float4(uv, 0.0, mipLevels-blur*mipLevels));
		#endif
	#else
		// single tap, no blurs...
		return tex2D(tex, uv);
	#endif
}

// Struct encapsulating Spherical Harmonics envirenment lighting data.
// Elements cerrespond to Unity's unity_SHAr, unity_SHAb etc...
// They contain 9 SH coefficients up to l=2 and are in the form ready
// for polynomial evaluation.
// See SHAddDirectionalLight function and the referenced paper for exact mapping.
struct SHEnvCoeffs {
	half4 SHAr; // Red channel coefficients. xyz: l=1, w: combined l0 and l2
	half4 SHAg; // Blue channel coefficients. xyz: l=1, w: combined l0 and l2
	half4 SHAb; // Green channel coefficients. xyz: l=1, w: combined l0 and l2
	half4 SHBr; // Red channel coefficients. xyz: l=2
	half4 SHBg; // Blue channel coefficients. xyz: l=2
	half4 SHBb; // Green channel coefficients. xyz: l=2
	half4 SHC;  // RGB coefficients. xyz:l=2, w:unused
};

// Samples Unity's light probe data.
SHEnvCoeffs SHSampleLightProbes() {
	SHEnvCoeffs sh;
	sh.SHAr = unity_SHAr;
	sh.SHAg = unity_SHAg;
	sh.SHAb = unity_SHAb;
	sh.SHBr = unity_SHBr;
	sh.SHBg = unity_SHBg;
	sh.SHBb = unity_SHBb;
	sh.SHC = unity_SHC;
	return sh;
}

// Creates an empty spherical harmonics coefficient struct.
SHEnvCoeffs SHEmpty() {
	SHEnvCoeffs sh;
	sh.SHAr = 0;
	sh.SHAg = 0;
	sh.SHAb = 0;
	sh.SHBr = 0;
	sh.SHBg = 0;
	sh.SHBb = 0;
	sh.SHC = 0;
	return sh;
}

// Adds a directional light to the SH evironment data.
// This function is based on code from old Unity documentation (http://docs.unity3d.com/400/Documentation/ScriptReference/LightProbes-coefficients.html)
// and the snippet in appendix A10 from Peter-Pike Sloan's paper, which Unity folks evidently used (Stupid Spherical Harmonics Tricks, http://www.ppsloan.org/publications/StupidSH36.pdf).
// Known issue: this function produces ringing(?) artifacts, just like Unity4.
// Unity 5 does it differently, but me no has da codez :/
// <rant>Also, albeit without ringing Unity5 (5.0 and 5.1) does something bad still and the whole SH lighting wraps around unnaturally and everything is way too ambient-ish. </rant>
void SHAddDirectionalLight(inout SHEnvCoeffs sh, half3 direction, half3 colorAndIntensity) {
	half dirFactors[9];
	dirFactors[0] = 1.0 / (2.0*sqrt(PSS_PI)); // l=0, m=0
	dirFactors[1] = direction.y * -(sqrt(3.0) / (2.0*sqrt(PSS_PI))); // l=1, m=-1
	dirFactors[2] = direction.z * (sqrt(3.0) / (2.0*sqrt(PSS_PI))); // l=1, m=0
	dirFactors[3] = direction.x * -(sqrt(3.0) / (2.0*sqrt(PSS_PI))); // l=1, m=1
	dirFactors[4] = (direction.x * direction.y) * (sqrt(15.0) / (2.0*sqrt(PSS_PI))); // l=2, m=-2
	dirFactors[5] = (direction.y * direction.z) * -(sqrt(15.0) / (2.0*sqrt(PSS_PI))); // l=2, m=-1
	dirFactors[6] = (direction.z * direction.z - 1.0/3.0) * (3.0 * sqrt(5.0) / (4.0*sqrt(PSS_PI))); // l=2, m=0
	dirFactors[7] = (direction.x * direction.z) * -(sqrt(15.0) / (2.0*sqrt(PSS_PI))); // l=2, m=1
	dirFactors[8] = (direction.x * direction.x - direction.y * direction.y) * (sqrt(15.0) / (4.0*sqrt(PSS_PI))); // l=2, m=2

	half normalization = 16.0*PSS_PI/17.0;
	
	half3 scale = colorAndIntensity.rgb * normalization;
	
	half fC0 = 1.0/(2.0*sqrt(PSS_PI));
	half fC3 = sqrt(5.0) / (16.0 * sqrt(PSS_PI));
	half fC1 = sqrt(3.0) / (3.0 * sqrt(PSS_PI));
	half fC2 = sqrt(15.0) / (8.0 * sqrt(PSS_PI));
	half fC4 = 0.5 * fC2;
	
	// A little hack, an attempt to remove ringing artifacts (or the undesired light on opposite side, anyway).
	// Seems to work, but beware, it's complete vodoo and the shape of lighting is somewhat altered.
	fC0 *= fC0 * PSS_PI;
	fC1 *= fC1 * PSS_PI;
	fC2 *= fC2 * PSS_PI;
	
	// whene these come to play ringing is not noticable and changing them alters shape too much
	//fC3 *= fC3 * PSS_PI;
	//fC4 *= fC4 * PSS_PI;
	
	sh.SHAr.x += -fC1*dirFactors[3] * scale.r; // l=1
	sh.SHAg.x += -fC1*dirFactors[3] * scale.g; // l=1
	sh.SHAb.x += -fC1*dirFactors[3] * scale.b; // l=1
	sh.SHAr.y += -fC1*dirFactors[1] * scale.r; // l=1
	sh.SHAg.y += -fC1*dirFactors[1] * scale.g; // l=1
	sh.SHAb.y += -fC1*dirFactors[1] * scale.b; // l=1
	sh.SHAr.z += fC1*dirFactors[2] * scale.r; // l=1
	sh.SHAg.z += fC1*dirFactors[2] * scale.g; // l=1
	sh.SHAb.z += fC1*dirFactors[2] * scale.b; // l=1
	sh.SHAr.w += fC0*dirFactors[0] * scale.r /*l=0*/ - fC3*dirFactors[6] * scale.r/*l=2*/;
	sh.SHAg.w += fC0*dirFactors[0] * scale.g /*l=0*/ - fC3*dirFactors[6] * scale.g/*l=2*/;
	sh.SHAb.w += fC0*dirFactors[0] * scale.b /*l=0*/ - fC3*dirFactors[6] * scale.b/*l=2*/;
	sh.SHBr.x += fC2*dirFactors[4] * scale.r; //l=2
	sh.SHBg.x += fC2*dirFactors[4] * scale.r; //l=2
	sh.SHBb.x += fC2*dirFactors[4] * scale.b; //l=2
	sh.SHBr.y += -fC2*dirFactors[5] * scale.r; //l=2
	sh.SHBg.y += -fC2*dirFactors[5] * scale.r; //l=2
	sh.SHBb.y += -fC2*dirFactors[5] * scale.b; //l=2
	sh.SHBr.z += 3.0 * fC3*dirFactors[6] * scale.r; //l=2
	sh.SHBg.z += 3.0 * fC3*dirFactors[6] * scale.r; //l=2
	sh.SHBb.z += 3.0 * fC3*dirFactors[6] * scale.b; //l=2
	sh.SHBr.w += -fC2*dirFactors[7] * scale.r; //l=2
	sh.SHBg.w += -fC2*dirFactors[7] * scale.r; //l=2
	sh.SHBb.w += -fC2*dirFactors[7] * scale.b; //l=2
	sh.SHC.x += fC4*dirFactors[8] * scale.r; //l=2
	sh.SHC.y += fC4*dirFactors[8] * scale.g; //l=2
	sh.SHC.z += fC4*dirFactors[8] * scale.b; //l=2
}

// Again, taken from Unity's old documentation.
void SHAddPointLight(inout SHEnvCoeffs sh, float3 probePos, float3 lightPos, float lightRange, half3 colorAndIntensity) {
	float3 probeToLight = lightPos - probePos;
	float attenuation = 1.0 / (1.0 + (25.0 * dot(probeToLight,probeToLight) / (lightRange*lightRange)));
	SHAddDirectionalLight(/*inout*/ sh, normalize(probeToLight), colorAndIntensity*attenuation);
}

// Evaluates irradiance from Spherical Harmonics environment data in given direction (normally world space).
// This is the same code from Unity's ShadeSH9 function (which is itself taken form Sloan's paper), but
// applied to custom SH data.
half3 SHEval(SHEnvCoeffs sh, half3 worldNormal) {
	half4 n = half4(worldNormal, 1.0);
	half3 x1, x2, x3;

	// Linear + constant polynomial terms
	x1.r = dot(sh.SHAr,n);
	x1.g = dot(sh.SHAg,n);
	x1.b = dot(sh.SHAb,n);
	
	// 4 of the quadratic polynomials
	half4 vB = n.xyzz * n.yzzx;
	x2.r = dot(sh.SHBr,vB);
	x2.g = dot(sh.SHBg,vB);
	x2.b = dot(sh.SHBb,vB);
	
	// Final quadratic polynomial
	half vC = n.x*n.x - n.y*n.y;
	x3 = sh.SHC.rgb * vC;
	
	return x1 + x2 + x3;
}

// Applies Zonal Harmonics coefficients of a radially symmetric function to SH evironment data.
// X, y and z components of coeffs are l=0, l=1 and l=2 band coefficients respectively.
// To understand see for example <Crafting a Next-Gen Material Pipeline for The Order: 1886>
// siggraph presentation notes, or <Photo-Realistic Real-time Face Rendering, Daniel Chappuis>.
// This function just multiplies the 9 SH coefficients, but taking into account that the SH data
// isn't in direct form, but ready for polynomial evaluation.
void SHApplyZHCoeffs(inout SHEnvCoeffs sh, half3 coeffs) {
	// SHA[r/g/b].w fed to the shaders is combines l=0 and l=2 (see SHAddDirectionalLight),
	// so we need to inverse it, apply the coefficient and recombine.
	sh.SHAr.w = (sh.SHAr.w+sh.SHBr.z/3.0)*coeffs.x - sh.SHBr.z/3.0*coeffs.z;
	sh.SHAg.w = (sh.SHAg.w+sh.SHBg.z/3.0)*coeffs.x - sh.SHBg.z/3.0*coeffs.z;
	sh.SHAb.w = (sh.SHAb.w+sh.SHBb.z/3.0)*coeffs.x - sh.SHBb.z/3.0*coeffs.z;
	// The rest is simple, just multiply the right fields.
	sh.SHAr.xyz *= coeffs.y;
	sh.SHAg.xyz *= coeffs.y;
	sh.SHAb.xyz *= coeffs.y;
	sh.SHBr.xyzw *= coeffs.z;
	sh.SHBg.xyzw *= coeffs.z;
	sh.SHBb.xyzw *= coeffs.z;
	sh.SHC.xyz *= coeffs.z;
}


// Forward declare the surface function that need to be defined in final shader.
// This way you'll get a hint from compiler if it's missing or parameters don't match, including when parameters chenge
// due to feature enablement.
void pss_surf(PSS_V2F i, inout SkinSurfaceOutput o);

void pss_vert_post(PSS_VIN i, inout PSS_V2F o);

PSS_V2F pss_vert(PSS_VIN v) {
	PSS_V2F o;
	
	UNITY_INITIALIZE_OUTPUT(PSS_V2F,o);

	o.pos = UnityObjectToClipPos(v.vertex.xyz);
		
	float2 uv = v.texcoord;
	// For standard texture setup UV tiling and offset from _MainTex will be used.
	// This can be disabled for exotic customizations or for performance reasons.
	#ifdef PSS_USEMAINTEXUVTRANSFORM
	uv = TRANSFORM_TEX(uv, _MainTex).xy;
	#endif
	o.uv.xy = uv;
	
	float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	
	float3 normalWorld = UnityObjectToWorldNormal(v.normal);
	float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	float3 binormal = cross(normalWorld, tangentWorld.xyz) * tangentWorld.w;
	float3x3 tangentToWorld = float3x3(tangentWorld.xyz, binormal, normalWorld);
	o.tangentToWorldAndWPos[0].xyz = tangentToWorld[0];
	o.tangentToWorldAndWPos[1].xyz = tangentToWorld[1];
	o.tangentToWorldAndWPos[2].xyz = tangentToWorld[2];
	
	o.tangentToWorldAndWPos[0].w = worldPos.x;
	o.tangentToWorldAndWPos[1].w = worldPos.y;
	o.tangentToWorldAndWPos[2].w = worldPos.z;

	TRANSFER_SHADOW(o);
	// Standard would be UNITY_TRANSFER_FOG(o, o.pos); and defining UNITY_FOG_COORDS in PSS_VIN, but
	// it uses up one precious texture interpolator for just one float!
	// And no, it doesn't get packed by the compiler.
	// So here we go, yet another low lever unity macro swallowed into the shader.
	#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
		#if (SHADER_TARGET < 30) || defined(SHADER_API_MOBILE)
			// mobile or SM2.0: calculate fog factor per-vertex
			UNITY_CALC_FOG_FACTOR(o.pos.z);
			o.uv.z = unityFogFactor;
		#else
			// SM3.0 and PC/console: calculate fog distance per-vertex, and fog factor per-pixel
			o.uv.z = o.pos.z;
		#endif
	#else
		o.uv.z = 0.0;
	#endif

	// unused for now
	o.uv.w = 0.0;

	

	o.ambient.rgb = 0;
 	#if defined(UNITY_PASS_FORWARDBASE)  && defined(PSS_ENABLE_DIFFUSE)
	 	#if PSS_PERPIXELLIGHTPROBES_ON
			// For now, if PSS_PERPIXELLIGHTPROBES_ON is enabled, full SH and collapsed vertex lights are computed per pixel.
			// Unity (as of writing, 5.0 & 5.1) does split the workload between vertex shader and fragment shader.
			// It uses Shade4PointLights for vertex lights and computes SH l=2 in VS and l=0..1 in FS.
			// Since doing so would prevent from applying scattering it's all or nothing for now.
			// For lookup texture the solution would be curve fitting, but remains the fact the scattering amount depends on
			// the depth texture. There's vertex fetch, but, well, i'd rather experiment with baking som attributes to
			// vertex color, at least for mobile.
	 	#else
	 		// Be a cheapstake, apply SH lighting per vertex, without SSS.
	 		o.ambient.rgb += ShadeSH9(float4(normalWorld.xyz, 1.0));
	 	#endif
	 	
		#if defined(VERTEXLIGHT_ON)
			#if (SHADER_TARGET < 30 || !defined(PSS_PERPIXELLIGHTPROBES_ON))
				// Idem for collapsed "unimportant" lights.
	 			o.ambient.rgb += Shade4PointLights (
	 				unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
	 				unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
	 				unity_4LightAtten0, worldPos, normalWorld);
	 			// FIXME unity's standard shader (as of 5.5) applies gamma correction to the result of Shade4PointLights
	 			// toghether with lightmaps etc, but should I? Doesn't seem right to me.
	 				
	 			// vertex lights already applied, the fragment shader should not use it
			 	o.ambient.a = 0.0;
	 		#else
		 		// vertex lights already applied in the fragment shader
			 	o.ambient.a = 1.0;
	 		#endif
	 	#else
	 		// VERTEXLIGHT is off, the fragment shader should not use it either
		 	o.ambient.a = 0.0;
	 	#endif
 	#endif
 	
 	pss_vert_post(v, o);
	
	return o;
}

// taken from Unity's standard shader
half3x3 ExtractTangentToWorldPerPixel(half4 tan2world[3]) {
	half3 t = tan2world[0].xyz;
	half3 b = tan2world[1].xyz;
	half3 n = tan2world[2].xyz;

	#if UNITY_TANGENT_ORTHONORMALIZE
		#if (SHADER_TARGET >= 25)
			n = normalize(n);
		#endif

		// ortho-normalize Tangent
		t = normalize (t - n * dot(t, n));

		// recalculate Binormal
		half3 newB = cross(n, t);
		b = newB * sign (dot (newB, b));
	#endif

	return half3x3(t, b, n);
}

half3 PSSTangentToWorldNormal(half3x3 tspace, half3 tangentSpaceNormal) {
	half3 worldSpaceNormal = mul(tangentSpaceNormal, tspace);
	#if (SHADER_TARGET >= 25)
		worldSpaceNormal = normalize(worldSpaceNormal);
	#endif
	return worldSpaceNormal;
}

inline half3 DirectSpecularFunction(half3 N, half3 V, half3 L, half m, half3 F0) {
	float3 H = normalize(V + L);
	
	float NdotV = dot(N, V);
	float NdotL = dot(N, L);
	float LdotH = dot(L, H);
	float NdotH = dot(N, H);
	
	#if SHADER_TARGET >= 30
		#if PSS_QUALITY >= PSS_QUALITY_HIGH
			float alpha = m*m;
			
//			// Normally, for specular you'd cut the negative values of the varius dot products, but it's not necessary
//			// because we feed them into lookups that clamp them anyway.
//			// Also it's important not to clamp the them before diffuse lookup!
//			// #if SHADER_TARGET > 30
//			// 	NdotL = max(0.0, NdotL);
//			// 	NdotE = max(0.0, NdotE);
//			// #else
//			// 	NdotL = saturate(NdotL);
//			// 	NdotE = saturate(NdotE);
//			// #endif			
			
			// 
			NdotL = saturate(NdotL);
			NdotV = saturate(NdotV);
			LdotH = saturate(LdotH);
			NdotH = saturate(NdotH);

			// D
			float alphaSqr = alpha*alpha;
			float denom = NdotH * NdotH *(alphaSqr-1.0) + 1.0;
			float D = alphaSqr/(PSS_PI * denom * denom);

			// F
			float dotLH5 = pow(1.0-LdotH,5);
			float F = F0 + (1.0-F0)*(dotLH5);

			// V
			float k = alpha/2.0;
			float vis = G1V(NdotL,k)*G1V(NdotV,k);

			return max(0.0, NdotL * D * F * vis);
		#else
    		float4 lookupCoord;
    		lookupCoord.x = LdotH;
    		lookupCoord.y = NdotH;
    		lookupCoord.z = 0.0;
    		lookupCoord.w = m * 6.0; // 256x256, which has 8 mip levels minus two discarded
    		
	    	// lookupCoord.x = Root4(lookupCoord.x);
	    	// lookupCoord.y = Pow4(lookupCoord.y);
    		lookupCoord.x = sqrt(lookupCoord.x);
	    	// lookupCoord.y = Pow2(lookupCoord.y);
    		lookupCoord.y = Pow3(lookupCoord.y);
    		
			half2 specLookup = tex2Dlod(_LookupDirect, lookupCoord).yz;

			// transform to linear scale
			specLookup *= 16.0;
			specLookup = specLookup*specLookup;
			
			return max(0.0, NdotL * (specLookup.x*F0 + specLookup.y));
		#endif
	#else
		// Use two lookups for NdotH and LdotH, just like in John Hable's blog post since we can't count
		// on tex2Dlod :(
		//
		// Sample the lookup twice and transform to linear scale. Both D and FVHelper are compressed to same
		// non linear range so we can put both into a vector and take advantage of vector ops (SM2 hardware
		// is most likely a vector architecture).
		half3 specLookup;
		specLookup.x = tex2D(_LookupDirectSM2, float2(NdotH, m)).w;
		specLookup.yz = tex2D(_LookupDirectSM2, float2(LdotH, m)).yz;
		specLookup *= half3(4.0, 16.0, 16.0);
		specLookup = specLookup*specLookup;
		half D = specLookup.x;
		half2 FV_helper = specLookup.yz;
		
		//return max(0.0, NdotL * D * (FV_helper.x*F0 + FV_helper.y));
		return saturate(NdotL * D * (FV_helper.x*F0 + FV_helper.y));
	#endif
}

fixed4 pss_frag(PSS_V2F i) : SV_Target {
	float3 worldPos = float3(i.tangentToWorldAndWPos[0].w, i.tangentToWorldAndWPos[1].w, i.tangentToWorldAndWPos[2].w);
	
	half3 worldSpaceViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
	half3 worldSpaceLightDir = UnityWorldSpaceLightDir(worldPos);
	// directional light is the same all over so there's no need to normalize or account for vertex position
	#ifndef USING_DIRECTIONAL_LIGHT
		worldSpaceLightDir = normalize(worldSpaceLightDir);
	#endif
	
	half3x3 tspace = ExtractTangentToWorldPerPixel(i.tangentToWorldAndWPos);
	
	#ifdef PSS_PERPIXELLIGHTPROBES_ON
		SHEnvCoeffs sh = SHSampleLightProbes();
		//SHEnvCoeffs sh = SHEmpty();

//		SHAddDirectionalLight(/*inout*/ sh, worldSpaceLightDir, _LightColor0.rgb);
		
		#if defined(UNITY_PASS_FORWARDBASE) && SHADER_TARGET >= 30
		// NB: VERTEXLIGHT_ON is not defined in fragment shader, so we incur the cost even if they are off.
		// Well, let's try dynamic branching (where possible). Since it's not varying, this should be a performance gain.
		// Note on SM "2.5" or less I'm leaving it per vertex since no dynamic branching there and the cost would be constant.
		// It may be a better idea to instead use UNITY_FLATTEN if SHADER_TARGET < 30, but maybe not always? Quality setting?
		// Maybe in future I'll make a helper script that'd do it on CPU side once. Esp. useful for mobile.
		UNITY_BRANCH
		if (i.ambient.a > 0.0) {
			// Unity collapses lights over the per pixel light limit in quality settings into
			// four point lights, that are supposed to be evaluated in the vertex shader
			// using Shade4PointLights function.
			// Since the results are quite usadisfactory and could ruin the look in some
			// situations (too blurry and bland ambient-ish look), we want to apply scattering
			// to them as well.
			// One way would be to evaluate them as direct lights in addition to the main one,
			// the other way, which is what I do here is to add these lights to SH that we evaluate anyway.
			// There is certainly a performance tradeoff between the two. I guess the direct approach could
			// be faster despite additional texture lookups, but for now I leave it like this because I
			// don't have time now to implement that.
			// The best thing though would be to use SH, but add the lights on the CPU side. I wish Unity
			// could do that for me.
			// Doing it in vertex shader is not an option because we'd need 7 interpolators just for this.
			// But I guess it could be done partially in VS and partially in FS or with some
			// packing/compression tricks.
		
			// to light vectors
			float4 toLightX = unity_4LightPosX0 - worldPos.x;
			float4 toLightY = unity_4LightPosY0 - worldPos.y;
			float4 toLightZ = unity_4LightPosZ0 - worldPos.z;
			// squared lengths
			float4 lengthSq = 0;
			lengthSq += toLightX * toLightX;
			lengthSq += toLightY * toLightY;
			lengthSq += toLightZ * toLightZ;
			float4 atten = 1.0 / (1.0 + lengthSq * unity_4LightAtten0);
			
			// Note there's SHAddPointLight, but it calls SHAddDirectionalLight anyway and needs to evaluate the same things we do above, but for each light.
			// SHAddPointLight(/*inout*/ sh, float3(0,0,0), float3(unity_4LightPosX0.x,unity_4LightPosY0.x,unity_4LightPosZ0.x), distance(..), unity_LightColor[0].rgb*unity_4LightAtten0.x);
			
			SHAddDirectionalLight(/*inout*/ sh, normalize(float3(toLightX.x,toLightY.x,toLightZ.x)), unity_LightColor[0].rgb*atten.x);
			SHAddDirectionalLight(/*inout*/ sh, normalize(float3(toLightX.y,toLightY.y,toLightZ.y)), unity_LightColor[1].rgb*atten.y);
			SHAddDirectionalLight(/*inout*/ sh, normalize(float3(toLightX.z,toLightY.z,toLightZ.z)), unity_LightColor[2].rgb*atten.z);
			SHAddDirectionalLight(/*inout*/ sh, normalize(float3(toLightX.w,toLightY.w,toLightZ.w)), unity_LightColor[3].rgb*atten.w);
		}
	 	#endif
	#endif

	half4 outputColor = half4(0.0, 0.0, 0.0, 1.0);
	half3 directLight = 0;
	
	
	// Normally you'd want to use LIGHT_ATTENUATION(i) macro and be done, but I want the various components
	// that make the attenuation separately in order to apply shadow penumbra. Penumbra scattering should
	// only apply on shadow and cookie attenuation and not on distance/falloff attenuation.
	// Otherwise the skin becomes uniformly red when distant from point and spot lights.
	//
	// This is the most likely place for brakage! Below code is based on macros in Light helpers section of
	// Unity's AutoLight.cginc. It takes the Unity5 approach for Unity 4 as well since we do have world pos.
	// in fragment shader.
	
	// fixed totalAtten = LIGHT_ATTENUATION(i);
	fixed lightShadow = SHADOW_ATTENUATION(i);
	 
	half shadowStrength = _LightShadowData.x; // shadow strength set on the light

	// Depending on light type we want some components that make up the light attenuation to contribute to
	// scattering, but not others.
	// Let's divide them into two factors, that multiplied give back the total attenuation.
	fixed penumbraScattered = 1.0;
	fixed penumbraNonscatteredTotal = 1.0;
	fixed penumbraNonscatteredDiffuse = 1.0;

	#ifdef PSS_PENUMBRA_SCATTERING_ON
		// Remove shadow intensity factor in order to apply penumbra scattering only on the actual penumbra.
		// Otherwise the entire shadow area becomes unnaturally red.

		if (shadowStrength > 0.0 && shadowStrength < 1.0)
		{
			// Shadow strength is applied by Unity in this way:
			//  lightShadow = shadowStrength + shadow * (1-shadowStrength)
			// so
			lightShadow = (lightShadow - shadowStrength) / (1.0 - shadowStrength);
		}
	#endif

	#if defined(DIRECTIONAL) || defined(DIRECTIONAL_COOKIE)
		#ifdef PSS_PENUMBRA_SCATTERING_ON
			penumbraScattered *= lightShadow;
			
			// specular limited with same narrowed punumbra function as diffuse
			penumbraNonscatteredTotal *= newPenumbra(lightShadow);
		#else
			penumbraNonscatteredTotal *= lightShadow;
			penumbraNonscatteredDiffuse *= lightShadow;
		#endif
		
		#ifdef DIRECTIONAL_COOKIE
			unityShadowCoord2 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xy;
			fixed lightCookie = tex2D(_LightTexture0, lightCoord).w;
			#ifdef PSS_COOKIE_SCATTERING_ON
				// Apply scattering to shadow penumbra with gradient embedded into diffuse lookup.
				// Before I was doing it to combined shadow and cookie value, but there are a few problems with it:
				// - What the cookie means is totally use dependent and its gradient compared to world space can
				// make things look unnaturally red.
				// - The cookie may not transit between 100% white and 100% black, again making thing look just red.
				// - Cookie size can affect the world space gradient as well, which may differ from shadow penumbra.
				// 
				// Now, to avoid these problems the cookie scattering is separate and done by means of sampling
				// cookie mips for different blur levels of the profile, similar to normal map and ambient occlusion.
				// The actual code is below, in the loop over profile elements.
				penumbraNonscatteredTotal *= lightCookie;
				penumbraScattered *= lightCookie;
			#else
				penumbraNonscatteredTotal *= lightCookie;
				penumbraNonscatteredDiffuse *= lightCookie;
			#endif
		#endif
	#elif defined(SPOT)
		unityShadowCoord4 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1));
		
		fixed lightAtten = (lightCoord.z > 0) * UnitySpotAttenuate(lightCoord.xyz);
		fixed lightCookie = UnitySpotCookie(lightCoord);
		
		#if defined(PSS_PENUMBRA_SCATTERING_ON) || defined(PSS_COOKIE_SCATTERING_ON)
			// For spot lights apply penumbra scattering on both shadow and cookie.
			// Assuming here that the spot cookie intensity goes from complete black at edges to
			// roughly 100% white at center.
			// Not 100% black at edges produces visual artifacts on standard shader as well, but
			// is more noticeable with scattering applied.
			// While not going to 100% white or a too smooth gradient will produce unnaturally
			// red penumbra.
			// Theoretically a better way would be to use mips instead, like for directional
			// cookies, but I tried it and it doesn't quite work unless used with very high
			// resolution cookies. Default cookie becomes non round at lower mips, not usable
			// at all :(
			// Also the spot range, and thus world space cookie scale doesn't affect the penumbra
			// width for now. May get into it in the future, or maybe not. Switching to screen
			// space or texture space scattering may be simpler...
			fixed tmpScattered = 1.0;
			fixed tmpNonScattered = 1.0;
			#ifdef PSS_PENUMBRA_SCATTERING_ON
				tmpScattered *= lightShadow;
			#else
				tmpNonScattered *= lightShadow;
			#endif
			#ifdef PSS_COOKIE_SCATTERING_ON
				tmpScattered *= lightCookie;
			#else
				tmpNonScattered *= lightCookie;
			#endif
			
			penumbraScattered *= tmpScattered;
			penumbraNonscatteredTotal *= newPenumbra(tmpScattered) * tmpNonScattered;
			penumbraNonscatteredDiffuse *= tmpNonScattered;
		#else
			penumbraNonscatteredTotal *= lightShadow*lightCookie;
			penumbraNonscatteredDiffuse *= lightShadow*lightCookie;
		#endif
		
		penumbraNonscatteredTotal *= lightAtten;
		penumbraNonscatteredDiffuse *= lightAtten;
	#elif defined(POINT_COOKIE)
		unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz;
		
		// No penumbra for point lights.
		// Unity's "soft shadows" for point lights look like crap and ruin everything (still true
		// as of 5.1, seriously, fix it!), punumra scattering makes things even worse.
		// Not doing it for cookies either.
		// May reintroduce it later using mips like for directionals, but let's keep it simple for now.
		fixed lightAtten = tex2D(_LightTextureB0, dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
		fixed lightCookie = texCUBE(_LightTexture0, lightCoord).w;
		
		// Without cookies can avoid a few ops by turning it off completely.
		#undef PSS_PENUMBRA_SCATTERING_ON
		
		penumbraScattered = 1.0;
		penumbraNonscatteredTotal = lightAtten*lightCookie*lightShadow;
		penumbraNonscatteredDiffuse = lightAtten*lightCookie*lightShadow;
	#elif defined(POINT)
		unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz;
		
		fixed lightAtten = tex2D(_LightTexture0, dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
						
		// Without cookies can avoid a few ops by turning it off completely.
		#undef PSS_PENUMBRA_SCATTERING_ON
		
		penumbraScattered = 1.0;
		penumbraNonscatteredTotal = lightAtten*lightShadow;
		penumbraNonscatteredDiffuse = lightAtten*lightShadow;
	#endif

	#ifdef PSS_PENUMBRA_SCATTERING_ON
		// Reapply shadow strength to penumbraNonscatteredTotal, which is used for specular etc, but not
                // to penumbraNonscatteredDiffuse or penumbraScattered. The shadow strength is applied with
                // special care in diffuse lookup later.

		if (shadowStrength > 0.0 && shadowStrength < 1.0)
                    penumbraNonscatteredTotal = shadowStrength + penumbraNonscatteredTotal * (1.0 - shadowStrength);
	#else
		penumbraNonscatteredDiffuse = penumbraNonscatteredTotal;
		penumbraScattered = 1.0;
	#endif
	
	#ifdef HACK_LIGHTATTEN_TO_ALPHA
		// NB: this assumes no penumbra scattering
		outputColor.a = penumbraNonscatteredTotal;
	#endif

	#if defined(HACK_LIGHTATTEN_DISCARD) || !defined(PSS_ENABLE_DIRECTLIGHT)
		// Don't use light attenuation as we want to use alpha blending for it.
		// By forcing them to one, compiler will removed all the code that came first in the
		// case of HACK_LIGHTATTEN_FROM_ALPHA or PSS_ENABLE_DIRECTLIGHT. In case of HACK_LIGHTATTEN_TO_ALPHA we only
		// get rid of one mul.
		penumbraNonscatteredTotal = 1.0;
		penumbraNonscatteredDiffuse = 1.0;
		penumbraScattered = 1.0;
	#endif

	// For each blur level, call the surf function and calculate diffuse lighting.
	// The surf struct contains all surface parameters for shading provider by the final shader.
	// Some parameters depend on the blur level, while others don't. I'm relying on the compiler to remove dead code
	// so most parameters will be only those left by the last call of pss_surf.
	// With that in mind let's call them in the inverse order so the last one is the least blurred, which is
	// used for specular and translucency.
	
	// Diffuse lookup texture (both direct and SH) is parametrized with scattering that varies with surface
	// curvature and for each profile blur level.
	// Spatially varying surface curvature/scattering from "depth" texure is multiplied by pre-computed
	// factor for each blur level.

	
	// TODO precompute gamma corrected profile weights

	// Penumbra scattering is pre-integrated toghether with the diffuse in the lookup texture. Each mip level of the
	// lookup is computed for relative location in the shadow penumbra.
	// The lookup is 256x256, thus has 8 mip maps, of wich the smallest two (1x1 and 2x2 px) are unused because of
	// insufficient resolution.
	float penumbraMip = saturate(1.0-penumbraScattered)*6.0;

	// NB: not using array initializers to avoid compilation problems for Metal

	#if PSS_QUALITY == PSS_QUALITY_UGLY
		const int profileElementCnt = 1;
		half3 profileWeights[1];
		profileWeights[0] = half3(1.0, 1.0, 1.0);
		half profileVariance[1];
		profileVariance[0] = 1.0;
		half profileVarianceSqrt[1];
		profileVarianceSqrt[0] = 1.0;
	#elif PSS_QUALITY == PSS_QUALITY_LOW
		const int profileElementCnt = 2;
		half3 profileWeights[2];
		profileWeights[0] = _PSSProfileLow_weighths1_var1.xyz;
		profileWeights[1] = _PSSProfileLow_weighths2_var2.xyz;
		half profileVariance[2];
		profileVariance[0] = _PSSProfileLow_weighths1_var1.w;
		profileVariance[1] = _PSSProfileLow_weighths2_var2.w;
		half profileVarianceSqrt[2];
		profileVarianceSqrt[0] = _PSSProfileLow_sqrtvar12.x;
		profileVarianceSqrt[1] = _PSSProfileLow_sqrtvar12.y;
	#elif PSS_QUALITY == PSS_QUALITY_MEDIUM
		const int profileElementCnt = 3;
		half3 profileWeights[3];
		profileWeights[0] = _PSSProfileMedium_weighths1_var1.xyz;
		profileWeights[1] = _PSSProfileMedium_weighths2_var2.xyz;
		profileWeights[2] = _PSSProfileMedium_weighths3_var3.xyz;
		half profileVariance[3];
		profileVariance[0] = _PSSProfileMedium_weighths1_var1.w;
		profileVariance[1] = _PSSProfileMedium_weighths2_var2.w;
		profileVariance[2] = _PSSProfileMedium_weighths3_var3.w;
		half profileVarianceSqrt[3];
		profileVarianceSqrt[0] = _PSSProfileMedium_sqrtvar123.x;
		profileVarianceSqrt[1] = _PSSProfileMedium_sqrtvar123.y;
		profileVarianceSqrt[2] = _PSSProfileMedium_sqrtvar123.z;
	#else // PSS_QUALITY >= PSS_QUALITY_HIGH
		const int profileElementCnt = 6;
		half3 profileWeights[6];
		profileWeights[0] = _PSSProfileHigh_weighths1_var1.xyz;
		profileWeights[1] = _PSSProfileHigh_weighths2_var2.xyz;
		profileWeights[2] = _PSSProfileHigh_weighths3_var3.xyz;
		profileWeights[3] = _PSSProfileHigh_weighths4_var4.xyz;
		profileWeights[4] = _PSSProfileHigh_weighths5_var5.xyz;
		profileWeights[5] = _PSSProfileHigh_weighths6_var6.xyz;
		half profileVariance[6];
		profileVariance[0] = _PSSProfileHigh_weighths1_var1.w;
		profileVariance[1] = _PSSProfileHigh_weighths2_var2.w;
		profileVariance[2] = _PSSProfileHigh_weighths3_var3.w;
		profileVariance[3] = _PSSProfileHigh_weighths4_var4.w;
		profileVariance[4] = _PSSProfileHigh_weighths5_var5.w;
		profileVariance[5] = _PSSProfileHigh_weighths6_var6.w;
		half profileVarianceSqrt[6];
		profileVarianceSqrt[0] = _PSSProfileHigh_sqrtvar1234.x;
		profileVarianceSqrt[1] = _PSSProfileHigh_sqrtvar1234.y;
		profileVarianceSqrt[2] = _PSSProfileHigh_sqrtvar1234.z;
		profileVarianceSqrt[3] = _PSSProfileHigh_sqrtvar1234.w;
		profileVarianceSqrt[4] = _PSSProfileHigh_transl123_sqrtvar5.w;
		profileVarianceSqrt[5] = _PSSProfileHigh_transl456_sqrtvar6.w;
	#endif
	
	SkinSurfaceOutput surf;
	UNITY_INITIALIZE_OUTPUT(SkinSurfaceOutput,surf);
	
	#if !defined(PROFILE_PASS) || PROFILE_PASS == 0
	{
		pss_surf(i, surf, 0.0);
		
		half3 worldNormal = PSSTangentToWorldNormal(tspace, surf.Normal);
		half NdotE = dot(worldNormal, worldSpaceViewDir);
		#ifdef PSS_ENABLE_DIRECTLIGHT
			half NdotL = dot(worldNormal,worldSpaceLightDir);
		#endif

		#if defined(UNITY_PASS_FORWARDBASE)
		outputColor.rgb += surf.Emission;
		#endif
		
		#if defined(PSS_ENABLE_SPECULAR) || defined(HACK_SPEC_AO_TO_ALPHA)
			#ifdef PSS_AMBIENT_OCCLUSION_ON
				// From "Real-time Physically Based Rendering - Implementation" CEDEC 2011 by tri-Ace research
				// see http://research.tri-ace.com.
				// Varius methods for specular occlusion derived from ambient occlusion with respective quality to 
				// performance tradeoffs.
				
				// simplest, more agressive than AO as intended, but not taking into account specular roughness
				// float specularOcclusion = saturate(pow(NdotE,2) + 2*surf.AmbientOcclusion - 1.0);
				
				// v2
				// float specularOcclusion = saturate(pow(NdotE+surf.AmbientOcclusion, oneMinusRoughness) - 1.0 + surf.AmbientOcclusion);

				// v3
				#if SHADER_TARGET >= 25
					half specularOcclusion = saturate(Pow2(NdotE+surf.AmbientOcclusion) - 1.0 + surf.AmbientOcclusion/2.0);
				#else
					// Use a lookup to save just a few instructions. I know it may actually slow down, but if I can save a pass per light, it's still a win.
					half specularOcclusion = tex2D(_LookupSpecAO, float2(NdotE, surf.AmbientOcclusion));
				#endif
			#else
				half specularOcclusion = 1.0;
			#endif
			
		 	#ifdef HACK_SPEC_AO_TO_ALPHA
				outputColor.a = specularOcclusion;
				#ifdef HACK_SPEC_AO_DISCARD
					specularOcclusion = 1.0;
				#endif
			#endif
		#endif		
		
		#ifdef PSS_ENABLE_SPECULAR
			#ifdef PSS_ENABLE_DIRECTLIGHT
			{
				float3 V = normalize(worldSpaceViewDir);
				float3 H = normalize(worldSpaceViewDir+worldSpaceLightDir);
				float LdotH = dot(worldSpaceLightDir,H);
				float NdotH = dot(worldNormal,H);
				
				half3 directSpecular = 0.0;
		    	half m = surf.SpecularRoughness;
		    	half3 F0 = surf.SpecularIntensity;
		    	
		    	half3 specularDirect = DirectSpecularFunction(worldNormal, worldSpaceViewDir, worldSpaceLightDir, m, F0);
				
				directLight += specularDirect * (penumbraNonscatteredTotal * specularOcclusion);
			}
			#endif // PSS_ENABLE_DIRECTLIGHT

			#if defined(UNITY_PASS_FORWARDBASE) && defined(PSS_REFLECTION_PROBES_ON) && UNITY_VERSION >= 500
	    	{
				half3 specularIndirect = 0;
	    	
	    		half m = surf.SpecularRoughness;
	    		half3 F0 = surf.SpecularIntensity;
	    		
	    		half3 worldSpaceReflection = reflect(-worldSpaceViewDir, worldNormal);
	    		
	    		float oneMinusRoughness = 1.0-m;

	    		#if UNITY_VERSION < 540
	    			// For older Unity versions continue using the old proven code that I took from Unity's built-in shaders.
	    			// It's roughly unmodified from what standard shader does. I copied it because in 5.0 there was no
	    			// reusable function independent of standard shader internals.
	    			#if UNITY_SPECCUBE_BOX_PROJECTION
						half3 worldSpaceReflection0 = BoxProjectedCubemapDirection (worldSpaceReflection, worldPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
					#else
						half3 worldSpaceReflection0 = worldSpaceReflection;
					#endif

					half3 env0 = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, worldSpaceReflection0, 1-oneMinusRoughness);
					#if UNITY_SPECCUBE_BLENDING
						const float kBlendFactor = 0.99999;
						float blendLerp = unity_SpecCube0_BoxMin.w;
						UNITY_BRANCH
						if (blendLerp < kBlendFactor)
						{
							#if UNITY_SPECCUBE_BOX_PROJECTION
								half3 worldSpaceReflection1 = BoxProjectedCubemapDirection (worldSpaceReflection, worldPos, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
							#else
								half3 worldSpaceReflection1 = worldSpaceReflection;
							#endif

							half3 env1 = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE(unity_SpecCube1), unity_SpecCube1_HDR, worldSpaceReflection1, 1-oneMinusRoughness); // UNITY_SHADER_NO_UPGRADE
						}
						else
						{
							specularIndirect = env0;
						}
					#else
						specularIndirect = env0;
					#endif
	    		#else
	    			// In newer unity versions use the provided function so we're less likely to break. Hopefully.
	    			// Need to construct some boilerplate structs, but the compiler should do the rigt job and 
	    			// strip unused stuff, so I don't excpect any overhead relative to the code above.

	    			UnityGIInput d;
					d.worldPos = worldPos;
					#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
						d.boxMin[0] = unity_SpecCube0_BoxMin;
						d.boxMin[1] = unity_SpecCube1_BoxMin;
					#endif
					
					#if UNITY_SPECCUBE_BOX_PROJECTION
						d.boxMax[0] = unity_SpecCube0_BoxMax;
						d.boxMax[1] = unity_SpecCube1_BoxMax;
						d.probePosition[0] = unity_SpecCube0_ProbePosition;
						d.probePosition[1] = unity_SpecCube1_ProbePosition;
					#endif
					
					d.probeHDR[0] = unity_SpecCube0_HDR;
					d.probeHDR[1] = unity_SpecCube1_HDR;

					// not used by UnityGI_IndirectSpecular
					UnityLight l;
					l.color = 0;
					l.ndotl  = 0;
					l.dir = 0;
					d.light = l; 
					d.atten = 1.0;
					d.ambient = 0;
					d.lightmapUV = 0;
					d.worldViewDir = 0;

	    			Unity_GlossyEnvironmentData glossIn;
					glossIn.roughness = m;
					glossIn.reflUVW = worldSpaceReflection;

	    			specularIndirect = UnityGI_IndirectSpecular(d, 1.0/*occlusion applied later*/, worldNormal, glossIn);
	    		#endif
				
				
				//half oneMinusReflectivity;
				//half3 diffColor = EnergyConservationBetweenDiffuseAndSpecular(surf.Albedo, F0, /*out*/ oneMinusReflectivity);
				half3 oneMinusReflectivity = 1.0 - F0;
				
				half3 grazingTerm = saturate(oneMinusRoughness + (1.0-oneMinusReflectivity));
				
				half3 fresnelFactor = FresnelLerp(F0, grazingTerm, NdotE);
				
				specularIndirect *= fresnelFactor;

				// Note that it is not physically correct to just multiply result of specular lighting, but here it's
				// somewhat intentional to compensate for lack of real occlusion in specular light from the reflection
				// probes. The SpecularEnvMapIntensity parameter in particular exists for the purpose of toning down
				// specular light at incident angles, since not being occluded makes the environment spec much stronger
				// than for direct specular, even if otherwise consistent.
				specularIndirect *= surf.SpecularEnvMapIntensity * specularOcclusion;
				
				#if SHADER_TARGET > 25
					specularIndirect = max(half3(0,0,0), specularIndirect);
				#else
					specularIndirect = saturate(specularIndirect);
				#endif
				
				outputColor.rgb += specularIndirect;
			}
			#endif // defined(UNITY_PASS_FORWARDBASE) && defined(PSS_REFLECTION_PROBES_ON) && defined(PSS_UNITY_5_0_ORLATER)
		#endif // PSS_ENABLE_SPECULAR
		
		#ifdef PSS_ENABLE_TRANSLUCENCY
		{
			fixed translucencyDepth = surf.TranslucencyDepth;
			half3 translucencyProfile;
			
			// Original code, based on <<Real-Time Realistic Skin Translucency>> paper by Jorge Jimenez, David Whelan,
			// Veronica Sundstedt and Diego Gutierrez. See http://www.iryoku.com/translucency/
			// float dd = -translucencyDepth*translucencyDepth;
			// translucencyProfile =
			// 	  exp(dd / PSS_PROFILE_VARIANCE_1) * PSS_PROFILE_WEIGHTS_1
			// 	+ exp(dd / PSS_PROFILE_VARIANCE_2) * PSS_PROFILE_WEIGHTS_2
			// 	+ exp(dd / PSS_PROFILE_VARIANCE_3) * PSS_PROFILE_WEIGHTS_3
			// 	+ exp(dd / PSS_PROFILE_VARIANCE_4) * PSS_PROFILE_WEIGHTS_4
			// 	+ exp(dd / PSS_PROFILE_VARIANCE_5) * PSS_PROFILE_WEIGHTS_5
			// 	+ exp(dd / PSS_PROFILE_VARIANCE_6) * PSS_PROFILE_WEIGHTS_6;
			//
			// Reduced to less factors on lower quality settings, using values precomputed and stored in the profile.
			// The precomputed factors are also altered in order to change exp to exp2, which is a bit faster (usually
			// maps to one native op).
			// As a bonus should be faster on vector archs by combining the variance uniforms into vectors.
			// Minus sign is moved in the factor too, but it probably doesn't make a difference.
			// Note that PSS1.1 used a lookup for translucency, but on modern hardware it's faster to compute, even in
			// the original form.
			#if PSS_QUALITY >= PSS_QUALITY_HIGH
				float3 expddA = exp2(translucencyDepth*translucencyDepth * _PSSProfileHigh_transl123_sqrtvar5.xyz);
				float3 expddB = exp2(translucencyDepth*translucencyDepth * _PSSProfileHigh_transl456_sqrtvar6.xyz);
				translucencyProfile =
					  expddA.x * profileWeights[0]
					+ expddA.y * profileWeights[1]
					+ expddA.z * profileWeights[2]
					+ expddB.x * profileWeights[3]
					+ expddB.y * profileWeights[4]
					+ expddB.z * profileWeights[5];
			#elif PSS_QUALITY >= PSS_QUALITY_MEDIUM
				float3 expdd = exp2(translucencyDepth*translucencyDepth * _PSSProfileMedium_transl123.xyz);
				translucencyProfile =
					  expdd.x * profileWeights[0]
					+ expdd.y * profileWeights[1]
					+ expdd.z * profileWeights[2];
			#elif PSS_QUALITY >= PSS_QUALITY_LOW
				// 3 component exponential, but without using weigths to reduce instruction count.
				// The assumpion is that for the old hardware is still the samne vector op
				// be it exp(float3) or exp(float2).
				translucencyProfile = exp2(translucencyDepth*translucencyDepth * _PSSProfileLow_transl.xyz);
			#endif
			
			translucencyProfile *= surf.TranslucencyColor;
			
			// In theory to account for energy conservation I should do something like below (twice), but it gets awkward.
			// When albedo is too bright you'd see no translucency.
			// translucencyProfile *= (1.0-surf.Albedo);
			// translucencyProfile *= (1.0-surf.Albedo);
			// FIXME probably the better way is the inverse: translucency power subtracts from albedo
			// translucencyProfile *= (1.0-Luminance(surf.Albedo))*(1.0-Luminance(surf.Albedo));
			
			// simple energy conservation, like in Unity's Standard Shader
	    	half3 F0 = surf.SpecularIntensity;
			translucencyProfile = translucencyProfile - F0*translucencyProfile; // translucencyProfile *= (1.0 - F0);
			
			#ifdef PSS_ENABLE_DIRECTLIGHT
			{
				#if PSS_QUALITY > PSS_QUALITY_LOW
					float translucencyAttenuation = max(0.0, 0.3 -NdotL); // NB: -NdotL = dot(lightDir,-normal)
				#else
					// A little little cheaper (in terms of instrucion count) method used in previous versions, but let's leave micro optimizations for later...
					float translucencyAttenuation = saturate(NdotE - NdotL);
				#endif
				
				// NB: occluding penumbra with the same shadow as the front siding surface. Though quite wrong, still better
				// than completely completely unoccluded. Shadow artefacts are quite visible, but less noticable with more
				// lights and/or ambient lighting.
				translucencyAttenuation *= penumbraNonscatteredTotal;

		    	directLight += translucencyProfile * translucencyAttenuation;
			}
			#endif // PSS_ENABLE_DIRECTLIGHT

			#if defined(PSS_PERPIXELLIGHTPROBES_ON) && defined(UNITY_PASS_FORWARDBASE)
			{
				// To understand consider how back scattering for direct lights is done above:
				// the depth of skin traversed by light is approximated by the depth texture, which doesn't have
				// any directionality. The result is attenuated with max(0, 0.3-N.L) trick/approximation just like
				// described by Jimenez et all (http://www.iryoku.com/translucency/).
				// This means we can:
				// 1. Reuse translucencyProfile from direct light since this part only depends on the 
				// omni-directional thickness from the depth map.
				// 2. Apply the max(0, 0.3-N.L) in SH domain by integrating it just like we do for diffuse SSS.
				// This part is not parametrized, which makes things really cheap: just multiply each order by the
				// constant resulting from integration.
				//
				// See the mathematica notebook for how the magic values are calculated.
				// Actually why multiplying by {2,3,4} second time was necessary is still a mystery to me, but it
				// matches translucencyAttenuation from direct lighting perfectly so... whatever.
				//
				// If you don't have Mathematica you can just paste these in wolframalpha.com.
				// It gives slightly different values, due to some approximations. The ones from Mathematica are
				// probably more precise.
				// integrate 2*2*sin(x)*max(0,0.3-cos(x)) dx from 0 to pi
				// integrate 3*3*sin(x)*(cos(x))*max(0,0.3-cos(x)) dx from 0 to pi
				// integrate 4*4*sin(x)*(3*cos(x)^2-1)*max(0,0.3-cos(x)) dx from 0 to pi
				
				SHEnvCoeffs shTransl = sh;
				half3 backscatterCoeffs = half3(1.6, -1.315, 0.568);
				//half3 backscatterCoeffs = half3(1.69, -1.4365, 0.8281); // values from wolframalpha
				
				// used this to compare with direct light:
				//shTransl = SHEmpty();
				//SHAddDirectionalLight(/*inout*/ shTransl, worldSpaceLightDir, _LightColor0.rgb);
				//SHApplyZHCoeffs(/*inout*/ shTransl, backscatterCoeffs);
				//return SHEval(shTransl, worldNormal.xyz).rgbb;
				
				SHApplyZHCoeffs(/*inout*/ shTransl, backscatterCoeffs);

				half3 shlight = SHEval(shTransl, worldNormal.xyz);

				#ifdef UNITY_COLORSPACE_GAMMA
					shlight.rgb = LinearToGammaSpace (shlight.rgb);
				#endif

				outputColor.rgb += saturate(translucencyProfile * shlight);
			}
			#endif // defined(PSS_PERPIXELLIGHTPROBES_ON) && defined(UNITY_PASS_FORWARDBASE)
		}
		#endif // PSS_ENABLE_TRANSLUCENCY

    }
	#endif // !defined(PROFILE_PASS) || PROFILE_PASS == 0
	
	#ifdef PROFILE_PASS
	// On SM2 in order to render anything decent we need to go multi-pass. That's the main reason I went to the hoops of
	// making everything as scalable and modularized.
	const int profileInd = PROFILE_PASS;
	#else
	// Otherwise loop over all profile elements.
	PSS_UNROLL(6)
	for (int profileInd=0; profileInd<profileElementCnt; profileInd++)
	#endif
	{
		half3 weights = profileWeights[profileInd];
		half variance = profileVariance[profileInd];
		half varianceSqrt = profileVarianceSqrt[profileInd];
		
		pss_surf(i, surf, variance);
		half3 worldNormal = PSSTangentToWorldNormal(tspace, surf.Normal);

		weights *= surf.Albedo;
		
		half scattering = surf.Scattering*varianceSqrt;
		
		float NdotE = dot(worldNormal, worldSpaceViewDir);
		
		#if defined(UNITY_PASS_FORWARDBASE) && defined(PSS_ENABLE_DIFFUSE)
		{
			half m = surf.SpecularRoughness;
	    	half3 F0 = surf.SpecularIntensity;

			// For SH only use simple energy conservation. No fancy retro reflection&stuff.
			// It IS possible, but let's keep things simple.
			// If we realy, reeallyyy wanted to, let's then consider this braindump:
			// 1. Add a lookup texture parametrized in UV by spherical coordinates of world space view vector.
			// 2. Integrate into the lookup the fancy energy conservation&retro-reflection.
			// Would need to reconstruct the view vector and build a light vector for each direction.
			// Split the integral into two parts: incident and grazing angle and store the rusult in two textures.
			// 3. Lookup the two textures and weight them with F0.
			// 4. Convolve with scattering coefficients. That is multiply them.
			// And then I'm not so sure it work at all.
			half3 diffuseEnergy = (1.0 - F0);

			// Also for indirect light compensate for loss of energy caused by the SpecularEnvMapIntensity parameter.
			half3 diffuseEnergyIndirect = (1.0 - F0*surf.SpecularEnvMapIntensity);
	    	
			#ifdef PSS_PERPIXELLIGHTPROBES_ON
				half3 scatterCoeffs = tex2D(_LookupSH, float2(scattering, 0.0)).rgb;
				
				// x2 because coeffs go beyound 0..1 range of ldr texture
				scatterCoeffs *= 2.0;
				
				#ifdef PSS_AMBIENT_OCCLUSION_ON
					// Apply ambient occlusion only to the constant term. This way we get a kind of directionality.
					scatterCoeffs.x *= surf.AmbientOcclusion;
				#endif
				
				SHEnvCoeffs shScattered = sh;
				SHApplyZHCoeffs(/*inout*/ shScattered, scatterCoeffs);

				half3 shlight = SHEval(shScattered, worldNormal.xyz);

				#ifdef UNITY_COLORSPACE_GAMMA
					shlight.rgb = LinearToGammaSpace (shlight.rgb);
				#endif
				
				outputColor.rgb += saturate(diffuseEnergyIndirect * weights * shlight);
			#else
				// Per-vertex SH: apply with albedo and ambient occlusion.
				// Note that ambient value doesn't change for loop iterations, but:
				// a) ambient occlusion inside loop does change, so we get scattered AO, yay!
				// b) this code path is for SM2, where we can do one profile elem at a time anyway,
				//    so moving it out of the loop wouldn't be of any advantage anyway.
				half3 ambient = i.ambient.rgb;
				#if defined(PSS_AMBIENT_OCCLUSION_ON) && !defined(HACK_PLAIN_AO_TO_ALPHA)
			 		ambient *= surf.AmbientOcclusion;
				#endif
		 		outputColor.rgb += diffuseEnergy * weights * ambient;
			#endif
		}
		#endif
		

		
		#ifdef PSS_ENABLE_DIRECTLIGHT
		float NdotL = dot(worldNormal, worldSpaceLightDir);
		{
			float diffLookup = (0.5 + 0.5 * NdotL);
			
			// Penumbra scattering of directional light cookies. See comments in code above.
			#if defined(PSS_COOKIE_SCATTERING_ON) && defined(DIRECTIONAL_COOKIE)
			{
				unityShadowCoord2 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xy;
				float2 tc = lightCoord;

				// Account for world space cookie size.
				// Cookie size can be recovered from the scale of the light matrix.
				// The scale can be reconstructed by calculating lengths of three basis vectors
				// from the "upper-left" 3x3 part of the matrix.
				// Since the cookie size is symmetrically scaled in all axes we can only consider
				// one of them.
				float worldSpaceCookieSize = length(unity_WorldToLight[0].xyz);
				

				//float worldScale = surf.WorldScale;
				float worldScale = 1.0;

				//float blur = (1.0-variance) / worldScale / worldSpaceCookieSize;
				
				// Voodoo: the resulting scale doesn't seem to scale linearly with actual result.
				// There's something I don't completely understand here, but let's make it work
				// like this for now.
				// It's either what the _LightMatrix0 actually represents or, quite likely something
				// diffferent, since non sqrtd variance doesn't look right either.
				// It may even be related to PSS_SAMPLE_BLURRED.
				float blur = (1.0-variance) / pow(worldSpaceCookieSize/worldScale, 1.0/4.0);
				
				// TODO optimization: pre-calculate mip count for _LightTexture0 in VS.
				// Put it in .w of ambient interpolator.
				// Not bothering for now since disabled by default.
				float testCookie = PSS_SAMPLE_BLURRED(_LightTexture0, tc, blur).w;
				weights *= testCookie;
			}
			#endif
			
			#ifdef PSS_ENABLE_DIFFUSE
				// Energy conservation.
				// Use specular intensity from each profile component to avoid unnaturally harsh shadowing.
				// Since skin will scatter between texels, the light for blurry diffuse layers should not be occluded only
				// by the sharp specular map.
				// Can cheat for lower detail by just using mid-high blurry level into consideration.
		    	half m = surf.SpecularRoughness;
		    	half3 F0 = surf.SpecularIntensity;
		    	
		    	#if SHADER_TARGET >= 25 && PSS_QUALITY >= PSS_QUALITY_HIGH
					//float diffuseEnergy = tex2Dlod(_LookupDirect, float4(NdotL*0.5+0.5, F0, 0, m*6.0)).w;
					//float specularEnergy = F0+(1.0-F0)*pow(NdotL, 5.0);
					//float diffuseEnergy = (1.0 - saturate(specularEnergy));
					
					// Diffuse fresnel - go from 1 at normal incidence to .5 at grazing
					// and mix in diffuse retro-reflection based on roughness
					float3 H = normalize(worldSpaceViewDir+worldSpaceLightDir);
					float LdotH = dot(worldSpaceLightDir,H);
					float roughness = surf.SpecularRoughness;
					float FL = SchlickFresnel(NdotL), FV = SchlickFresnel(NdotE);
					float Fd90 = 0.5 + 2.0 * LdotH*LdotH * roughness;
					float3 Fd = lerp(1.0-F0, Fd90.xxx, FL) * lerp(1.0-F0, Fd90.xxx, FV);
					float3 diffuseEnergy = Fd;
					
					//diffuseEnergy = lerp(1.0-F0, Fd90, FL);
		    	#else
		    		// simple energy conservation, like in Unity's Standard Shader
					half3 diffuseEnergy = (1.0 - F0);
		    	#endif
				
				// Now diffuseEnergy can boost intensity at grazing angles. Due to scattering these areas are usualy
				// red and otherwise dark. The result is unnaturally saturated red with high roughness.
				// A quick hack is to "shift" the NdotL instead of multiplying the result, but it comes with its own
				// isses. Mostly the fact that the lookup saturates at 1.
				//diffLookup = (0.5 + 0.5 * NdotL*diffuseEnergy);

				#ifdef PSS_AMBIENT_OCCLUSION_ON
					#ifdef PSS_AMBIENT_OCCLUSION_DIRECTIONAL
						diffLookup *= lerp(surf.AmbientOcclusion, 1, surf.AmbientOcclusionSuppression*NdotL);
					#else
						diffLookup *= surf.AmbientOcclusion;
					#endif
				#endif
				
				half diffuseDirect;
				#if SHADER_TARGET >= 30
					#ifdef PSS_PENUMBRA_SCATTERING_ON
						// Here it ought to be as simple as performing the lookup in the else part of the branch.
						// But this results in inconsistencies when shadow strength (the setting on the light) is not 100%.
						// Unity's shadow strength setting doesn't have a direct physical equivalent, but the intuitive
						// result is similar to the shadowing surface being translucent.
						// Since we don't want the cost of two lookups for such a niche case, dynamic branchig to the rescue!
						// Whether it'll actually help avoding the cost is subject to many variables. On my GPU, in a simple
						// scene at least, it doesn't make any difference.
						// Also I have some doubts here about the branch. Some OpenGL drivers for example can optimize code
						// dependent only on an uniform, but there's no gaurantee.
						// - Will this optimization take place if I use shadowStrength instead of _LightShadowData.x directly?
						// - Will the UNITY_BRANCH have any effect on it?
						UNITY_BRANCH
						if (shadowStrength > 0.0 && shadowStrength < 1.0) {
							diffuseDirect = tex2Dlod(_LookupDirect, float4(diffLookup, scattering, 0, penumbraMip)).r*(1.0-shadowStrength)
						                  + tex2Dlod(_LookupDirect, float4(diffLookup, scattering, 0, 0)).r*shadowStrength;
						} else {
							diffuseDirect = tex2Dlod(_LookupDirect, float4(diffLookup, scattering, 0, penumbraMip)).r;
						}
					#else
						diffuseDirect = tex2Dlod(_LookupDirect, float4(diffLookup, scattering, 0, 0)).r;
					#endif
				#else
					// no penumbra for SM2
					diffuseDirect = tex2D(_LookupDirectSM2, float2(diffLookup, scattering)).r;
				#endif
				directLight += (diffuseEnergy * weights) * (diffuseDirect * penumbraNonscatteredDiffuse);
			#endif
		}
		#endif
	}
	
	#ifdef PSS_ENABLE_DIRECTLIGHT
		outputColor.rgb += directLight * _LightColor0.rgb;
	#endif
	
	#if UNITY_VERSION < 500
		outputColor.rgb *= 2.0;
	#endif
	
	#if !defined(HACK_SPEC_AO_TO_ALPHA) && !defined(HACK_LIGHTATTEN_TO_ALPHA) && !defined(HACK_PLAIN_AO_TO_ALPHA)
		UNITY_OPAQUE_ALPHA(outputColor.a);
	#endif
	
	#ifdef HACK_PLAIN_AO_TO_ALPHA
		outputColor.a = surf.AmbientOcclusion;
	#endif
	
	outputColor.rgb = PSS_OUTPUTGAMMACORRECTION(outputColor.rgb);

	// Note that normally this would be UNITY_APPLY_FOG(i.fogCoord, outputColor), but I'm packing fogcoord with UV.
	// See notes on fog coords in vertex function.
	// Fun fact: the macro will evaluate the first param to something like i.uv.z.x
	// Less fun fact: it would appear that here we can just call UNITY_APPLY_FOG(i.uv.z, outputColor), but it's not
	// the case since it's declared before UNITY_PASS_FORWARDADD because of the use of CGINCLUDE outside subshaders.
	#if defined(UNITY_PASS_FORWARDADD) || defined(HACK_FOG_WITHOUT_COLOR)
		UNITY_APPLY_FOG_COLOR(i.uv.z, outputColor.rgb, fixed4(0,0,0,0));
	#else
		UNITY_APPLY_FOG_COLOR(i.uv.z, outputColor.rgb, unity_FogColor);
	#endif

	return outputColor;
}

#endif // DEFINED_PREINTEGRATEDSKINSHADER_BASE