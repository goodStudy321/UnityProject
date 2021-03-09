
CBUFFER_START(AfsGrass)
	float4 		_AfsWaveAndDistance;
	float2 		_AfsWindJitterVariationScale;
	fixed4 		_AfsWavingTint;
	float4 		_AfsGrassWind;
	float4 		_AfsGrassWindDir;
	float4x4	_AfsWindRotation;
CBUFFER_END


float2 TriangleWaveGrass( float2 x ) {   
	return abs( frac( x + 0.5 ) * 2.0 - 1.0 );   
}
float2 SmoothCurveGrass( float2 x ) {   
	return x * x *( 3.0 - 2.0 * x );   
}

float2 SmoothTriangleWaveGrass( float2 x ) {   
	return SmoothCurveGrass( TriangleWaveGrass( x ) );   
}

fixed4 WaveGrass (inout float4 vertex, inout float3 normal, float waveAmount, fixed4 color, float2 Instance)
{
//	Start bending
	#if defined (AFSMANUALGRASS)
		float inst = Instance.x;
	#else
		float inst = dot(color.rgb, 1);
		inst = inst*inst;
	#endif
//	Add Variation
	inst *= _AfsWindJitterVariationScale.x;

	#define GrassWaveSize _AfsWaveAndDistance.y
	// derives from WindJitterFrequency
	#define GrassWindSpeed _AfsWaveAndDistance.x

	float4 _waveXSize = float4 (0.012, 0.02, 0.06, 0.024) * (GrassWaveSize ); // * -_AfsGrassWind.x;; // + inst * 0.1);
	float4 _waveZSize = float4 (.006, .02, 0.02, 0.05) * (GrassWaveSize); // * -_AfsGrassWind.z; // + inst * 0.1);
	float4 waveSpeed = float4 (0.3, .5, .4, 1.2) * 4 * (1 + inst * 0.0005 );
	
	float4 _waveXmove = float4(0.012, 0.02, -0.06, 0.048) * 2 * _AfsGrassWind.x; //_Wind.x;  	// add wind direction
	float4 _waveZmove = float4 (0.006, .02, -0.02, 0.1) * _AfsGrassWind.z; //_Wind.z;			// add wind direction

	float4 waves;

//	Adjust waveDirection – somehow
	float4 samplePoint = mul(_AfsWindRotation, float4(0,0,-1,0) );
	_waveXSize *= samplePoint.xxxx + samplePoint.z * 0.05; // + 0.05; 
	_waveZSize *= samplePoint.zzzz + samplePoint.x * 0.05; // + 0.05; 

	waves =	 vertex.x * _waveXSize; 
	waves += vertex.z * _waveZSize; 

//	Add time to model
    waves += (GrassWindSpeed + inst ) * waveSpeed;

	float4 s, c;
	waves = frac (waves);
	FastSinCos (waves, s,c);
	
	// It already comes in like this...
	// waveAmount = color.a * _AfsWaveAndDistance.z;

//	s = s * s;
//	s = s * s; // Getting rid of ^4 makes the bending smoother

	float lighting = dot (s, normalize (float4 (1,1,.4,.2))) * .7;
	s *= waveAmount;

	fixed3 waveColor = lerp (fixed3(1,1,1), _AfsWavingTint.rgb, saturate(lighting * _AfsWaveAndDistance.z * 0.25) );

	float3 waveMove = float3 (0,0,0);
	waveMove.x = dot (s, _waveXmove);
	waveMove.z = dot (s, _waveZmove);

//	End bending
	float2 finalMove =
		(
		//	Add Main Wind: Contains Direction, per instance variation
			_AfsGrassWind.xz * color.a * lighting // * (1 + inst * 0.5 )  /* sttt jitter */ //  * waveMove.xz
		//	Add Jitter
			+ _AfsWindJitterVariationScale.y * waveMove.xz * (1 + inst) //* color.a
//			+ _AfsWindJitterVariationScale.y * waveMove.xz * (1 + inst * 0.5 ) * 1.5 //* color.a
		) * _AfsWaveAndDistance.z;
	vertex.xz += finalMove;
	vertex.y -= lighting * color.a * 0.25 * _AfsWaveAndDistance.z;

//	Color grass due to waving
	color.rgb *= waveColor;

//	Fade the grass out before detail distance.
//	Saturate because Radeon HD drivers on OS X 10.4.10 don't saturate vertex colors properly. // We use original values from the terrain engine here	
	#if defined(AFSMANUALGRASS)
		float3 offset = vertex.xyz - _WorldSpaceCameraPos;
		color.a = saturate (2 * (_AfsWaveAndDistance.w - dot (offset, offset)) * ( 1 / _AfsWaveAndDistance.w) );
	#else
		float3 offset = vertex.xyz - _CameraPosition.xyz;
		color.a = saturate (2 * (_WaveAndDistance.w - dot (offset, offset)) * _CameraPosition.w); 
	#endif


	return fixed4(color.rgb, color.a);
}


void AfsWavingGrassVert_DepthNormal (inout appdata_grass v)
{
	float waveAmount = v.color.a * _AfsWaveAndDistance.z;
	#if defined (AFSMANUALGRASS)
		// doing the animation in worldspace will give us less contrast between manually placed grass
		// and grass within the terrain engine
		v.vertex = mul(unity_ObjectToWorld, v.vertex);
		v.color = WaveGrass (v.vertex, v.normal, waveAmount, v.color, v.texcoord.zz );
		v.vertex = mul(unity_WorldToObject, v.vertex);
	#else
		v.color = WaveGrass (v.vertex, v.normal, waveAmount, v.color, v.texcoord1.xy );
	#endif
}
