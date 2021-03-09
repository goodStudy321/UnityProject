// Upgrade NOTE: upgraded instancing buffer 'FoliageInstance' to new syntax.

// Detail bending

struct appdata_vertexlit {
	float4 vertex : POSITION;
	float4 tangent : TANGENT;
	float3 normal : NORMAL;
	float4 texcoord : TEXCOORD0;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2; // needed by GI
	fixed4 color : COLOR;
	//UNITY_VERTEX_INPUT_INSTANCE_ID
};


#if defined (VERTEXLIT)
	float _VertexLitLeafTurbulence;
	// Global Vars
	half _AfsVertexLitVariation;
	half _AfsVertexLitTranslucency;
	float4 _AfsWaveAndDistance; // From Grass Shader. Needed to fade out Details over distance.
#else
	float _LeafTurbulence;
#endif
fixed _BendingControls;

UNITY_INSTANCING_BUFFER_START (FoliageInstance)
	// UNITY_DEFINE_INSTANCED_PROP (float3, _AfsFoliageScale)
	#if defined(AFS_TOUCHBENDING)
        UNITY_DEFINE_INSTANCED_PROP (float4, _TouchBendingForce)
#define _TouchBendingForce_arr FoliageInstance
        UNITY_DEFINE_INSTANCED_PROP (float4x4, _RotMatrix)
#define _RotMatrix_arr FoliageInstance
    #endif
UNITY_INSTANCING_BUFFER_END(FoliageInstance)

// global vars
float 	_AfsFoliageWaveSize;
float 	_WindFrequency;
float4 	_AfsFoliageTimeFrequency; 				// x: time * frequency, y: time, zw: turbulence for 2nd bending
float4 	_AfsFoliageWind;
float4 	_AfsFoliageWindPulsMagnitudeFrequency;
float2 	_AfsFoliageWindMultiplier; 				// x: primary strength, y: secondary strength


#define WIND _AfsFoliageWind

///

