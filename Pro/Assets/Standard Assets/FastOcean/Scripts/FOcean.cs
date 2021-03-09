
#if UNITY_IPHONE || UNITY_ANDROID || UNITY_WP8 || UNITY_BLACKBERRY
#define MOBILE
#endif

using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.Rendering;

namespace FastOcean
{
    public enum eFShaderMode
    {
        Fast = 0,
        High = 1,
        FFT = 2,
    }

    public enum eFFTResolution
    {
        Small = 32,
        Medium = 64,
        Large = 128,
    }

    public enum eFRWQuality
    {
        High = 0,
        Medium = 1,
        Low = 2,
    }

    public enum eFSDQuality
    {
        High = 0,
        Medium = 1,
        Low = 2,
    }

    public enum eFUnderWaterMode
    {
        Blend,
        Simple,
        None,
    }

    public enum eFBlendMode
    {
        Depth,
        Alpha,
        None,
    }

    public enum eFUnderWater
    {
        Above,
        AboveIntersect,
        UnderIntersect,
        Under,
    }

	[Serializable]
	public class FEnvParameters
	{
        public Light sunLight;

        public eFBlendMode blendMode = eFBlendMode.Depth;

        public eFUnderWaterMode underWaterMode = eFUnderWaterMode.Blend;

        [Range(0.1f, 1f)]
        public float underDepth = 1f;
        public float depthFade = 250f;
        public float surfaceFade = 200f;
        
        public Color underColor = new Color(0.0f, 0.31f, 0.52f, 1);
        public Color underAmb = new Color(0.72f, 0.74f, 0.835f, 1);

        [Range(0f, 0.1f)]
        public float distortMag = 0.01f;
        public float distortFrq = 200f;

        public Texture2D distortMap = null;
        public Shader underWaterShader = null;

        public Mesh underButtom = null;

        [Range(2, 16)]
        public int skirt = 4;
        
        public Transform trailer = null;

        [Range(256, 1024)]
        public int trailMapSize = 512;
        [Range(0.01f, 1)]
        public float trailMapScale = 0.2f;
        public float trailMapFade = 10.0f;
        public float trailIntensity = 1f;

        public bool shadowEnabled = true;

        public eFSDQuality shadowQuality = eFSDQuality.Medium;
        public float shadowDistance = 7f;
        public float shadowStrength = 0.9f;
        public float shadowDistort = 0.03f;
        public float shadowFade = 0.9f;
    }

    [Serializable]
    public class FShaderPack
    {   
        public Shader fade = null;
        public Shader blur = null;
        public Shader blurLinear = null;
        public Shader cull = null;
        public Shader shadow = null;
        public Shader clear = null;
        public Shader initspectrum = null;
        public Shader spectrum = null;
        public Shader wtable = null;
        public Shader fourier = null;
    }

    [Serializable]
    public class FLayerDefinition
    {
        //Definition
        public int transparentlayer = 1;
        public int waterlayer = 4;
        public int uilayer = 5;
        public int traillayer = 6;
        public int terrainlayer = 7;
        public int shadowlayer = 30;
    }

	[DisallowMultipleComponent]
	[ExecuteInEditMode]
	public class FOcean : MonoBehaviour
    {
        public const string version = "1.1.6";

        //Shader LOD
        public const int LOD = 200;//only for editor
        public const int ABOVELODSM3EX = LOD + 5;
        public const int ABOVELODSM3 = LOD + 4;
        public const int ABOVELOD = LOD + 3;
        public const int UNDERLODSM3 = LOD + 2;
        public const int UNDERLOD = LOD + 1;
	    public const int OCEANLOD = LOD - 1;
	    public const int UNDEROCEANLOD = LOD - 2;
        public const int UNDEROCEANLOD2 = LOD - 3;
        public const int GlARELOD = LOD - 4;
        
	    public const float g = 9.80665f;

        public const string projectorCameraName = "FOProjectorCamera";
        public const string trailCameraName = "FOTrailCamera";
        public const string reflCameraName = "FOReflectionCamera";
        public const string oceanCameraName = "FOceanMapCamera";
        public const string shadowCameraName = "FShadowCamera";

        [NonSerialized]
        public bool needSM3 = true;

#if UNITY_EDITOR
        [NonSerialized]
        public bool drawButtomGizmos = false;
#endif

        public FEnvParameters envParam = new FEnvParameters();

	    private FReflection reflection;

	    public static FOcean instance = null;

	    private FOceanGrid mainGrid;

	    private HashSet<FOceanGrid> grids = new HashSet<FOceanGrid>();
        private HashSet<FObject> objs = new HashSet<FObject>();

        public FShaderPack shaderPack = new FShaderPack();

        public FLayerDefinition layerDef = new FLayerDefinition();
        
        [NonSerialized]
	    public Material matFade = null;
        [NonSerialized]
        public Material matBlur = null;
        [NonSerialized]
        public Material matBlurLinear = null;
        [NonSerialized]
        public Material matCull = null;
        [NonSerialized]
        public Material matClear = null;
        [NonSerialized]
        public Material matInitSpec = null;
        [NonSerialized]
        public Material matSpectrum = null;
        [NonSerialized]
        public Material matWtable = null;
        [NonSerialized]
        public Material matFourier = null;

        private LinkedListNode<RenderTexture> queueNode = null;
        private LinkedList<RenderTexture> queueRTs = new LinkedList<RenderTexture>();

        private Camera shadowCamera = null;
        private Camera oceanCamera = null;
        private Camera trailCamera = null;
        
        private RenderTexture shadowmap = null;

        private RenderTexture trailmap = null;
        [NonSerialized]
        public RenderTexture oceanmap = null;
        [NonSerialized]
        public RenderTexture glaremap = null;

        [NonSerialized]
        public bool isStarted = false;

        private bool m_bSunGlare = false;

        private bool m_bShadowEnabled = true;
        private eFSDQuality m_shadowQuality = eFSDQuality.Medium;

        private eFUnderWaterMode m_underMode = eFUnderWaterMode.Blend;
        
        private int m_TrailMapSize = 512;
        private Transform m_trailer = null;

        [NonSerialized]
        public RenderTextureFormat rtR8Format = RenderTextureFormat.R8;

        [NonSerialized]
        public HashSet<MonoBehaviour> needDepthBehaviour = new HashSet<MonoBehaviour>();

        [NonSerialized]
        public HashSet<MonoBehaviour> needGlareBehaviour = new HashSet<MonoBehaviour>();

        [NonSerialized]
        private eFUnderWater underState = eFUnderWater.Above;

        [NonSerialized]
        public int targetResWidth = -1;
        [NonSerialized]
        public int targetResHeight = -1;

        private int m_targetWidth = -1;
        private int m_targetHeight = -1;
        
        public static RenderTexture target = null;

        [NonSerialized]
        public double gTime = 0f;

        private void AcquireComponents()
	    {
	        if (Camera.main == null)
	            return;

            if (instance == null)
                return;

            transform.gameObject.layer = layerDef.waterlayer;

	        // set up camera
	        if (envParam.trailer != null)
	        {
                Camera.main.cullingMask &= ~(1 << layerDef.traillayer);
	        }
	        else
	        {
                Camera.main.cullingMask |= (1 << layerDef.traillayer);
	        }

            if (!envParam.sunLight)
            {
                Light[] lights = Light.GetLights(LightType.Directional, -1);
                if (lights != null && lights.Length > 0)
                {
                    envParam.sunLight = lights[0];
                }
            }
	    }

	    [NonSerialized]
        public bool supportSM3, mobile;

	    void CheckInstance()
	    { 
	        if (instance == null)
	        {
	            instance = this;
	        }
	        else if (instance != this)
	        {
	            Debug.LogWarning("Only can have one FOcean Script instance in scene, Please check!");
	            DestroyImmediate(gameObject);
	        }
	    }

        Material CreateMaterial(ref Shader shader, string shaderName)
        {
            Material newMat = null;
            if (shader == null)
            {
                Debug.LogWarningFormat("ShaderName: " + shaderName.ToString() + " is missing, would find the shader, then please save FOcean prefab.");
                shader = Shader.Find(shaderName);
            }

            if (shader == null)
            {
                Debug.LogError("FOcean CreateMaterial Failed.   ShaderName: " + shaderName.ToString());
                return newMat;
            }


            newMat = new Material(shader);
#if UNITY_EDITOR
            newMat.hideFlags = HideFlags.DontSave;
#endif

            return newMat;
        }

        public void GenAllMaterial()
        {
            matFade = CreateMaterial(ref shaderPack.fade, "Hidden/FastOcean/Fade");
            matBlur = CreateMaterial(ref shaderPack.blur, "Hidden/FastOcean/BlurEffectConeTap");
            matBlurLinear = CreateMaterial(ref shaderPack.blurLinear, "Hidden/FastOcean/BlurEffectConeTapLinear");
            matCull = CreateMaterial(ref shaderPack.cull, "Hidden/FastOcean/CullMask");
            matClear = CreateMaterial(ref shaderPack.clear, "Hidden/FastOcean/SimpleClear");
            matInitSpec = CreateMaterial(ref shaderPack.initspectrum, "Hidden/FastOcean/InitialSpectrum");
            matSpectrum = CreateMaterial(ref shaderPack.spectrum, "Hidden/FastOcean/SpectrumFragment");
            matWtable = CreateMaterial(ref shaderPack.wtable, "Hidden/FastOcean/WTable");
            matFourier = CreateMaterial(ref shaderPack.fourier, "Hidden/FastOcean/Fourier");
        }


