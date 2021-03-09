using UnityEngine;
using System.Collections;

namespace JBrothers.PreIntegratedSkinShader2.Demo {
	public class DemoController : MonoBehaviour {
		public Light sun;
		public ReflectionProbe reflectionProbe;

		public PreIntegratedSkinProfile[] profiles;

		public Material[] skyboxes;
		private SkyboxSphere[] skyboxSpheres;

		private Quaternion probeBakedWithSunRotation = Quaternion.identity;
		private SkyboxSphere probeBakedWithSkybox = null;

		private SkyboxSphere selectedSkybox = null;

		public Shader skyboxSphereShader;
		private Material skyboxSphereMaterial;

		public Shader profileSphereShader;
		private Material profileSphereMaterial;

		public Renderer meshRenderer;
		private Material materialCopy;
		private Material materialOrig;

		private int _MainTex;

		public float sphereSize = 64f;
		public int cubemapResolution = 64;

		private float scattering;
		private int _ScatteringPower;

		[System.Serializable]
		private class SkyboxSphere {
			public Material skybox;
			public Cubemap cube;
		}

		void Start () {
			_MainTex = Shader.PropertyToID("_MainTex");
			_ScatteringPower = Shader.PropertyToID("_ScatteringPower");

			if (!skyboxSphereShader) {
				Debug.LogWarning("no skybox preview shader");
				enabled = false;
				return;
			}
			skyboxSphereMaterial = new Material(skyboxSphereShader);
			
			if (!profileSphereShader) {
				Debug.LogWarning("no profile preview shader");
				enabled = false;
				return;
			}
			profileSphereMaterial = new Material(profileSphereShader);
			profileSphereMaterial.SetTexture("_LookupDirectSM2", Resources.Load<Texture2D>("PSSLookupDirectSM2"));
			
			if (!meshRenderer) {
				Debug.LogWarning("no mesh renderer");
				enabled = false;
				return;
			}
			materialOrig = meshRenderer.sharedMaterial;
			materialCopy = meshRenderer.material; // this makes a copy and applies it tot the renderer

			scattering = materialCopy.GetFloat(_ScatteringPower);
			//profileSphereMaterial.SetFloat (_ScatteringPower, scattering);
			profileSphereMaterial.SetFloat (_ScatteringPower, 0.4f);

			// bake reflection probes for all syboxes
			skyboxSpheres = new SkyboxSphere[skyboxes.Length];
			for (int i=0; i<skyboxes.Length; i++) {
				Material skybox = skyboxes[i];
				
				SkyboxSphere sp = new SkyboxSphere();
				if (!skybox) {
					Debug.LogWarning("no skybox material specified");
					enabled = false;
					return;
				}
				
				sp.skybox = skybox;
				sp.cube = bakeSkyboxMaterialToCube(cubemapResolution, skybox);
				
				skyboxSpheres[i] = sp;
			}
			SelectSkybox(skyboxSpheres[0]);

			UpdateRelfectionProbeIfNecessary();
		}

		void OnDestroy() {
			if (skyboxSpheres != null) {
				foreach (SkyboxSphere sp in skyboxSpheres)
					Object.Destroy (sp.cube);
			}

			if (skyboxSphereMaterial)
				Object.Destroy(skyboxSphereMaterial);
			if (materialCopy)
				Object.Destroy(materialCopy);
		}

		private void SelectSkybox(SkyboxSphere sb) {
			selectedSkybox = sb;
			RenderSettings.skybox = sb.skybox;
		}

		void Update () {
			UpdateRelfectionProbeIfNecessary();
		}

