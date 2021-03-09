Shader "Hidden/PreIntegratedSkinShader/ComputeLookup/VisualizeReflectanceGraph" {
	Properties {
		_MipLevel ("_MipLevel", Float) = 0.0
		_MipCount ("_MipCount", Float) = 0.0
		_MipLevelNormalized ("_MipLevelNormalized", Float) = 0.0
		_TextureWidth ("_TextureWidth", Float) = 0.0
		_TextureHeight ("_TextureHeight", Float) = 0.0
		
		_PreviewScatteringPower ("_PreviewScatteringPower", Float) = 0.0
		
		_PSSProfileHigh_weighths1_var1 ("_PSSProfileHigh_weighths1_var1", Vector) = (0.234, 0.562, 0.644, 0.006)
		_PSSProfileHigh_weighths2_var2 ("_PSSProfileHigh_weighths2_var2", Vector) = (0.101, 0.415, 0.341, 0.048)
		_PSSProfileHigh_weighths3_var3 ("_PSSProfileHigh_weighths3_var3", Vector) = (0.113, 0.009, 0.007, 0.187)
		_PSSProfileHigh_weighths4_var4 ("_PSSProfileHigh_weighths4_var4", Vector) = (0.113, 0.009, 0.007, 0.567)
		_PSSProfileHigh_weighths5_var5 ("_PSSProfileHigh_weighths5_var5", Vector) = (0.359, 0.005, 0.000, 1.990)
		_PSSProfileHigh_weighths6_var6 ("_PSSProfileHigh_weighths6_var6", Vector) = (0.078, 0.000, 0.000, 7.410)
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		Pass {		
			Tags { "LightMode"="Always"}
			ZTest Always
			Cull Off
			ZWrite Off
			Blend Off
			
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma target 3.0
				#pragma glsl
				
				// only compile for traditional desktop renderers to avoid strange warnings
				#pragma only_renderers d3d9 d3d11 opengl glcore
				
				#include "./ComputeLookups.cginc"
				
				float _PreviewScatteringPower;
				
				struct v2f {
					float4 pos : SV_POSITION;
					float4 uv : TEXCOORD0;
				};

				v2f vert(appdata_base v) {
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv = v.texcoord;
					return o;
				}
				
// 				float3 plot(float2 p) {
// 					float x = p.x;
// 					float y = p.y;
// 					
// 					float r = x * 10.0;
// 					
// 					float3 profile = PSS_PI * r * Scatter(r);
// 					
// 					return sin(PSS_PI * 2.0 * x);
// 					
// 					return profile;
// 				}
				
				float3 plot(float x) {
// 					float x = p.x;
// 					float y = p.y;
					
					float r = x * 10.0;
					
					float3 profile = PSS_PI * r * Scatter(r);
					
// 					return sin(PSS_PI * 2.0 * x);
					
					return profile;
				}
				
				// closes point to p on line defined by two points a,b
				float2 projectPoint(float2 a, float2 b, float2 p) {
// 					float2 e = normalize(b - a);
// 					return a + e * dot(e, p - a);
				
					// vector from A to B
					float2 AB = (b-a);
					// squared distance from A to B
					float AB_squared = dot(AB,AB);
  if(AB_squared == 0) {
    // A and B are the same point
    return a;
  } else {
    // vector from A to p
    float2 Ap = (p-a);
    // from http://stackoverflow.com/questions/849211/
    // Consider the line extending the segment, parameterized as A + t (B - A)
    // We find projection of point p onto the line. 
    // It falls where t = [(p-A) . (B-A)] / |B-A|^2
    float t = dot(Ap,AB)/AB_squared;
      return a + t * AB;
    if (t < 0.0)  {
      // "Before" A on the line, just return A
      return a;
    } else if (t > 1.0)  {
      // "After" B on the line, just return B
      return b;
    } else {
      // projection lines "inbetween" A and B on the line
      return a + t * AB;
    }
  }
				
					//float2 e = normalize(b - a);
					//return a + e * dot(e, c - a);
// 					return a + (dot(a*b, a*c) / pow(normalize(a*b),2)) * a*b;
				}
				
				// distance of point p to line defined by two points p1,p2
				float lineDistance(float2 p1, float2 p2, float2 p) {
// 					return distance(projectPoint(p1,p2,p), p);
				
					return
						abs(p.x*(p2.y-p1.y) - p.y*(p2.x-p1.x) + p2.x*p1.y - p2.y*p1.x)
						/ sqrt(pow(p2.y-p1.y,2) + pow(p2.x-p1.x,2));
				}
				
				
				
				float4 frag(v2f i) : COLOR {
					float aspectRatio = (float)_TextureWidth / (float)_TextureHeight;
					float x = i.uv.x;
					float y = i.uv.y;
					
					float pixelWidth = 1.0 / _TextureWidth;
					float pixelHeight = 1.0 / _TextureHeight;
					
					float strokeWidth = max(pixelWidth, pixelHeight);
					
					float2 p = float2(x, y);
					float2 pLeft = float2(x-pixelWidth/2, y);
					float2 pRight = float2(x+pixelWidth/2, y);
					
					float3 rRGB = plot(p);
					float3 rRGBLeft = plot(pLeft);
					float3 rRGBRight = plot(pRight);
					float3 rRGBAvg = lerp(rRGBLeft, rRGBRight, 0.5);
					
// 					reflectanceRGB1 = plot(p);
// 					reflectanceRGB2 = plot(p);
					
// 					return abs(reflectanceRGB1.x-p.y);
					
					
// 					float3 graphDelta = abs(profile - y);


// 		float pAvg = ;

float3 color = 0.95;
for (int rgb=0; rgb<3; rgb++) {
	int samples = 4;
	float2 step = float2(pixelWidth/samples*2.0, pixelHeight/samples*2.0);
	float sum = 0.0;
	for (int i = 0.0; i < samples; i++) {
		for (int  j = 0.0;j < samples; j++) {
			float f = plot(p.x+ i*step.x)[rgb]-(p.y+ j*step.y);
			sum += (f>0.) ? 1 : -1;
		}
	}
	// base color on abs(count)/(samples*samples)	
	float alpha = 1.0 - abs(sum)/(samples*samples);
// 	return alpha;
	
	//if (dd.x <= pixelWidth && dd.y <= pixelHeight)
// 	if (alpha > 0 && alpha <1)
	color = lerp(color, float3(rgb==0, rgb==1, rgb==2), saturate(alpha));
}
return float4(color, 1.0);

{
		float2 pp = projectPoint(float2(pLeft.x,plot(pLeft).x), float2(pRight.x,plot(pRight).x), float2(p.x,plot(p).x));
// 		pp = rRGBAvg;
		float2 dd = abs(pp - p);
		
		
		
		float alpha = (1.0 - max(dd.x/pixelWidth/2, dd.y/pixelHeight/2));
// 		float alpha = max(dd.x, dd.y);
		
// 		alpha = lineDistance(float2(pLeft.x,plot(pLeft).x), float2(pRight.x,plot(pRight).x), p);
// 		alpha = abs(alpha);
// 		alpha /= pixelHeight;
		if (dd.x <= pixelWidth && dd.y <= pixelHeight)
			return float4(0.0, 1.0, 0.0, 0.75);
		
// 		alpha = abs(dd.x);
		return alpha;
		
// 		p = projectPoint(p1, p2.x, p);
		
// 		return plot(p).x;
// 		return rRGBAvg.y;
// 		return rRGBLeft.x;
}
					/*
					for (int rgb=0; rgb<3; rgb++) {
						float2 pp = projectPoint(float2(p1.x,reflectanceRGB1[rgb]), float2(p2.x,reflectanceRGB2[rgb]), p);
						float2 dd = abs(pp - p);
						
						return reflectanceRGB1.x;
						
//float2 grid = abs(dd) / max(abs(fwidth(dd * 2)), 0.001);
// float2 grid = dd / float2(pixelWidth, pixelHeight) * 2;
// float q = max(grid.x, grid.y);
// return q;
						
						float d = lineDistance(float2(p1.x,reflectanceRGB1[rgb]), float2(p2.x,reflectanceRGB2[rgb]), p);
						return dd.x > pixelWidth || dd.y > pixelHeight;

						float alpha = 0.75;
						
						// anti-aliasing
// 						alpha = (1.0 - max(dd.x/pixelWidth, dd.y/pixelHeight));
// 						alpha = 1.0 - length(dd)/ length(float2(pixelWidth,pixelHeight));
// 						alpha = alpha*alpha*2.0;
// 						return dd.y;
// 						return (dd.x/pixelWidth) + (dd.y/pixelHeight);
// 						return abs(x-0.5) >= pixelWidth/2.0;
// alpha = min( (fwidth(d) / pixelWidth) , (fwidth(d) / pixelHeight) );

						//if (dd.x <= pixelWidth && dd.y <= pixelHeight)
						color = lerp(color, float3(rgb==0, rgb==1, rgb==2), saturate(alpha));
					}
					
// 					{
// 						float2 pp = projectPoint(float2(p1.x,reflectanceRGB1.r), float2(p2.x,reflectanceRGB2.r), p);
// 						float2 dd = abs(pp - p);
// 						if (dd.x <= pixelWidth && dd.y <= pixelHeight)
// 							color = lerp(color, float3(1.0, 0.0, 0.0), 0.75);
// 					}
// 					{
// 						float2 pp = projectPoint(float2(p1.x,reflectanceRGB1.g), float2(p2.x,reflectanceRGB2.g), p);
// 						float2 dd = abs(pp - p);
// 						if (dd.x <= pixelWidth && dd.y <= pixelHeight)
// 							color = lerp(color, float3(0.0, 1.0, 0.0), 0.75);
// 					}
// 					{
// 						float2 pp = projectPoint(float2(p1.x,reflectanceRGB1.b), float2(p2.x,reflectanceRGB2.b), p);
// 						float2 dd = abs(pp - p);
// 						if (dd.x <= pixelWidth && dd.y <= pixelHeight)
// 							color = lerp(color, float3(0.0, 0.0, 1.0), 0.75);
// 					}
					
// 					float3 graphDelta;
// 					graphDelta.r = lineDistance(float2(p1.x,reflectanceRGB1.r), float2(p2.x,reflectanceRGB2.r), p);
// 					graphDelta.g = lineDistance(float2(p1.x,reflectanceRGB1.g), float2(p2.x,reflectanceRGB2.g), p);
// 					graphDelta.b = lineDistance(float2(p1.x,reflectanceRGB1.b), float2(p2.x,reflectanceRGB2.b), p);
// 					
// 					
// 					if (graphDelta.r < strokeWidth)
// 						color = lerp(color, float3(1,0,0), 0.5);
// 					if (graphDelta.g < strokeWidth)
// 						color = lerp(color, float3(0,1,0), 0.5);
// 					if (graphDelta.b < strokeWidth)
// 						color = lerp(color, float3(0,0,1), 0.5);
					
					return float4(color, 1.0);
					*/
				}
			ENDCG
		}
	}
	FallBack Off
}