        public void DestroyAllMaterial()
        {
            DestroyMaterial(ref matFade);
            DestroyMaterial(ref matBlur);
            DestroyMaterial(ref matBlurLinear);
            DestroyMaterial(ref matCull);
            DestroyMaterial(ref matClear);
            DestroyMaterial(ref matSpectrum);
            DestroyMaterial(ref matInitSpec);
            DestroyMaterial(ref matWtable);
            DestroyMaterial(ref matFourier);

        }

        void Awake()
	    {
            CheckInstance();

            supportSM3 = needSM3 && SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.Depth) &&
                SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.RHalf) &&
                SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBHalf);

            rtR8Format = SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.R8) ? RenderTextureFormat.R8 : RenderTextureFormat.Default;

            if (supportSM3)
            {
                supportSM3 = SystemInfo.graphicsDeviceType != GraphicsDeviceType.OpenGLES2;
            }

            GenAllMaterial();

#if MOBILE
            mobile = true;
            
            if (Application.isPlaying)
	        {
                if (envParam.blendMode == eFBlendMode.Depth && !supportSM3)
		        {
                    envParam.blendMode = eFBlendMode.Alpha;
                    Debug.LogWarning("DepthBlend is not supported, turn to alphaBlend.");
		        }

                if (envParam.underWaterMode == eFUnderWaterMode.Blend && !supportSM3)
                {
                    envParam.underWaterMode = eFUnderWaterMode.Simple;
                    Debug.LogWarning("UnderWater Effect is simplified.");
                }

                if (envParam.shadowEnabled && !supportSM3)
                {
                    envParam.shadowEnabled = false;
                    Debug.LogWarning("ShadowEffect not supported.");
                }
            }
#else
            if (Application.isPlaying)
	        {
                if (envParam.blendMode == eFBlendMode.Depth && !supportSM3)
		        {
                    envParam.blendMode = eFBlendMode.Alpha;
                    Debug.LogWarning("DepthBlend is not supported, turn to alphaBlend.");
		        }

                if (envParam.underWaterMode == eFUnderWaterMode.Blend && !supportSM3)
                {
                    envParam.underWaterMode = eFUnderWaterMode.Simple;
                    Debug.LogWarning("UnderWater Effect is simplified.");
                }

                if (envParam.shadowEnabled && !supportSM3)
                {
                    envParam.shadowEnabled = false;
                    Debug.LogWarning("ShadowEffect is not supported.");
                }
            }

            mobile = false;
