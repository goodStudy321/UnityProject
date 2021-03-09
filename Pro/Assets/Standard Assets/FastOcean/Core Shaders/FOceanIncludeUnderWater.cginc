// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#ifndef FASTOCEAN_CG_INCLUDEUNDERWATER
#define FASTOCEAN_CG_INCLUDEUNDERWATER

// interpolator structs
	struct v2f_UFO
	{
		float4 pos : SV_POSITION;
		float4 normalInterpolator : TEXCOORD0;
		float4 viewInterpolator : TEXCOORD1; 	
		float4 tileCoords : TEXCOORD2;
		float4 screenPos : TEXCOORD3;

#if defined (FO_SHADOW_ON)
		float4 shadowCoords : TEXCOORD4;
#endif	
	};
	
	struct v2f_UFO_Ocean
	{
		float4 pos : SV_POSITION;
		float4 screenPos : TEXCOORD0;
	};
	
#if defined (FO_SKIRT)
	half _Skirt;
#endif

	v2f_UFO vert_UFO(appdata_base vert)
	{
		v2f_UFO o;

		half3 localSpaceVertex = vert.vertex.xyz;
#if defined (FO_PROJECTED_ON)

		FoProjInterpolate(localSpaceVertex);

#if defined (FO_SKIRT)
		localSpaceVertex.y -= vert.vertex.y * _Skirt;
#endif
		//float3 worldSpaceVertex = mul(_Object2World, half4(localSpaceVertex,1)).xyz;
		float3 center = float3(_FoCenter.x, 0, _FoCenter.z);
		float3 worldSpaceVertex = localSpaceVertex + center;
#else

#if defined (FO_SKIRT)
		localSpaceVertex.y = -vert.vertex.y * _Skirt;
#else
		localSpaceVertex.y = 0;
#endif
		//use localVertex to eliminate floating point error
		float3 worldSpaceVertex = mul(unity_ObjectToWorld, half4(localSpaceVertex,1)).xyz;
#endif

		float3 distance = _WorldSpaceCameraPos - worldSpaceVertex;

		float4 fadeAway = float4(normalize(distance),Fade(distance));

		half3 offsets;
		half3 nrml;	
		Gerstner (
			offsets, nrml, worldSpaceVertex							// offsets, nrml will be written
		);
		
		offsets *= fadeAway.w;
		nrml = lerp(WORLD_UP, nrml, fadeAway.w);

		worldSpaceVertex += offsets;	
		localSpaceVertex += offsets;	
		
		o.pos = UnityObjectToClipPos(half4(localSpaceVertex,1));

		float2 tileableUv = worldSpaceVertex.xz;
		float2 tileableUvScale = tileableUv * _InvFoScale;

		o.tileCoords = float4(tileableUv, tileableUvScale);

		o.viewInterpolator = fadeAway;

		o.screenPos = ComputeScreenPos(o.pos);

		o.normalInterpolator.xyz = nrml;
		o.normalInterpolator.w = saturate(offsets.y * _InvFoScale * nrml.g);

#if defined (FO_SHADOW_ON)
		o.shadowCoords = mul(_FoMatrixShadowMVP, float4(worldSpaceVertex, 1));
		o.shadowCoords = FoShadowScreenPos(o.shadowCoords);
#endif
		FO_TRANSFER_FOG(o, o.pos);
		return o;
	}

	fixed4 frag_UFO( v2f_UFO i ) : SV_Target
	{				
#if defined (FO_FFTWAVES_ON)
		float2 fftUvScale2 = i.tileCoords.zw * _FoFFTTiling;

	    half3 worldNormal = PerPixelNormalBump(_OceanNMRT, fftUvScale2, VERTEX_WORLD_NORMAL, BUMP_POWER);
		half3 worldNormal2 = PerPixelNormalBump(_OceanNMRT, fftUvScale2, VERTEX_WORLD_NORMAL, BUMP_SHARPBIAS);
#else
		float4 bumpUvScale4 = i.tileCoords.zwzw * _BumpTiling.xxyy + _BumpDirection;

	    half3 worldNormal = PerPixelNormalBump(_OceanNM, bumpUvScale4, VERTEX_WORLD_NORMAL, BUMP_POWER);
		half3 worldNormal2 = PerPixelNormalBump(_OceanNM, bumpUvScale4, VERTEX_WORLD_NORMAL, BUMP_SHARPBIAS);
#endif
		half3 viewVector = i.viewInterpolator.xyz;

		half fade = i.viewInterpolator.w;

		half top = i.normalInterpolator.w;

		worldNormal = lerp(WORLD_UP, worldNormal, fade);
#if defined (FO_TRAIL_ON)
		half2 slope = worldNormal.xz;
#endif	
		worldNormal.xz *= _FresnelScale;

		half NDotV = abs(dot(viewVector, worldNormal));
		half refl2Refr = 1 - Fresnel(_FresnelLookUp, NDotV);
		half refl2RefrFade = refl2Refr * fade;

#if defined (FO_DEPTHBLEND_ON)					
		half depth = UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, i.screenPos));
		depth = LinearEyeDepth(depth) - i.screenPos.w;
		depth *= _InvFoScale;
