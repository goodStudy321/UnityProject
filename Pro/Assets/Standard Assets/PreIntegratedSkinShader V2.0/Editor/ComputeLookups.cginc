#ifndef MAXITERATIONS
	#define MAXITERATIONS 255
#endif

#include "../PreIntegratedSkinShaderCommon.cginc"

half4 _PSSProfileHigh_weighths1_var1;
half4 _PSSProfileHigh_weighths2_var2;
half4 _PSSProfileHigh_weighths3_var3;
half4 _PSSProfileHigh_weighths4_var4;
half4 _PSSProfileHigh_weighths5_var5;
half4 _PSSProfileHigh_weighths6_var6;

#define PSS_PROFILE_WEIGHTS_1 _PSSProfileHigh_weighths1_var1.xyz
#define PSS_PROFILE_WEIGHTS_2 _PSSProfileHigh_weighths2_var2.xyz
#define PSS_PROFILE_WEIGHTS_3 _PSSProfileHigh_weighths3_var3.xyz
#define PSS_PROFILE_WEIGHTS_4 _PSSProfileHigh_weighths4_var4.xyz
#define PSS_PROFILE_WEIGHTS_5 _PSSProfileHigh_weighths5_var5.xyz
#define PSS_PROFILE_WEIGHTS_6 _PSSProfileHigh_weighths6_var6.xyz

#define PSS_PROFILE_VARIANCE_1 _PSSProfileHigh_weighths1_var1.w
#define PSS_PROFILE_VARIANCE_2 _PSSProfileHigh_weighths2_var2.w
#define PSS_PROFILE_VARIANCE_3 _PSSProfileHigh_weighths3_var3.w
#define PSS_PROFILE_VARIANCE_4 _PSSProfileHigh_weighths4_var4.w
#define PSS_PROFILE_VARIANCE_5 _PSSProfileHigh_weighths5_var5.w
#define PSS_PROFILE_VARIANCE_6 _PSSProfileHigh_weighths6_var6.w

int _TextureWidth;
int _TextureHeight;

int _MipLevel;
int _MipCount;
float _MipLevelNormalized;

// Parts of code originally from GPU Pro book (based on ), but actually taken from a gamasutra article.
float Gaussian (float v, float r) {
	return 1.0 / sqrt(2.0 * PSS_PI * v) * exp(-(r * r) / (2.0 * v));
}

float3 Scatter(float r) {
	return
		  Gaussian(PSS_PROFILE_VARIANCE_1 * 1.414, r) * PSS_PROFILE_WEIGHTS_1.rgb
		+ Gaussian(PSS_PROFILE_VARIANCE_2 * 1.414, r) * PSS_PROFILE_WEIGHTS_2.rgb
		+ Gaussian(PSS_PROFILE_VARIANCE_3 * 1.414, r) * PSS_PROFILE_WEIGHTS_3.rgb
		+ Gaussian(PSS_PROFILE_VARIANCE_4 * 1.414, r) * PSS_PROFILE_WEIGHTS_4.rgb
		+ Gaussian(PSS_PROFILE_VARIANCE_5 * 1.414, r) * PSS_PROFILE_WEIGHTS_5.rgb
		+ Gaussian(PSS_PROFILE_VARIANCE_6 * 1.414, r) * PSS_PROFILE_WEIGHTS_6.rgb;
}