#endif
            
            //Debug.LogWarning(SystemInfo.supportedRenderTargetCount);

        }

        void OnEnable()
        {
#if UNITY_EDITOR
            transform.hideFlags = HideFlags.HideInInspector;
#endif
        }

        // Use this for initialization
        void Start()
	    {
	        AcquireComponents();

#if UNITY_EDITOR
            transform.hideFlags = HideFlags.HideInInspector;
#endif

            queueRTs.Clear();

            if (trailCamera == null)
            {
                GameObject go = GameObject.Find(trailCameraName);

                if (!go)
                {
                    go = new GameObject(trailCameraName, typeof(Camera));
                    go.transform.parent = transform;
                }
                if (!go.GetComponent(typeof(Camera)))
                    go.AddComponent(typeof(Camera));
                trailCamera = go.GetComponent<Camera>();
            }

            trailCamera.backgroundColor = Color.black;
            trailCamera.clearFlags = CameraClearFlags.SolidColor;
            trailCamera.renderingPath = RenderingPath.Forward;

            trailCamera.cullingMask = 1 << layerDef.traillayer;
            trailCamera.enabled = false;

            if (mobile)
            {
                envParam.trailMapSize = Mathf.Min(envParam.trailMapSize, 512);
            }

            if (oceanCamera == null)
            {
                GameObject go = GameObject.Find(oceanCameraName);

                if (!go)
                {
                    go = new GameObject(oceanCameraName, typeof(Camera));
                    go.transform.parent = transform;
                }
                if (!go.GetComponent(typeof(Camera)))
                    go.AddComponent(typeof(Camera));
                oceanCamera = go.GetComponent<Camera>();
            }

            oceanCamera.backgroundColor = Color.clear;
            oceanCamera.clearFlags = CameraClearFlags.SolidColor;

            oceanCamera.cullingMask = 1 << layerDef.waterlayer;
            oceanCamera.enabled = false;
            oceanCamera.renderingPath = RenderingPath.Forward;
            oceanCamera.targetTexture = null;

            if (shadowCamera == null)
            {
                GameObject go = GameObject.Find(shadowCameraName);

                if (!go)
                {
                    go = new GameObject(shadowCameraName, typeof(Camera));
                    go.transform.parent = transform;
                }
                if (!go.GetComponent(typeof(Camera)))
                    go.AddComponent(typeof(Camera));
                shadowCamera = go.GetComponent<Camera>();
            }

            shadowCamera.backgroundColor = Color.white;
            shadowCamera.clearFlags = CameraClearFlags.SolidColor;
            shadowCamera.orthographic = true;
            shadowCamera.enabled = false;
            shadowCamera.targetTexture = null;

            GenBuffer();

            UnderStateCache();

            isStarted = true;
	    }

        private Vector2 GetTargetRes(out int useResWidth, out int useResHeight)
        {
            if (targetResWidth != -1)
                useResWidth = targetResWidth;
            else
                useResWidth = Screen.width;

            if (targetResHeight != -1)
                useResHeight = targetResHeight;
            else
                useResHeight = Screen.height;

            if (targetResHeight != -1 && targetResWidth != -1)
                return new Vector2((float)useResHeight / Screen.height,(float)useResWidth / Screen.width);
            else
                return Vector2.one;
        }

        void GenBuffer()
        {
            m_bSunGlare = needGlareBehaviour.Count > 0;
            m_underMode = envParam.underWaterMode;
            m_shadowQuality = envParam.shadowQuality;
            m_trailer = envParam.trailer;
            m_TrailMapSize = envParam.trailMapSize;
            m_bShadowEnabled = envParam.shadowEnabled;

            simpleUnderFlag = !supportSM3 || envParam.underWaterMode != eFUnderWaterMode.Blend;

            Vector2 factorRes = GetTargetRes(out m_targetWidth, out m_targetHeight);

            if (envParam.trailer != null)
            {
                int resMaskW = (int)(envParam.trailMapSize * factorRes.x);
                int resMaskH = (int)(envParam.trailMapSize * factorRes.y);
                trailmap = new RenderTexture(resMaskW, resMaskH, 0);
                trailmap.filterMode = mobile ? FilterMode.Bilinear : FilterMode.Trilinear;
                trailmap.useMipMap = true;
                trailmap.wrapMode = TextureWrapMode.Clamp;
                trailmap.Create();
                trailmap.name = "FOcean.Buffer";
                trailmap.DiscardContents();
#if UNITY_EDITOR
                trailmap.hideFlags = HideFlags.DontSave;
#endif
                queueRTs.AddLast(trailmap);
            }

            if (!supportSM3)
                return;
            
            if (m_bSunGlare || envParam.underWaterMode == eFUnderWaterMode.Blend)
            {
                oceanmap = new RenderTexture(m_targetWidth, m_targetHeight, 16, RenderTextureFormat.RHalf);
                oceanmap.filterMode = FilterMode.Point;
                oceanmap.useMipMap = false;
                oceanmap.Create();
                oceanmap.name = "FOcean.oceanmap";
                oceanmap.DiscardContents();
#if UNITY_EDITOR
                oceanmap.hideFlags = HideFlags.DontSave;
#endif
                // to clear color
                RenderTexture.active = oceanmap;
                GL.Clear(true, true, Color.clear);

                queueRTs.AddLast(oceanmap);
            }

            if (m_bSunGlare)
            {
				//downsample
                int shifter = mobile ? 3 : 2;

                //keep screen width for glare size
                glaremap = new RenderTexture(Screen.width >> shifter, Screen.height >> shifter, 0, rtR8Format);
                glaremap.filterMode = FilterMode.Point;
                glaremap.useMipMap = false;
                glaremap.Create();
                glaremap.name = "FOcean.glaremap";
                glaremap.DiscardContents();
#if UNITY_EDITOR
                glaremap.hideFlags = HideFlags.DontSave;
#endif
                // to clear color
                RenderTexture.active = glaremap;
                GL.Clear(true, true, Color.clear);

                queueRTs.AddLast(glaremap);
            }

            if(envParam.shadowEnabled)
            {
                int resShadow = mobile ? 1024 : 2048; 
                //keep screen width for shadow size
                shadowmap = new RenderTexture(resShadow >> (int)envParam.shadowQuality, resShadow >> (int)envParam.shadowQuality, 16, RenderTextureFormat.RHalf);
                shadowmap.filterMode = FilterMode.Point;
                shadowmap.useMipMap = false;
                shadowmap.Create();
                shadowmap.name = "FOcean.shadowmap";
                shadowmap.DiscardContents();
#if UNITY_EDITOR
                shadowmap.hideFlags = HideFlags.DontSave;
#endif
                // to clear color
                RenderTexture.active = shadowmap;
                GL.Clear(true, true, Color.white);

                queueRTs.AddLast(shadowmap);
                
            }
            
        }

        void RelBuffer()
        {
            RenderTexture.active = null;

            queueRTs.Clear();
            
            if (oceanCamera != null)
                oceanCamera.targetTexture = null;

            if (trailCamera != null)
                trailCamera.targetTexture = null;
            
            if (shadowCamera != null)
                shadowCamera.targetTexture = null;

            if (trailmap != null)
            {
                trailmap.Release();
                DestroyImmediate(trailmap);
                trailmap = null;
            }

            if (oceanmap != null)
            {
                oceanmap.Release();
                DestroyImmediate(oceanmap);
                oceanmap = null;
            }

            if (glaremap != null)
            {
                glaremap.Release();
                DestroyImmediate(glaremap);
                glaremap = null;
            }

            if (shadowmap != null)
            {
                shadowmap.Release();
                DestroyImmediate(shadowmap);
                shadowmap = null;
            }
        }

        public FOceanGrid mainFG
        {
            get
            {
                return mainGrid;
            }
        }

        bool PointInOABB(Vector3 point, FOceanGrid grid)
        {
            Transform transform = grid.transform;
            Vector3 size = grid.baseParam.boundSize;
            float h = grid.usedOceanHeight;

            float rangeY = (size.y * 0.5f);

            if (point.y > h + rangeY || point.y < h - rangeY)
                return false;

            point = transform.InverseTransformPoint(point);

            float rangeX = (size.x * 0.5f);
            float rangeZ = (size.z * 0.5f);
            if (point.x < rangeX && point.x > -rangeX &&
               point.z < rangeZ && point.z > -rangeZ)
                return true;
            else
                return false;
        }

        private FOceanGrid FindMainGrid()
        {
            Vector3 p = Camera.main.transform.position + Camera.main.transform.forward * Camera.main.nearClipPlane;
            var _e = grids.GetEnumerator();
            FOceanGrid closestFG = null;
            float dis = Mathf.Infinity;
            while (_e.MoveNext())
            {
                if (!_e.Current.baseParam.projectedMesh)
                {
                    if (PointInOABB(p, _e.Current))
                    {
                        return _e.Current;
                    }
                }
                else
                {
                    if (_e.Current.offsetToGridPlane < dis)
                    {
                        dis = _e.Current.offsetToGridPlane;
                        closestFG = _e.Current;
                    }
                }
            }

            return closestFG;
        }

	    public FOceanGrid ClosestGrid(Vector3 p)
	    {
            var _e = grids.GetEnumerator();
            FOceanGrid closestFG = null;
			float dis = Mathf.Infinity;
            while (_e.MoveNext())
            {
                if (!_e.Current.baseParam.projectedMesh)
                {
                    if (PointInOABB(p, _e.Current))
                    {
                        return _e.Current;
                    }
                }
                else
                {
					if(mainGrid != null && mainGrid.baseParam.projectedMesh)
					{
                    	closestFG = mainGrid;
					}
					else if (_e.Current.offsetToGridPlane < dis)
					{
						dis = _e.Current.offsetToGridPlane;
						closestFG = _e.Current;
					}
                }
            }

            return closestFG;
	    }

        public FOceanGrid ClosestGrid(Transform t)
        {
            var _e = grids.GetEnumerator();
            FOceanGrid closestFG = null;
			float dis = Mathf.Infinity;
            while (_e.MoveNext())
            {
                if (!_e.Current.baseParam.projectedMesh)
                {
                    if (PointInOABB(t.position, _e.Current))
                    {
                        return _e.Current;
                    }
                }
                else
                {
					if(mainGrid != null && mainGrid.baseParam.projectedMesh)
					{
						closestFG = mainGrid;
					}
					else if (_e.Current.offsetToGridPlane < dis)
					{
						dis = _e.Current.offsetToGridPlane;
						closestFG = _e.Current;
					}
                }
            }

            return closestFG;
        }

        public bool GlareMapEnabled(FOceanGrid grid)
        {
            if (!Application.isPlaying)
                return false;

			if (grid == null)
                return false;

            if (IntersectWater())
                return false;

			if (grid != mainGrid)
				return false;

            if (!supportSM3)
                return false;

            return needGlareBehaviour.Count > 0;
        }

        public bool OceanMapEnabled(FOceanGrid grid)
        {
            if (!Application.isPlaying)
                return false;

            bool bNoSunGlare = !m_bSunGlare;
            if (envParam.underWaterMode == eFUnderWaterMode.Blend)
            {
                if (bNoSunGlare && !IntersectWater())
                    return false;
            }
            else
            {
                if(IntersectWater())
                    return false;
                else if (bNoSunGlare)
                    return false;
            }

            if (!supportSM3)
                return false;
            
            if (grid == null)
                return false;

			if (grid != mainGrid)
				return false;

            return true;
        }

        public bool UnderWater()
        {
            if (simpleUnderFlag)
                return underState == eFUnderWater.Under;

            return (underState == eFUnderWater.Under || newUnderState == eFUnderWater.UnderIntersect) && newUnderState != eFUnderWater.AboveIntersect;
        }

        public bool IntersectWater()
        {
            if (simpleUnderFlag)
                return underState == eFUnderWater.Under;

            return underState == eFUnderWater.Under || newUnderState == eFUnderWater.AboveIntersect || newUnderState == eFUnderWater.UnderIntersect;
        }

        public bool OnlyUnderWater()
        {
            return underState == eFUnderWater.Under && newUnderState != eFUnderWater.AboveIntersect && newUnderState != eFUnderWater.UnderIntersect;
        }

	    public Color GetBaseColor()
	    {
			if (mainGrid != null && mainGrid.oceanMaterial != null)
				return mainGrid.oceanMaterial.GetColor("_FoBaseColor");

	        return Color.black;
	    }

        public Color GetDeepColor()
        {
            if (mainGrid != null && mainGrid.oceanMaterial != null)
                return mainGrid.oceanMaterial.GetColor("_FoDeepColor");

            return Color.black;
        }

        public void SetBaseColor(Color c)
		{
			if (mainGrid != null && mainGrid.oceanMaterial != null)
			    mainGrid.oceanMaterial.SetColor("_FoBaseColor", c);
		}

        public void SetDeepColor(Color c)
        {
            if (mainGrid != null && mainGrid.oceanMaterial != null)
                mainGrid.oceanMaterial.SetColor("_FoDeepColor", c);
        }

        public void SetShallowColor(Color c)
		{
			if (mainGrid != null && mainGrid.oceanMaterial != null)
				mainGrid.oceanMaterial.SetColor("_FoShallowColor", c);
		}
        
        public void ForceReload(bool bReGen)
        {
			if (!isStarted)
				return;

			if (instance == null)
			{
				instance = this;
			}
			
            if(bReGen)
            {
                DestroyAllMaterial();
                GenAllMaterial();
            }

            RelBuffer();
            GenBuffer();

            var _e = grids.GetEnumerator();
            while (_e.MoveNext())
            {
                _e.Current.ForceReload(bReGen);
            }
        }

	    public void ForceUpdate()
	    {
	       var _e = grids.GetEnumerator();
	       if (instance == null)
	       {
	           instance = this;
               instance.ForceReload(true);
	       }

	        Update();

	        _e = grids.GetEnumerator();
	        while (_e.MoveNext())
	        {
	            _e.Current.Update();
	        }

            LateUpdate();
	    }
        
        public void CheckParams()
        {
            if(!isStarted)
                return;

            if (mobile)
            {
                if (envParam.blendMode == eFBlendMode.Depth && !supportSM3)
                {
                    envParam.blendMode = eFBlendMode.Alpha;
                }

                if (envParam.underWaterMode == eFUnderWaterMode.Blend && !supportSM3)
                {
                    envParam.underWaterMode = eFUnderWaterMode.Simple;
                }
            }

            bool bSunGlare = needGlareBehaviour.Count > 0;
            if (m_bSunGlare != bSunGlare)
            {
                ForceReload(false);
                return;
            }

            if (m_underMode != envParam.underWaterMode)
            {
                UnderStateReset();

                if (envParam.underWaterMode == eFUnderWaterMode.Blend)
                {
                    ForceReload(false);
                    return;
                }

                m_underMode = envParam.underWaterMode;
            }


            if (m_trailer != envParam.trailer)
            {
                ForceReload(false);
                return;
            }

            if (m_TrailMapSize != envParam.trailMapSize)
            {
                ForceReload(false);
                return;
            }

            int useResWidth;
            int useResHeight;
            GetTargetRes(out useResWidth, out useResHeight);

            if (useResWidth != m_targetWidth || useResHeight != m_targetHeight)
            {
                ForceReload(false);
                return;
            }

            if(m_shadowQuality != envParam.shadowQuality)
            {
                ForceReload(false);
                return;
            }

            if (m_bShadowEnabled != envParam.shadowEnabled)
            {
                ForceReload(false);
                return;
            }
            
        }


        Vector3[] fofrustum = new Vector3[5];
        eFUnderWater newUnderState = eFUnderWater.Above;
        bool simpleUnderFlag = false;
        // Update is called once per frame
        void Update()
	    {

            CheckInstance();

#if UNITY_EDITOR
            transform.position = Vector3.zero;
            transform.rotation = Quaternion.identity;
            transform.localScale = Vector3.one;
#endif
            //this for visual smooth and network sync, not only physics accurate
            gTime += Time.smoothDeltaTime;

            if (Camera.main == null)
	            return;

            if (queueNode != null)
            {
                if (queueNode.Value != null && !queueNode.Value.IsCreated())
                {
                    if (Application.isPlaying)
                        ForceReload(false);

                    queueNode = null;
                    return;
                }

                queueNode = queueNode.Next;
            }
            else
                queueNode = queueRTs.First;


            CheckParams();

            Matrix4x4 invviewproj = (Camera.main.projectionMatrix * Camera.main.worldToCameraMatrix).inverse;

            fofrustum[0] = invviewproj.MultiplyPoint(new Vector3(-1, -1, -1));
            fofrustum[1] = invviewproj.MultiplyPoint(new Vector3(+1, -1, -1));
            fofrustum[2] = invviewproj.MultiplyPoint(new Vector3(-1, +1, -1));
            fofrustum[3] = invviewproj.MultiplyPoint(new Vector3(+1, +1, -1));
            fofrustum[4] = Camera.main.transform.position;

            //check underwater
            newUnderState = CheckUnder();

            if (newUnderState == eFUnderWater.Above && newUnderState == underState)
            {
                UnderStateCache();
            }

            if (newUnderState != underState && newUnderState != eFUnderWater.AboveIntersect && newUnderState != eFUnderWater.UnderIntersect)
            {
                UnderStateChanged();
            }
          
	        //find main grid
            mainGrid = FindMainGrid();

	        if (mainGrid != null && mainGrid.IsVisible())
	            UpdateMainGrid();
	    }

        CameraClearFlags tmpFlags;
        Color tmpBgColor;
        Color tmpFogColor;
        FogMode tmpFogMode;
        bool tmpUnderFog;

        public eFUnderWater CheckUnder()
        {
            eFUnderWater us = eFUnderWater.Above;

            if (envParam.underWaterMode == eFUnderWaterMode.None)
                return us;

            bool allUnder = true;

            int i = 0;
            for (; i < 5; i++)
            {
                Vector3 contactP = fofrustum[i];
                Vector3 d = Vector3.zero;

                if (!GetSurDisplace(contactP, out d, mainGrid))
                {
                    allUnder = false;
                    continue;
                }

                if (d.y > 0f)
                {
                    if (i == 4)
                        us = eFUnderWater.UnderIntersect;
                    else
                        us = eFUnderWater.AboveIntersect;
                }
                else
                    allUnder = false;
            }

            if(allUnder)
            {
                us = eFUnderWater.Under;
            }

            return us;
        }

