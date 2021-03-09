// Upgrade NOTE: upgraded instancing buffer 'Trees' to new syntax.


#ifndef AFS_BUILTIN_5X_TREE_LIBRARY_INCLUDED
#define AFS_BUILTIN_5X_TREE_LIBRARY_INCLUDED

// Shared tree shader functionality

#include "UnityCG.cginc"
#include "Lighting.cginc"
//#include "TerrainEngine.cginc"

#define halfPI 1.5707963267949

fixed4 _Color;
float4 _AfsTerrainTrees;
float2 _AfsTreeWindMuliplier;
float4 _AfsBillboardCameraForward;
float _AfsXtraBending;
float4 _AfsWetnessTree;

#if defined (LEAFTUMBLING)
	float _TumbleStrength;
	float _TumbleFrequency;
#endif

// ---- From terrainengine.cginc

UNITY_INSTANCING_BUFFER_START (Trees)
    //UNITY_DEFINE_INSTANCED_PROP (float4, _Color)
	UNITY_DEFINE_INSTANCED_PROP(float4, _Wind)
#define _Wind_arr Trees
	UNITY_DEFINE_INSTANCED_PROP(fixed4, _TreeInstanceColor)
#define _TreeInstanceColor_arr Trees
	UNITY_DEFINE_INSTANCED_PROP(float4, _TreeInstanceScale)
#define _TreeInstanceScale_arr Trees
	UNITY_DEFINE_INSTANCED_PROP(float4, _SquashPlaneNormal)
#define _SquashPlaneNormal_arr Trees
	UNITY_DEFINE_INSTANCED_PROP(float, _SquashAmount)
#define _SquashAmount_arr Trees
	#if defined (FOLIAGEASTREE)
		UNITY_DEFINE_INSTANCED_PROP(fixed, _BendingControls)
#define _BendingControls_arr Trees
	#endif
UNITY_INSTANCING_BUFFER_END(Trees)


// Expand billboard and modify normal + tangent to fit
inline void ExpandBillboard (in float4x4 mat, inout float4 pos, inout float3 normal, inout float4 tangent)
{
	// tangent.w = 0 if this is a billboard
	float isBillboard = 1.0f - abs(tangent.w);
	
	// billboard normal
	float3 norb = normalize(mul(float4(normal, 0), mat)).xyz;
	
	// billboard tangent
	float3 tanb = normalize(mul(float4(tangent.xyz, 0.0f), mat)).xyz;
	
	pos += mul(float4(normal.xy, 0, 0), mat) * isBillboard;
	normal = lerp(normal, norb, isBillboard);
	tangent = lerp(tangent, float4(tanb, -1.0f), isBillboard);
}

float4 SmoothCurve( float4 x ) {   
	return x * x *( 3.0 - 2.0 * x );   
}
float4 TriangleWave( float4 x ) {   
	return abs( frac( x + 0.5 ) * 2.0 - 1.0 );   
}
float4 SmoothTriangleWave( float4 x ) {   
	return SmoothCurve( TriangleWave( x ) );   
}

// ---- end terrainengine.cginc


float4 AfsSmoothTriangleWave( float4 x ) {   
	return (SmoothCurve( TriangleWave( x )) - 0.5) * 2.0;   
}

// see http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
float3x3 AfsRotationMatrix(float3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return float3x3	(	oc * axis.x * axis.x + c,			oc * axis.x * axis.y - axis.z * s,	oc * axis.z * axis.x + axis.y * s,
                		oc * axis.x * axis.y + axis.z * s,	oc * axis.y * axis.y + c,			oc * axis.y * axis.z - axis.x * s,
                		oc * axis.z * axis.x - axis.y * s,	oc * axis.y * axis.z + axis.x * s,	oc * axis.z * axis.z + c);   
}

// taken from afs3
inline float4 AfsSquashNew(in float4 pos, float SquashNew)
{
	float3 planeNormal = UNITY_ACCESS_INSTANCED_PROP(_SquashPlaneNormal_arr, _SquashPlaneNormal).xyz;
	float3 projectedVertex = pos.xyz - (dot(planeNormal, pos.xyz) + UNITY_ACCESS_INSTANCED_PROP(_SquashPlaneNormal_arr, _SquashPlaneNormal).w) * planeNormal + _AfsBillboardCameraForward.xyz * halfPI * pos.y;
	pos = float4(lerp(projectedVertex, pos.xyz, max(0.05f, SquashNew)), 1.0f);
	return pos;
}

