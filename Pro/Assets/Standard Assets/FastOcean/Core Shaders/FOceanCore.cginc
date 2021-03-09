#ifndef FASTOCEAN_CG_CORE
#define FASTOCEAN_CG_CORE

#include "FOceanCommon.cginc"

#if defined (FO_PROJECTED_ON)
half4 _FoCorners0;
half4 _FoCorners1;
half4 _FoCorners2;
half4 _FoCorners3;
float4 _FoCenter;
#endif

float4 _FoTime;
half4 _GAmplitude;
half4 _GDirectionAB;		
half4 _GDirectionCD;

half4 _GSteepnessAB;
half4 _GSteepnessCD;
half4 _GFreqAB;
half4 _GFreqCD;
half4 _GMFreqABCD;

#if defined (FO_FFTWAVES_ON)
sampler2D _OceanNMRT;
half _FoFFTTiling;
#else
// textures
sampler2D _OceanNM;

float4 _BumpTiling;// need float precision
float4 _BumpDirection;// need float precision
#endif

fixed4 _ExtinctColor;
half _ExtinctScale;
half _FoFade;
half _InvFoScale;
half _nSnell;
// fresnel, vertex & bump displacements & strength
float4 _DistortParams; // need float precision
half _FresnelScale;	

// textures
sampler2D _FresnelLookUp;
sampler2D _Reflection;

#if defined (FO_HQWAVES_ON)
sampler2D _ParallaxMap;
half _FoParallax1;
half _FoParallax2;
#endif

#if defined (FO_FOAM_ON)
sampler2D _FoamTex;
sampler2D _FoamMask;
sampler2D _FoamGradient;
half4 _FoamTime;

half _FoamGScale;
half _FoamMaskScale;

float4 _FoamTiling; // need float precision
float4 _FoamDirection; // need float precision
	
// foam
float4 _Foam;// need float precision
#endif

#if defined (FO_TRAIL_ON)
// trail
sampler2D _TrailMap;
float4 _TrailOffset;
half _TrailIntensity;
#endif

#if defined (FO_SHADOW_ON)
// trail
sampler2D _ShadowMap;
float4x4 _FoMatrixShadowMVP;
half4 _ShadowParams;
#endif

// edge & shore fading
#if defined (FO_DEPTHBLEND_ON)
half _AboveDepth;
#if defined (FO_UNDERWATER)
half _UnderDepth;	
#endif
half _ShallowDepth;	
sampler2D _Refraction;
#endif

#if defined (FO_UNDERWATER)
fixed4 _UnderAmbient;
#endif
// shortcuts
#define REFRACTION_DISTORTION _DistortParams.x
#define REFLECTION_DISTORTION _DistortParams.y
#define BUMP_POWER _DistortParams.z
#define BUMP_SHARPBIAS _DistortParams.w

#define VERTEX_WORLD_NORMAL i.normalInterpolator.xyz
#define VERTEX_WORLD_TAN i.tanInterpolator.xyz
#define VERTEX_WORLD_BIN i.binInterpolator.xyz

#if defined (FO_UNDERWATER)
#define WORLD_UP half3(0,-1,0)
#define WORLD_FORW half3(0,0,-1)
#define WORLD_BI half3(-1,0,0)
#else
#define WORLD_UP half3(0,1,0)
#define WORLD_FORW half3(0,0,1)
#define WORLD_BI half3(1,0,0)
#endif

#if defined (FO_PROJECTED_ON)
inline void FoProjInterpolate(inout half3 i)
{
	half v = i.x; 
	half _1_v = 1 - i.x; 
	half u = i.z; 
	half _1_u = 1 - i.z; 
	i.x = _1_v*(_1_u*_FoCorners0.x + u*_FoCorners1.x) + v*(_1_u*_FoCorners2.x + u*_FoCorners3.x); 
	i.y = _1_v*(_1_u*_FoCorners0.y + u*_FoCorners1.y) + v*(_1_u*_FoCorners2.y + u*_FoCorners3.y); 
	i.z = _1_v*(_1_u*_FoCorners0.z + u*_FoCorners1.z) + v*(_1_u*_FoCorners2.z + u*_FoCorners3.z); 
	half w = _1_v*(_1_u*_FoCorners0.w + u*_FoCorners1.w) + v*(_1_u*_FoCorners2.w + u*_FoCorners3.w); 
	half divide = 1.0f / w; 
	i.x *= divide; 
	i.y *= divide; 
	i.z *= divide;
}
#endif

inline half PhongSpecular(half3 V, half3 N)
{
	half3 h = reflect(_FoSunDir.xyz, N);
	half nh = max (0,dot(V, h));
	return max(0.0,pow (nh, _FoShininess)) * _FoSunInt;	
}

