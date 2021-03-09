#ifndef FASTOCEAN_CG_COMMON
#define FASTOCEAN_CG_COMMON

#if defined (FO_DEPTHBLEND_ON)
sampler2D _CameraDepthTexture;
#endif

#if defined (FO_OCEANMAP)
sampler2D _OceanMap;
#endif

// colors in use
fixed4 _FoBaseColor;
fixed4 _FoDeepColor;
fixed4 _FoShallowColor;
half _FoReflAmb2Scene;

// specularity
fixed4 _FoSunColor;
half _FoShininess;
half _FoSunInt;
half4 _FoSunDir;

inline half FoSin(half a)
{
  /* C simulation gives a max absolute error of less than 1.8e-7 */
  const half4 c0 = half4( 0.0,            0.5,
                      1.0,            0.0            );
  const half4 c1 = half4( 0.25,          -9.0,
                      0.75,           0.159154943091 );
  const half4 c2 = half4( 24.9808039603, -24.9808039603,
                     -60.1458091736,  60.1458091736  );
  const half4 c3 = half4( 85.4537887573, -85.4537887573,
                     -64.9393539429,  64.9393539429  );
  const half4 c4 = half4( 19.7392082214, -19.7392082214,
                     -1.0,            1.0            );

  /* r0.x = sin(a) */
  half3 r0, r1, r2;

  r1.x  = c1.w * a - c1.x;                // only difference from cos!
  r1.y  = frac( r1.x );                   // and extract fraction
  r2.x  = (half) ( r1.y < c1.x );        // range check: 0.0 to 0.25
  r2.yz = (half2) ( r1.yy >= c1.yz );    // range check: 0.75 to 1.0
  r2.y  = dot( r2, c4.zwz );              // range check: 0.25 to 0.75
  r0    = c0.xyz - r1.yyy;                // range centering
  r0    = r0 * r0;
  r1    = c2.xyx * r0 + c2.zwz;           // start power series
  r1    =     r1 * r0 + c3.xyx;
  r1    =     r1 * r0 + c3.zwz;
  r1    =     r1 * r0 + c4.xyx;
  r1    =     r1 * r0 + c4.zwz;
  r0.x  = dot( r1, -r2 );                 // range extract

  return r0.x;
}

inline half4 FoSin4(half4 a)
{
  return half4(FoSin(a.x),FoSin(a.y),FoSin(a.z),FoSin(a.w));
}

inline half FoCos(half a)
{
  /* C simulation gives a max absolute error of less than 1.8e-7 */
  const half4 c0 = half4( 0.0,            0.5,
                            1.0,            0.0            );
  const half4 c1 = half4( 0.25,          -9.0,
                            0.75,           0.159154943091 );
  const half4 c2 = half4( 24.9808039603, -24.9808039603,
                           -60.1458091736,  60.1458091736  );
  const half4 c3 = half4( 85.4537887573, -85.4537887573,
                           -64.9393539429,  64.9393539429  );
  const half4 c4 = half4( 19.7392082214, -19.7392082214,
                           -1.0,            1.0            );

  /* r0.x = cos(a) */
  half3 r0, r1, r2;

  r1.x  = c1.w * a;                       // normalize input
  r1.y  = frac( r1.x );                   // and extract fraction
  r2.x  = (half) ( r1.y < c1.x );        // range check: 0.0 to 0.25
  r2.yz = (half2) ( r1.yy >= c1.yz );    // range check: 0.75 to 1.0
  r2.y  = dot( r2, c4.zwz );              // range check: 0.25 to 0.75
  r0    = c0.xyz - r1.yyy;                // range centering
  r0    = r0 * r0;
  r1    = c2.xyx * r0 + c2.zwz;           // start power series
  r1    =     r1 * r0 + c3.xyx;
  r1    =     r1 * r0 + c3.zwz;
  r1    =     r1 * r0 + c4.xyx;
  r1    =     r1 * r0 + c4.zwz;
  r0.x  = dot( r1, -r2 );                 // range extract

  return r0.x;
}

inline half4 FoCos4(half4 a)
{
  return half4(FoCos(a.x),FoCos(a.y),FoCos(a.z),FoCos(a.w));
}

inline half3 PerPixelBump(sampler2D bumpMap, float4 coords, half bumpStrength) 
{
	fixed4 bump = tex2D(bumpMap, coords.xy) + tex2D(bumpMap, coords.zw);
	bump *= 0.5;
	half3 normal = UnpackNormal(bump);
	normal.xy *= bumpStrength;
	return normalize(normal);
} 

inline half3 PerPixelNormal(sampler2D bumpMap, float4 coords, half bumpStrength) 
{
	fixed4 bump = tex2D(bumpMap, coords.xy) + tex2D(bumpMap, coords.zw);
	bump *= 0.5;
	half3 normal = UnpackNormal(bump);
	normal.xz = normal.xy * bumpStrength;
	normal.y = 1;
	return normalize(normal);
} 

inline half3 QTransform(half4 q, half3 v)
{ 
	return 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w*v) + v;
}

inline float TriWave(float x)
{ 
	return abs(frac(x) * 2.0 - 1.0);  
}			

#endif
