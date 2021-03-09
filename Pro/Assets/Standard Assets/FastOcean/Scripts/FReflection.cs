
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace FastOcean
{
	[ExecuteInEditMode]
	[RequireComponent(typeof(FOcean))]
	public class FReflection : MonoBehaviour 
	{
        public const System.String reflectionSampler = "_Reflection";
        
        private Camera reflectionCamera = null;

        private bool isStarted = false;

        void OnEnable()
        {
#if UNITY_EDITOR
            hideFlags = HideFlags.HideInInspector;
#endif
            if(!isStarted)
               StartCoroutine(Init());
        }

        IEnumerator Init()
        {
            while (FOcean.instance == null)
            {
                yield return null;
            }
			
			CreateReflectionCameraFor();
            isStarted = true;
        }

	    public void Update()
	    {
            ClearRenderTexs();
	    }
		
		private Camera CreateReflectionCameraFor() 
		{		
			GameObject go = GameObject.Find(FOcean.reflCameraName);

	        if (!go)
	        {
	            go = new GameObject(FOcean.reflCameraName, typeof(Camera));
	            go.transform.parent = FOcean.instance.transform;
	        }
			if(!go.GetComponent(typeof(Camera)))
				go.AddComponent(typeof(Camera));
			Camera reflectCamera = go.GetComponent<Camera>();

            reflectCamera.enabled = false;
			
			return reflectCamera;
		}

		private RenderTexture CreateTextureFor(Camera cam, FReflParameters reflParam) 
		{
            eFRWQuality quality = reflParam.quality;
            //if (FOcean.instance.mobile)
            //    quality = eFRWQuality.Low;

            bool blurEnabled = reflParam.blurEnabled;

            int shifter = blurEnabled ? (int)quality >> 1 : (int)quality;

            RenderTexture rt = RenderTexture.GetTemporary((int)(Screen.width >> shifter), (int)(Screen.height >> shifter), 16);
            //rt.useMipMap = false;
            //rt.filterMode = FilterMode.Point;
            //rt.hideFlags = HideFlags.DontSave;
            //rt.Create();
			return rt;
		}	
		
		public void WaterTileBeingRendered (Camera currentCam, float planeH, Material mat, FReflParameters reflParam) 
		{
            if (currentCam == reflectionCamera)
                return;

	        if (reflectionCamera == null)
	            reflectionCamera = CreateReflectionCameraFor();

            RenderTexture rt = RenderReflectionFor(currentCam, planeH, reflParam);

	        if (reflectionCamera && mat)
	        {
                mat.SetTexture(reflectionSampler, rt);			
			} 	
		}

		public void WaterTileClear (Material material) 
		{
			if (material)
			{
				material.SetTexture(reflectionSampler, null);			
			}

            if (reflectionCamera != null)
                reflectionCamera.targetTexture = null;
		}

        void ClearRenderTexs()
        {
            var _e = dic_RenderTexs.GetEnumerator();
            while (_e.MoveNext())
            {
                Dictionary<float, RenderTexture> dicVal = _e.Current.Value;
                var __e = dicVal.GetEnumerator();
                while (__e.MoveNext())
                {
                    RenderTexture.ReleaseTemporary(__e.Current.Value);
                }

                dicVal.Clear();
            }
        }

        void OnDestroy()
        {
            ClearRenderTexs();
            dic_RenderTexs.Clear();
        }

        Dictionary<Camera, Dictionary<float, RenderTexture>> dic_RenderTexs = new Dictionary<Camera, Dictionary<float, RenderTexture>>();
		private RenderTexture RenderReflectionFor (Camera cam, float planeH, FReflParameters reflParam) 
		{
            RenderTexture rt = null;
			if(!reflectionCamera)
                return rt;

            Dictionary<float, RenderTexture> dicVal = null;
            if (!dic_RenderTexs.TryGetValue(cam, out dicVal))
            {
                dicVal = new Dictionary<float, RenderTexture>();
                dic_RenderTexs.Add(cam, dicVal);
            }
            
            //render reflection to rt at planeH
            if (!dicVal.TryGetValue(planeH, out rt))
            {
                rt = CreateTextureFor(cam, reflParam);
                dicVal.Add(planeH, rt);

                float depth = reflectionCamera.depth;
                reflectionCamera.CopyFrom(cam);
                reflectionCamera.rect = new Rect(0, 0, 1, 1);

				reflectionCamera.clearFlags = reflParam.useSkybox ? CameraClearFlags.Skybox : CameraClearFlags.Color;
				if(!reflParam.useSkybox)
					reflectionCamera.backgroundColor = reflParam.clearColor;
						
                reflectionCamera.depth = depth;
                reflectionCamera.enabled = true;
                reflectionCamera.targetTexture = rt;
                reflectionCamera.renderingPath = RenderingPath.VertexLit;

                reflectionCamera.cullingMask &= reflParam.reflectionMask & ~(1 << FOcean.instance.layerDef.waterlayer);
                reflectionCamera.cullingMask &= ~(1 << FOcean.instance.layerDef.transparentlayer);
                reflectionCamera.cullingMask &= ~(1 << FOcean.instance.layerDef.uilayer);
                reflectionCamera.cullingMask &= ~(1 << FOcean.instance.layerDef.traillayer);

                reflectionCamera.depthTextureMode = DepthTextureMode.None;

                bool tmpCull = GL.invertCulling;

                GL.invertCulling = true;
                
                Vector3 normal = Vector3.up;
                float d = planeH + reflParam.clipPlaneOffset;
                Vector4 reflectionPlane = new Vector4(normal.x, normal.y, normal.z, -d);

                Matrix4x4 reflection = Matrix4x4.identity;
                CalculateReflectionMatrix(ref reflection, reflectionPlane);

                reflectionCamera.worldToCameraMatrix = reflectionCamera.worldToCameraMatrix * reflection;

                Vector4 clipPlane = CameraSpacePlane(reflectionCamera, normal, planeH);

                //reflectCamera.CalculateObliqueMatrix is worse, so self Achieve
                Matrix4x4 projection = reflectionCamera.projectionMatrix;
                CalculateObliqueMatrix(ref projection, clipPlane);
                reflectionCamera.projectionMatrix = projection;

                reflectionCamera.transform.position = reflection.MultiplyPoint3x4(reflectionCamera.transform.position);
                Vector3 euler = reflectionCamera.transform.eulerAngles;
                reflectionCamera.transform.eulerAngles = new Vector3(-euler.x, euler.y, euler.z);


                int oldPixelLightCount = QualitySettings.pixelLightCount;
                QualitySettings.pixelLightCount = 0;

                LightShadows oldShadows = LightShadows.None;

                if (FOcean.instance.envParam.sunLight != null)
                {
                    oldShadows = FOcean.instance.envParam.sunLight.shadows;
                    FOcean.instance.envParam.sunLight.shadows = LightShadows.None;
                }

                reflectionCamera.Render();

                QualitySettings.pixelLightCount = oldPixelLightCount;

                if (FOcean.instance.envParam.sunLight != null)
                    FOcean.instance.envParam.sunLight.shadows = oldShadows;
                
                reflectionCamera.enabled = false;

                GL.invertCulling = tmpCull;

                Material blurMat = QualitySettings.activeColorSpace == ColorSpace.Linear ?
                    FOcean.instance.matBlurLinear : FOcean.instance.matBlur;

                if (reflParam.blurEnabled && blurMat != null)
                {
                    int rtW = rt.width >> 1;
                    int rtH = rt.height >> 1;

                    RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0, rt.format);
                    RenderTexture buffer2 = RenderTexture.GetTemporary(rtW, rtH, 0, rt.format);

                    // down sampler once
                    FOcean.BlurTapCone(rt, buffer, blurMat, 0f);

                    // blur
                    const int blurIterations = 1;
                    for (int i = 0; i < blurIterations; i++)
                    {
                        FOcean.BlurTapCone(buffer, buffer2, blurMat, i + reflParam.blurSpread);
                        //swap buffer
                        RenderTexture tmp = buffer;
                        buffer = buffer2;
                        buffer2 = tmp;
                    }

                    FOcean.Blit(buffer, rt, null);
                    RenderTexture.ReleaseTemporary(buffer);
                    RenderTexture.ReleaseTemporary(buffer2);
                }
            }

            return rt;
		}

	    void CalculateObliqueMatrix(ref Matrix4x4 projection, Vector4 clipPlane)
	    {
			Vector4 q = projection.inverse * new Vector4(
	            Mathf.Sign(clipPlane.x),
                Mathf.Sign(clipPlane.y),
	            1.0F,
	            1.0F
	        );
	        Vector4 c = clipPlane * (2.0F / (Vector4.Dot(clipPlane, q)));
	        // third row = clip plane - fourth row
	        projection[2] = c.x;
	        projection[6] = c.y;
	        projection[10] = c.z + 1f;
	        projection[14] = c.w;
	    }	
		 
	    void CalculateReflectionMatrix (ref Matrix4x4 reflectionMat, Vector4 plane) 
		{
		    reflectionMat.m00 = (1.0F - 2.0F*plane[0]*plane[0]);
		    reflectionMat.m01 = (   - 2.0F*plane[0]*plane[1]);
		    reflectionMat.m02 = (   - 2.0F*plane[0]*plane[2]);
		    reflectionMat.m03 = (   - 2.0F*plane[3]*plane[0]);
		
		    reflectionMat.m10 = (   - 2.0F*plane[1]*plane[0]);
		    reflectionMat.m11 = (1.0F - 2.0F*plane[1]*plane[1]);
		    reflectionMat.m12 = (   - 2.0F*plane[1]*plane[2]);
		    reflectionMat.m13 = (   - 2.0F*plane[3]*plane[1]);
		
		   	reflectionMat.m20 = (   - 2.0F*plane[2]*plane[0]);
		   	reflectionMat.m21 = (   - 2.0F*plane[2]*plane[1]);
		   	reflectionMat.m22 = (1.0F - 2.0F*plane[2]*plane[2]);
		   	reflectionMat.m23 = (   - 2.0F*plane[3]*plane[2]);
		
		   	reflectionMat.m30 = 0.0F;
		   	reflectionMat.m31 = 0.0F;
		   	reflectionMat.m32 = 0.0F;
		   	reflectionMat.m33 = 1.0F;
		}
		
		private Vector4 CameraSpacePlane (Camera cam, Vector3 normal, float planeH) 
		{
			Matrix4x4 m = cam.worldToCameraMatrix;
			Vector3 cpos = m.MultiplyPoint3x4 (normal * planeH);
			Vector3 cnormal = m.MultiplyVector (normal).normalized;
			
			return new Vector4 (cnormal.x, cnormal.y, cnormal.z, -Vector3.Dot (cpos,cnormal));
		}
	}
}