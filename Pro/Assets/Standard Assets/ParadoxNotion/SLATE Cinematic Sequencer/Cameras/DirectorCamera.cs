
using UnityEngine;
using UnityEngine.UI;
using System.Collections;

using DepthOfField = Slate.DepthOfField;

/// LY add begin ///
#if UNITY_EDITOR
using UnityEditor;
#endif
/// LY add end ///

namespace Slate
{

	///The master director render camera for all cutscenes.
	public class DirectorCamera : MonoBehaviour, IDirectableCamera {

		[SerializeField] [HideInInspector]
		private bool _matchMainWhenActive   = true;
		[SerializeField] [HideInInspector]
		private bool _setMainWhenActive     = true;
		[SerializeField] [HideInInspector]
		private bool _autoHandleActiveState = true;
		[SerializeField] [HideInInspector]
		private bool _ignoreFOVChanges      = false;
		[SerializeField] [HideInInspector]
		private bool _dontDestroyOnLoad     = false;

		//max possible damp able to be used for post-smoothing
		public const float MAX_DAMP = 3f;

		///Raised when a camera cut takes place from one shot to another.
		public static event System.Action<IDirectableCamera> OnCut;
		///Raised when the Director Camera is activated/enabled.
		public static event System.Action OnActivate;
		///Raised when the Director Camera is deactivated/disabled.
		public static event System.Action OnDeactivate;

		private static DirectorCamera _current;
		private static Camera _cam;
		private static IDirectableCamera lastTargetShot;
		private static DepthOfField dof;


        /// LY add begin ///

        /// <summary>
        /// 是否转换渲染摄像机父节点
        /// </summary>
        public static bool mChangeCamParent = false;
        /// <summary>
        /// 渲染摄像机原始父节点(可以没有)
        /// </summary>
        private static Transform mOriCamParent = null;


        /// LY add end ///


		public static DirectorCamera current{
			get
			{
				if (_current == null)
                {
					_current = FindObjectOfType<DirectorCamera>();
					if (_current == null)
                    {
                        /// LY edit begin ///
                        if (Application.isPlaying == false)
                        {
#if UNITY_EDITOR
                            string prefabPath = "Assets/Standard Assets/ParadoxNotion/★ Director Camera Root.prefab";
                            GameObject tLoadPrefab = AssetDatabase.LoadAssetAtPath(prefabPath, typeof(GameObject)) as GameObject;
                            if (tLoadPrefab != null)
                            {
                                GameObject tObj = Instantiate(tLoadPrefab);
                                tObj.name = "★ Director Camera Root";
                                _current = tObj.GetAddComponent<DirectorCamera>();
                            }
#endif
                        }
                        else
                        {
                            _current = new GameObject("★ Director Camera Root").AddComponent<DirectorCamera>();
                            _current.cam.nearClipPlane = 0.01f;
                            _current.cam.farClipPlane = 1000;
                        }
                        /// LY edit end ///
					}
                }
				return _current;
			}
		}

		/////////

		public Camera cam{
			get
			{
				if (_cam == null){
					_cam = GetComponentInChildren<Camera>(true);
					if (_cam == null){
						_cam = CreateRenderCamera();
					}
				}
				return _cam;
			}
            /// LY add begin ///
            set
            {
                _cam = value;
            }
            /// LY add end ///
		}

		//////////
		//These properties are instance properties so that they can potentially be animated.
		public Vector3 position{
			get{return current.transform.position;}
			set {current.transform.position = value;}
		}

		public Quaternion rotation{
			get {return current.transform.rotation;}
			set {current.transform.rotation = value;}
		}

		public float fieldOfView{
			get {return cam.orthographic? cam.orthographicSize : cam.fieldOfView;}
			set { if (!ignoreFOVChanges) {cam.fieldOfView = value; cam.orthographicSize = value;} }
		}

		public float focalPoint{
			get { return dof != null? dof.focus.focusPlane : 10f; }
			set { if (dof != null) dof.focus.focusPlane = Mathf.Max(value, 0); }
		}

		public float focalRange{
			get { return dof != null? dof.focus.range : 15f; }
			set { if (dof != null) dof.focus.range = Mathf.Max(value, 0); }
		}
		/////////

		///Should DirectorCamera be matched to Camera.main when active?
		public static bool matchMainWhenActive{
			get {return current._matchMainWhenActive;}
			set {current._matchMainWhenActive = value;}
		}

		///Should DirectorCamera be set as Camera.main when active?
		public static bool setMainWhenActive{
			get {return current._setMainWhenActive;}
			set {current._setMainWhenActive = value;}
		}