///// <summary>
///// Integrate the GGX specular BRDF component over the hemisphere
///// </summary>
///// <returns>integrated sum over hemisphere</returns>
///// <param name="costheta">Costheta - N.L</param>
///// <param name="m">m - roughness</param>
///// <param name="F0">F0 - fresnel value</param>
//float IntegrateGGX(float costheta, float m, float F0) {
//	int numterms = sqrt(MAXITERATIONS) - 1;
//	
//	float incr1 = PSS_PI*2.0 / (float)numterms;
//	float incr2 = PSS_PI/2.0 / (float)numterms;
//	
//	float sum = 0.0;  
//	float3 N = float3(0.0, 0.0, 1.0);
//	float3 V = float3(0.0, sqrt(1.0 - costheta*costheta), costheta);
//	for (int i = 0; i < numterms; i++) {
//		float phip = (float)i / (float)(numterms - 1) * 2.0 * PSS_PI;  
//		float localsum = 0.0;
//		float cosp = cos(phip);
//		float sinp = sin(phip);
//		for (int j = 0; j < numterms; j++) {
//			float thetap = (float)j / (float)(numterms - 1) * PSS_PI / 2.0;
//			float sint = sin(thetap);
//			float cost = cos(thetap);
//			float3 L = float3(sinp * sint, cosp * sint, cost);
//			localsum += GGXSpecular(N, V, L, m, F0) * sint;
//
//		}  
//		sum += localsum * (PSS_PI/ 2.0) / (float)numterms;
//	}  
//	return sum * (2.0 * PSS_PI) / (float)numterms;
//}

// Translucency function based on <<Real-Time Realistic Skin Translucency>> paper by Jorge Jimenez, David Whelan,
// Veronica Sundstedt and Diego Gutierrez. See http://www.iryoku.com/translucency/
// Values from "Separable SSS" (MIT licensed)
float3 TranslucencyProfile(float depth) {
	float dd = -depth*depth;
	return
		  exp(dd / PSS_PROFILE_VARIANCE_1) * PSS_PROFILE_WEIGHTS_1.rgb
		+ exp(dd / PSS_PROFILE_VARIANCE_2) * PSS_PROFILE_WEIGHTS_2.rgb
		+ exp(dd / PSS_PROFILE_VARIANCE_3) * PSS_PROFILE_WEIGHTS_3.rgb
		+ exp(dd / PSS_PROFILE_VARIANCE_4) * PSS_PROFILE_WEIGHTS_4.rgb
		+ exp(dd / PSS_PROFILE_VARIANCE_5) * PSS_PROFILE_WEIGHTS_5.rgb
		+ exp(dd / PSS_PROFILE_VARIANCE_6) * PSS_PROFILE_WEIGHTS_6.rgb;
}

//float4 lookupGGXEnergy_NdotL_m(float2 uv) {
//	// FIXME need to split integral
//	float F0 = 0.028;
//	float cosTheta = saturate(uv.x)*2.0-1.0;
//	float roughness = max(0.01, saturate(uv.y));
//	float4 specularEnergy;
//	specularEnergy.x = IntegrateGGX(cosTheta, roughness, F0);
//	return specularEnergy;
//}

/*
 * Originally from GPU Pro book, but taken from gamasutra article.
 * NB: this is not supposed to run in the final shader, unless I manage
 * to approximate it well with curve fitting and get rid of lookup textures
 * at least on modern hardware.
 */
float IntegrateDiffuseScatteringOnRingComponent(float cosTheta, float scattering, float penumbraWidth, float penumbraLocation, int numTerms) {
//	float theta = acos(cosTheta);
//	float totalWeights = 0;
//	float totalLight = 0;
//
//	for (float a=-PSS_PI/2.0; a<=PSS_PI/2.0; a+=0.001) {
//		float sampleAngle = theta + a;
//		float diffuse = max(0.0, cos(sampleAngle));
//
//		// Distance
//		float sampleDist = abs(2.0 * skinRadius * sin(a * 0.5));
//
//		// Profile Weight
//		float weights = Gaussian(variance * 1.414, sampleDist);
//
//		totalWeights += weights;
//		totalLight += diffuse * weights;
//	}
//
//	return totalLight / totalWeights;

	float diffuseScattering;

	float theta = acos(cosTheta);
	float totalWeights = 0;
	float totalLight = 0;
	
	float incr = PSS_PI / numTerms;
	
	float c = scattering*scattering;

	for (float a=-PSS_PI/2.0; a<=PSS_PI/2.0; a+=incr) {
		float sampleAngle = theta + a;
		float diffuse = max(0.0, cos(sampleAngle));
		
		float light = saturate(newPenumbra(penumbraLocation + abs(a*0.5)/penumbraWidth));

		// Profile Weight
		float weights = exp(-pow(abs(sin(a * 0.5)),2) * c);

		totalWeights += weights;
		totalLight += light * diffuse * weights;
	}

	diffuseScattering = totalLight / totalWeights;
	
	return diffuseScattering;
}

