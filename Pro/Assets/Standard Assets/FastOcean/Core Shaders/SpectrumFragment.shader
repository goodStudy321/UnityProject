// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/FastOcean/SpectrumFragment" {
	SubShader 
	{
		Pass 
    	{
			ZTest Always Cull Off ZWrite Off
      		Fog { Mode off }
    		
			CGPROGRAM
			#include "UnityCG.cginc"
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma exclude_renderers gles

			sampler2D _Spectrum01;
			sampler2D _Spectrum23;
			sampler2D _WTable;
			float _Offset;
			float4 _InverseGridSizes;
			float _T;

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
			
			float2 GetSpectrum(float w, float2 s0, float2 s0c) 
			{
			    float c = cos(w*_T);
			    float s = sin(w*_T);
			    return float2((s0.x + s0c.x) * c - (s0.y + s0c.y) * s, (s0.x - s0c.x) * s + (s0.y - s0c.y) * c);
			}
			
			float2 COMPLEX(float2 z) 
			{
			    return float2(-z.y, z.x); // returns i times z (complex number)
			}
			
			float4 frag(v2f IN): SV_Target
			{ 
				float2 uv = IN.uv.xy;
			
				float2 st;
				st.x = uv.x > 0.5 ? uv.x - 1.0 : uv.x;
		    	st.y = uv.y > 0.5 ? uv.y - 1.0 : uv.y;
		    	
		    	float4 s12 = tex2D(_Spectrum01, uv);
		    	float4 s12c = tex2D(_Spectrum01, _Offset-uv);
		    	float4 s34 = tex2D(_Spectrum23, uv);
		    	float4 s34c = tex2D(_Spectrum23, _Offset-uv);
		    	
			    float2 k2 = st * _InverseGridSizes.y;
			    float2 k3 = st * _InverseGridSizes.z;
			    
			    float4 w = tex2D(_WTable, uv);
			    
			    float2 h2 = GetSpectrum(w.y, s12.zw, s12c.zw);
			   	float2 h3 = GetSpectrum(w.z, s34.xy, s34c.xy);
			    
				float2 n2 = COMPLEX(k2.x * h2) - k2.y * h2;
				float2 n3 = COMPLEX(k3.x * h3) - k3.y * h3;
	
			    float4 OUT;
			    
				//normal
				OUT = float4(n2, n3);
				
				return OUT;
			}
			
			ENDCG

    	}
	}
	Fallback off
}