#if UNITY_EDITOR
        static bool[] nearstate = new bool[5];
        public void OnDrawGizmos()
        {
            if (Camera.main == null)
                return;

            for (int i = 0; i < 5; i++)
            {
                Vector3 contactP = fofrustum[i];
                Vector3 d = Vector3.zero;
                if (!GetSurDisplace(contactP, out d, mainGrid))
                    continue;

                nearstate[i] = d.y > 0;
            }

            Gizmos.color = nearstate[0] ? Color.red : Color.green;
            Gizmos.DrawSphere(fofrustum[0], 0.1f);

            Gizmos.color = nearstate[1] ? Color.red : Color.green;
            Gizmos.DrawSphere(fofrustum[1], 0.1f);

            Gizmos.color = nearstate[2] ? Color.red : Color.green;
            Gizmos.DrawSphere(fofrustum[2], 0.1f);

            Gizmos.color = nearstate[3] ? Color.red : Color.green;
            Gizmos.DrawSphere(fofrustum[3], 0.1f);

            Gizmos.color = nearstate[4] ? Color.red : Color.green;
            Gizmos.DrawSphere(Camera.main.transform.position, 0.1f);

            if (Camera.main == null)
                return;

            Gizmos.matrix = Matrix4x4.identity;

            Transform camtr = Camera.main.transform;
            float camNear = Camera.main.nearClipPlane;
            float camFar = Camera.main.farClipPlane;
            float camFov = Camera.main.fieldOfView;
            float camAspect = Camera.main.aspect;


            float fovWHalf = camFov * 0.5f;

            Vector3 toRight = camtr.right * camNear * Mathf.Tan(fovWHalf * Mathf.Deg2Rad) * camAspect;
            Vector3 toTop = camtr.up * camNear * Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

            Vector3 topLeft = (camtr.forward * camNear - toRight + toTop);
            float camScale = topLeft.magnitude;

            Vector3 topLeftN = topLeft;
            topLeftN.Normalize();
            topLeftN *= camScale;

            Vector3 topRightN = (camtr.forward * camNear + toRight + toTop);
            topRightN.Normalize();
            topRightN *= camScale;

            Vector3 bottomRightN = (camtr.forward * camNear + toRight - toTop);
            bottomRightN.Normalize();
            bottomRightN *= camScale;

            Vector3 bottomLeftN = (camtr.forward * camNear - toRight - toTop);
            bottomLeftN.Normalize();
            bottomLeftN *= camScale;

            camScale *= camFar / camNear;

            topLeft.Normalize();
            topLeft *= camScale;

            Vector3 topRight = (camtr.forward * camNear + toRight + toTop);
            topRight.Normalize();
            topRight *= camScale;

            Vector3 bottomRight = (camtr.forward * camNear + toRight - toTop);
            bottomRight.Normalize();
            bottomRight *= camScale;

            Vector3 bottomLeft = (camtr.forward * camNear - toRight - toTop);
            bottomLeft.Normalize();
            bottomLeft *= camScale;

            Gizmos.color = Color.green;
            Gizmos.DrawLine(camtr.position, camtr.position + topLeft);
            Gizmos.DrawLine(camtr.position, camtr.position + topRight);
            Gizmos.DrawLine(camtr.position, camtr.position + bottomLeft);
            Gizmos.DrawLine(camtr.position, camtr.position + bottomRight);

            Gizmos.DrawLine(camtr.position + topLeft, camtr.position + topRight);
            Gizmos.DrawLine(camtr.position + topRight, camtr.position + bottomRight);
            Gizmos.DrawLine(camtr.position + bottomRight, camtr.position + bottomLeft);
            Gizmos.DrawLine(camtr.position + bottomLeft, camtr.position + topLeft);

            Gizmos.DrawLine(camtr.position + topLeftN, camtr.position + topRightN);
            Gizmos.DrawLine(camtr.position + topRightN, camtr.position + bottomRightN);
            Gizmos.DrawLine(camtr.position + bottomRightN, camtr.position + bottomLeftN);
            Gizmos.DrawLine(camtr.position + bottomLeftN, camtr.position + topLeftN);

            if (!drawButtomGizmos)
                return;

            if(oceanCamera != null && envParam.underButtom != null && matCull != null)
            {
                if (OnlyUnderWater())
                {
                    Gizmos.color = Color.cyan;

                    Matrix4x4 matrixButtom = Matrix4x4.identity;
                    matrixButtom.SetTRS(oceanCamera.transform.position, Quaternion.identity, Vector3.one * Camera.main.farClipPlane * 0.5f);
                    Gizmos.matrix = matrixButtom;
                    Gizmos.DrawWireMesh(envParam.underButtom);
                }
                else if (IntersectWater())
                {
                    Gizmos.color = Color.cyan;

                    Matrix4x4 matrixButtom = Matrix4x4.identity;
                    matrixButtom.SetTRS(oceanCamera.transform.position - Vector3.up * Camera.main.farClipPlane * 0.5f, Quaternion.identity, new Vector3(1f, 0.5f, 1f) * Camera.main.farClipPlane);
                    Gizmos.matrix = matrixButtom;
                    Gizmos.DrawWireMesh(envParam.underButtom);
                }
            }
        }