inline half FoGGXTerm (half NdotH, half roughness)
{
	half a = roughness * roughness;
	a *= a;
	//on some gpus need float precision
	float d = NdotH * NdotH * (a - 1.f) + 1.f;
	return a / (UNITY_PI * d * d + 1e-7f); 
}

inline half GGXNDFSpecular(half3 V, half3 N)
{	
	half3 h = normalize (-_FoSunDir.xyz + V);
	half nh = 1 - dot(N, h);
	return FoGGXTerm(nh, _FoShininess) * _FoSunInt;
}

inline half BlinnPhongSpecular(half3 V, half3 N)
{
	half3 h = normalize (-_FoSunDir.xyz + V);
	half nh = max (0,dot(N, h));
	return max(0.0,pow (nh, _FoShininess)) * _FoSunInt;	
}

inline half UnderWaterSpecular(half3 V, half3 N)
{
	half3 l = _FoSunDir.xyz;
	l.y = -l.y;
	half3 h = reflect(l, N);
	half nh = max (0,dot(V, h));
	return max(0.0,pow (nh, _FoShininess));	
}

inline half3 GerstnerOffset4 (float2 xzVtx) 
{
	half3 offsets;
	
	float4 dotABCD = float4(dot(_GDirectionAB.xy, xzVtx), dot(_GDirectionAB.zw, xzVtx), dot(_GDirectionCD.xy, xzVtx), dot(_GDirectionCD.zw, xzVtx));
	dotABCD += _FoTime;

	half4 COS = FoCos4 (dotABCD);
	half4 SIN = FoSin4 (dotABCD);
	
	//offsets.x = -dot(SIN, half4(_GSteepnessAB.xz, _GSteepnessCD.xz));
	//offsets.z = -dot(SIN, half4(_GSteepnessAB.yw, _GSteepnessCD.yw));

	offsets.x = dot(COS, half4(_GSteepnessAB.xz, _GSteepnessCD.xz));
	offsets.z = dot(COS, half4(_GSteepnessAB.yw, _GSteepnessCD.yw));
	offsets.y = dot(SIN, _GAmplitude);

	return offsets;			
}	
	
inline half3 GerstnerNormal4 (float2 xzVtx) 
{
	half3 nrml = WORLD_UP;
	
	float4 dotABCD = float4(dot(_GDirectionAB.xy, xzVtx), dot(_GDirectionAB.zw, xzVtx), dot(_GDirectionCD.xy, xzVtx), dot(_GDirectionCD.zw, xzVtx));
	dotABCD += _FoTime;

	half4 COS = FoCos4 (dotABCD);
	
	nrml.x -= dot(COS, half4(_GFreqAB.xz, _GFreqCD.xz));
	nrml.z -= dot(COS, half4(_GFreqAB.yw, _GFreqCD.yw));
	
	nrml = normalize (nrml);

	return nrml;			
}

inline void GerstnerNormalTangentBin4 (float2 xzVtx, out half3 nrml, out half3 tan, out half3 bin) 
{
    nrml = WORLD_UP;
	tan = WORLD_FORW;
	bin = WORLD_BI;

	float4 dotABCD = float4(dot(_GDirectionAB.xy, xzVtx), dot(_GDirectionAB.zw, xzVtx), dot(_GDirectionCD.xy, xzVtx), dot(_GDirectionCD.zw, xzVtx));
	dotABCD += _FoTime;

	half4 COS = FoCos4 (dotABCD);
	
	nrml.x -= dot(COS, half4(_GFreqAB.xz, _GFreqCD.xz));
	nrml.z -= dot(COS, half4(_GFreqAB.yw, _GFreqCD.yw));
	
	half4 SIN = FoSin4 (dotABCD);

	tan.x -= dot(SIN, _GMFreqABCD);
	tan.y -= nrml.z;
	
	bin.y -= nrml.x;
	bin.z = tan.x;

	nrml = normalize (nrml);
	tan = normalize (tan);
	bin = normalize (bin);
}

inline void GerstnerNormalTangent4 (float2 xzVtx, out half3 nrml, out half3 tan) 
{
    nrml = WORLD_UP;
	tan = WORLD_FORW;

	float4 dotABCD = float4(dot(_GDirectionAB.xy, xzVtx), dot(_GDirectionAB.zw, xzVtx), dot(_GDirectionCD.xy, xzVtx), dot(_GDirectionCD.zw, xzVtx));
	dotABCD += _FoTime;

	half4 COS = FoCos4 (dotABCD);
	
	nrml.x -= dot(COS, half4(_GFreqAB.xz, _GFreqCD.xz));
	nrml.z -= dot(COS, half4(_GFreqAB.yw, _GFreqCD.yw));
	
	half4 SIN = FoSin4 (dotABCD);

	tan.x -= dot(SIN, _GMFreqABCD);
	tan.y -= nrml.z;

	nrml = normalize (nrml);
	tan = normalize (tan);
}
	