inline float3 AfsSquashNormal(in float3 normal, float SquashNew)
{
	float3 planeNormal = UNITY_ACCESS_INSTANCED_PROP(_SquashPlaneNormal_arr, _SquashPlaneNormal).xyz;
	float3 projectedVertex = normal.xyz - (dot(planeNormal, normal.xyz) + UNITY_ACCESS_INSTANCED_PROP(_SquashPlaneNormal_arr, _SquashPlaneNormal).w) * planeNormal + _AfsBillboardCameraForward.xyz * halfPI * normal.y;
	normal = float3(lerp(projectedVertex, normal.xyz, max(0.05f, SquashNew)));
	return normal;
}

// Detail bending
// pos.w = per leaf tumble strength
inline float4 afsAnimateVertex(float4 pos, float4 normal_fOsc, float4 animParams, float4 i_pivot_fade)
{	

	// animParams.x = branch phase
	// animParams.y = edge flutter factor
	// animParams.z = primary factor
	// animParams.w = secondary factor

	#define branchOrigin i_pivot_fade.xyz
	#define vertexnormal normal_fOsc.xyz
	#define Oscillation normal_fOsc.w
	#define tumbleStrength pos.w

//	Adjust and fade in wind
	float SquashTwo = i_pivot_fade.w; // * i_TreeWorldPos.w; //_SquashAmount * _SquashAmount;

	float4 Wind = UNITY_ACCESS_INSTANCED_PROP (_Wind_arr, _Wind);
	Wind.w *= _AfsTreeWindMuliplier.y; 
	Wind.xyz = (Wind.xyz * Oscillation);
	Wind *= SquashTwo;

	float fDetailAmp = 0.1f;
	float fBranchAmp = 0.3f;
	
	// Phases (object, vertex, branch)
	float fObjPhase = dot(unity_ObjectToWorld[3].xyz, 1);
	float fBranchPhase = fObjPhase + animParams.x;
	float fVtxPhase = dot(pos.xyz, animParams.y + fBranchPhase);
	
	// x is used for edges; y is used for branches
	float2 vWavesIn = _Time.yy + float2(fVtxPhase, fBranchPhase );
	// 1.975, 0.793, 0.375, 0.193 are good frequencies
	float4 vWaves = (frac( vWavesIn.xxyy * float4(1.975, 0.793, 0.375, 0.193) ) * 2.0 - 1.0);
	vWaves = SmoothTriangleWave( vWaves );
	float2 vWavesSum = vWaves.xz + vWaves.yw;

//	Tumbling / Should be done before all other deformations
	#if defined (LEAFTUMBLING)
		float absWindStrength = length(Wind.xyz);
		if(_TumbleStrength > 0 && tumbleStrength > 0 && absWindStrength > 0) {
			// Wind.w is turbulence
			// Move point to 0,0,0
			pos.xyz -= branchOrigin;
			// Add variance to the different leaf planes
			float3 fracs = frac( branchOrigin * 33.3 );
	 		float offset = fracs.x + fracs.y + fracs.z;
			float tFrequency = _TumbleFrequency * _Time.y;

			float4 vWaves1 = SmoothTriangleWave( float4( (tFrequency + offset) * (1.0 + offset * 0.25), tFrequency * 0.75 + offset, tFrequency * 0.5 + offset, tFrequency * 1.5 + offset));
			float3 windDir = normalize (Wind.xyz);
			//float3 windTangent = cross(float3(0,1,0), Wind.xyz);
			float3 windTangent = float3(-windDir.z, windDir.y, windDir.x);
			float twigPhase = vWaves1.x + vWaves1.y + (vWaves1.z * vWaves1.z);
			float facingWind = (dot(normalize(float3(pos.x, 0, pos.z)), windDir));
			float windStrength = dot(abs(Wind.xyz), 1) * pos.w * (1.35 - facingWind) * Wind.w + absWindStrength; // Use abs(_Wind)!!!!!!
			pos.xyz = mul(AfsRotationMatrix(windTangent, windStrength * (twigPhase + fBranchPhase * 0.1) * _TumbleStrength * tumbleStrength * SquashTwo ), pos.xyz);
			// Move point back to origin
			pos.xyz += branchOrigin;
		}
	#endif


//	Preserve Length
	float origLength = length(pos.xyz);

	// Edge (xz) and branch bending (y)
	float3 bend = animParams.y * fDetailAmp * vertexnormal * sign(vertexnormal);

	#if defined (XLEAFBENDING)
		// As bark might be effected too we should simplify it
		// bend.y = (animParams.w + animParams.y * _AfsXtraBending) * (fBranchAmp * ( (vWaves.y - vWaves.z) * 0.5 * frac( (pos.x + pos.z)) ) );
		bend.y = (animParams.w + animParams.y * _AfsXtraBending) * fBranchAmp;
	#else
		bend.y = animParams.w * fBranchAmp;
	#endif
//	Apply secondary bending and edge fluttering
	pos.xyz += ((vWavesSum.xyx * bend) + (Wind.xyz * vWavesSum.y * animParams.w)) * Wind.w;

//	Primary bending / Displace position
	pos.xyz += animParams.z * Wind.xyz * _AfsTreeWindMuliplier.x;

//	Preserve Length
	pos.xyz = normalize(pos.xyz) * origLength;
	
	return pos;
}

