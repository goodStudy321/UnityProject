using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace FastOcean
{
	[ExecuteInEditMode]
    [DisallowMultipleComponent]
    public class FObject : MonoBehaviour
    {
        public bool castShadow = true;

        private Renderer[] renderers = null;

        public virtual void Start()
        {
            renderers = gameObject.GetComponentsInChildren<Renderer>();
        }

        public Renderer[] GetRenderers()
        {
            return renderers;
        }

        private List<int> tmpLayers = new List<int>();

        internal void CacheShadowLayer()
        {
            for (int i = 0; i < renderers.Length; i++)
            {
                Renderer render = renderers[i];
                if (render == null)
                    continue;
                
                if (render.gameObject.layer == FOcean.instance.layerDef.transparentlayer)
                    continue;

                if (render.gameObject.layer == FOcean.instance.layerDef.traillayer)
                    continue;

                if (render.gameObject.layer == FOcean.instance.layerDef.waterlayer)
                    continue;

                tmpLayers.Add(render.gameObject.layer);
                render.gameObject.layer = FOcean.instance.layerDef.shadowlayer;
            }
        }

        internal void RestoreShadowLayer()
        {
            if (tmpLayers.Count == 0)
                return;

            for (int i = 0; i < renderers.Length; i++)
            {
                Renderer render = renderers[i];
                if (render == null)
                    continue;

                if (render.gameObject.layer == FOcean.instance.layerDef.transparentlayer)
                    continue;

                if (render.gameObject.layer == FOcean.instance.layerDef.traillayer)
                    continue;

                if (render.gameObject.layer == FOcean.instance.layerDef.waterlayer)
                    continue;

                render.gameObject.layer = tmpLayers[i];
            }

            tmpLayers.Clear();
        }

        public void Update()
        {
            if (FOcean.instance != null)
                FOcean.instance.AddFObject(this);
        }

        public float SumBoundSize()
        {
            float size = 0f;
            for (int i = 0; i < renderers.Length; i++)
            {
                Renderer render = renderers[i];
                if (render == null)
                    continue;

                size += render.bounds.size.magnitude;
            }

            return size;
        }

        public void OnDisable()
        {
            if (FOcean.instance != null)
                FOcean.instance.RemoveFObject(this);
        }

        public void OnDestroy()
        {
            if (FOcean.instance != null)
                FOcean.instance.RemoveFObject(this);
        }
    }
}