inline void Gerstner (out half3 offs, out half3 nrml, out half3 tan, out half3 bin, float3 tileableVtx) 
{
	offs = GerstnerOffset4(tileableVtx.xz);
	GerstnerNormalTangentBin4(tileableVtx.xz + offs.xz, nrml, tan, bin);								
}

inline void Gerstner (out half3 offs, out half3 nrml, out half3 tan, float3 tileableVtx) 
{
	offs = GerstnerOffset4(tileableVtx.xz);
	GerstnerNormalTangent4(tileableVtx.xz + offs.xz, nrml, tan);								
}

inline void Gerstner (out half3 offs, out half3 nrml, float3 tileableVtx) 
{
	offs = GerstnerOffset4(tileableVtx.xz);
	nrml = GerstnerNormal4(tileableVtx.xz + offs.xz);								
}

inline void Gerstner (out half3 offs, float3 tileableVtx) 
{
	offs = GerstnerOffset4(tileableVtx.xz);						
}

inline float Fade(float3 d) 
{
	//on some gpus need float precision
	float _f = length(d) * _FoFade * _InvFoScale;
	return saturate(1 / exp2(_f));
}

inline half Fresnel(sampler2D fresnelLookUp, half NDotV)
{
	half costhetai = NDotV;
	return tex2D(fresnelLookUp, half2(costhetai, 0.0)).a;
}

inline half Fresnel(half NDotV)
{
	half facing = 1 - NDotV;
	return facing * facing;
}

#if defined (FO_HQWAVES_ON)
inline half3 PerPixelNormalTangentSpace(sampler2D bumpMap, float4 coords, half3x3 m, half bumpStrength) 
{
	fixed4 bump = tex2D(bumpMap, coords.xy) + tex2D(bumpMap, coords.zw);
	bump *= 0.5;
	half3 normal = UnpackNormal(bump);
	normal.xz = normal.xy * bumpStrength;
	normal.y = 1;

	return normalize(mul(normal, m));
} 

inline half3 FoParallaxViewDir(half3 viewDir)
{
	half3 v = viewDir;
	v.y += 0.42;
	return v;
}

inline half2 FoParallaxOffset(half h, half height, half3 v)
{
	h = (h - 0.5) * height;
	return h * (v.xz / v.y);
}

inline half3 PerPixelTangentSpaceParallax(sampler2D bumpMap, float4 coords, half3x3 m, half3 viewDir, half bumpStrength) 
{
	// inverse to tangent space
	viewDir = mul(m, viewDir);

	half h1 = tex2D (_ParallaxMap, coords.xy).w;
	half h2 = tex2D (_ParallaxMap, coords.zw).w;
	half3 v = FoParallaxViewDir(viewDir);
	half2 offset1 = FoParallaxOffset(h1, _FoParallax1, v);
	half2 offset2 = FoParallaxOffset(h2, _FoParallax2, v);

	fixed4 bump = tex2D(bumpMap, coords.xy + offset1) + tex2D(bumpMap, coords.zw + offset2);
	bump *= 0.5;
	half3 normal = UnpackNormal(bump);
	normal.xz = normal.xy * bumpStrength;
	normal.y = 1;

	return normalize(mul(normal, m));
} 
#endif

#if defined (FO_FFTWAVES_ON)
inline half3 PerPixelNormalTangentSpace(sampler2D bumpMap, float2 coords, half3x3 m, half bumpStrength) 
{
	half4 c = tex2D(bumpMap, coords);
	half3 normal = 1;
	normal.xz *= (c.xy + c.zw) * bumpStrength;

	return normalize(mul(normal, m));
}

inline half3 PerPixelNormalBump(sampler2D bumpMap, float2 coords, half3 vertexNormal, half bumpStrength) 
{
	half4 c = tex2D(bumpMap, coords);
	half3 normal = 1;
	normal.xy *= (c.xy + c.zw) * bumpStrength;
    normal = vertexNormal + normal.xxy * half3(1,0,1);
	return normalize(normal);
} 
#else
inline half3 PerPixelNormalBump(sampler2D bumpMap, float4 coords, half3 vertexNormal, half bumpStrength) 
{
	fixed4 bump = tex2D(bumpMap, coords.xy) + tex2D(bumpMap, coords.zw);
	bump *= 0.5;
	half3 normal = UnpackNormal(bump);
	normal.xy *= bumpStrength;
    normal = vertexNormal + normal.xxy * half3(1,0,1);
	return normalize(normal);
} 
#endif

#if defined (FO_FOAM_ON)

inline fixed4 Foam(float4 coords) 
{
	fixed4 foam = lerp(tex2D(_FoamTex, coords.xy), tex2D(_FoamTex,coords.zw), _FoamTime.y);
	return foam;
}