		///If true, the RenderCamera active state is automatically handled. This is highly recommended.
		public static bool autoHandleActiveState{
			get {return current._autoHandleActiveState;}
			set {current._autoHandleActiveState = value;}
		}

		///If true, any changes made by shots will be bypassed/ignored.
		public static bool ignoreFOVChanges{
			get {return current._ignoreFOVChanges;}
			set {current._ignoreFOVChanges = value;}
		}

		///Should DirectorCamera be persistant between level changes?
		public static bool dontDestroyOnLoad{
			get {return current._dontDestroyOnLoad;}
			set {current._dontDestroyOnLoad = value;}
		}

        /// LY add begin ///
        
		///The actual camera from within cutscenes are rendered
		//public static Camera renderCamera{get { return current.cam; }}
        public static Camera renderCamera { get { return current.cam; } set { current.cam = value; } }
        /// <summary>
        /// 使用的动画摄像机是否默认的渲染摄像机
        /// </summary>
        public static bool isDefaultRenCam = true;
        public static bool isMainCam = false;

        public static bool closeCamFin = false;
        public static bool openUIMaskEnd = false;

        public static Camera camMain = null;
        /// LY add end ///

        ///The gameplay camera
        public static GameCamera gameCamera{get; set;}
		///Is director enabled?
		public static bool isEnabled{get; private set;}

		void Awake(){

            /// LY add begin ///
            camMain = Camera.main;
            /// LY add end ///

            if (_current != null && _current != this){
				DestroyImmediate(this.gameObject);
				return;
			}

			_current = this;
			if (Application.isPlaying == true && dontDestroyOnLoad){
				DontDestroyOnLoad(this.gameObject);
			}

            /// LY add begin ///
            OnDeactivate += DelayOpenCamera;
            /// LY add end ///

            Disable();
		}


		Camera CreateRenderCamera(){
			_cam = new GameObject("Render Camera").AddComponent<Camera>();
			_cam.gameObject.AddComponent<AudioListener>();
			//_cam.gameObject.AddComponent<GUILayer>();
			_cam.gameObject.AddComponent<FlareLayer>();
            _cam.transform.SetParent(this.transform);
			return _cam;
		}

		///Enable the Director Camera, while disabling the main camera if any
		public static void Enable(){

            /// Ly edit begin ///

            //init gamecamera if any
            //         if (gameCamera == null){
            //	var main = Camera.main;
            //	if (main != null && main != renderCamera){
            //		gameCamera = main.GetAddComponent<GameCamera>();
            //	}
            //}

            if (gameCamera == null)
            {
                if (isMainCam == true)
                {
                    gameCamera = renderCamera.GetAddComponent<GameCamera>();
                }
                else
                {
                    //var main = Loong.Game.CameraMgr.Main;
                    var main = camMain/*Camera.main*/;
                    if (main != null && main != renderCamera)
                    {
                        gameCamera = main.GetAddComponent<GameCamera>();
                    }
                    else
                    {
                        gameCamera = renderCamera.GetAddComponent<GameCamera>();
                    }
                }
            }

            /// Ly edit end ///

            //use gamecamera and disable it
            if (gameCamera != null){

                /// Ly add begin ///

                //if (CutscenePlayMgr.instance.CheckMainCam(renderCamera) == false)
                //{
                //    gameCamera.gameObject.SetActive(false);
                //}
                if(isMainCam == false)
                {
                    gameCamera.gameObject.SetActive(false);
                }
                //gameCamera.enabled = false;

                /// Ly add end ///

                //if (matchMainWhenActive)
                //{
                //    var tempFOV = current.fieldOfView;
                //    renderCamera.CopyFrom(gameCamera.cam);
                //    if (ignoreFOVChanges)
                //    {
                //        renderCamera.fieldOfView = tempFOV;
                //    }
                //}

                /// LY add begin ///
                if (isMainCam == false)
                {
                    if (matchMainWhenActive)
                    {
                        var tempFOV = current.fieldOfView;
                        renderCamera.CopyFrom(gameCamera.cam);
                        if (ignoreFOVChanges)
                        {
                            renderCamera.fieldOfView = tempFOV;
                        }
                    }
                }

                if (mChangeCamParent == true)
                {
                    mOriCamParent = renderCamera.transform.parent;
                    renderCamera.transform.parent = current.transform;
                }
                /// LY add end ///

                //set the root pos/rot
                current.transform.position = gameCamera.position;
				current.transform.rotation = gameCamera.rotation;
			}

            //reset render camera local pos/rot
            renderCamera.transform.localPosition = Vector3.zero;
			renderCamera.transform.localRotation = Quaternion.identity;

            //set render camera to MainCamera if option enabled
            //if (setMainWhenActive){
            //	renderCamera.gameObject.tag = "MainCamera";
            //}

            if (setMainWhenActive){
                //renderCamera.gameObject.tag = "MainCamera";
                /// LY add begin ///
                if (isMainCam == false)
                {
                    renderCamera.gameObject.tag = "MainCamera";
                }
                /// LY add end ///
            }
            
            ///enable
            if (autoHandleActiveState){
                //renderCamera.gameObject.SetActive(true);
                /// LY add begin ///
                //QualityMgr.instance.ChangeAnimQuality(renderCamera.gameObject);
                EventMgr.Trigger("EventChangeAnimQuality", renderCamera.gameObject);
                renderCamera.gameObject.SetActive(true);
                renderCamera.enabled = true;
                /// LY add end ///
			}
			dof = renderCamera.GetComponent<DepthOfField>();

			isEnabled = true;
			lastTargetShot = null;

			if (OnActivate != null){
				OnActivate();
			}
		}

