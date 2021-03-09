using UnityEngine;
using System.Collections;

namespace FastOcean
{
	public enum GlareEffectResolution
	{
	    Low,
	    Normal,
	    High,
	}

	public class FGlareEffect : FPostEffectsBase 
	{
        public bool enableGlare = true;

        [Range(0, 2)]
	    public float attenuation = 0.95f;
        [Range(0, 1)]
	    public float intensity = 0.25f;
        [Range(0, 1)]
	    public float cutoff = 1.0f;

	    public GlareEffectResolution resolution = GlareEffectResolution.Normal;

		public Shader glareBlendShader;
	    private Material glareBlendMaterial;
		
		public Shader combineShader;
		private Material combineMaterial;
		
		protected override  bool CheckResources () {
			CheckSupport ();

	        glareBlendMaterial = CheckShaderAndCreateMaterial(glareBlendShader, glareBlendMaterial);
	        combineMaterial = CheckShaderAndCreateMaterial(combineShader, combineMaterial);
			
			if(!isSupported)
				ReportAutoDisable ();
			return isSupported;
		}
        
        void Awake()
        {
            if (Application.isPlaying)
                InvokeRepeating("CheckEnable", 0f, fixedTime);
        }

        protected override void CheckEnable()
        {
            if (FOcean.instance != null)
            {
                bool glareChanged = false;

                //avoid GC Alloc when understate changed
                bool bNeedIndeed = enableGlare && FOcean.instance.supportSM3;

                enabled = bNeedIndeed && !FOcean.instance.IntersectWater();

                if (enabled)
                {
                    if (!FOcean.instance.needDepthBehaviour.Contains(this))
                        FOcean.instance.needDepthBehaviour.Add(this);

                    if (!FOcean.instance.needGlareBehaviour.Contains(this))
                    {
                        FOcean.instance.needGlareBehaviour.Add(this);
                        glareChanged = true;
                    }
                }
                else
                {
                    FOcean.instance.needDepthBehaviour.Remove(this);
                    if (FOcean.instance.needGlareBehaviour.Contains(this) && !bNeedIndeed)
                    {
                        FOcean.instance.needGlareBehaviour.Remove(this);
                        glareChanged = true;
                    }
                }

                if(glareChanged)
                {
                    FOcean.instance.ForceReload(false);
                    glareChanged = false;
                }
            }
        }

        void OnDestroy()
        {
            if (glareBlendMaterial != null)
                DestroyImmediate(glareBlendMaterial);

            if (combineMaterial != null)
                DestroyImmediate(combineMaterial);

            CancelInvoke();

            if (FOcean.instance != null)
            {
                FOcean.instance.needDepthBehaviour.Remove(this);
                FOcean.instance.needGlareBehaviour.Remove(this);
                FOcean.instance.ForceReload(false);
            }
        }

