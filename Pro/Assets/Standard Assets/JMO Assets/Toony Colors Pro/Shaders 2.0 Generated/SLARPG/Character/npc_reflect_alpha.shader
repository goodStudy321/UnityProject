Shader "cathy/NPC Reflect Alpha" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
		_Smoothness ("Smoothness", Range(0, 1)) = 1.0
		_Reflect ("Reflect Plus", Range(0,2)) = 1
		_Pow ("Power Plus", Range(1,3)) = 1
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.00014
	}

	SubShader {
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		LOD 200

		CGPROGRAM
		#pragma vertex vert
		#pragma surface surf Lambert alphatest:_Cutoff

		sampler2D _MainTex;
		fixed4 _Color;
		 float _Reflect;
		 float _Smoothness;
		 float _Pow;

		struct Input {
			float2 uv_MainTex;
			float3 viewDir;
			float3 normal;
			float3 worldPos;
		};

		float3 BoxProjection (
			float3 direction, float3 position,
			float4 cubemapPosition, float3 boxMin, float3 boxMax
		) {
			#if UNITY_SPECCUBE_BOX_PROJECTION
				UNITY_BRANCH
				if (cubemapPosition.w > 0) {
					float3 factors =
						((direction > 0 ? boxMax : boxMin) - position) / direction;
					float scalar = min(min(factors.x, factors.y), factors.z);
					direction = direction * scalar + (position - cubemapPosition);
				}
			#endif
			return direction;
		}

		void vert(inout appdata_full v,out Input data){
			data.worldPos = mul(unity_ObjectToWorld, v.vertex);
			data.normal = UnityObjectToWorldNormal(v.normal);
			data.uv_MainTex = v.texcoord.xy;
			data.viewDir = normalize(_WorldSpaceCameraPos - data.worldPos);
		}

		void surf (Input IN, inout SurfaceOutput o) {
	/*fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
	o.Albedo = c.rgb;
	//o.Alpha = c.a;
	o.Alpha = (1-c.g)+ c.r+c.b ;*/

	o.Albedo = 0.0;

	float3 reflectionDir = reflect(-IN.viewDir, IN.normal);

	Unity_GlossyEnvironmentData envData;
	envData.roughness = 1 - _Smoothness;
	envData.reflUVW = BoxProjection(
		reflectionDir, IN.worldPos,
		unity_SpecCube0_ProbePosition,
		unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
		);
	float3 probe0 = Unity_GlossyEnvironment(
		UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData
		);
	envData.reflUVW = BoxProjection(
		reflectionDir, IN.worldPos,
		unity_SpecCube1_ProbePosition,
		unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax
		);

	fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;

	half ar = c.a; //clamp( c.a,0,1);

	fixed3 diff =  c.rgb ;
	half ar2 = pow(ar,2)*_Pow;

	o.Albedo =  	diff  ;

	float interpolator = unity_SpecCube0_BoxMin.w;
	UNITY_BRANCH
	if (interpolator < 0.99999) {
		float3 probe1 = Unity_GlossyEnvironment(
			UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0),
			unity_SpecCube1_HDR, envData
			);

		o.Albedo += lerp(probe1, probe0, interpolator)* ar2 *  _Reflect;
	}
	else {

		o.Albedo += probe0 * ar2 * _Reflect;
	}

	//o.Alpha = c.a ;
	//o.Alpha = normalize((_Pow + c.g)+ c.r+c.b) ;
	o.Alpha = min(c.a,0.05)*20;

}
ENDCG
}

Fallback "Legacy Shaders/Transparent/Cutout/VertexLit"
}