		///Disable the Director Camera, while enabling back the main camera if any
		public static void Disable(){

			if (OnDeactivate != null){
				OnDeactivate();
			}

            /// LY add begin ///
            
            // 检查并复原摄像机
            if(mChangeCamParent == true)
            {
                if(renderCamera != null)
                {
                    renderCamera.transform.parent = mOriCamParent;
                }
            }

            mChangeCamParent = false;
            mOriCamParent = null;

            //CutscenePlayMgr.instance.CheckAndOpenUIMask();
            //CutscenePlayMgr.instance.CheckAndOpenUILoading();
            EventMgr.Trigger("CheckAndOpenUIMask");
            EventMgr.Trigger("CheckAndOpenUILoading");
            /// LY add end ///

            //disable render camera
            if (autoHandleActiveState){
                //renderCamera.gameObject.SetActive(false);
                /// LY add begin ///
                if (isMainCam == false && closeCamFin == true)
                {
                    renderCamera.gameObject.SetActive(false);
                }
                /// LY add end ///
            }

			//reset tag
			if (setMainWhenActive){
                //renderCamera.gameObject.tag = "Untagged";
                /// LY add begin ///
                if (isMainCam == false)
                {
                    renderCamera.gameObject.tag = "Untagged";
                }
                /// LY add end ///
			}

            //enable gamecamera
            /// LY add begin ///
            if (openUIMaskEnd == false && closeCamFin == true)
            {
                if (gameCamera != null)
                {
                    //gameCamera.enabled = false;
                    gameCamera.gameObject.SetActive(true);
                }
            }
            /// LY add end ///

            isEnabled = false;
		}

        /// LY add begin ///
        private void DelayOpenCamera()
        {
            if (Application.isPlaying == false)
                return;

            if (openUIMaskEnd == false)
                return;

            Invoke("OpenMainCamera", 0.1f);
        }

        private void OpenMainCamera()
        {
            //Debug.Log("Delay open main cam !!! ");
            if (gameCamera != null)
            {
                gameCamera.enabled = false;
                gameCamera.gameObject.SetActive(true);
            }
        }
        /// LY add end ///

        ///Ease from game camera to target. If target is null, eases to DirectorCamera current.
        public static void Update(IDirectableCamera source, IDirectableCamera target, EaseType interpolation, float weight, float damping = 0f){

			if (source == null){ source = gameCamera != null? (IDirectableCamera)gameCamera : (IDirectableCamera)current; }
			if (target == null){ target = current; }

			var targetPosition   = weight < 1? Easing.Ease(interpolation, source.position, target.position, weight)		 	: target.position;
			var targetRotation   = weight < 1? Easing.Ease(interpolation, source.rotation, target.rotation, weight)		 	: target.rotation;
			var targetFOV        = weight < 1? Easing.Ease(interpolation, source.fieldOfView, target.fieldOfView, weight)	: target.fieldOfView;
			var targetFocalPoint = weight < 1? Easing.Ease(interpolation, source.focalPoint, target.focalPoint, weight)	 	: target.focalPoint;
			var targetFocalRange = weight < 1? Easing.Ease(interpolation, source.focalRange, target.focalRange, weight)	 	: target.focalRange;

			var isCut = target != lastTargetShot;
			if (!isCut && damping > 0){
				current.position    = Vector3.Lerp(current.position, targetPosition, Time.deltaTime * (MAX_DAMP/damping));
				current.rotation    = Quaternion.Lerp(current.rotation, targetRotation, Time.deltaTime * (MAX_DAMP/damping));
				current.fieldOfView = Mathf.Lerp(current.fieldOfView, targetFOV, Time.deltaTime * (MAX_DAMP/damping));
				current.focalPoint  = Mathf.Lerp(current.focalPoint, targetFocalPoint, Time.deltaTime * (MAX_DAMP/damping));
				current.focalRange  = Mathf.Lerp(current.focalRange, targetFocalRange, Time.deltaTime * (MAX_DAMP/damping));
			
			} else {
				current.position    = targetPosition;
				current.rotation    = targetRotation;
				current.fieldOfView = targetFOV;
				current.focalPoint  = targetFocalPoint;
				current.focalRange  = targetFocalRange;
			}

			if (isCut && OnCut != null){
				OnCut(target);
			}
				
			lastTargetShot = target;
		}