//float3 IntegrateDiffuseScatteringOnRing(float cosTheta, float skinRadius) {
//	// Originally was done in one loop, like in the code commented out below.
//	//	float theta = acos(cosTheta);
//	//	float3 totalWeights = 0;
//	//	float3 totalLight = 0;
//	//
//	//	for (float a=-PSS_PI/2.0; a<=PSS_PI/2.0; a+=0.001) {
//	//		float sampleAngle = theta + a;
//	//		float diffuse = max(0.0, cos(sampleAngle));
//	//
//	//		// Distance
//	//		float sampleDist = abs(2.0 * skinRadius * sin(a * 0.5));
//	//
//	//		// Profile Weight
//	//		float3 weights = Scatter(sampleDist);
//	//
//	//		totalWeights += weights;
//	//		totalLight += diffuse * weights;
//	//	}
//	//
//	//	return totalLight / totalWeights;
//
//	float3 result = 0;
//	result.rgb += IntegrateDiffuseScatteringOnRingComponent(cosTheta, skinRadius, _ScatteringProfile6_1.a) * _ScatteringProfile6_1.rgb;
//	result.rgb += IntegrateDiffuseScatteringOnRingComponent(cosTheta, skinRadius, _ScatteringProfile6_2.a) * _ScatteringProfile6_2.rgb;
//	result.rgb += IntegrateDiffuseScatteringOnRingComponent(cosTheta, skinRadius, _ScatteringProfile6_3.a) * _ScatteringProfile6_3.rgb;
//	result.rgb += IntegrateDiffuseScatteringOnRingComponent(cosTheta, skinRadius, _ScatteringProfile6_4.a) * _ScatteringProfile6_4.rgb;
//	result.rgb += IntegrateDiffuseScatteringOnRingComponent(cosTheta, skinRadius, _ScatteringProfile6_5.a) * _ScatteringProfile6_5.rgb;
//	result.rgb += IntegrateDiffuseScatteringOnRingComponent(cosTheta, skinRadius, _ScatteringProfile6_6.a) * _ScatteringProfile6_6.rgb;
//	return result;
//}

/// Integrate the GGX specular BRDF component over the hemisphere
float IntegrateGGX(float costheta, float m, float F0) {
	//int numterms = sqrt(MAXITERATIONS) - 1;
	int numterms = 80;
	
	float incr1 = PSS_PI*2.0 / (float)numterms;
	float incr2 = PSS_PI/2.0 / (float)numterms;
	
	float sum = 0.0;  
	float3 N = float3(0.0, 0.0, 1.0);
	float3 V = float3(0.0, sqrt(1.0 - costheta*costheta), costheta);
	PSS_LOOP
	for (int i = 0; i < numterms; i++) {
		float phip = (float)i / (float)(numterms - 1) * 2.0 * PSS_PI;  
		float localsum = 0.0;
		float cosp = cos(phip);
		float sinp = sin(phip);
		PSS_LOOP
		for (int j = 0; j < numterms; j++) {
			float thetap = (float)j / (float)(numterms - 1) * PSS_PI / 2.0;
			float sint = sin(thetap);
			float cost = cos(thetap);
			float3 L = float3(sinp * sint, cosp * sint, cost);
//			localsum += GGXSpecular(N, V, L, m, F0) * sint;
// 			localsum += max(0.0, GGXSpecularRef(N, V, L, m, F0) * sint* sinp);
			localsum += max(0.0, GGXSpecularRef(N, V, L, m, F0) * sint);

		}
// 		localsum = max(0, localsum*sinp);
		sum += localsum * (PSS_PI/ 2.0) / (float)numterms;
	}  
	return sum * (2.0 * PSS_PI) / (float)numterms;
}
