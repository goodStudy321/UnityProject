// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/FastOcean/SunShaftsComposite" {
	Properties {
		_MainTex ("Base", 2D) = "white" {}
		_GodRays ("GodRays", 2D) = "white" {}
	}
	
	CGINCLUDE
				
	#include "UnityCG.cginc"

	#define FO_OCEANMAP
	#define FO_DEPTHBLEND_ON
	#include "FOceanCommon.cginc"

	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		#if UNITY_UV_STARTS_AT_TOP
		float2 uv1 : TEXCOORD1;
		#endif		
	};
		
	struct v2f_radial {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float2 blurVector : TEXCOORD1;
	};
		
	sampler2D _MainTex;
	sampler2D _ColorBuffer;
	sampler2D _GodRays;
	
	half _SinRaysWave;
	half4 _BlurRadius4;
	half4 _SunPosition;
	half4 _MainTex_TexelSize;	
	half _UnderDepthFade;

	#define SAMPLES_FLOAT 6.0f
	#define SAMPLES_INT 6
			
	v2f vert( appdata_img v ) {
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		
		#if UNITY_UV_STARTS_AT_TOP
		o.uv1 = v.texcoord.xy;
		if (_MainTex_TexelSize.y < 0)
			o.uv1.y = 1-o.uv1.y;
		#endif				
		
		return o;
	}
		
	fixed4 fragScreen(v2f i) : SV_Target { 
		fixed4 colorA = tex2D (_MainTex, i.uv.xy);
		#if UNITY_UV_STARTS_AT_TOP
		fixed4 colorB = tex2D (_ColorBuffer, i.uv1.xy);
		#else
		fixed4 colorB = tex2D (_ColorBuffer, i.uv.xy);
		#endif
		fixed4 depthMask = saturate (colorB * _FoSunColor);
		return 1.0f - (1.0f-colorA) * (1.0f-depthMask);	
	}

	fixed4 fragAdd(v2f i) : SV_Target { 
		fixed4 colorA = tex2D (_MainTex, i.uv.xy);
		#if UNITY_UV_STARTS_AT_TOP
		fixed4 colorB = tex2D (_ColorBuffer, i.uv1.xy);
		#else
		fixed4 colorB = tex2D (_ColorBuffer, i.uv.xy);
		#endif
		fixed4 depthMask = saturate (colorB * _FoSunColor);
		return colorA + depthMask;	
	}
	
	v2f_radial vert_radial( appdata_img v ) {
		v2f_radial o;
		o.pos = UnityObjectToClipPos(v.vertex);
		
		o.uv.xy =  v.texcoord.xy;
		o.blurVector = (_SunPosition.xy - v.texcoord.xy) * _BlurRadius4.xy;	
		
		return o; 
	}
	
	fixed4 frag_radial(v2f_radial i) : SV_Target 
	{	
		fixed4 color = fixed4(0,0,0,0);
		for(int j = 0; j < SAMPLES_INT; j++)   
		{	
			fixed4 tmpColor = tex2D(_MainTex, i.uv.xy);
			color += tmpColor;
			i.uv.xy += i.blurVector; 	
		}
		return color / SAMPLES_FLOAT;
	}	
	
	half TransformColor (half4 skyboxValue) {
		return max (skyboxValue.a, dot (skyboxValue.rgb, float3 (0.59,0.3,0.11))); 		
	}
	
	fixed4 frag_depth (v2f i) : SV_Target {
		#if UNITY_UV_STARTS_AT_TOP
		float depthSample = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv1.xy);
		#else
		float depthSample = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv.xy);		
		#endif
		
		fixed4 tex = tex2D (_MainTex, i.uv.xy);
		
		depthSample = Linear01Depth (depthSample);
		 
		// consider maximum radius
		#if UNITY_UV_STARTS_AT_TOP
		half2 vec = _SunPosition.xy - i.uv1.xy;
		#else
		half2 vec = _SunPosition.xy - i.uv.xy;		
		#endif
		half dist = saturate (_SunPosition.w - length (vec.xy));		
		
		fixed4 outColor = 0;
		
		// consider shafts blockers
		if (depthSample > 0.99)
			outColor = TransformColor (tex) * dist * _FoSunInt;
			
		return outColor;
	}
	
	fixed4 frag_depth_rays (v2f i) : SV_Target {
		#if UNITY_UV_STARTS_AT_TOP
		float depthSample = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv1.xy);
		float depthWater = tex2D(_OceanMap, i.uv1.xy).r;
		#else
		float depthSample = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv.xy);		
		float depthWater = tex2D(_OceanMap, i.uv.xy).r;
		#endif
		
		fixed4 tex = tex2D (_MainTex, i.uv.xy);
		
		depthSample = Linear01Depth (depthSample);

		if(depthWater > 0 && depthWater < depthSample)
		{
		   depthSample = depthWater;
		}
		
		// consider maximum radius
		#if UNITY_UV_STARTS_AT_TOP
		half2 vec = _SunPosition.xy - i.uv1.xy;
		#else
		half2 vec = _SunPosition.xy - i.uv.xy;		
		#endif
		half dist = saturate (_SunPosition.w - length (vec.xy));		
		
		fixed4 outColor = 0;
		
		// consider shafts blockers
		outColor = saturate(1 - depthSample * tex2D(_GodRays, i.uv.xy + half2(_SinRaysWave, 0)).r * _UnderDepthFade) * TransformColor (tex) * dist * _FoSunInt;
			
		return outColor;
	}	

	

	ENDCG
	
Subshader {
  
 //0
 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      
      #pragma fragmentoption ARB_precision_hint_fastest 
      #pragma vertex vert
      #pragma fragment fragScreen
      #pragma exclude_renderers gles

      ENDCG
  }
  
  //1
 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vert_radial
      #pragma fragment frag_radial
      #pragma exclude_renderers gles

      ENDCG
  }
  
  //2
  Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      
      #pragma fragmentoption ARB_precision_hint_fastest      
      #pragma vertex vert
      #pragma fragment frag_depth
      #pragma exclude_renderers gles

      ENDCG
  }
  
  //3
  Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      
      #pragma fragmentoption ARB_precision_hint_fastest      
      #pragma vertex vert
      #pragma fragment frag_depth_rays
      #pragma exclude_renderers gles

      ENDCG
  } 

  //4
  Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      
      #pragma fragmentoption ARB_precision_hint_fastest 
      #pragma vertex vert
      #pragma fragment fragAdd
      #pragma exclude_renderers gles

      ENDCG
  } 
}

Fallback off
	
} // shader