#endif

		fixed4 baseColor = ExtinctColor (_FoBaseColor, top, _ExtinctScale * refl2Refr);

#if defined (FO_DEPTHBLEND_ON)
		baseColor = lerp(_FoShallowColor, baseColor, saturate(_ShallowDepth * depth));
#endif

		baseColor = lerp(baseColor, _FoDeepColor, pow(NDotV, _FoDeepColor.a));

#if defined (FO_FFTWAVES_ON)
		fixed4 reflectionColor = lerp (fixed4(ShadeSH9(half4(worldNormal,1)), 1), _UnderAmbient, _FoReflAmb2Scene);
#else
		fixed4 reflectionColor = lerp (UNITY_LIGHTMODEL_AMBIENT, _UnderAmbient, _FoReflAmb2Scene);
#endif

#if defined (FO_SHADOW_ON)
		half4 shadowCoords = i.shadowCoords;
		shadowCoords.xy += worldNormal.xz * _ShadowParams.z;

		half shadowDepth = FoProjectShadow(shadowCoords, fade);

		baseColor = lerp (baseColor * shadowDepth, reflectionColor, refl2Refr);
#else 
		baseColor = lerp (baseColor, reflectionColor, refl2Refr);
#endif	

		half4 spec = UnderWaterSpecular(viewVector, worldNormal2);
		
#if defined (FO_SHADOW_ON)
		spec *= shadowDepth * shadowDepth;
#endif	

#if defined (FO_TRAIL_ON)
		float2 tileCoords = (i.tileCoords.xy - _TrailOffset.xy) * _TrailOffset.z;
		spec = FoTrailsMask(tileCoords, spec);
#endif
		baseColor += _FoSunColor * spec;

		FO_APPLY_FOG(i.screenPos, baseColor);

#if defined (FO_DEPTHBLEND_ON)
		baseColor.a = saturate(_UnderDepth * depth * (1 - refl2RefrFade));
#else 
		baseColor.a = saturate(refl2RefrFade); //use refl2Refr as depth
#endif	

		baseColor.a *= _FoBaseColor.a;

		return baseColor;
	}

	v2f_UFO_Ocean vert_UOCEAN_MAP(appdata_base vert)
	{
		v2f_UFO_Ocean o;

		half3 localSpaceVertex = vert.vertex.xyz;
#if defined (FO_PROJECTED_ON)

		FoProjInterpolate(localSpaceVertex);

#if defined (FO_SKIRT)
		localSpaceVertex.y -= vert.vertex.y * _Skirt;
#endif

		//float3 worldSpaceVertex = mul(_Object2World, half4(localSpaceVertex,1)).xyz;
		float3 center = float3(_FoCenter.x, 0, _FoCenter.z);
		float3 worldSpaceVertex = localSpaceVertex + center;
#else
	
#if defined (FO_SKIRT)
		localSpaceVertex.y = -vert.vertex.y * _Skirt;
#else
		localSpaceVertex.y = 0;
#endif

		//use localVertex to eliminate floating point error
		float3 worldSpaceVertex = mul(unity_ObjectToWorld, half4(localSpaceVertex,1)).xyz;
#endif

		float3 distance = _WorldSpaceCameraPos - worldSpaceVertex;

		float4 fadeAway = float4(normalize(distance),Fade(distance));

		half3 offsets;
		half3 nrml;	
		Gerstner (
			offsets, nrml, worldSpaceVertex							// offsets, nrml will be written
		);
		
		offsets *= fadeAway.w;
		nrml = lerp(WORLD_UP, nrml, fadeAway.w);

		worldSpaceVertex += offsets;	
		localSpaceVertex += offsets;	
		
		o.pos = UnityObjectToClipPos(half4(localSpaceVertex,1));

		o.screenPos = ComputeScreenPos(o.pos);
		return o;
	}
	
	half4 frag_UOCEAN_MAP(v2f_UFO_Ocean i) : SV_Target
	{
		return half4(i.screenPos.w * _ProjectionParams.w, 0, 0, 1);
	}
			
#endif
