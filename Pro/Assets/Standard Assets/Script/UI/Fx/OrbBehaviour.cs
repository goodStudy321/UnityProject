using UnityEngine;
using UnityEngine.UI;

namespace guiraffe.SubstanceOrb
{
    [RequireComponent(typeof(Renderer))]
    public class OrbBehaviour : MonoBehaviour
    {
        Material material;

        protected Material Material
        {
            get
            {
                if (Application.isPlaying)
                {
                    if (material == null)
                    {
                        ObjRenderer.sharedMaterial = Instantiate(ObjRenderer.sharedMaterial);

                        OrbBehaviour[] behaviours = GetComponents<OrbBehaviour>();
                        foreach (OrbBehaviour behaviour in behaviours)
                        {
                            behaviour.material = ObjRenderer.sharedMaterial;
                        }
                    }

                    return material;
                }

                return ObjRenderer.sharedMaterial;
            }
        }

        protected Renderer ObjRenderer
        {
            get { return GetComponent<Renderer>(); }
        }
    }
}