void AfsAnimateVertex (inout float4 pos, inout float3 normal, float4 tangent, float3 pivot, float originalLength, float4 animParams, inout float variation)
{	
	// animParams.r = branch phase
	// animParams.g = edge flutter factor
	// animParams.b = primary factor
	// animParams.a = secondary factor

//	Preserve Length
	#if !defined(GEOM_TYPE_BRANCH)
		originalLength = length(pos.xyz);
	#endif
	float3 origPos = pos.xyz;
	float3 offset;

// 	All computation is done in worldspace
	#if !defined(VERTEXLIT)
		pos.xyz = mul(unity_ObjectToWorld, pos).xyz;
	#endif

//	based on original wind bending
	const float fDetailAmp = 0.1;
	const float fBranchAmp = 0.3;

	#if defined (VERTEXLIT)
		float3 wpos = pivot; // abs
	#else
		#if defined(GEOM_TYPE_BRANCH)
		//	combined mesh using baked pivots
			float3 wpos = pos.xyz + pivot.xyz; //abs
		#else
		//	instancing
			float3 wpos = float3(unity_ObjectToWorld[0].w, unity_ObjectToWorld[1].w, unity_ObjectToWorld[2].w); // abs
		#endif
	#endif

//	Phases (object, vertex, branch)
	#if defined(INSTANCING_ON) || defined(VERTEXLIT) || defined (INSTANCEDDEPTHPASSAFS)
		float3 variations = abs( frac( wpos.xyz * _AfsFoliageWaveSize /* * float3(443.8975,397.2973, 491.1871) */ ) - 0.5 );
		float fObjPhase = dot(variations, float3(1,1,1) ) + variation;
//	This would be OpenGL or DX9	
	#else
		// In order to handle dynamic batching...
		float fObjPhase = frac( (pos.x + pos.z) * _AfsFoliageWaveSize ) + variation;
	#endif

	float fObjPhase01 = 1.0 + (frac(fObjPhase) - 0.5) * 0.1;

//	Do not recalculate variation in VertexLit shader
	#if !defined(VERTEXLIT)
		#if defined(INSTANCING_ON)
			variation = saturate(fObjPhase * 0.6665);
		#else
			variation = saturate(fObjPhase);
		#endif
	#else
		fObjPhase *= 1.5;
	#endif

	fObjPhase *= 10;



	float fBranchPhase = fObjPhase.x + animParams.r;
	float fVtxPhase = dot(origPos, animParams.g + fBranchPhase);

//	Animate Wind – as we do not get per instance data we have to create variation within the shader
	float sinuswave = _Time.y * 0.5; //_SinTime.z; // _SinTime does not allow much difference between the instances

	// Seems to be ok to not use domainTime which would be: float sinuswave = _AfsTimeFrequency.x + fObjPhase;
//	float sinPulsObj = sinuswave + fObjPhase;
//	float4 TriangleWaves = SmoothTriangleWave(float4( sinPulsObj, fObjPhase + sinuswave * 0.8, 0.4 * (sinPulsObj), 0.0));	
//	float Oscillation = TriangleWaves.x + (TriangleWaves.y * TriangleWaves.z);
//	Oscillation = (Oscillation + 3.0) * 0.33;

	float4 TriangleWaves = SmoothTriangleWave( float4( fObjPhase + sinuswave, fObjPhase + sinuswave * 0.8 * fObjPhase01, 0.0, 0.0) );
	float Oscillation = (TriangleWaves.x + (TriangleWaves.y * TriangleWaves.y)) * 0.5; 

//	Now factor in wind pulse magnitude
	//WIND.xyzw = WIND.xyzw + float4(_AfsFoliageWindPulsMagnitudeFrequency.xyz, 0.25) * (1.0 + Oscillation * _AfsFoliageWindPulsMagnitudeFrequency.w) * 0.5;
	WIND.xyz = WIND.xyz + float4(_AfsFoliageWindPulsMagnitudeFrequency.xyz, 0.25) * (1.0 + Oscillation * _AfsFoliageWindPulsMagnitudeFrequency.w) * 0.5;

//	x is used for edges; y is used for branches
	float2 vWavesIn = _Time.yy + float2(fVtxPhase, fBranchPhase); // Seems to be ok to not use domainTime which would be: float2 vWavesIn = _AfsTimeFrequency.y + float2(fVtxPhase, fBranchPhase);

//	Calculate waves and factor in _LeafTurbulence
	#if defined (VERTEXLIT)
		float4 vWaves = (frac( vWavesIn.xxyy * (fObjPhase01) * float4(1.975, 0.793, lerp(float2(0.375, 0.193), _AfsFoliageTimeFrequency.zw, _VertexLitLeafTurbulence ) ) ) * 2.0 - 1.0);
	#else
		float4 vWaves = (frac( vWavesIn.xxyy * (fObjPhase01) * float4(1.975, 0.793, lerp(float2(0.375, 0.193), _AfsFoliageTimeFrequency.zw, _LeafTurbulence ) ) ) * 2.0 - 1.0);
	#endif
	vWaves = SmoothTriangleWave( vWaves );
	float2 vWavesSum = vWaves.xz + vWaves.yw;

//	Edge (xz) controlled by vertex green and branch bending (y) controled by vertex alpha
	float3 bend = animParams.g * fDetailAmp * normal.xyz * sign(normal.xyz); // sign important to match normals on double sided geometry
	bend.y = animParams.a * fBranchAmp;

//	Secondary bending and edge fluttering
	offset = ( (vWavesSum.xyx * bend) + ( WIND.xyz * vWavesSum.y * animParams.a) ) /* (1 + Oscillation) */ * WIND.w * _AfsFoliageWindMultiplier.y;

//	Primary bending / Displace position
	offset += animParams.b * Oscillation * WIND.xyz * _AfsFoliageWindMultiplier.x;

//	Apply Wind Animation	
	pos.xyz += offset;

//	Touch bending
	#if defined(AFS_TOUCHBENDING)
	//	Primary displacement by touch bending
		float4 TouchBendingForce = UNITY_ACCESS_INSTANCED_PROP(_TouchBendingForce_arr, _TouchBendingForce);
	//	Touch rotation
		if (TouchBendingForce.w != 0) {
			//float3 TouchBendingPosition = UNITY_ACCESS_INSTANCED_PROP(_TouchBendingPosition);
			float4x4 RotMatrix = UNITY_ACCESS_INSTANCED_PROP(_RotMatrix_arr, _RotMatrix);
			pos.xyz += animParams.a * TouchBendingForce.xyz * TouchBendingForce.w;
			pos.xyz = lerp( pos.xyz, mul(RotMatrix, float4(pos.xyz - wpos.xyz, 0)).xyz + wpos.xyz, animParams.b * 10 * (1 + animParams.r ) );
			#if !defined(UNITY_PASS_SHADOWCASTER)
				normal = lerp( normal , mul(RotMatrix, float4(normal, 0)).xyz, animParams.b * 10 * (1 + animParams.r ) );
			#endif
		}
	#endif

//	Bring pos back to local space
	#if !defined(VERTEXLIT)
		pos.xyz = mul( unity_WorldToObject, pos).xyz;
	#endif

//	Preserve length
	#if !defined(VERTEXLIT)
		#if defined(GEOM_TYPE_BRANCH)
			// combined & baked pivot
			float3 pivotPos = (origPos + pivot);
			float3 pivotToNewPos = normalize(pos.xyz - pivotPos);
			pos.xyz = pivotPos + pivotToNewPos * originalLength;
		#else
			#if defined(INSTANCING_ON) || defined (INSTANCEDDEPTHPASSAFS)
				// instancing | (combined & not baked pivots)
				pos.xyz = normalize(pos.xyz) * originalLength;
			#endif
		#endif
	#endif
}

