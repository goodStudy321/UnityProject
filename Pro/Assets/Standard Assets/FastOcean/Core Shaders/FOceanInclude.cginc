// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#ifndef FASTOCEAN_CG_INCLUDE
#define FASTOCEAN_CG_INCLUDE

// interpolator structs
	struct v2f_FO
	{
		float4 pos : SV_POSITION;
		float4 normalInterpolator : TEXCOORD0;
		float4 viewInterpolator : TEXCOORD1; 	
		float4 tileCoords : TEXCOORD2;
		float4 screenPos : TEXCOORD3;
#if defined (FO_HQWAVES_ON)	|| defined (FO_FFTWAVES_ON)
		float4 tanInterpolator : TEXCOORD4;
		float4 binInterpolator : TEXCOORD5;
#endif 

#if defined (FO_SHADOW_ON)
		float4 shadowCoords : TEXCOORD6;
#endif	

	};	

	struct v2f_FO_Ocean
	{
		float4 pos : SV_POSITION;
		float4 screenPos : TEXCOORD0;
	};	
	
	v2f_FO vert_FO(appdata_base vert)
	{
		v2f_FO o;

		half3 localSpaceVertex = vert.vertex.xyz;
#if defined (FO_PROJECTED_ON)

		FoProjInterpolate(localSpaceVertex);

		//float3 worldSpaceVertex = mul(_Object2World, half4(localSpaceVertex,1)).xyz;
		float3 center = float3(_FoCenter.x, 0, _FoCenter.z);
		float3 worldSpaceVertex = localSpaceVertex + center;
#else
		//use localVertex to eliminate floating point error
		localSpaceVertex.y = 0;

		float3 worldSpaceVertex = mul(unity_ObjectToWorld, half4(localSpaceVertex,1)).xyz;
#endif

		float3 distance = _WorldSpaceCameraPos - worldSpaceVertex;

		float4 fadeAway = float4(distance,Fade(distance));

		half3 offsets;
#if defined (FO_HQWAVES_ON) || defined (FO_FFTWAVES_ON)
		half3 nrml;	
		half3 tan;
		half3 bin;
		Gerstner (
			offsets, nrml, tan, bin, worldSpaceVertex							// offsets, nrml will be written
		);
#else
		half3 nrml;	
		Gerstner (
			offsets, nrml, worldSpaceVertex							// offsets, nrml will be written
		);
		
#endif

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
		o.normalInterpolator.w = saturate(offsets.y * _InvFoScale * nrml.g); // 		o.normalInterpolator.w = -tan.g;

#if defined (FO_HQWAVES_ON)	|| defined (FO_FFTWAVES_ON)
		o.tanInterpolator.xyz = tan;
		o.tanInterpolator.w = 1;
		o.binInterpolator.xyz = bin;
		o.binInterpolator.w = 1;
#endif

#if defined (FO_SHADOW_ON)
		o.shadowCoords = mul(_FoMatrixShadowMVP, float4(worldSpaceVertex, 1));
		o.shadowCoords = FoShadowScreenPos(o.shadowCoords);
#endif
		FO_TRANSFER_FOG(o,o.pos);
		return o;
	}

	fixed4 frag_FO( v2f_FO i ) : SV_Target
	{	
		half3 viewVector = normalize(i.viewInterpolator.xyz);

#if defined (FO_HQWAVES_ON)	
        FO_TANGENTSPACE

		float4 bumpUvScale4 = i.tileCoords.zwzw * _BumpTiling.xxyy + _BumpDirection;
						
	    half3 worldNormal = PerPixelTangentSpaceParallax(_OceanNM, bumpUvScale4, m, viewVector, BUMP_POWER);
		half3 worldNormal2 = PerPixelTangentSpaceParallax(_OceanNM, bumpUvScale4, m, viewVector,BUMP_SHARPBIAS);
#elif defined (FO_FFTWAVES_ON)	
        FO_TANGENTSPACE

		float2 fftUvScale2 = i.tileCoords.zw * _FoFFTTiling;

	    half3 worldNormal = PerPixelNormalTangentSpace(_OceanNMRT, fftUvScale2, m, BUMP_POWER);
		half3 worldNormal2 = PerPixelNormalTangentSpace(_OceanNMRT, fftUvScale2, m, BUMP_SHARPBIAS);
#else

		float4 bumpUvScale4 = i.tileCoords.zwzw * _BumpTiling.xxyy + _BumpDirection;
						
	    half3 worldNormal = PerPixelNormalBump(_OceanNM, bumpUvScale4, VERTEX_WORLD_NORMAL, BUMP_POWER);
		half3 worldNormal2 = PerPixelNormalBump(_OceanNM, bumpUvScale4, VERTEX_WORLD_NORMAL, BUMP_SHARPBIAS);
#endif
		
		half top = i.normalInterpolator.w;

		half fade = i.viewInterpolator.w;

		worldNormal = lerp(WORLD_UP, worldNormal, fade);

#if defined (FO_FOAM_ON) || defined (FO_TRAIL_ON) 
		half2 slope = worldNormal.xz;
#endif	

		worldNormal.xz *= _FresnelScale;

		half NDotV = saturate(dot(viewVector, worldNormal));
		half refl2Refr = Fresnel(_FresnelLookUp, NDotV);
		half refl2RefrFade = refl2Refr * fade;
		
		fixed4 baseColor = ExtinctColor (_FoBaseColor, top, _ExtinctScale * refl2Refr);
			
#if defined (FO_DEPTHBLEND_ON)
		half depth = UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, i.screenPos));
		depth = LinearEyeDepth(depth) - i.screenPos.w;
		depth *= _InvFoScale;