#endif

        void UnderStateChanged()
        {
            if (newUnderState == eFUnderWater.Under)
            {
                UnderStateReset(false);
            }
            else
            {
                Camera.main.clearFlags = tmpFlags;
                Camera.main.backgroundColor = tmpBgColor;
                
                RenderSettings.fog = tmpUnderFog;
                RenderSettings.fogColor = tmpFogColor;
                RenderSettings.fogMode = tmpFogMode;
            }

            underState = newUnderState;
        }

        public void UnderStateCache()
        {
            if (Camera.main == null)
                return;

            tmpFlags = Camera.main.clearFlags;
            tmpBgColor = Camera.main.backgroundColor;

            tmpFogColor = RenderSettings.fogColor;
            tmpFogMode = RenderSettings.fogMode;
            tmpUnderFog = RenderSettings.fog;
        }

        public void UnderStateReset(bool checkUnder = true)
        {
            if (underState != eFUnderWater.Under && checkUnder)
                return;

            simpleUnderFlag = !supportSM3 || envParam.underWaterMode != eFUnderWaterMode.Blend;

            //for simple
            if (simpleUnderFlag)
            {
                RenderSettings.fog = true;

                Camera.main.clearFlags = CameraClearFlags.SolidColor;
                RenderSettings.fogMode = FogMode.Exponential;
            }
            else
            {
                Camera.main.clearFlags = CameraClearFlags.Skybox;
            }
            
            RenderSettings.fogColor = envParam.underColor;
            Camera.main.backgroundColor = RenderSettings.fogColor;
        }

        void LateUpdate()
        {
            if (mainGrid == null)
                return;

            if (Camera.main == null && Application.isPlaying)
            {
                Debug.LogWarning("Camera.main == null, Please Tag That!");
                return;
            }

            if (mainGrid.oceanMaterial == null && Application.isPlaying)
            {
                Debug.LogWarning("oceanMaterial == null, Please Set That!");
                return;
            }

            var _e = grids.GetEnumerator();
            while (_e.MoveNext())
            {
                _e.Current.SetupMaterial();
                _e.Current.enabled = true;
            }

            if (!mainGrid.IsVisible())
            {
                if (oceanmap)
                {
                    RenderTexture.active = oceanmap;
                    GL.Clear(true, true, UnderWater() ? Color.white : Color.clear);
                }

                if (glaremap)
                {
                    RenderTexture.active = glaremap;
                    GL.Clear(true, true, Color.clear);
                }

                if (trailmap)
                {
                    RenderTexture.active = trailmap;
                    GL.Clear(true, true, Color.clear);
                }

                if (shadowmap)
                {
                    RenderTexture.active = shadowmap;
                    GL.Clear(true, true, Color.white);
                }

                return;
            }

            RenderShadowMap();
            RenderTrails();
            RenderOceanMap();
            RenderGlareMap();
        }

        public float UpdateCameraPlane(FOceanGrid grid, float fAdd)
        {
			return Mathf.Max(Camera.main.nearClipPlane, Camera.main.farClipPlane + fAdd);
        }

	    private void UpdateMainGrid()
	    {
	        AcquireComponents();

			if (!mainGrid.oceanMaterial)
                return;

	        CheckDepth(mainGrid);
            
            FUnderWater ueffect = (FUnderWater)Camera.main.gameObject.GetComponent(typeof(FUnderWater));
            if (!ueffect)
            {
                ueffect = Camera.main.gameObject.AddComponent<FUnderWater>();
            }

            ueffect.enabled = !simpleUnderFlag && IntersectWater();
	    }

	    public void UpdateMaterial(FOceanGrid grid, Material material)
	    {
            if (material == null)
                return;

            if (!reflection)
            {
                reflection = transform.GetComponent<FReflection>();
                if (reflection == null)
                {
                    reflection = gameObject.AddComponent<FReflection>();
                }
            }

            if (envParam.sunLight != null)
	        {
                material.SetVector("_FoSunDir", envParam.sunLight.transform.forward);
                material.SetColor("_FoSunColor", envParam.sunLight.color);
                material.SetFloat("_FoSunInt", envParam.sunLight.intensity * material.GetFloat("_FoSunIntensity"));
            }
            else
            {
                material.SetVector("_FoSunDir", -Vector3.up);
                material.SetColor("_FoSunColor", Color.black);
                material.SetFloat("_FoSunInt", material.GetFloat("_FoSunIntensity"));
            }

            if (envParam.trailer != null)
            { 
                material.EnableKeyword("FO_TRAIL_ON");
	        }
	        else
	        {
                material.DisableKeyword("FO_TRAIL_ON");
	        }

            if (envParam.shadowEnabled && shadowCamera != null && shadowmap != null)
            {
                material.EnableKeyword("FO_SHADOW_ON");
                material.SetMatrix("_FoMatrixShadowMVP", GL.GetGPUProjectionMatrix(shadowCamera.projectionMatrix, false) * shadowCamera.worldToCameraMatrix);
                material.SetTexture("_ShadowMap", shadowmap);
                material.SetVector("_ShadowParams", new Vector4(1f - envParam.shadowStrength, (1f - envParam.shadowFade) * shadowCamera.farClipPlane,
                       envParam.shadowDistort, 0f));
            }
            else
            {
                material.DisableKeyword("FO_SHADOW_ON");
            }

            if (material.GetFloat("_FoSunMode") == 0)
            {
                material.EnableKeyword("FO_PHONG_ON");
            }
            else
            {
                material.DisableKeyword("FO_PHONG_ON");
            }

            if (IntersectWater())
            {
                if (simpleUnderFlag)
                {
                    material.SetFloat("_Skirt", 0f);
                }
                else
                {
                    material.SetFloat("_Skirt", grid.offsetToGridPlane + Camera.main.farClipPlane);
                }
            }

            if(envParam.underWaterMode != eFUnderWaterMode.None)
            {
                material.SetColor("_UnderAmbient", envParam.underAmb);
                material.SetFloat("_UnderDepth", envParam.underDepth);
            }

            if (envParam.blendMode != eFBlendMode.None)
            {
                if (supportSM3 && envParam.blendMode == eFBlendMode.Depth)
                {
                    material.EnableKeyword("FO_DEPTHBLEND_ON");
                }
                else
                {
                    material.DisableKeyword("FO_DEPTHBLEND_ON");
                }

                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
            }
	        else
	        {
	            material.DisableKeyword("FO_DEPTHBLEND_ON");

                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
            }

            if (envParam.underWaterMode == eFUnderWaterMode.Blend)
            {
                material.SetInt("_CullAbove", (int)UnityEngine.Rendering.CullMode.Off);
                material.SetInt("_CullUnder", (int)UnityEngine.Rendering.CullMode.Off);
            }
            else
            {
                material.SetInt("_CullAbove", (int)UnityEngine.Rendering.CullMode.Back);
                material.SetInt("_CullUnder", (int)UnityEngine.Rendering.CullMode.Front);
            }
            
            if (supportSM3)
            {
                if (grid.dwParam.mode == eFShaderMode.High)
                {
                    material.EnableKeyword("FO_HQWAVES_ON");
                    material.DisableKeyword("FO_FFTWAVES_ON");
                }
                else if (grid.dwParam.mode == eFShaderMode.FFT)
                {
                    material.EnableKeyword("FO_FFTWAVES_ON");
                    material.DisableKeyword("FO_HQWAVES_ON");
                }
                else
                {
                    material.DisableKeyword("FO_HQWAVES_ON");
                    material.DisableKeyword("FO_FFTWAVES_ON");
                }
            }
            else
            {
                material.DisableKeyword("FO_HQWAVES_ON");
                material.DisableKeyword("FO_FFTWAVES_ON");
            }

            if (grid.baseParam.projectedMesh)
            {
                material.EnableKeyword("FO_PROJECTED_ON");
            }
            else
            {
                material.DisableKeyword("FO_PROJECTED_ON");
            }
        }

	    public int AboveLOD()
	    {
            if (!Application.isPlaying)
                return LOD;

	        return supportSM3 ? (envParam.blendMode == eFBlendMode.Depth ? ABOVELODSM3EX : ABOVELODSM3) : ABOVELOD;
	    }

	    public int UnderLOD()
	    {
            if (!Application.isPlaying)
                return LOD;

	        return supportSM3 ? UNDERLODSM3 : UNDERLOD;
	    }

	    public int OceanMapLOD()
	    {
	        return IntersectWater() ? (newUnderState == eFUnderWater.AboveIntersect ? UNDEROCEANLOD2 : UNDEROCEANLOD) : OCEANLOD;
	    }

	    public int GlareMapLOD()
	    {
	        return GlARELOD;
	    }

	    public void AddFGrid(FOceanGrid grid)
	    {
	        if (!grids.Contains(grid))
	        {
                Material mat = grid.oceanMaterial;
	            UpdateMaterial(grid, mat);
	            grids.Add(grid);
	        }
	    }

        public void RemoveFGrid(FOceanGrid grid)
	    {
	         grids.Remove(grid);
	    }

        public HashSet<FOceanGrid> GetGrids()
        {
            return grids;
        }

        public void AddFObject(FObject body)
        {
            if (!objs.Contains(body))
            {
                objs.Add(body);
            }
        }

        public void RemoveFObject(FObject body)
        {
            objs.Remove(body);
        }

        static Vector2[] blurOffsets = new Vector2[4];
        public static void BlurTapCone(RenderTexture src, RenderTexture dst, Material mat, float blurSpread)
        {
#if MOBILE
            if (dst != null)
                dst.DiscardContents();
            else
                return;
#endif
            if (mat == null)
                return;

            float off = 0.5f + blurSpread;
            blurOffsets[0] = new Vector2(-off, -off);
            blurOffsets[1] = new Vector2(-off, off);
            blurOffsets[2] = new Vector2(off, off);
            blurOffsets[3] = new Vector2(off, -off);
            
            Graphics.BlitMultiTap(src, dst, mat, blurOffsets);
        }

	    public static void Blit(RenderTexture src, RenderTexture dst, Material mat)
	    {
	#if MOBILE
            if (dst != null)
                dst.DiscardContents();
            else
                return;
	#endif
	        if (mat != null)
	            Graphics.Blit(src, dst, mat);
	        else
	            Graphics.Blit(src, dst);
	    }

        public static void BlitDontClear(RenderTexture src, RenderTexture dst, Material mat)
        {
#if MOBILE
            if (target != null)
            {
                if (dst != null)
                    dst.DiscardContents();
                else
                    return;
            }
#endif
            if (mat != null)
                Graphics.Blit(src, dst, mat);
            else
                Graphics.Blit(src, dst);
        }

	    public static void Blit(RenderTexture src, RenderTexture dst, Material mat, int pass)
	    {
	#if MOBILE
            if (dst != null)
	            dst.DiscardContents();
            else
                return;
	#endif
	        if (mat != null)
	            Graphics.Blit(src, dst, mat, pass);
	        else
	            Graphics.Blit(src, dst);
	    }

        public static void BlitDontClear(RenderTexture src, RenderTexture dst, Material mat, int pass)
        {
#if MOBILE
            if (target != null)
            {
                if (dst != null)
                    dst.DiscardContents();
                else
                    return;
            }
#endif
            if (mat != null)
                Graphics.Blit(src, dst, mat, pass);
            else
                Graphics.Blit(src, dst);
        }


        public static void CustomGraphicsBlit(RenderTexture src, RenderTexture dst, Material fxMaterial, int passNr)
        {
#if MOBILE
            if (target != null)
            {
                if (dst != null)
                    dst.DiscardContents();
                else
                    return;
            }
#endif
            RenderTexture.active = dst;

            fxMaterial.SetTexture("_MainTex", src);

            GL.PushMatrix();
            GL.LoadOrtho();

            fxMaterial.SetPass(passNr);

            GL.Begin(GL.QUADS);

            GL.MultiTexCoord2(0, 0.0f, 0.0f);
            GL.Vertex3(0.0f, 0.0f, 3.0f); // BL

            GL.MultiTexCoord2(0, 1.0f, 0.0f);
            GL.Vertex3(1.0f, 0.0f, 2.0f); // BR

            GL.MultiTexCoord2(0, 1.0f, 1.0f);
            GL.Vertex3(1.0f, 1.0f, 1.0f); // TR

            GL.MultiTexCoord2(0, 0.0f, 1.0f);
            GL.Vertex3(0.0f, 1.0f, 0.0f); // TL

            GL.End();
            GL.PopMatrix();
        }
        
        public static void DrawBorder(RenderTexture dest, Color color)
        {
#if MOBILE
            if (target != null)
            {
                if (dest != null)
                    dest.DiscardContents();
                else
                    return;
            }
#endif

            if (instance == null)
                return;

            float x1;
            float x2;
            float y1;
            float y2;

            RenderTexture.active = dest;
            bool invertY = true; // source.texelSize.y < 0.0f;
                                 // Set up the simple Matrix
            GL.PushMatrix();
            GL.LoadOrtho();

            /// LY add begin ///
            if(instance.matClear != null)
            {
                instance.matClear.SetColor("_Color", color);
                instance.matClear.SetPass(0);
            }
            /// LY add end ///

            float y1_; float y2_;
            if (invertY)
            {
                y1_ = 1.0f; y2_ = 0.0f;
            }
            else
            {
                y1_ = 0.0f; y2_ = 1.0f;
            }

            // left	        
            x1 = 0.0f;
            x2 = 0.0f + 1.0f / (dest.width * 1.0f);
            y1 = 0.0f;
            y2 = 1.0f;
            GL.Begin(GL.QUADS);

            GL.TexCoord2(0.0f, y1_); GL.Vertex3(x1, y1, 0.1f);
            GL.TexCoord2(1.0f, y1_); GL.Vertex3(x2, y1, 0.1f);
            GL.TexCoord2(1.0f, y2_); GL.Vertex3(x2, y2, 0.1f);
            GL.TexCoord2(0.0f, y2_); GL.Vertex3(x1, y2, 0.1f);

            // right
            x1 = 1.0f - 1.0f / (dest.width * 1.0f);
            x2 = 1.0f;
            y1 = 0.0f;
            y2 = 1.0f;

            GL.TexCoord2(0.0f, y1_); GL.Vertex3(x1, y1, 0.1f);
            GL.TexCoord2(1.0f, y1_); GL.Vertex3(x2, y1, 0.1f);
            GL.TexCoord2(1.0f, y2_); GL.Vertex3(x2, y2, 0.1f);
            GL.TexCoord2(0.0f, y2_); GL.Vertex3(x1, y2, 0.1f);

            // top
            x1 = 0.0f;
            x2 = 1.0f;
            y1 = 0.0f;
            y2 = 0.0f + 1.0f / (dest.height * 1.0f);

            GL.TexCoord2(0.0f, y1_); GL.Vertex3(x1, y1, 0.1f);
            GL.TexCoord2(1.0f, y1_); GL.Vertex3(x2, y1, 0.1f);
            GL.TexCoord2(1.0f, y2_); GL.Vertex3(x2, y2, 0.1f);
            GL.TexCoord2(0.0f, y2_); GL.Vertex3(x1, y2, 0.1f);

            // bottom
            x1 = 0.0f;
            x2 = 1.0f;
            y1 = 1.0f - 1.0f / (dest.height * 1.0f);
            y2 = 1.0f;

            GL.TexCoord2(0.0f, y1_); GL.Vertex3(x1, y1, 0.1f);
            GL.TexCoord2(1.0f, y1_); GL.Vertex3(x2, y1, 0.1f);
            GL.TexCoord2(1.0f, y2_); GL.Vertex3(x2, y2, 0.1f);
            GL.TexCoord2(0.0f, y2_); GL.Vertex3(x1, y2, 0.1f);

            GL.End();


            GL.PopMatrix();
        }

        public static void ComputeBlit(RenderTexture dest, Material mat, int pass)
        {
#if MOBILE
            if (target != null)
            {
                if (dest != null)
                    dest.DiscardContents();
                else
                    return;
            }
#endif
            Graphics.SetRenderTarget(dest);

            GL.Clear(true, true, Color.clear);

            GL.PushMatrix();
            GL.LoadOrtho();

            mat.SetPass(pass);

            GL.Begin(GL.QUADS);
            GL.TexCoord2(0.0f, 0.0f); GL.Vertex3(0.0f, 0.0f, 0.1f);
            GL.TexCoord2(1.0f, 0.0f); GL.Vertex3(1.0f, 0.0f, 0.1f);
            GL.TexCoord2(1.0f, 1.0f); GL.Vertex3(1.0f, 1.0f, 0.1f);
            GL.TexCoord2(0.0f, 1.0f); GL.Vertex3(0.0f, 1.0f, 0.1f);
            GL.End();

            GL.PopMatrix();
        }

        private bool IsNeedDepth(FOceanGrid grid)
	    {
            if (!supportSM3)
                return false;

            return  envParam.blendMode == eFBlendMode.Depth || envParam.underWaterMode == eFUnderWaterMode.Blend ||
                    needDepthBehaviour.Count > 0;
	    }

	    public void CheckDepth(FOceanGrid grid)
	    {
	#if !UNITY_EDITOR
	        Camera cur = Camera.main;
	#else 
	        Camera cur = Camera.current;
	#endif 
	        if (cur == null)
	            return;

	        if (grid == null)
	            return;

            if (cur != Camera.main)
            {
    //#if !UNITY_EDITOR
    //            cur.depthTextureMode = DepthTextureMode.None;
    //#endif
                return;
            }

	        if (IsNeedDepth(grid))
	            cur.depthTextureMode |= DepthTextureMode.Depth;
	        else
	            cur.depthTextureMode = DepthTextureMode.None;
	        
	    }

		void DestroyMaterial(ref Material mat)
		{
			if(mat != null)
			   DestroyImmediate(mat);

			mat = null;
		}

	    void OnDestroy()
	    {
            RelBuffer();

            DestroyAllMaterial();

            mainGrid = null;

	        instance = null;

            grids.Clear();

            objs.Clear();
        }


        void RenderTrails()
        {
            if (envParam.trailer == null)
                return;

            if (trailmap == null)
                return;

            if (!trailmap.IsCreated())
                return;

            if (matFade == null)
                return;

            if (trailCamera == null)
                return;

            bool tmpfog = RenderSettings.fog;

            RenderSettings.fog = false;

            trailCamera.enabled = true;

            float worldsize = envParam.trailMapSize * envParam.trailMapScale * 0.5f;

            // render in project space
            trailCamera.orthographicSize = worldsize;
            trailCamera.transform.rotation = Quaternion.Euler(new Vector3(90, 0, 0));
            trailCamera.transform.position = new Vector3(envParam.trailer.position.x, Camera.main.farClipPlane * 0.5f, envParam.trailer.position.z);

            trailCamera.nearClipPlane = Camera.main.nearClipPlane;
            trailCamera.farClipPlane = Camera.main.farClipPlane;
            trailCamera.orthographic = true;
            trailCamera.aspect = 1;
            trailCamera.depthTextureMode = DepthTextureMode.None;
            trailCamera.backgroundColor = Color.black;
            trailCamera.clearFlags = CameraClearFlags.SolidColor;
            trailCamera.cullingMask = 1 << layerDef.traillayer;
            trailCamera.renderingPath = RenderingPath.Forward;

            trailCamera.targetTexture = trailmap;
            trailCamera.Render();

            // render mask texture
            RenderTexture tmpRt = RenderTexture.GetTemporary(trailmap.width, trailmap.height, 0, trailmap.format);
            matFade.SetTexture("_MainTex", trailmap);
            matFade.SetFloat("u_FoFade", envParam.trailMapFade);
            Blit(null, tmpRt, matFade);

            BlurTapCone(tmpRt, trailmap, matBlur, 0f);

            var _e = grids.GetEnumerator();
            while (_e.MoveNext())
            {
                Material oceanMaterial = _e.Current.oceanMaterial;

                float tmpInt = QualitySettings.activeColorSpace == ColorSpace.Linear ? 2f : 1f;
                
                oceanMaterial.SetFloat("_TrailIntensity", envParam.trailIntensity * tmpInt);

                oceanMaterial.SetTexture("_TrailMap", trailmap);
                oceanMaterial.SetVector("_TrailOffset", new Vector4(envParam.trailer.position.x - worldsize,
                    envParam.trailer.position.z - worldsize, 1f / (worldsize * 2.0f), 0));
            }

            RenderTexture.ReleaseTemporary(tmpRt);

            trailCamera.enabled = false;

            RenderSettings.fog = tmpfog;
        }
			
        void RenderOceanMap()
        {
			if (!OceanMapEnabled(mainGrid))
				return;

            if (oceanmap != null && oceanmap.IsCreated())
            {
                bool tmpfog = RenderSettings.fog;

                RenderSettings.fog = false;

                float depth = oceanCamera.depth;
                oceanCamera.CopyFrom(Camera.main);
                oceanCamera.rect = new Rect(0, 0, 1, 1);
                oceanCamera.depth = depth;

                oceanCamera.depthTextureMode = DepthTextureMode.None;
                oceanCamera.backgroundColor = Color.clear;
                oceanCamera.clearFlags = CameraClearFlags.SolidColor;
                oceanCamera.cullingMask = 1 << layerDef.waterlayer;
                oceanCamera.targetTexture = oceanmap;
                oceanCamera.renderingPath = RenderingPath.Forward;

				var _e = grids.GetEnumerator();
				while (_e.MoveNext())
				{
					if(mainGrid == _e.Current)
						continue;

					_e.Current.gameObject.layer = 0;
				}

				int tmpLod = mainGrid.oceanMaterial.shader.maximumLOD;

				mainGrid.oceanMaterial.shader.maximumLOD = OceanMapLOD();

                oceanCamera.enabled = true;

                //draw buttom
                if (OnlyUnderWater())
                {
                    Matrix4x4 matrixButtom = Matrix4x4.identity;
                    matrixButtom.SetTRS(oceanCamera.transform.position, Quaternion.identity, Vector3.one * Camera.main.farClipPlane * 0.5f);
                    Graphics.DrawMesh(envParam.underButtom, matrixButtom, matCull, layerDef.waterlayer, oceanCamera);
                }
                else if (IntersectWater())
                {
                    Matrix4x4 matrixButtom = Matrix4x4.identity;
                    matrixButtom.SetTRS(oceanCamera.transform.position - Vector3.up * Camera.main.farClipPlane * 0.5f, Quaternion.identity, new Vector3(1f, 0.5f, 1f) * Camera.main.farClipPlane);
                    Graphics.DrawMesh(envParam.underButtom, matrixButtom, matCull, layerDef.waterlayer, oceanCamera);
                }

                oceanCamera.Render();
                oceanCamera.enabled = false;

				mainGrid.oceanMaterial.shader.maximumLOD = tmpLod;

			    _e = grids.GetEnumerator();
				while (_e.MoveNext())
				{
					if(mainGrid == _e.Current)
						continue;

                    _e.Current.gameObject.layer = layerDef.waterlayer;
				}

                RenderSettings.fog = tmpfog;
            }
        }

        void RenderGlareMap()
        {
			if (!GlareMapEnabled(mainGrid))
				return;
			
            if (glaremap != null && glaremap.IsCreated())
            {
                float depth = oceanCamera.depth;
                oceanCamera.CopyFrom(Camera.main);
                oceanCamera.rect = new Rect(0, 0, 1, 1);
                oceanCamera.depth = depth;

                oceanCamera.depthTextureMode = DepthTextureMode.None;
                oceanCamera.backgroundColor = Color.clear;
                oceanCamera.clearFlags = CameraClearFlags.SolidColor;
                oceanCamera.cullingMask = 1 << layerDef.waterlayer;
                oceanCamera.renderingPath = RenderingPath.Forward;
                oceanCamera.targetTexture = glaremap;

				var _e = grids.GetEnumerator();
				while (_e.MoveNext())
				{
					if(mainGrid == _e.Current)
					   continue;

					_e.Current.gameObject.layer = 0;
				}

				int tmpLod = mainGrid.oceanMaterial.shader.maximumLOD;

				mainGrid.oceanMaterial.shader.maximumLOD = GlareMapLOD();

                oceanCamera.enabled = true;
                oceanCamera.Render();
                oceanCamera.enabled = false;

				mainGrid.oceanMaterial.shader.maximumLOD = tmpLod;

			    _e = grids.GetEnumerator();
				while (_e.MoveNext())
				{
					if(mainGrid == _e.Current)
						continue;

                    _e.Current.gameObject.layer = layerDef.waterlayer;
				}
            }
        }
        
        Bounds shadowBound = new Bounds();
        Vector3[] shadowBoundVerts = new Vector3[8];
        void RenderShadowMap()
        {
            if (!envParam.shadowEnabled)
                return;

            if (shaderPack.shadow == null)
                return;
            
            if (!supportSM3)
                return;

            if (matClear == null)
                return;

            if (objs.Count == 0)
                return;

            if (shadowmap != null && shadowmap.IsCreated())
            {
                //close fit ocean shadow bound
                shadowBound.center = Camera.main.transform.position;
                shadowBound.size = Vector3.zero;

                int containCount = 0;
                var _e = objs.GetEnumerator();
                while (_e.MoveNext())
                {
                    if (!_e.Current.castShadow)
                        continue;

                    if (!_e.Current.gameObject.activeSelf)
                        continue;

                    Vector3 vDistance = Camera.main.transform.position - _e.Current.gameObject.transform.position;
                    if (_e.Current.SumBoundSize() + envParam.shadowDistance < vDistance.magnitude * 0.5f)
                        continue;

                    _e.Current.CacheShadowLayer();

                    Renderer[] renderers = _e.Current.GetRenderers();

                    for(int i = 0; i < renderers.Length; i++)
                    {
                        Renderer render = renderers[i];
                        if (render == null)
                            continue;

                        shadowBound.Encapsulate(render.bounds);
                    }

                    containCount++;
                }

                if(containCount == 0)
                {
                    RenderTexture.active = shadowmap;
                    GL.Clear(true, true, Color.white);
                    
                    return;
                }

                for (int i = 0; i < 5; i++)
                    shadowBound.Encapsulate(fofrustum[i]);

                float depth = shadowCamera.depth;
                shadowCamera.CopyFrom(Camera.main);
                shadowCamera.rect = new Rect(0, 0, 1, 1);
                shadowCamera.depth = depth;

                shadowCamera.depthTextureMode = DepthTextureMode.None;
                shadowCamera.backgroundColor = Color.white;
                shadowCamera.clearFlags = CameraClearFlags.SolidColor;
                shadowCamera.targetTexture = shadowmap;

                shadowCamera.transform.rotation = envParam.sunLight.transform.rotation;
                shadowCamera.transform.position = shadowBound.center;

                Vector3 v3Center = shadowBound.center;
                Vector3 v3Extents = shadowBound.extents;

                shadowBoundVerts[0] = new Vector3(v3Center.x - v3Extents.x, v3Center.y + v3Extents.y, v3Center.z - v3Extents.z);  // Front top left corner
                shadowBoundVerts[1] = new Vector3(v3Center.x + v3Extents.x, v3Center.y + v3Extents.y, v3Center.z - v3Extents.z);  // Front top right corner
                shadowBoundVerts[2] = new Vector3(v3Center.x - v3Extents.x, v3Center.y - v3Extents.y, v3Center.z - v3Extents.z);  // Front bottom left corner
                shadowBoundVerts[3] = new Vector3(v3Center.x + v3Extents.x, v3Center.y - v3Extents.y, v3Center.z - v3Extents.z);  // Front bottom right corner
                shadowBoundVerts[4] = new Vector3(v3Center.x - v3Extents.x, v3Center.y + v3Extents.y, v3Center.z + v3Extents.z);  // Back top left corner
                shadowBoundVerts[5] = new Vector3(v3Center.x + v3Extents.x, v3Center.y + v3Extents.y, v3Center.z + v3Extents.z);  // Back top right corner
                shadowBoundVerts[6] = new Vector3(v3Center.x - v3Extents.x, v3Center.y - v3Extents.y, v3Center.z + v3Extents.z);  // Back bottom left corner
                shadowBoundVerts[7] = new Vector3(v3Center.x + v3Extents.x, v3Center.y - v3Extents.y, v3Center.z + v3Extents.z);  // Back bottom right corner

                for (int i = 0; i < 8; i++)
                    shadowBoundVerts[i] -= shadowCamera.transform.position;

                float projBoundExt = 0f;
                for(int i = 0; i < 8; i++)
                    projBoundExt = Mathf.Max(projBoundExt, Mathf.Abs(Vector3.Dot(shadowBoundVerts[i], shadowCamera.transform.forward)));

                projBoundExt = Mathf.Min(envParam.shadowDistance, projBoundExt * 1.001f);
                shadowCamera.nearClipPlane = -projBoundExt;
                shadowCamera.farClipPlane = projBoundExt;

                float projBoundSize = 0f;
                for (int i = 0; i < 8; i++)
                    projBoundSize = Mathf.Max(projBoundSize, 
                    Mathf.Max(Mathf.Abs(Vector3.Dot(shadowBoundVerts[i], shadowCamera.transform.up)),
                    Mathf.Abs(Vector3.Dot(shadowBoundVerts[i], shadowCamera.transform.right))));

                projBoundSize = Mathf.Min(envParam.shadowDistance, projBoundSize * 1.001f) ;
                shadowCamera.orthographicSize = projBoundSize;
                shadowCamera.orthographic = true;
                shadowCamera.aspect = 1;

                shadowCamera.cullingMask = 1 << layerDef.shadowlayer;

                bool tmpfog = RenderSettings.fog;

                RenderSettings.fog = false;

                shadowCamera.enabled = true;

                shadowCamera.RenderWithShader(shaderPack.shadow, null);

                DrawBorder(shadowmap, Color.white);

                shadowCamera.enabled = false;

                _e = objs.GetEnumerator();
                while (_e.MoveNext())
                {
                    if (!_e.Current.castShadow)
                        continue;

                    if (!_e.Current.gameObject.activeSelf)
                        continue;

                    _e.Current.RestoreShadowLayer();
                }

                RenderSettings.fog = tmpfog;
            }
        }


        public void OnWillRender(FOceanGrid grid, Material material)
	    {
            if (material == null)
                return;

	#if UNITY_EDITOR
	        CheckDepth(grid);
	#endif

            if (grid == null)
	            return;

	        UpdateMaterial(grid, material);

	        if (Camera.current != Camera.main)
			{

    #if UNITY_EDITOR
                //when !Application.isPlaying, may not clearTexs in Update, so clear here
                if (reflection && !Application.isPlaying)
                    reflection.WaterTileClear(material);

                if (Camera.current == oceanCamera)
                    return;

                if (Camera.current == trailCamera)
                    return;

                if (Camera.current == shadowCamera)
                    return;

                //disable trails in scene view
                if (material)
                {
                    material.DisableKeyword("FO_TRAIL_ON");
                    material.DisableKeyword("FO_SHADOW_ON");
                }

    #else
				return;
    #endif
            }

            if (reflection)
            {
                if(!UnderWater())
                   reflection.WaterTileBeingRendered(Camera.current, grid.usedOceanHeight, material, grid.reflParam);
                else
                   reflection.WaterTileClear(material);
            }
	    }

        public bool GetSurDisplaceNormal(Vector3 worldPoint, out Vector3 d, out Vector3 n, Transform trans)
        {
            FOceanGrid grid = ClosestGrid(trans);

            if (grid == null)
            {
                d = Vector3.zero;
                n = Vector3.up;
                return false;
            }

            Vector3 ch;
            bool ret = grid.GetSurPointNormal(worldPoint, out ch, out n);
            d = ch - worldPoint;
            return ret;
        }

        public bool GetSurDisplaceNormal(Vector3 worldPoint, out Vector3 d, out Vector3 n, FOceanGrid grid)
        {
            if (grid == null)
            {
                d = Vector3.zero;
                n = Vector3.up;
                return false;
            }

            Vector3 ch;
            bool ret = grid.GetSurPointNormal(worldPoint, out ch, out n);
            d = ch - worldPoint;
            return ret;
        }

        public bool GetSurDisplace(Vector3 worldPoint, out Vector3 d, Transform trans)
        {
            FOceanGrid grid = ClosestGrid(trans);

            if (grid == null)
            {
                d = Vector3.zero;
                return false;
            }

            Vector3 ch;
            bool ret = grid.GetSurPoint(worldPoint, out ch);
            d = ch - worldPoint;
            return ret;
        }

        public bool GetSurDisplace(Vector3 worldPoint, out Vector3 d, FOceanGrid grid)
        {
            if (grid == null)
            {
                d = Vector3.zero;
                return false;
            }

            Vector3 ch;
            bool ret = grid.GetSurPoint(worldPoint, out ch);
            d = ch - worldPoint;
            return ret;
        }

        public bool GetSurPointNormal(Vector3 worldPoint, out Vector3 p, out Vector3 n, Transform trans)
        {
            FOceanGrid grid = ClosestGrid(trans);

            if (grid == null)
            {
                p = worldPoint;
                n = Vector3.up;
                return false;
            }

            return grid.GetSurPointNormal(worldPoint, out p, out n);
        }

        public bool GetSurPointNormal(Vector3 worldPoint, out Vector3 p, out Vector3 n, FOceanGrid grid)
	    {
            if (grid == null)
	        {
                p = worldPoint;
	            n = Vector3.up;
	            return false;
	        }

            return grid.GetSurPointNormal(worldPoint, out p, out n);
	    }

        public bool GetSurPoint(Vector3 worldPoint, out Vector3 p, Transform trans)
        {
            FOceanGrid grid = ClosestGrid(trans);

            if (grid == null)
            {
                p = worldPoint;
                return false;
            }

            return grid.GetSurPoint(worldPoint, out p);
        }

        public bool GetSurPoint(Vector3 worldPoint, out Vector3 p, FOceanGrid grid)
        {
            if (grid == null)
            {
                p = worldPoint;
                return false;
            }

            return grid.GetSurPoint(worldPoint, out p);
        }

	    public static Vector4 CosV4(ref Vector4 V)
	    {
	        return new Vector4(Mathf.Cos(V.x), Mathf.Cos(V.y), Mathf.Cos(V.z), Mathf.Cos(V.w));
	    }

        public static Vector4 SinV4(ref Vector4 V)
	    {
	        return new Vector4(Mathf.Sin(V.x), Mathf.Sin(V.y), Mathf.Sin(V.z), Mathf.Sin(V.w));
	    }

	    public static Vector4 CosScaleXY(Vector4 V, Vector4 F)
	    {
	        return Vector4.Scale(new Vector4(F.x, F.x, F.y, F.y), new Vector4(Mathf.Cos(V.x), Mathf.Sin(V.x), Mathf.Cos(V.y), Mathf.Sin(V.y)));
	    }

	    public static Vector4 CosScaleZW(Vector4 V, Vector4 F)
	    {
	        return Vector4.Scale(new Vector4(F.z, F.z, F.w, F.w), new Vector4(Mathf.Cos(V.z), Mathf.Sin(V.z), Mathf.Cos(V.w), Mathf.Sin(V.w)));
	    }

	    public static Vector4 InverseV4(Vector4 V)
	    {
	        return new Vector4(1f / V.x, 1f / V.y, 1f / V.z, 1f / V.w);
	    }

        public static Vector4 SqrtV4(Vector4 V)
        {
            return new Vector4(Mathf.Sqrt(V.x), Mathf.Sqrt(V.y), Mathf.Sqrt(V.z), Mathf.Sqrt(V.w));
        }

        public static float Frac(float value)
        {
            float frac = value - (int)value;

            if (value < 0f)
                frac += 1f;

            return frac;
        }

        public static Vector4 FracV4(Vector4 V)
        {
            return new Vector4(Frac(V.x), Frac(V.y), Frac(V.z), Frac(V.w));
        }

        public static Color SuppleColor(Color c)
        {
            float max = Mathf.Max(Mathf.Max(c.r, c.g), c.b);

            float r = Mathf.Clamp01((c.r - max) * 255 + 1);
            float g = Mathf.Clamp01((c.g - max) * 255 + 1);
            float b = Mathf.Clamp01((c.b - max) * 255 + 1);

            r = Mathf.Lerp(0.5f * c.r, c.r, r);
            g = Mathf.Lerp(0.5f * c.g, c.g, g);
            b = Mathf.Lerp(0.5f * c.b, c.b, b);

            return new Color(r, g, b);
        }
    }
}