inline void FoWaveFoam(half Shape, fixed4 foam, float2 coords, inout fixed4 baseColor)
{ 
	half coverage = (exp2(_Foam.x * Shape) + _Foam.y) * tex2D(_FoamMask, coords * _FoamMaskScale);
	half4 baseFoam = saturate(foam * coverage);
	baseColor += baseFoam;
}

inline void FoShallowFoam(fixed4 foam, half depth, half2 coords, inout fixed4 shallowColor)
{
	float foamRange = saturate(_FoamGScale * depth);
	float2 gtex1 = float2(foamRange + _FoamTime.x, 0.5) + coords;
	float2 gtex2 = float2(foamRange - _FoamTime.x, 0.5) + coords;
	fixed4 foamGradient = saturate(_Foam.z * foam * lerp(tex2D(_FoamGradient, gtex1), tex2D(_FoamGradient, gtex2), _FoamTime.y));
	shallowColor *= 1 - foamGradient;
	shallowColor += foamGradient;
}
#endif

#if defined (FO_TRAIL_ON)
inline half4 FoTrailsFoam(float2 tileCoords, half4 spec, half4 foam)
{
	fixed4 trailsMask = tex2D(_TrailMap, tileCoords);
	return lerp(spec, foam * _TrailIntensity, trailsMask);
}

inline half FoTrailsMask(float2 tileCoords, half4 spec)
{
	fixed4 trailsMask = tex2D(_TrailMap, tileCoords);
	return lerp(spec, trailsMask * _TrailIntensity, trailsMask);
}

inline half FoTrailsMaskLuminance(float2 tileCoords, half spec)
{
	fixed4 trailsMask = tex2D(_TrailMap, tileCoords);
	return lerp(spec, 0, saturate(trailsMask.r + trailsMask.g + trailsMask.b)); // dot 1
}
#endif

#define FO_TANGENTSPACE \
	half3x3 m; \
    m[0] = VERTEX_WORLD_BIN; \
    m[1] = VERTEX_WORLD_NORMAL; \
    m[2] = VERTEX_WORLD_TAN; \

#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
#if (SHADER_TARGET < 30) || defined(SHADER_API_MOBILE)
// mobile or SM2.0: calculate fog factor per-vertex
#define FO_TRANSFER_FOG(o,outpos) UNITY_CALC_FOG_FACTOR((outpos).z); o.screenPos.z = unityFogFactor
#else
// SM3.0 and PC/console: calculate fog distance per-vertex, and fog factor per-pixel
#define FO_TRANSFER_FOG(o,outpos) o.screenPos.z = (outpos).z
#endif
#else
#define FO_TRANSFER_FOG(o,outpos)
#endif

#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
#if (SHADER_TARGET < 30) || defined(SHADER_API_MOBILE)
// mobile or SM2.0: fog factor was already calculated per-vertex, so just lerp the color
#define FO_APPLY_FOG_COLOR(coord,col,fogCol) UNITY_FOG_LERP_COLOR(col,fogCol,coord.z)
#else
// SM3.0 and PC/console: calculate fog factor and lerp fog color
#define FO_APPLY_FOG_COLOR(coord,col,fogCol) UNITY_CALC_FOG_FACTOR(coord.z); UNITY_FOG_LERP_COLOR(col,fogCol,unityFogFactor)
#endif
#else
#define FO_APPLY_FOG_COLOR(coord,col,fogCol)
#endif

#ifdef UNITY_PASS_FORWARDADD
#define FO_APPLY_FOG(coord,col) FO_APPLY_FOG_COLOR(coord,col,fixed4(0,0,0,0))
#else
#define FO_APPLY_FOG(coord,col) FO_APPLY_FOG_COLOR(coord,col,unity_FogColor)
#endif

#ifdef FO_SHADOW_ON
inline float4 FoShadowScreenPos(float4 pos) {
	float4 o = pos * 0.5;
	o.xy += o.w;
	o.zw = pos.zw;
	return o;
}

inline half FoProjectShadow(float4 shadowCoords, half fade)
{
	half shadowDepth = tex2D(_ShadowMap, shadowCoords.xy).r;

#if defined(UNITY_REVERSED_Z)
	half shadowDistance = shadowDepth - shadowCoords.z;
#else
	half shadowDistance = shadowCoords.z - shadowDepth;
#endif
	shadowDepth = step(1, shadowDepth) + step(shadowDistance, 0);
	return saturate(lerp(saturate(_ShadowParams.x + max(_ShadowParams.y * shadowDistance, 1 - fade)), 1, shadowDepth));
}

#endif

inline fixed4 ExtinctColor (fixed4 baseColor, half top, half extinctionAmount) 
{
	// tweak the extinction coefficient for different coloring
	 return baseColor + top * _ExtinctColor * extinctionAmount;
}


#endif