        void OnRenderImage(RenderTexture source, RenderTexture destination) {
            if (glareBlendMaterial == null || CheckResources() == false || FOcean.instance == null ||
                !FOcean.instance.gameObject.activeSelf || FOcean.instance.envParam.sunLight == null)
            {
                FOcean.BlitDontClear(source, destination, null);
                return;
            }

            int divider = 4;
            if (resolution == GlareEffectResolution.Normal)
                divider = 2;
            else if (resolution == GlareEffectResolution.High)
                divider = 1;
            
            RenderTextureFormat rtFormat = FOcean.instance.rtR8Format;
	        float fDownRes = 1.0f / (float)divider;
	        int rtW4 = (int)(source.width * fDownRes);
	        int rtH4 = (int)(source.height * fDownRes);

            glareBlendMaterial.SetTexture("_MainTex", FOcean.instance.glaremap);
	        glareBlendMaterial.SetTexture("_OceanMap", FOcean.instance.oceanmap);
	        glareBlendMaterial.SetFloat("_Attenuation", attenuation);
	        glareBlendMaterial.SetFloat("_CutOff", cutoff);
	        glareBlendMaterial.SetVector("_TexelSize", new Vector4(1f / source.width, 1f / source.height, fDownRes / source.width, fDownRes / source.height));

			// Downsample
			RenderTexture quarterRezColor = RenderTexture.GetTemporary (rtW4, rtH4, 0, rtFormat);
            FOcean.Blit(FOcean.instance.glaremap, quarterRezColor, glareBlendMaterial, 0);

	        RenderTexture streakBuffer1 = RenderTexture.GetTemporary(rtW4, rtH4, 0, rtFormat);
	        RenderTexture streakBuffer2 = RenderTexture.GetTemporary(rtW4, rtH4, 0, rtFormat);
	        RenderTexture streakBuffer3 = RenderTexture.GetTemporary(rtW4, rtH4, 0, rtFormat);
	        RenderTexture streakBuffer4 = RenderTexture.GetTemporary(rtW4, rtH4, 0, rtFormat);
	        RenderTexture rtDown4 = RenderTexture.GetTemporary(rtW4, rtH4, 0, rtFormat);

	        // Streak filter top Right
	        glareBlendMaterial.SetTexture("_MainTex", quarterRezColor);
	        glareBlendMaterial.SetVector("_Direction", new Vector4(0.5f, 0.5f, 1.0f, 0.0f));
            FOcean.Blit(quarterRezColor, rtDown4, glareBlendMaterial, 1);

	        glareBlendMaterial.SetTexture("_MainTex", rtDown4);
	        glareBlendMaterial.SetVector("_Direction", new Vector4(0.5f, 0.5f, 2.0f, 0.0f));
            FOcean.Blit(rtDown4, streakBuffer1, glareBlendMaterial, 1);

	        // Streak filter Bottom left
	        glareBlendMaterial.SetTexture("_MainTex", quarterRezColor);
	        glareBlendMaterial.SetVector("_Direction", new Vector4(-0.5f, -0.5f, 1.0f, 0.0f));
            FOcean.Blit(quarterRezColor, rtDown4, glareBlendMaterial, 1);

	        glareBlendMaterial.SetTexture("_MainTex", rtDown4);
	        glareBlendMaterial.SetVector("_Direction", new Vector4(- 0.5f, -0.5f, 2.0f, 0.0f));
            FOcean.Blit(rtDown4, streakBuffer2, glareBlendMaterial, 1);

	        // Streak filter Bottom right
	        glareBlendMaterial.SetTexture("_MainTex", quarterRezColor);
	        glareBlendMaterial.SetVector("_Direction", new Vector4(0.5f, -0.5f, 1.0f, 0.0f));
            FOcean.Blit(quarterRezColor, rtDown4, glareBlendMaterial, 1);

	        glareBlendMaterial.SetTexture("_MainTex", rtDown4);
	        glareBlendMaterial.SetVector("_Direction", new Vector4(0.5f, -0.5f, 2.0f, 0.0f));
            FOcean.Blit(rtDown4, streakBuffer3, glareBlendMaterial, 1);

	        // Streak filter Top Left
	        glareBlendMaterial.SetTexture("_MainTex", quarterRezColor);
	        glareBlendMaterial.SetVector("_Direction", new Vector4(-0.5f, 0.5f, 1.0f, 0.0f));
            FOcean.Blit(quarterRezColor, rtDown4, glareBlendMaterial, 1);

	        glareBlendMaterial.SetTexture("_MainTex", rtDown4);
	        glareBlendMaterial.SetVector("_Direction", new Vector4(-0.5f, 0.5f, 2.0f, 0.0f));
            FOcean.Blit(rtDown4, streakBuffer4, glareBlendMaterial, 1);

	        //combine
	        combineMaterial.SetTexture("_MainTex", source);
	        combineMaterial.SetTexture("_StreakBuffer1", streakBuffer1);
	        combineMaterial.SetTexture("_StreakBuffer2", streakBuffer2);
	        combineMaterial.SetTexture("_StreakBuffer3", streakBuffer3);
	        combineMaterial.SetTexture("_StreakBuffer4", streakBuffer4);
	        combineMaterial.SetFloat("_Intensity", intensity);
            Color sunColor = FOcean.instance.envParam.sunLight.color;
            combineMaterial.SetColor("_FoSunColor", sunColor);

            FOcean.BlitDontClear(source, destination, combineMaterial);
	        
	        RenderTexture.ReleaseTemporary(rtDown4);
			RenderTexture.ReleaseTemporary(quarterRezColor);
	        RenderTexture.ReleaseTemporary(streakBuffer1);
	        RenderTexture.ReleaseTemporary(streakBuffer2);
	        RenderTexture.ReleaseTemporary(streakBuffer3);
	        RenderTexture.ReleaseTemporary(streakBuffer4);
		}
	}
}