#endif	

		fixed4 shallowColor = _FoShallowColor;

#if defined (FO_FOAM_ON)
		float4 foamUvScale4 = i.tileCoords.zwzw * _FoamTiling.xxyy + _FoamDirection;

		half4 distortUV = slope.xyxy * _FoamTime.zzww;
		half4 foamUV = foamUvScale4 + distortUV;

		fixed4 foam = Foam(foamUV) * _FoSunColor * fade;

	#if defined (FO_DEPTHBLEND_ON)	
		FoShallowFoam(foam, depth, distortUV.xy, shallowColor);
	#endif
#endif	

#if defined (FO_DEPTHBLEND_ON)	
		baseColor = lerp(shallowColor, baseColor, saturate(_ShallowDepth * depth));
#endif

		baseColor = lerp(baseColor, _FoDeepColor, pow(NDotV, _FoDeepColor.a));
				
		half4 screenPosproj = half4(i.screenPos.xy + worldNormal.xz * REFLECTION_DISTORTION * i.screenPos.w, 0, i.screenPos.w);
		
		fixed4 rtReflections = tex2Dproj(_Reflection, screenPosproj);
#if defined (FO_FFTWAVES_ON)
		baseColor = lerp (fixed4(ShadeSH9(half4(worldNormal,1)), 1), baseColor, _FoReflAmb2Scene);
#else
		baseColor = lerp (UNITY_LIGHTMODEL_AMBIENT, baseColor, _FoReflAmb2Scene);
#endif

#if defined (FO_SHADOW_ON)
		half4 shadowCoords = i.shadowCoords;
		shadowCoords.xy += worldNormal.xz * _ShadowParams.z;

		half shadowDepth = FoProjectShadow(shadowCoords, fade);

		baseColor = lerp (baseColor, rtReflections * shadowDepth, refl2Refr);
#else 
		baseColor = lerp (baseColor, rtReflections, refl2Refr);
#endif	

#if defined (FO_FOAM_ON)
		FoWaveFoam(top, refl2RefrFade * foam, foamUV.zw, baseColor);
#endif	

#if defined (FO_PHONG_ON)
		half4 spec = _FoSunColor * PhongSpecular(viewVector, worldNormal2);
#else
		half4 spec = _FoSunColor * BlinnPhongSpecular(viewVector, worldNormal2);
#endif	

#if defined (FO_SHADOW_ON)
		spec *= shadowDepth * shadowDepth;
#endif	

#if defined (FO_TRAIL_ON)
		float2 tileCoords = (i.tileCoords.xy - _TrailOffset.xy) * _TrailOffset.z;
	#if defined (FO_FOAM_ON)
		spec = FoTrailsFoam(tileCoords, spec, foam); // foam * fade
	#else 
		spec = FoTrailsMask(tileCoords, spec);
	#endif	
#endif

		baseColor += spec;

		FO_APPLY_FOG(i.screenPos, baseColor);

#if defined (FO_DEPTHBLEND_ON)		
		baseColor.a = saturate(_AboveDepth * depth * (1 - refl2RefrFade));
