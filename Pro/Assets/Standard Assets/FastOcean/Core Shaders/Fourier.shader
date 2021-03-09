// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/FastOcean/Fourier" 
{
	CGINCLUDE
	
	#include "UnityCG.cginc"

	sampler2D _ReadBuffer0;
	sampler2D _ButterFlyLookUp;
	
	struct v2f 
	{
		float4  pos : SV_POSITION;
		float2  uv : TEXCOORD0;
	};

	v2f vert(appdata_base v)
	{
		v2f OUT;
		OUT.pos = UnityObjectToClipPos(v.vertex);
		OUT.uv = v.texcoord;
		return OUT;
	}
	
	//Performs two FFTs on two complex numbers packed in a vector4
	float4 FFT4(float2 w, float4 input1, float4 input2) 
	{
		float rx = w.x * input2.x - w.y * input2.y;
		float ry = w.y * input2.x + w.x * input2.y;
		float rz = w.x * input2.z - w.y * input2.w;
		float rw = w.y * input2.z + w.x * input2.w;

		return input1 + float4(rx,ry,rz,rw);
	}

	float4 fragX(v2f IN): SV_Target
	{
		float4 lookUp = tex2D(_ButterFlyLookUp, float2(IN.uv.x, 0));

		//todo: Wlut
		float2 w = float2(cos(2.0*UNITY_PI*lookUp.z), sin(2.0*UNITY_PI*lookUp.z));
		
		 w *= (lookUp.w * 2 - 1.0);
		
		float4 OUT;
		
		float2 uv1 = float2(lookUp.x, IN.uv.y);
		float2 uv2 = float2(lookUp.y, IN.uv.y);
		
		OUT = FFT4(w, tex2D(_ReadBuffer0, uv1), tex2D(_ReadBuffer0, uv2));

		return OUT;
	}
	
	float4 fragY(v2f IN): SV_Target
	{
		float4 lookUp = tex2D(_ButterFlyLookUp, float2(IN.uv.y, 0));
		
		//todo: Wlut
		float2 w = float2(cos(2.0*UNITY_PI*lookUp.z), sin(2.0*UNITY_PI*lookUp.z));
		
		w *= (lookUp.w * 2 - 1.0);
		
		float4 OUT;
		
		float2 uv1 = float2(IN.uv.x, lookUp.x);
		float2 uv2 = float2(IN.uv.x, lookUp.y);
		
		OUT = FFT4(w, tex2D(_ReadBuffer0, uv1), tex2D(_ReadBuffer0, uv2));

		return OUT;
	}
	
	ENDCG
			
	SubShader 
	{
		Pass 
    	{
			ZTest Always Cull Off ZWrite Off
      		Fog { Mode off }
    		
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment fragX
			#pragma exclude_renderers gles

			#pragma fragmentoption ARB_precision_hint_fastest

			ENDCG
		}
		
		Pass 
    	{
			ZTest Always Cull Off ZWrite Off
      		Fog { Mode off }
    		
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment fragY
			#pragma exclude_renderers gles

			#pragma fragmentoption ARB_precision_hint_fastest

			ENDCG
		}
	}

}