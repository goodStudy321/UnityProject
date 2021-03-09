// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef DISSOLVE_STANDARD_CORE_FORWARD_INCLUDED
#define DISSOLVE_STANDARD_CORE_FORWARD_INCLUDED

#if defined(UNITY_NO_FULL_STANDARD_SHADER)
#	define UNITY_STANDARD_SIMPLE 1
#endif

#include "UnityStandardConfig.cginc"

#if UNITY_STANDARD_SIMPLE
	#include "DissolveStandardCoreForwardSimple.cginc"
	VertexOutputBaseSimple vertBase (VertexInput v) { return vertForwardBaseSimple(v); }
	VertexOutputForwardAddSimple vertAdd (VertexInput v) { return vertForwardAddSimple(v); }
	half4 fragBase (VertexOutputBaseSimple i) : SV_Target { return fragForwardBaseSimpleInternalDissolve(i); }
	half4 fragAdd (VertexOutputForwardAddSimple i) : SV_Target { return fragForwardAddSimpleInternalDissolve(i); }
#else
	#include "DissolveStandardCore.cginc"
	VertexOutputForwardBase vertBase (VertexInput v) { return vertForwardBase(v); }
	VertexOutputForwardAdd vertAdd (VertexInput v) { return vertForwardAdd(v); }
	half4 fragBase (VertexOutputForwardBase i) : SV_Target { return fragForwardBaseInternalDissolve(i); }
	half4 fragAdd (VertexOutputForwardAdd i) : SV_Target { return fragForwardAddInternalDissolve(i); }
#endif

#endif // DISSOLVE_STANDARD_CORE_FORWARD_INCLUDED