		void OnGUI() {
			var hovelLabelStyle = new GUIStyle("label");
			hovelLabelStyle.alignment = TextAnchor.MiddleCenter;
			hovelLabelStyle.fontStyle = FontStyle.Bold;

			var propertyLabel = new GUIStyle("label");
			propertyLabel.alignment = TextAnchor.UpperLeft;
			propertyLabel.fontStyle = FontStyle.Normal;

			int controlID = GUIUtility.GetControlID (FocusType.Passive);
			GUILayout.BeginVertical(GUI.skin.box);
			//GUILayout.BeginVertical(GUI.skin.window);

			GUILayout.BeginHorizontal(GUILayout.ExpandWidth(false));
			foreach (SkyboxSphere sp in skyboxSpheres) {
				Rect r = GUILayoutUtility.GetRect(sphereSize, sphereSize, GUILayout.ExpandWidth(false));

				Rect rFlipped = new Rect (r.x, Screen.height - r.y - r.height, r.width, r.height);

				bool mouseHovers = false;
				
				if (rFlipped.Contains (Input.mousePosition)) {
					float d1 = r.width * r.height / 4.0f;
					float d2 = ((Vector2)Input.mousePosition-rFlipped.center).sqrMagnitude;
					mouseHovers = d2 < d1;
				}

				if (Event.current.type == EventType.Repaint) {
					float rotation = Mathf.Repeat (Time.time / 10.0f, 1.0f);

					skyboxSphereMaterial.SetFloat("_Alpha", mouseHovers ? 1.0f : 0.5f);
					skyboxSphereMaterial.SetFloat("_Radius", mouseHovers ? 0.5f : 0.4f);
					skyboxSphereMaterial.SetTexture("_Cube", sp.cube);
					skyboxSphereMaterial.SetFloat("_Rotation", rotation);

					Graphics.DrawTexture(r, Texture2D.whiteTexture, skyboxSphereMaterial);
				}

				if (mouseHovers)
					GUI.Label(r, sp.skybox.name, hovelLabelStyle);

				if (mouseHovers && Input.GetMouseButtonDown(0)) {
					SelectSkybox(sp);
//					Event.current.Use();
				}
			}
			GUILayout.EndHorizontal();

			GUILayout.BeginHorizontal(GUILayout.ExpandWidth(false));
			foreach (PreIntegratedSkinProfile profile in profiles) {
				Rect r = GUILayoutUtility.GetRect(sphereSize, sphereSize, GUILayout.ExpandWidth(false));
				
				Rect rFlipped = new Rect (r.x, Screen.height - r.y - r.height, r.width, r.height);
				
				bool mouseHovers = false;
				
				if (rFlipped.Contains (Input.mousePosition)) {
					float d1 = r.width * r.height / 4.0f;
					float d2 = ((Vector2)Input.mousePosition-rFlipped.center).sqrMagnitude;
					mouseHovers = d2 < d1;
				}
				
				if (Event.current.type.Equals(EventType.Repaint)) {
					float rotation = Mathf.Repeat (Time.time / 10.0f, 1.0f);
					
					profileSphereMaterial.SetFloat("_Alpha", mouseHovers ? 1.0f : 0.5f);
					profileSphereMaterial.SetFloat("_Radius", mouseHovers ? 0.5f : 0.4f);
					profileSphereMaterial.SetFloat("_Rotation", rotation);

					profile.ApplyProfile(profileSphereMaterial);
					
					Graphics.DrawTexture(r, Texture2D.whiteTexture, profileSphereMaterial);
				}

				if (mouseHovers)
					GUI.Label(r, profile.name, hovelLabelStyle);
				
				if (mouseHovers && Input.GetMouseButtonDown(0)) {
					profile.ApplyProfile(materialCopy);
//					Event.current.Use();
				}
			}
			GUILayout.EndHorizontal();

			sun.enabled = GUILayout.Toggle (sun.enabled, "Direct light");

			GUILayout.BeginVertical ();
			GUILayout.Label ("Ambient intensity", propertyLabel);
			RenderSettings.ambientIntensity = GUILayout.HorizontalSlider(RenderSettings.ambientIntensity, 0f, 2f);
			GUILayout.EndVertical ();

			GUILayout.BeginVertical ();
			GUILayout.Label ("Reflection intensity", propertyLabel);
			reflectionProbe.intensity = GUILayout.HorizontalSlider(reflectionProbe.intensity, 0f, 2f);
			GUILayout.EndVertical ();

			GUILayout.BeginVertical ();
			GUILayout.Label ("Scattering", propertyLabel);
			{
				float newValue = GUILayout.HorizontalSlider (scattering, 0f, 2f);
				if (newValue != scattering) {
					scattering = newValue;
					materialCopy.SetFloat (_ScatteringPower, scattering);
				}
			}
			GUILayout.EndVertical ();

			{
				bool useDiffuse = !System.Object.ReferenceEquals(materialCopy.GetTexture (_MainTex), Texture2D.whiteTexture);
				bool tmp = GUILayout.Toggle (useDiffuse, "Use diffuse texture");
				if (tmp != useDiffuse) {
					if (tmp) {
						materialCopy.SetTexture(_MainTex, materialOrig.GetTexture(_MainTex));
					} else {
						materialCopy.SetTexture(_MainTex, Texture2D.whiteTexture);
					}
				}
			}

			GUILayout.EndVertical();

			Rect boxRect = GUILayoutUtility.GetLastRect ();
			switch (Event.current.GetTypeForControl(controlID))
			{
			case EventType.MouseDown:
				if (boxRect.Contains(Event.current.mousePosition))
				{
					GUIUtility.hotControl = controlID;
					Event.current.Use();
				}
				break;
				
			case EventType.MouseUp:
				if (GUIUtility.hotControl == controlID)
				{
					GUIUtility.hotControl = 0;
					Event.current.Use();
				}
				break;
				
			case EventType.MouseDrag:
				if (GUIUtility.hotControl == controlID)
					Event.current.Use();
				break;
				
			case EventType.ScrollWheel:
				if (boxRect.Contains(Event.current.mousePosition))
					Event.current.Use();
				break;
			}
		
		}
	
		private void UpdateRelfectionProbeIfNecessary() {
			if (sun) {
				bool render = false;
				if (!System.Object.ReferenceEquals(probeBakedWithSkybox, selectedSkybox)) {
				//Debug.Log("skybox changed"); // FIXME rmln
					render = true;
					probeBakedWithSkybox = selectedSkybox;
				}
				if (sun.transform.rotation != probeBakedWithSunRotation) {
					//Debug.Log("light rotated"); // FIXME rmln
					render = true;
					probeBakedWithSunRotation = sun.transform.rotation;
				}

				if (render) {
					if (reflectionProbe.isActiveAndEnabled)
						reflectionProbe.RenderProbe ();
				}
			}
		}

		/// <summary>
		/// Bakes the skybox material to rgb cubemap of specified size. No fancy roughness mip-chain, plain cubemap.
		/// </summary>
		private Cubemap bakeSkyboxMaterialToCube(int size, Material skybox) {
			var go = new GameObject();
			try {
				go.SetActive(false);
				
				var sb = go.AddComponent<Skybox>();
				sb.material = skybox;
				
				var cube = new Cubemap(size, TextureFormat.RGB24, false);
				
				var cam = go.AddComponent<Camera>();
				cam.enabled = false;
				cam.clearFlags = CameraClearFlags.Skybox;
				cam.renderingPath = RenderingPath.Forward;
				cam.cullingMask = 0;
				cam.RenderToCubemap(cube);
				
				cube.Apply(false, true);
				return cube;
			} finally {
				Object.Destroy(go);
			}
		}
	}
}