#if defined(SURFACESHADER)
void AfsTreeVertBark_Surface (inout appdata_full v, out Input o)
{
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_OUTPUT(Input,o);
	o.AFSuv_MainTex.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
#else
void AfsTreeVertBark_DepthNormal (inout appdata_full v)
{
#endif
	float4 TreeWorldPos = float4(unity_ObjectToWorld[0].w, unity_ObjectToWorld[1].w, unity_ObjectToWorld[2].w, 0);
	float Distance = distance(_WorldSpaceCameraPos.xyz, TreeWorldPos.xyz);
	float fadeState = saturate( ( _AfsTerrainTrees.x - Distance ) / _AfsTerrainTrees.y );
	TreeWorldPos.w = clamp(fadeState * UNITY_ACCESS_INSTANCED_PROP(_SquashAmount_arr, _SquashAmount), 0.0, 1.0);
//	Scale
	v.vertex.xyz *= UNITY_ACCESS_INSTANCED_PROP(_TreeInstanceScale_arr, _TreeInstanceScale).xyz;
//	Add extra animation to make it fit speedtree
	TreeWorldPos.xyz = abs(TreeWorldPos.xyz);
	float sinuswave = _SinTime.z;
//float4 vOscillations = AfsSmoothTriangleWave(float4(TreeWorldPos.x + sinuswave , TreeWorldPos.z + sinuswave * 0.8, 0.0, 0.0));
	//float fOsc = vOscillations.x + (vOscillations.y * vOscillations.y);
	//fOsc = (fOsc + 3.0) * 0.33;
	// float offset = frac(dot(TreeWorldPos.x, TreeWorldPos.z)); // looks quite ok
	float offset = abs(frac((TreeWorldPos.x + TreeWorldPos.z) * 5) - 0.5) * 2; 
	float4 vOscillations = AfsSmoothTriangleWave(float4(offset + sinuswave , offset + sinuswave * 0.8, 0.4 * (sinuswave + offset), 0));
	//vOscillations.z *= sign(vOscillations.z);
	float fOsc = vOscillations.x + (vOscillations.y * vOscillations.z);
	fOsc = (fOsc + 3.0) * 0.33;
//	Apply Wind	
	v.vertex = afsAnimateVertex( float4(v.vertex.xyz, v.color.b), float4(v.normal.xyz,fOsc), float4(v.color.xy, v.texcoord1.xy), float4(0,0,0, TreeWorldPos.w) );
	v.vertex = AfsSquashNew(v.vertex, TreeWorldPos.w);
	v.normal = normalize(v.normal);
	v.tangent.xyz = normalize(v.tangent.xyz);

//	Store fadestate (delayed)
	//fadeState = saturate( ( _AfsTerrainTrees.x - _AfsTerrainTrees.y * 2 - Distance ) / _AfsTerrainTrees.y );
	fadeState = saturate( ( _AfsTerrainTrees.x - _AfsTerrainTrees.y - Distance) / (_AfsTerrainTrees.y)); // * 0.5) );
	float shadowState = clamp(fadeState * UNITY_ACCESS_INSTANCED_PROP(_SquashAmount_arr, _SquashAmount), 0.0, 1.0);

	#if defined(SURFACESHADER)
		o.AFSuv_MainTex.w = shadowState;
	//	Apply tree color
		v.color.rgb = lerp(_AfsTreeColor, 1.0, UNITY_ACCESS_INSTANCED_PROP(_TreeInstanceColor_arr, _TreeInstanceColor).g); // * _Color.rgb;
		o.AFSuv_MainTex.z = TreeWorldPos.w;
	//	Setup wetness
		o.Wetness.xy = saturate( (_AfsWetnessTree.zw - max(half2(0,0), v.vertex.yy)) / _AfsWetnessTree.zw ) ;
	#else	
		v.color.r = shadowState;
	#endif
}

void AfsTreeVertLeaf_DepthNormal (inout appdata_full v)
{
	float4 TreeWorldPos = float4(unity_ObjectToWorld[0].w, unity_ObjectToWorld[1].w, unity_ObjectToWorld[2].w, 0);
	float Distance = distance(_WorldSpaceCameraPos.xyz, TreeWorldPos.xyz);
	float fadeState = saturate( ( _AfsTerrainTrees.x - Distance) / _AfsTerrainTrees.y );

	// test
	float shadowState = saturate( ( _AfsTerrainTrees.x - _AfsTerrainTrees.y - Distance) / (_AfsTerrainTrees.y)); // * 0.5) );
	shadowState = clamp(shadowState * UNITY_ACCESS_INSTANCED_PROP(_SquashAmount_arr, _SquashAmount), 0.0, 1.0);

	//bool CameraIsRenderingDepth = dot(unity_LightShadowBias,1) == 0.0; 
	//if(!CameraIsRenderingDepth) {
	if(unity_LightShadowBias.z != 0.0) {
		if(shadowState < 0.05) {
			v.vertex.y += 10000;
			return;
		}
	}

	TreeWorldPos.w = clamp(fadeState * UNITY_ACCESS_INSTANCED_PROP(_SquashAmount_arr, _SquashAmount), 0.0, 1.0);
//	Depricated:
//	ExpandBillboard (UNITY_MATRIX_IT_MV, v.vertex, v.normal, v.tangent);

//	Scale
	v.vertex.xyz *= UNITY_ACCESS_INSTANCED_PROP(_TreeInstanceScale_arr, _TreeInstanceScale).xyz;
//	Decode UV3
	float3 pivot;
	#if defined(LEAFTUMBLING)
		// 15bit compression 2 components only, important: sign of y
		pivot.xz = (frac(float2(1.0f, 32768.0f) * v.texcoord2.xx) * 2) - 1;
		pivot.y = sqrt(1 - saturate(dot(pivot.xz, pivot.xz)));
		pivot *= v.texcoord2.y;
		pivot *= UNITY_ACCESS_INSTANCED_PROP(_TreeInstanceScale_arr, _TreeInstanceScale).xyz;
	#endif
//	Add extra animation to make it fit speedtree
	TreeWorldPos.xyz = abs(TreeWorldPos.xyz);
	float sinuswave = _SinTime.z;
	//float4 vOscillations = AfsSmoothTriangleWave(float4(TreeWorldPos.x + sinuswave , TreeWorldPos.z + sinuswave * 0.8, 0.0, 0.0));
	//float fOsc = vOscillations.x + (vOscillations.y * vOscillations.y);
	//fOsc = (fOsc + 3.0) * 0.33;
	// float offset = frac(dot(TreeWorldPos.x, TreeWorldPos.z)); // looks quite ok
	float offset = abs(frac((TreeWorldPos.x + TreeWorldPos.z) * 5) - 0.5) * 2; 
	float4 vOscillations = AfsSmoothTriangleWave(float4(offset + sinuswave , offset + sinuswave * 0.8, 0.4 * (sinuswave + offset), 0));
	//vOscillations.z *= sign(vOscillations.z);
	float fOsc = vOscillations.x + (vOscillations.y * vOscillations.z);
	fOsc = (fOsc + 3.0) * 0.33;
//	Apply Wind

	#if defined (FOLIAGEASTREE)
		float4 bendingCoords;
		bendingCoords.rg = v.color.rg;
		bendingCoords.ba = ( UNITY_ACCESS_INSTANCED_PROP(_BendingControls_arr, _BendingControls) == 0) ? v.color.bb : v.texcoord3.xy;
		v.vertex = afsAnimateVertex( float4(v.vertex.xyz, v.color.b), float4(v.normal.xyz,fOsc), bendingCoords, float4(pivot, TreeWorldPos.w ) );
	#else
		v.vertex = afsAnimateVertex( float4(v.vertex.xyz, v.color.b), float4(v.normal.xyz,fOsc), float4(v.color.xy, v.texcoord1.xy), float4(pivot, TreeWorldPos.w ) );
	#endif
	v.vertex = AfsSquashNew(v.vertex, TreeWorldPos.w );
	v.normal = normalize(v.normal);
	v.tangent.xyz = normalize(v.tangent.xyz);


	v.color.r = shadowState; //min(0.99, shadowState); // * 0.99; shadowState; //
}


#endif // AFS_BUILTIN_5X_TREE_LIBRARY_INCLUDED
