// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "CoolMotionBlur" 
{
	Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Center ("Center", Vector) = (0.5,0.5,0,0)
		_SampleDist ("Simple Distance", Range(0.0, 1.0)) = 0.2
		_Strength ("Strength", float) = 1.0
	}
	
	SubShader
    {
        Pass
        {
            ZTest Always Cull Off ZWrite Off
           
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
               
                #include "UnityCG.cginc"
              
                uniform sampler2D _MainTex;
                uniform float4 _MainTex_ST;
               
                float4 _Center;
                float _SampleDist;
                float _Strength;
               
                struct v2f
                {
                    float4 pos : SV_POSITION;
                    float2 mainTexcoord : TEXCOORD0;
                };

                v2f vert(appdata_base v)
                {
                    v2f o;
                   
                    o.pos = UnityObjectToClipPos (v.vertex);
                    o.mainTexcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                   
                    return o;
                }
                
                float4 frag(v2f inFrag) : COLOR
                {   
			        float2 dir = _Center.xy - inFrag.mainTexcoord.xy;
			        
			 		float dist = length(dir); 
					dir /= dist; 
				
				    float4 ret = tex2D(_MainTex, inFrag.mainTexcoord.xy);
				    
				    const float PreWeights[12] = 
					{
					   -0.21,-0.13,-0.08,-0.05,-0.03,-0.01,0.01,0.03,0.05,0.08,0.13,0.21
					};
				
					float4 sum = float4(0, 0, 0, 0);
					
					float2 UVoffset = dir * 0.13 * _SampleDist;
					sum += tex2D(_MainTex, inFrag.mainTexcoord.xy + UVoffset); 
					for (int i = 0; i < 12; ++i)  
					{  
						sum += tex2D(_MainTex, inFrag.mainTexcoord.xy + dir * PreWeights[i] * _SampleDist); 
					}
					
	                sum += ret;
					sum /= 13.0; 
					float t = saturate(dist * _Strength); 
					
					return lerp(ret, sum, t);
                }
                
            ENDCG
        }
    }
    
	FallBack "Diffuse"
}