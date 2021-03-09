
using UnityEngine;
using System.Collections;

namespace FastOcean
{
    [RequireComponent(typeof(Camera))]
    public class FPostEffectsBase : MonoBehaviour 
	{	
		protected bool supportHDRTextures = true;
		protected bool isSupported = true;
        
        /// <summary>
        /// A reference to the camera this component is added to.
        /// </summary>
        protected Camera m_Camera;


        protected float fixedTime = 0.1f;

        protected Material CheckShaderAndCreateMaterial(Shader s, Material m2Create)
	    {
			if (!s) { 
				Debug.Log("Missing shader in " + this.ToString ());
				enabled = false;
				return null;
			}
				
			if (s.isSupported && m2Create && m2Create.shader == s) 
				return m2Create;
			
			if (!s.isSupported) {
				NotSupported ();
				Debug.Log("The shader " + s.ToString() + " on effect "+this.ToString()+" is not supported on this platform!");
				return null;
			}
			else {
				m2Create = new Material (s);
#if UNITY_EDITOR
                m2Create.hideFlags = HideFlags.DontSave;
#endif
                if (m2Create) 
					return m2Create;
				else return null;
			}
		}

	    protected Material CreateMaterial(Shader s, Material m2Create)
	    {
			if (!s) { 
				Debug.Log ("Missing shader in " + this.ToString ());
				return null;
			}
				
			if (m2Create && (m2Create.shader == s) && (s.isSupported)) 
				return m2Create;
			
			if (!s.isSupported) {
				return null;
			}
			else {
				m2Create = new Material (s);
#if UNITY_EDITOR
                m2Create.hideFlags = HideFlags.DontSave;
#endif
                if (m2Create) 
					return m2Create;
				else return null;
			}
		}
		
		void OnEnable() {
			isSupported = true;
		}

	    protected virtual bool CheckResources()
	    {
			Debug.LogWarning ("CheckResources () for " + this.ToString() + " should be overwritten.");
			return isSupported;
		}
		
		protected virtual void Start () {
			 CheckResources ();
		}

        protected virtual void CheckEnable()
        {
        }

        protected  bool CheckSupport ()  {
			isSupported = true;
			supportHDRTextures = SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBHalf);
			
			//if (!SystemInfo.supportsImageEffects) {
			//	NotSupported ();
			//	return false;
			//}		
			
			if(!SystemInfo.SupportsRenderTextureFormat (RenderTextureFormat.Depth)) {
				NotSupported ();
				return false;
			}
			
			return true;
		}

	    protected bool CheckSupport(bool needHdr)
	    {
			if(!CheckSupport())
				return false;
			
			if(needHdr && !supportHDRTextures) {
				NotSupported ();
				return false;		
			}
			
			return true;
		}

	    protected void ReportAutoDisable()
	    {
			Debug.LogWarning ("The image effect " + ToString() + " has been disabled as it's not supported on the current platform.");
		}
				
		// deprecated but needed for old effects to survive upgrading
	    protected bool CheckShader(Shader s) 
	    {
			Debug.Log("The shader " + s.ToString () + " on effect "+ ToString () + " is not part of the Unity 3.2+ effects suite anymore. For best performance and quality, please ensure you are using the latest Standard Assets Image Effects (Pro only) package.");		
			if (!s.isSupported) {
				NotSupported ();
				return false;
			} 
			else {
				return false;
			}
		}

	    protected void NotSupported()
	    {
			enabled = false;
			isSupported = false;
			return;
		}
	}
}