		private static float noiseTimer;
		private static Vector3 noisePosOffset;
		private static Vector3 noiseRotOffset;
		private static Vector3 noiseTargetPosOffset;
		private static Vector3 noiseTargetRotOffset;
		private static Vector3 noiseCamPosVel;
		private static Vector3 noiseCamRotVel;
		//Apply noise effect (steadycam). This is better looking than using a multi Perlin noise.
		public static void ApplyNoise(float magnitude, float weight, float extent = 1)
        {
            /// LY edit begin ///
            //var posMlt = Mathf.Lerp(0.2f, 0.4f, magnitude);
            //var rotMlt = Mathf.Lerp(5, 10f, magnitude);

            var posMlt = Mathf.Lerp(0.2f, 0.4f * extent, magnitude) * extent;
            var rotMlt = Mathf.Lerp(5, 10f * extent, magnitude) * extent;

            /// LY edit end ///
			var damp = Mathf.Lerp(3, 1, magnitude);
			if (noiseTimer <= 0){
				noiseTimer = Random.Range(0.2f, 0.3f);
				noiseTargetPosOffset = Random.insideUnitSphere * posMlt;
				noiseTargetRotOffset = Random.insideUnitSphere * rotMlt;
			}
			noiseTimer -= Time.deltaTime;

			noisePosOffset = Vector3.SmoothDamp(noisePosOffset, noiseTargetPosOffset, ref noiseCamPosVel, damp);
			noiseRotOffset = Vector3.SmoothDamp(noiseRotOffset, noiseTargetRotOffset, ref noiseCamRotVel, damp);

			//Noise is applied as a local offset to the RenderCamera directly
			renderCamera.transform.localPosition = Vector3.Lerp(Vector3.zero, noisePosOffset, weight);
			renderCamera.transform.SetLocalEulerAngles( Vector3.Lerp(Vector3.zero, noiseRotOffset, weight) );
		}


		////////////////////////////////////////
		///////////GUI AND EDITOR STUFF/////////
		////////////////////////////////////////
#if UNITY_EDITOR

		[SerializeField] [HideInInspector]
		private bool hasUpdate_152;
		
		void Reset(){
			hasUpdate_152 = true;
			CreateRenderCamera();
			Disable();
		}

		void OnValidate(){
			if (!hasUpdate_152){
				hasUpdate_152 = true;
				foreach(var behaviour in renderCamera.gameObject.GetComponents<Behaviour>()){
					behaviour.enabled = true;
				}
			}
			if (this == _current){
				Disable();
			}
		}

		void OnDrawGizmos(){

			var color = Prefs.gizmosColor;
			if (!isEnabled){ color.a = 0.2f;}
			Gizmos.color = color;

			var hit = new RaycastHit();
			if (Physics.Linecast(cam.transform.position, cam.transform.position - new Vector3(0, 100, 0), out hit)){
				var d = Vector3.Distance(hit.point, cam.transform.position);
				Gizmos.DrawLine(cam.transform.position, hit.point);
				Gizmos.DrawCube(hit.point, new Vector3(0.2f, 0.05f, 0.2f));
				Gizmos.DrawCube(hit.point + new Vector3(0, d/2, 0), new Vector3(0.02f, d, 0.02f));
			}

			Gizmos.DrawLine(transform.position, cam.transform.position);

			if (isEnabled){color = Color.green;}
			Gizmos.color = color;
			Gizmos.matrix = Matrix4x4.TRS(cam.transform.position, cam.transform.rotation, Vector3.one);
			var dist = isEnabled? 0.8f : 0.5f;
			Gizmos.DrawFrustum(new Vector3(0,0,dist), fieldOfView, 0, dist, 1);

			color.a = 0.2f;
			Gizmos.color = color;
			Gizmos.matrix = Matrix4x4.TRS(transform.position, transform.rotation, Vector3.one);
			Gizmos.DrawFrustum( new Vector3(0,0,0.5f), fieldOfView, 0f, 0.5f, 1);
			Gizmos.color = Color.white;
		}			

#endif
	}
}