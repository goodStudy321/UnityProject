using UnityEngine;
using System.Collections;

namespace FastOcean
{
    [ExecuteInEditMode]
    public class FScaleScreen : FPostEffectsBase
    {
        [Range(0,2)]
        public int scale = 1;

        private Camera m_CurMainCamera = null;

        void OnEnable()
        {
            if (rt == null || rt.width != (Screen.width >> scale) || rt.height != (Screen.height >> scale))
            {
                if(Screen.width != 0 && Screen.height != 0)
                {
                    RenderTexture.ReleaseTemporary(rt);
                    rt = RenderTexture.GetTemporary(Screen.width >> scale, Screen.height >> scale, 16);
                }
            }

            // Misc
            m_Camera = GetComponent<Camera>();

            m_Camera.enabled = true;
            //See "Performance Tunning for Tile-Based Architecture"
            m_Camera.clearFlags = CameraClearFlags.SolidColor;
            m_Camera.depthTextureMode = DepthTextureMode.None;

            m_CurMainCamera = Camera.main;

            if(m_CurMainCamera != null)
               m_CurMainCamera.targetTexture = rt;

            FOcean.target = rt;
        }

        protected override bool CheckResources()
        {
            return rt != null;
        }

        RenderTexture rt = null;

        void Update()
        {
            if (Camera.main == null)
                return;

            if(m_CurMainCamera != Camera.main)
            {
                m_CurMainCamera.cullingMask = 0x7FFFFFFF;
                m_CurMainCamera.cullingMask &= ~(1 << FOcean.instance.layerDef.traillayer);
                m_CurMainCamera.targetTexture = null;

                m_CurMainCamera = Camera.main;
            }

            if (FOcean.instance == null)
                return;

            if ((FOcean.instance.mobile || !FOcean.instance.supportSM3) && scale == 0)
                scale = 1;

            if (scale == 0)
            {
                m_Camera.enabled = false;
                Camera.main.cullingMask = 0x7FFFFFFF;
                Camera.main.cullingMask &= ~(1 << FOcean.instance.layerDef.traillayer);
                Camera.main.targetTexture = null;

                if (rt != null)
                {
                    RenderTexture.ReleaseTemporary(rt);
                    rt = null;
                }

                FOcean.instance.targetResWidth = -1;
                FOcean.instance.targetResHeight = -1;

                FOcean.target = null;
                return;
            }


            m_Camera.enabled = true;
            m_Camera.cullingMask = 1 << FOcean.instance.layerDef.uilayer;

#if UNITY_EDITOR
            m_Camera.transform.position = Vector3.zero;
            m_Camera.transform.rotation = Quaternion.identity;
            m_Camera.transform.localScale = Vector3.zero;
#endif

            if (rt == null || rt.width != (Screen.width >> scale) || rt.height != (Screen.height >> scale))
            {
                if (Screen.width != 0 && Screen.height != 0)
                {
                    Camera.main.targetTexture = null;
                    RenderTexture.ReleaseTemporary(rt);
                    rt = RenderTexture.GetTemporary(Screen.width >> scale, Screen.height >> scale, 16);
                }
            }

            FOcean.instance.targetResWidth = Screen.width >> scale;
            FOcean.instance.targetResHeight = Screen.height >> scale;

            FOcean.target = rt;

            Camera.main.targetTexture = rt;
            Camera.main.cullingMask = ~(1 << FOcean.instance.layerDef.uilayer);
            Camera.main.cullingMask &= ~(1 << FOcean.instance.layerDef.traillayer);
        }

        void OnDisable()
        {
            GetComponent<Camera>().enabled = false;

            if (Camera.main != null)
            {
                Camera.main.cullingMask = 0x7FFFFFFF;
                Camera.main.targetTexture = null;
            }

            RenderTexture.ReleaseTemporary(rt);

            if (FOcean.instance != null)
            {
                FOcean.instance.targetResWidth = -1;
                FOcean.instance.targetResHeight = -1;
            }

            FOcean.target = null;

            rt = null;
        }

        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            //ugly hack
            FOcean.target = null;
            FOcean.BlitDontClear(rt, destination, null);
            FOcean.target = rt;
        }

    }
}