#else
		baseColor.a = saturate(1 - refl2RefrFade * (1 - _FoShallowColor.a));
#endif	
		baseColor.a *= _FoBaseColor.a;

#if defined (FO_DEPTHBLEND_ON)
	    screenPosproj = half4(i.screenPos.xy + worldNormal.xz * REFRACTION_DISTORTION * i.screenPos.w, 0, i.screenPos.w);

	#if UNITY_UV_STARTS_AT_TOP
		if (_ProjectionParams.x > 0)
			screenPosproj.y = 1 - screenPosproj.y;
	#endif		

		fixed4 refractions = tex2Dproj(_Refraction, screenPosproj);

		baseColor = lerp(refractions, baseColor, baseColor.a);
#endif	

		return baseColor;
	}

	v2f_FO_Ocean vert_FO_MAP(appdata_base vert)
	{
		v2f_FO_Ocean o;

		half3 localSpaceVertex = vert.vertex.xyz;
#if defined (FO_PROJECTED_ON)

		FoProjInterpolate(localSpaceVertex);

		//float3 worldSpaceVertex = mul(_Object2World, half4(localSpaceVertex,1)).xyz;
		float3 center = float3(_FoCenter.x, 0, _FoCenter.z);
		float3 worldSpaceVertex = localSpaceVertex + center;
#else
		//use localVertex to eliminate floating point error
		localSpaceVertex.y = 0;

		float3 worldSpaceVertex = mul(unity_ObjectToWorld, half4(localSpaceVertex,1)).xyz;
#endif

		float3 distance = _WorldSpaceCameraPos - worldSpaceVertex;

		float4 fadeAway = float4(distance,Fade(distance));

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

	half4 frag_OCEAN_MAP(v2f_FO_Ocean i ) : SV_Target
	{				
		return half4(i.screenPos.w * _ProjectionParams.w, 0, 0, 1);
	}

	half4 frag_OCEAN_MAP_CLEAR(v2f_FO_Ocean i) : SV_Target
	{
		return half4(0, 0, 0, 1);
	}

	fixed4 frag_GLARE_MAP( v2f_FO i ) : SV_Target
	{				
		half3 viewVector = normalize(i.viewInterpolator.xyz);

#if defined (FO_HQWAVES_ON)
		FO_TANGENTSPACE
		
		float4 bumpUvScale4 = i.tileCoords.zwzw * _BumpTiling.xxyy + _BumpDirection;	
		half3 worldNormal2 = PerPixelTangentSpaceParallax(_OceanNM, bumpUvScale4, m, viewVector,BUMP_SHARPBIAS);
#elif defined (FO_FFTWAVES_ON)	
        FO_TANGENTSPACE

		float2 fftUvScale2 = i.tileCoords.zw * _FoFFTTiling;
		half3 worldNormal2 = PerPixelNormalTangentSpace(_OceanNMRT, fftUvScale2, m, BUMP_SHARPBIAS);
#else
		float4 bumpUvScale4 = i.tileCoords.zwzw * _BumpTiling.xxyy + _BumpDirection;
		half3 worldNormal2 = PerPixelNormalBump(_OceanNM, bumpUvScale4, VERTEX_WORLD_NORMAL, BUMP_SHARPBIAS);
#endif
		
		half fade = i.viewInterpolator.w;

#if defined (FO_PHONG_ON)
		half spec = PhongSpecular(viewVector,worldNormal2);
#else
		half spec = BlinnPhongSpecular(viewVector,worldNormal2);
#endif	

#if defined (FO_TRAIL_ON)
		float2 tileCoords = (i.tileCoords.xy - _TrailOffset.xy) * _TrailOffset.z;
		spec = FoTrailsMaskLuminance(tileCoords, spec);
#endif

#if defined (FO_SHADOW_ON)
		half4 shadowCoords = i.shadowCoords;
		shadowCoords.xy += worldNormal2.xz * _ShadowParams.z;

		half shadowDepth = FoProjectShadow(shadowCoords, fade);
		spec *= shadowDepth * shadowDepth;
#endif	

		fixed4 c = fixed4(spec * fade * _FoBaseColor.a, 0, 0, 1);

		FO_APPLY_FOG_COLOR(i.screenPos,c,fixed4(0,0,0,0));
	    return fixed4(c.rgb, 1);
	}
			
#endif
