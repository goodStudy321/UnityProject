// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef DISSOLVE_STANDARD_CORE_INCLUDED
#define DISSOLVE_STANDARD_CORE_INCLUDED

#include "UnityCG.cginc"
#include "UnityStandardUtils.cginc"
#include "UnityStandardInput.cginc"
#include "UnityStandardCore.cginc"
#include "DissolveCoreFunctions.cginc"

half4 fragForwardBaseInternalDissolve (VertexOutputForwardBase i)
{
    FRAGMENT_SETUP(s)

    #if SHADER_TARGET >= 30
		s.diffColor = Dissolve(s.diffColor, i.tex.xy, s.oneMinusReflectivity);
	#endif

    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

    UnityLight mainLight = MainLight ();
    UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);

    half occlusion = Occlusion(i.tex.xy);
    UnityGI gi = FragmentGI (s, occlusion, i.ambientOrLightmapUV, atten, mainLight);

    half4 c = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);

	half3 emis = Emission(i.tex.xy);
	#if SHADER_TARGET >= 30
		emis = DissolveEmission(emis, i.tex.xy, s.diffColor);
	#endif

	c.rgb += emis;

    UNITY_APPLY_FOG(i.fogCoord, c.rgb);
    return OutputForward (c, s.alpha);
}

half4 fragForwardBaseDissolve (VertexOutputForwardBase i) : SV_Target	// backward compatibility (this used to be the fragment entry function)
{
	return fragForwardBaseInternalDissolve(i);
}

// Deferred Pass

void fragDeferredDissolve (
    VertexOutputDeferred i,
    out half4 outGBuffer0 : SV_Target0,
    out half4 outGBuffer1 : SV_Target1,
    out half4 outGBuffer2 : SV_Target2,
    out half4 outEmission : SV_Target3          // RT3: emission (rgb), --unused-- (a)
#if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
    ,out half4 outShadowMask : SV_Target4       // RT4: shadowmask (rgba)
#endif
)
{
    #if (SHADER_TARGET < 30)
        outGBuffer0 = 1;
        outGBuffer1 = 1;
        outGBuffer2 = 0;
        outEmission = 0;
        #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
            outShadowMask = 1;
        #endif
        return;
    #endif

    FRAGMENT_SETUP(s)

    // no analytic lights in this pass
    UnityLight dummyLight = DummyLight ();
    half atten = 1;

	#if SHADER_TARGET >= 30
		s.diffColor = Dissolve(s.diffColor, i.tex.xy, s.oneMinusReflectivity);
	#endif

    // only GI
    half occlusion = Occlusion(i.tex.xy);
#if UNITY_ENABLE_REFLECTION_BUFFERS
    bool sampleReflectionsInDeferred = false;
#else
    bool sampleReflectionsInDeferred = true;
#endif

    UnityGI gi = FragmentGI (s, occlusion, i.ambientOrLightmapUV, atten, dummyLight, sampleReflectionsInDeferred);

    half3 emissiveColor = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect).rgb;

	#if defined(_EMISSION) || defined(_DISSOLVEGLOW_ON) || defined(_EDGEGLOW_ON)
		half3 emis = Emission(i.tex.xy);
		#if SHADER_TARGET >= 30
			emis = DissolveEmission (emis, i.tex.xy, s.diffColor);
		#endif
		emissiveColor += emis;
	#endif

	#ifndef UNITY_HDR_ON
		emissiveColor.rgb = exp2(-emissiveColor.rgb);
	#endif

	UnityStandardData data;
	data.diffuseColor	= s.diffColor;
	data.occlusion		= occlusion;		
	data.specularColor	= s.specColor;
	data.smoothness		= s.smoothness;	
	data.normalWorld	= s.normalWorld;

	UnityStandardDataToGbuffer(data, outGBuffer0, outGBuffer1, outGBuffer2);

    // Emissive lighting buffer
    outEmission = half4(emissiveColor, 1);

    // Baked direct lighting occlusion if any
    #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
        outShadowMask = UnityGetRawBakedOcclusions(i.ambientOrLightmapUV.xy, IN_WORLDPOS(i));
    #endif
}

// ------------------------------------------------------------------
//  Additive forward pass (one light per pass)

half4 fragForwardAddInternalDissolve (VertexOutputForwardAdd i)
{
	FRAGMENT_SETUP_FWDADD(s)

	#if SHADER_TARGET >= 30
		s.diffColor = Dissolve(s.diffColor, i.tex.xy, s.oneMinusReflectivity);
	#endif

    UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld)
    UnityLight light = AdditiveLight (IN_LIGHTDIR_FWDADD(i), atten);
    UnityIndirect noIndirect = ZeroIndirect ();

    half4 c = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, light, noIndirect);

    UNITY_APPLY_FOG_COLOR(i.fogCoord, c.rgb, half4(0,0,0,0)); // fog towards black in additive pass
    return OutputForward (c, s.alpha);
}

half4 fragForwardAddDissolve (VertexOutputForwardAdd i) : SV_Target		// backward compatibility (this used to be the fragment entry function)
{
	return fragForwardAddInternal(i);
}

#endif // DISSOLVE_STANDARD_CORE_INCLUDED