void AfsFoligeBending_DepthNormal (inout appdata_full v)
{
	float4 bendingCoords;

	#if defined(VERTEXLIT)
		//	DX9 "changes" vertex colors... dx11 does not (last checked with Unity 5.4.0f3)
		#if (SHADER_API_D3D9)
			bendingCoords.xyzw = v.color.zyxx;
		#else
			#if defined(_LEGACYBENDING)
				bendingCoords.xyzw = v.color.rgbb;
			#else
				bendingCoords.xyzw = v.color.rgab;
				v.color.a = 1;
			#endif
		#endif
	#else
		bendingCoords.rg = v.color.rg;
	//	Legacy Bending:		Primary and secondary bending stored in vertex color blue
	//	New Bending:		Primary and secondary bending stored in uv4: x = primary bending / y = secondary
	//	VeretxColors Only: 	Primary in vertex color A, secondary bending in vertex color blue
		bendingCoords.ba = (_BendingControls == 2) ? v.color.ab : v.texcoord3.xy;
		bendingCoords.ba = (_BendingControls == 0) ? v.color.bb : bendingCoords.ba;
	#endif

	#if defined(VERTEXLIT)
		float2 variations =  abs ( frac(( v.texcoord1.xy) * _AfsVertexLitVariation) - 0.5);
		float variation = (variations.x + variations.y);
	#else
	//	Add variation only if the shader uses UV4
		float variation = (_BendingControls == 1) ? v.color.b * 2 : 0;
	#endif

	#if defined(VERTEXLIT)
		AfsAnimateVertex (v.vertex, v.normal, v.tangent, float3(v.texcoord2.x, 0, v.texcoord2.y) * _AfsVertexLitVariation, float(0), bendingCoords, variation);
		// From Grass Shader. Needed to fade out Details over distance.
		float3 offset = v.vertex.xyz - _WorldSpaceCameraPos;
		v.color.a = saturate (2 * (_AfsWaveAndDistance.w - dot (offset, offset)) * ( 0.85 /* was 1.0 */ / _AfsWaveAndDistance.w) );
	#else
	//	baked pivot
		#if defined(GEOM_TYPE_BRANCH)
			float2 pivotLength = (_BendingControls == 0) ? v.texcoord3.xy : v.texcoord3.zw;
			float3 normalToPivot = frac(pivotLength.xxx * float3(1.0, 256.0f, 65536.0f) );
			normalToPivot = normalToPivot * 2.0 - 1.0;
			float3 pivot = normalToPivot * pivotLength.y;
			float originalLength = pivotLength.y;
			AfsAnimateVertex (v.vertex, v.normal, v.tangent, pivot, originalLength, bendingCoords, variation);
		#else
			AfsAnimateVertex (v.vertex, v.normal, v.tangent, float3(0,0,0), 0.0f, bendingCoords, variation);
		#endif
	#endif

	v.normal = normalize(v.normal);
	v.tangent.xyz = normalize(v.tangent.xyz);
}