using System;
using UnityEngine;

namespace FastOcean
{
    [ExecuteInEditMode]
    public class FAntialiasing : FPostEffectsBase
    {
        [Range(0, 0.1f)]
        public float edgeThresholdMin = 0.05f;
        [Range(0, 1)]
        public float edgeThreshold = 0.2f;
        [Range(0, 10f)]
        public float edgeSharpness = 4.0f;

        public Shader shaderFXAAIII;
        private Material materialFXAAIII;
        
        protected override bool CheckResources()
        {
            CheckSupport(false);
            
            materialFXAAIII = CreateMaterial(shaderFXAAIII, materialFXAAIII);

            if (!shaderFXAAIII || !shaderFXAAIII.isSupported)
            {
                NotSupported();
                ReportAutoDisable();
                return false;
            }

            return isSupported;
        }

        void OnDestroy()
        {
            if (materialFXAAIII != null)
                DestroyImmediate(materialFXAAIII);
        }

        public void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            if (CheckResources() == false)
            {
                FOcean.BlitDontClear(source, destination, null);
                return;
            }

            // ----------------------------------------------------------------
            // FXAA antialiasing modes
            if (materialFXAAIII != null)
            {
                materialFXAAIII.SetFloat("_EdgeThresholdMin", edgeThresholdMin);
                materialFXAAIII.SetFloat("_EdgeThreshold", edgeThreshold);
                materialFXAAIII.SetFloat("_EdgeSharpness", edgeSharpness);

                FOcean.BlitDontClear(source, destination, materialFXAAIII);
            }
            else
            {
                // none of the AA is supported, fallback to a simple blit
                FOcean.BlitDontClear(source, destination, null);
            }
        }
    }
}
