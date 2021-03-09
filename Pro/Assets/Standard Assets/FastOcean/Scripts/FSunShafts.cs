using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace FastOcean
{
	public class FSunShafts : FPostEffectsBase 
	{
	    public enum SunShaftsResolution
	    {
	        Low = 0,
	        Normal = 1,
	        High = 2,
	    }

	    public enum ShaftsScreenBlendMode
	    {
	        Screen = 0,
	        Add = 1,
	    }

        public bool enableShaft = true;

        public SunShaftsResolution resolution = SunShaftsResolution.Normal;
		public ShaftsScreenBlendMode screenBlendMode = ShaftsScreenBlendMode.Screen;

		public int radialBlurIterations = 2;
		public float sunShaftBlurRadius  = 2.5f;

        [Range(0, 1)]
		public float maxRadius = 0.75f;
	    public Texture2D underWaterRays = null;
        [Range(0f, 0.5f)]
	    public float underWaterRaysFrq = 0.2f;
        [Range(0f, 0.2f)]
	    public float underWaterRaysAmp = 0.1f;
		
		public float underDepthFade = 10f;

		public Shader sunShaftsShader;
		private Material sunShaftsMaterial;	
			
		protected override  bool CheckResources () {	
			CheckSupport ();
			
			sunShaftsMaterial = CheckShaderAndCreateMaterial (sunShaftsShader, sunShaftsMaterial);
			
			if(!isSupported)
				ReportAutoDisable ();
			return isSupported;				
		}

        void OnDestroy()
        {
            if (sunShaftsMaterial != null)
                DestroyImmediate(sunShaftsMaterial);

            CancelInvoke();

            if (FOcean.instance != null)
            {
                FOcean.instance.needDepthBehaviour.Remove(this);
            }
        }

        Vector3 vSun = Vector3.one * 0.5f;
        void Awake()
        {
            if (Application.isPlaying)
                InvokeRepeating("CheckEnable", 0f, fixedTime);
        }

        protected override void CheckEnable()
        {
            if (FOcean.instance != null)
            {
                enabled = enableShaft && UpdateSun() && FOcean.instance.supportSM3;

                if (enabled)
                {
                    if (!FOcean.instance.needDepthBehaviour.Contains(this))
                        FOcean.instance.needDepthBehaviour.Add(this);
                }
                else
                {
                    FOcean.instance.needDepthBehaviour.Remove(this);
                }
            }
        }

        public bool UpdateSun()
        {
            Camera cam = GetComponent<Camera>();
            Vector3 sunPos = cam.transform.position - FOcean.instance.envParam.sunLight.transform.forward * cam.farClipPlane;
            vSun = cam.WorldToViewportPoint(sunPos);

            return vSun.z >= 0f;
        }

        void OnRenderImage (RenderTexture source, RenderTexture destination) {
	        if (sunShaftsMaterial == null || CheckResources() == false || null == FOcean.instance ||
                FOcean.instance.envParam.sunLight == null
	            )
	        {
	            FOcean.BlitDontClear(source, destination, null);
				return;
			}

	        //// we actually need to check this every frame
	        //if (useDepthTexture)
	        //    camera.depthTextureMode |= DepthTextureMode.Depth;	
			
	        int divider = 4;
            if (resolution == SunShaftsResolution.Normal)
                divider = 2;
            else if (resolution == SunShaftsResolution.High)
                divider = 1;

            if (vSun.z < 0f)
            {
                FOcean.BlitDontClear(source, destination, null);
                return;
            }

            int rtW = source.width / divider;
			int rtH = source.height / divider;
				
			RenderTexture lrColorB;
	        RenderTexture lrDepthBuffer = RenderTexture.GetTemporary (rtW, rtH, 0);
			
			// mask out everything except the skybox
			// we have 2 methods, one of which requires depth buffer support, the other one is just comparing images
			
			sunShaftsMaterial.SetVector ("_BlurRadius4", new Vector4 (1.0f, 1.0f, 0.0f, 0.0f) * sunShaftBlurRadius );
			sunShaftsMaterial.SetVector ("_SunPosition", new Vector4 (vSun.x, vSun.y, vSun.z, maxRadius));
            sunShaftsMaterial.SetFloat("_FoSunInt", FOcean.instance.envParam.sunLight.intensity);

            if (FOcean.instance.IntersectWater() && underWaterRays != null)
	        {
				RenderTexture rto = FOcean.instance.oceanmap;
	            sunShaftsMaterial.SetFloat("_SinRaysWave", Mathf.Sin((float)FOcean.instance.gTime * underWaterRaysFrq) * underWaterRaysAmp);
	            sunShaftsMaterial.SetTexture("_GodRays", underWaterRays);
				sunShaftsMaterial.SetFloat("_UnderDepthFade", underDepthFade);
				sunShaftsMaterial.SetTexture("_OceanMap", rto);

                FOcean.Blit(source, lrDepthBuffer, sunShaftsMaterial, 3);
	        }
	        else
	        {
                FOcean.Blit(source, lrDepthBuffer, sunShaftsMaterial, 2);
                // paint a small black small border to get rid of clamping problems
                FOcean.DrawBorder(lrDepthBuffer, Color.clear);
	        }
			        			
			// radial blur:
							
			radialBlurIterations = Mathf.Clamp (radialBlurIterations, 1, 4);

	        int iter = radialBlurIterations;
	        if (FOcean.instance.IntersectWater())
	            iter = 2;

			float ofs = sunShaftBlurRadius * (1.0f / 768.0f);
			
			sunShaftsMaterial.SetVector ("_BlurRadius4", new Vector4 (ofs, ofs, 0.0f, 0.0f));			
			sunShaftsMaterial.SetVector ("_SunPosition", new Vector4 (vSun.x, vSun.y, vSun.z, maxRadius));				
					
			for (int it2 = 0; it2 < iter; it2++ ) {
				// each iteration takes 2 * 6 samples
				// we update _BlurRadius each time to cheaply get a very smooth look
				
				lrColorB = RenderTexture.GetTemporary (rtW, rtH, 0);
                FOcean.Blit(lrDepthBuffer, lrColorB, sunShaftsMaterial, 1);
				RenderTexture.ReleaseTemporary (lrDepthBuffer);
				ofs = sunShaftBlurRadius * (((it2 * 2.0f + 1.0f) * 6.0f)) / 768.0f;
				sunShaftsMaterial.SetVector ("_BlurRadius4", new Vector4 (ofs, ofs, 0.0f, 0.0f) );			
				
				lrDepthBuffer = RenderTexture.GetTemporary (rtW, rtH, 0);
                FOcean.Blit(lrColorB, lrDepthBuffer, sunShaftsMaterial, 1);		
				RenderTexture.ReleaseTemporary (lrColorB);
				ofs = sunShaftBlurRadius * (((it2 * 2.0f + 2.0f) * 6.0f)) / 768.0f;
	            sunShaftsMaterial.SetVector("_BlurRadius4", new Vector4(ofs, ofs, 0.0f, 0.0f));
			}

            // put together:

            Color sunColor = FOcean.instance.envParam.sunLight.color;
            sunShaftsMaterial.SetVector ("_FoSunColor", new Vector4 (sunColor.r, sunColor.g, sunColor.b, sunColor.a));
			sunShaftsMaterial.SetTexture ("_ColorBuffer", lrDepthBuffer);
            FOcean.BlitDontClear(source, destination, sunShaftsMaterial, (screenBlendMode == ShaftsScreenBlendMode.Screen) ? 0 : 4); 	
			
			RenderTexture.ReleaseTemporary (lrDepthBuffer);
		}

	}
}