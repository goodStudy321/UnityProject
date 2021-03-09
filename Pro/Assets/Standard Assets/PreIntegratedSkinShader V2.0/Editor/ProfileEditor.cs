using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace JBrothers.PreIntegratedSkinShader2 {
	[CustomEditor(typeof(PreIntegratedSkinProfile))]
	public class ProfileEditor : Editor {
		public enum PreviewMode {
			Sphere,
			RadialDistance,
			Transmission,
			ReflectanceGraph
		}
		
		[SerializeField]
		private float previewScattering = 0.33f;

		[System.NonSerialized]
		private Dictionary<PreviewMode,Material> previewMaterials;

		public void OnDisable() {
			ReleaseResources();
		}

		public void OnDestroy() {
			ReleaseResources();
		}

		public override bool HasPreviewGUI() {
			return true;
		}

		private void ReleaseResources() {
			if (previewMaterials != null) {
				foreach (Material mat in previewMaterials.Values)
					DestroyImmediate(mat);
				previewMaterials = null;
			}
		}

		private Material GetOrCreatePreviewMaterial(PreviewMode previewMode) {
			if (previewMaterials == null)
				previewMaterials = new Dictionary<PreviewMode, Material>(3);

			Material mat;
			if (!previewMaterials.TryGetValue(previewMode, out mat)) {
				string shaderName = "Hidden/PreIntegratedSkinShader/ComputeLookup/";
				if (previewMode == PreviewMode.Sphere) {
					shaderName += "VisualizeSphere";
				} else if (previewMode == PreviewMode.RadialDistance) {
					shaderName += "VisualizeRadialDistance";
				} else if (previewMode == PreviewMode.Transmission) {
					shaderName += "VisualizeTransmission";
				} else if (previewMode == PreviewMode.ReflectanceGraph) {
					shaderName += "VisualizeReflectanceGraph";
				} else {
					throw new System.Exception("unknown preview mode: " + previewMode);
				}
				
				Shader shader = Shader.Find(shaderName);
				if (shader == null)
					throw new System.Exception("preview shader not found: " + shaderName);

				mat = new Material(shader);
				mat.hideFlags = HideFlags.HideAndDontSave;

				previewMaterials.Add(previewMode, mat);
			}

			return mat;
		}
		
		public override void OnPreviewSettings() {
			previewScattering = GUILayout.HorizontalSlider(previewScattering, 0.05f, 1.0f, GUILayout.MaxWidth(100f));
		}

		public override void OnPreviewGUI(Rect r, GUIStyle background) {
			PreIntegratedSkinProfile profile = target as PreIntegratedSkinProfile;

			if (profile == null)
				return;

			// for dynamic preview always show the sphere with user controllable scattering
			try {
				Material previewMaterial = GetOrCreatePreviewMaterial(PreviewMode.Sphere);
				profile.ApplyProfile(previewMaterial, true);

				previewMaterial.SetFloat("_TextureWidth", r.width);
				previewMaterial.SetFloat("_TextureHeight", r.height);

				previewMaterial.SetFloat("_PreviewScatteringPower", previewScattering);

				Graphics.DrawTexture(r, EditorGUIUtility.whiteTexture, previewMaterial);
			} catch (System.Exception ex) {
				Debug.LogException(ex);
			}
		}

		public override Texture2D RenderStaticPreview(string assetPath, Object[] subAssets, int width, int height) {
			Texture2D tex = null;

			PreIntegratedSkinProfile profile = (PreIntegratedSkinProfile)AssetDatabase.LoadAssetAtPath(assetPath, typeof(PreIntegratedSkinProfile));

			bool supportsRenderTextures;
			#if UNITY_5_5_OR_NEWER
			// From 5.5 on SystemInfo.supportsRenderTextures always returns true and Unity produces an ugly warning.
			supportsRenderTextures = true;
			#else
			supportsRenderTextures = SystemInfo.supportsRenderTextures;
			#endif

			if (profile != null && supportsRenderTextures) {
				try {
					// for static preview always show the radial distance, which visualizes well the profile, even with small size and just looks good :)
					Material mat = GetOrCreatePreviewMaterial(PreviewMode.RadialDistance);
					try {
						mat.hideFlags = HideFlags.HideAndDontSave;

						RenderTexture outRT = new RenderTexture(width, height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
						try {
							if (outRT.Create()) {
								RenderTexture oldRndT = RenderTexture.active;
								RenderTexture.active = outRT;
								try {
									profile.ApplyProfile(mat);
									
									mat.SetFloat("_TextureWidth", width);
									mat.SetFloat("_TextureHeight", height);
									
									GL.PushMatrix();
									GL.LoadOrtho();
									
									for (int i=0 ; i<mat.passCount; i++) {
										mat.SetPass(i);
										
										GL.Begin(GL.QUADS);
										
										GL.TexCoord2(0f, 1f);
										GL.Vertex3(0f, 0f, 0);
										
										GL.TexCoord2(1f, 1f);
										GL.Vertex3(1f, 0f, 0);
										
										GL.TexCoord2(1f, 0f);
										GL.Vertex3(1f, 1f, 0);
										
										GL.TexCoord2(0f, 0f);
										GL.Vertex3(0f, 1f, 0);
										
										GL.End();
									}
									
									GL.PopMatrix();
									
									tex = new Texture2D(width, height, TextureFormat.ARGB32, true, true);
									tex.ReadPixels(new Rect(0, 0, width, height), 0, 0, true);

									tex.Apply();
								} finally {
									RenderTexture.active = oldRndT;
									Graphics.SetRenderTarget(oldRndT);

									outRT.Release();
								}
							}
						} finally {
							DestroyImmediate(outRT);
						}
					} finally {
						DestroyImmediate(mat);
					}
				} catch (System.Exception ex) {
					tex = null;
					Debug.LogException(ex);
				}
			}

			// fall back to simple icon
			if (tex == null)
				base.RenderStaticPreview (assetPath, subAssets, width, height);

			return tex;
		}

		private Texture2D helpIcon;

		public static float MinHeight =
				// the six profile elements
				EditorGUIUtility.singleLineHeight*2f*6f
				// reflectance graph visualization
				+ EditorGUIUtility.singleLineHeight+100f
				// radial distance visualization
				+ EditorGUIUtility.singleLineHeight+100f
				// transmission visualization
				+ EditorGUIUtility.singleLineHeight+50f
				// plus some spacing a,t the end
				+ EditorGUIUtility.singleLineHeight;

		private void DrawProfileElementProperty(Rect position, SerializedProperty prop) {
			SerializedProperty weightRed = prop.FindPropertyRelative("x");
			SerializedProperty weightGreen = prop.FindPropertyRelative("y");
			SerializedProperty weightBlue = prop.FindPropertyRelative("z");
			SerializedProperty variance = prop.FindPropertyRelative("w");

			Rect rectColor = new Rect(position.x, position.y, 35, position.height/2);
			Rect rectWeightRed = new Rect(rectColor.xMax, position.y, (position.width-32)/4, position.height/2);
			Rect rectWeightGreen = new Rect(rectWeightRed.xMax, position.y, (position.width-32)/4, position.height/2);
			Rect rectWeightBlue = new Rect(rectWeightGreen.xMax, position.y, (position.width-32)/4, position.height/2);
			Rect rectWeightVariance = new Rect(rectWeightBlue.xMax, position.y, (position.width-32)/4, position.height/2);
			
			EditorGUI.BeginChangeCheck();
			Color color = new Color(weightRed.floatValue, weightGreen.floatValue, weightBlue.floatValue, 1f);
			color = EditorGUI.ColorField(rectColor, color);
			if (EditorGUI.EndChangeCheck()) {
				weightRed.floatValue = color.r;
				weightGreen.floatValue = color.g;
				weightBlue.floatValue = color.b;
			}
			
			EditorGUIUtility.labelWidth = 12;
			weightRed.floatValue = Mathf.Clamp(EditorGUI.FloatField(rectWeightRed, new GUIContent("R", "Red weight"), weightRed.floatValue), 0.001f, 1.0f);
			weightGreen.floatValue = Mathf.Clamp(EditorGUI.FloatField(rectWeightGreen, new GUIContent("G", "Green weight"), weightGreen.floatValue), 0.001f, 1.0f);
			weightBlue.floatValue = Mathf.Clamp(EditorGUI.FloatField(rectWeightBlue, new GUIContent("B", "Blue weight"), weightBlue.floatValue), 0.001f, 1.0f);
			variance.floatValue = Mathf.Clamp(EditorGUI.FloatField(rectWeightVariance, new GUIContent("V", "Variance"), variance.floatValue), 0.001f, 10.0f);
			EditorGUIUtility.labelWidth = 0; // reset to default
		}

		public void DrawInspectorGUI(SerializedObject profileObj, Rect rect) {
			EditorGUI.BeginChangeCheck();
			
			PreIntegratedSkinProfile profile = (PreIntegratedSkinProfile)profileObj.targetObject;
			profileObj.Update();

			float h = EditorGUIUtility.singleLineHeight * 2f;

			float y = rect.y;
			DrawProfileElementProperty(new Rect(rect.x, y, rect.width, h), profileObj.FindProperty("gauss6_1"));
			y += h;
			DrawProfileElementProperty(new Rect(rect.x, y, rect.width, h), profileObj.FindProperty("gauss6_2"));
			y += h;
			DrawProfileElementProperty(new Rect(rect.x, y, rect.width, h), profileObj.FindProperty("gauss6_3"));
			y += h;
			DrawProfileElementProperty(new Rect(rect.x, y, rect.width, h), profileObj.FindProperty("gauss6_4"));
			y += h;
			DrawProfileElementProperty(new Rect(rect.x, y, rect.width, h), profileObj.FindProperty("gauss6_5"));
			y += h;
			DrawProfileElementProperty(new Rect(rect.x, y, rect.width, h), profileObj.FindProperty("gauss6_6"));
			y += h;
			
			profileObj.ApplyModifiedProperties();

			if (EditorGUI.EndChangeCheck()) {
				if (profile != null) {
					profile.needsRecalcDerived = true;
					profile.needsRenormalize = true;
				}
			}

			// visualize profile
			try {
				{
					GUI.Label(new Rect(rect.x, y, rect.width, EditorGUIUtility.singleLineHeight), "Reflectance (y:r x R(r), x:radial distance)");
					y += EditorGUIUtility.singleLineHeight;
					Rect r = new Rect(rect.x, y, rect.width, 100f);

					Material previewMaterial = GetOrCreatePreviewMaterial(PreviewMode.ReflectanceGraph);
					
					//profile.ApplyProfile(previewMaterial, true);
					
					previewMaterial.SetVector("_PSSProfileHigh_weighths1_var1", profile.gauss6_1);
					previewMaterial.SetVector("_PSSProfileHigh_weighths2_var2", profile.gauss6_2);
					previewMaterial.SetVector("_PSSProfileHigh_weighths3_var3", profile.gauss6_3);
					previewMaterial.SetVector("_PSSProfileHigh_weighths4_var4", profile.gauss6_4);
					previewMaterial.SetVector("_PSSProfileHigh_weighths5_var5", profile.gauss6_5);
					previewMaterial.SetVector("_PSSProfileHigh_weighths6_var6", profile.gauss6_6);
					
					previewMaterial.SetFloat("_TextureWidth", r.width);
					previewMaterial.SetFloat("_TextureHeight", r.height);
					
					previewMaterial.SetFloat("_PreviewScatteringPower", previewScattering);
					
					Graphics.DrawTexture(r, EditorGUIUtility.whiteTexture, previewMaterial);
					y += r.height;
				}
			
				{
					GUI.Label(new Rect(rect.x, y, rect.width, EditorGUIUtility.singleLineHeight), "Radial distance");
					y += EditorGUIUtility.singleLineHeight;
					Rect r = new Rect(rect.x, y, rect.width, 100f);

					Material previewMaterial = GetOrCreatePreviewMaterial(PreviewMode.RadialDistance);
					profile.ApplyProfile(previewMaterial, true);
					
					previewMaterial.SetFloat("_TextureWidth", r.width);
					previewMaterial.SetFloat("_TextureHeight", r.height);
					
					previewMaterial.SetFloat("_PreviewScatteringPower", previewScattering);
					
					Graphics.DrawTexture(r, EditorGUIUtility.whiteTexture, previewMaterial);
					y += r.height;
				}

				{
					GUI.Label(new Rect(rect.x, y, rect.width, EditorGUIUtility.singleLineHeight), "Transmission");
					y += EditorGUIUtility.singleLineHeight;
					Rect r = new Rect(rect.x, y, rect.width, 50f);
					
					Material previewMaterial = GetOrCreatePreviewMaterial(PreviewMode.Transmission);
					profile.ApplyProfile(previewMaterial, true);
					
					previewMaterial.SetFloat("_TextureWidth", r.width);
					previewMaterial.SetFloat("_TextureHeight", r.height);
					
					previewMaterial.SetFloat("_PreviewScatteringPower", previewScattering);
					
					Graphics.DrawTexture(r, EditorGUIUtility.whiteTexture, previewMaterial);
					y += r.height;
				}
			} catch (System.Exception ex) {
				Debug.LogException(ex);
			}
			
			// ideally here I could show some curve plots...


			if (profile != null) {
				if (profile.needsRenormalize) {
					if (GUILayout.Button("Normalize weights")) {
						profile.NormalizeOriginalWeights();
					}
				}
				
				if (GUILayout.Button("Apply to referencing materials in project")) {
					ApplyToProjectMaterials(profile);
				}
			}
		}

		public override void OnInspectorGUI() {
			// For now just let the user edit crude values that control the gaussian curves that aproximate the
			// diffusion profile and let the voodoo happen.
			// See chapter 14.4 of http://http.developer.nvidia.com/GPUGems3/gpugems3_ch14.html to understand what it
			// all means.
			
			GUILayout.BeginHorizontal(GUILayout.ExpandWidth(true));
			{
				if (!helpIcon)
					helpIcon = EditorGUIUtility.FindTexture("_Help");
				
				GUILayout.Label("Diffusion Profile", EditorStyles.boldLabel, GUILayout.ExpandWidth(true));
				
				if (GUILayout.Button(new GUIContent(helpIcon, "Help"), GUIStyle.none, GUILayout.ExpandWidth(false)))
					EditorUtils.OpenManual("Diffusion Profiles");
				
			}
			GUILayout.EndHorizontal();
			EditorGUILayout.HelpBox("Don't know where to start? Use the help icon above.", MessageType.Info);

			Rect r = GUILayoutUtility.GetRect(100f, MinHeight);
			DrawInspectorGUI(serializedObject, r);
		}

		static void ApplyToProjectMaterials(PreIntegratedSkinProfile profile) {
			bool cancelled = EditorUtility.DisplayCancelableProgressBar("Applying profile", "loading asset list...", 0f);
			try {
				// Ideally I'd use Resources.FindObjectsOfTypeAll<Material>(), but it only returns materials that are
				// already loaded, which usually is limited to the open scene.
				// Since we don't want to miss any material let's check all assets in the project in search for materials...
				// GetAllAssetPaths is a lazy solution. It frees me to searching for files manually, though it would 
				// be a better to do a recursive file search directly since the list can be really big in a real project.
				string[] assetPaths = AssetDatabase.GetAllAssetPaths();

				int refId = profile.referenceTexture.GetInstanceID();
				for (int i=0; i<assetPaths.Length && !cancelled; i++) {
					string path = assetPaths[i];
					float progress = (float)i / (float)assetPaths.Length;
					cancelled = EditorUtility.DisplayCancelableProgressBar("Applying profile", "searching for materials", progress);

					if (path.EndsWith(".mat", System.StringComparison.InvariantCultureIgnoreCase)) {
						Material mat = AssetDatabase.LoadMainAssetAtPath(path) as Material;
						if (mat != null) {
							if (mat.HasProperty(ProfileUtils.ProfileMaterialPropertyID)) {
								var refTex = mat.GetTexture(ProfileUtils.ProfileMaterialPropertyID);
								if (refTex != null && refTex.GetInstanceID() == refId) {
									Debug.Log("applying to " + AssetDatabase.GetAssetPath(mat)); // FIXME rmln
									profile.ApplyProfile(mat);
								}
							}
						}
					}
				}
			} finally {
				EditorUtility.ClearProgressBar();
			}
		}

		static void ApplyToLoadedMaterials(PreIntegratedSkinProfile profile) {
			bool cancelled = EditorUtility.DisplayCancelableProgressBar("Applying profile", "loading asset list...", 0f);
			try {
				// Ideally I'd use Resources.FindObjectsOfTypeAll<Material>(), but it only returns materials that are
				// already loaded, which usually is limited to the open scene.
				// Since we don't want to miss any material let's check all assets in the project in search for materials...
				// GetAllAssetPaths is a lazy solution. It frees me to searching for files manually, though it would 
				// be a better to do a recursive file search directly since the list can be really big in a real project.
				//string[] assetPaths = AssetDatabase.GetAllAssetPaths();
				//EditorUtility.CollectDependencies

				int refId = profile.referenceTexture.GetInstanceID();
				Material[] materials = Resources.FindObjectsOfTypeAll<Material>();
				for (int i=0; i<materials.Length && !cancelled; i++) {
					Material mat = materials[i];
					float progress = (float)i / (float)materials.Length;
					cancelled = EditorUtility.DisplayCancelableProgressBar("Applying profile", "searching for materials", progress);

					if (mat.HasProperty(ProfileUtils.ProfileMaterialPropertyID)) {
						var refTex = mat.GetTexture(ProfileUtils.ProfileMaterialPropertyID);
						if (refTex != null && refTex.GetInstanceID() == refId) {
							Debug.Log("applying to " + AssetDatabase.GetAssetPath(mat)); // FIXME rmln
							profile.ApplyProfile(mat);
						}
					}
				}
			} finally {
				EditorUtility.ClearProgressBar();
			}
		}
	}

	internal static class EditorUtils {
		public static void OpenManual(string topic) {
			bool online =
				EditorUtility.DisplayDialog (
					"",
					"The on-line documentation can be more up to date and can contain additional resources.",
					"Browse on-line", "Browse off-line");
			if (online) {
				//string url = "https://gitlab.com/jbrothers/pre-integrated-skin-shader/wikis/manual-2x";
				string url = "http://gitlab.com/jbrothers/pre-integrated-skin-shader-public-wiki/wikis/manual-2x";
				if (topic != null) {
					string titleID = topic.ToLowerInvariant().Replace(' ', '-');
					url += "#" + titleID;
				}
				Help.BrowseURL(url);
			} else {
				string url = "Assets/PreIntegratedSkinShader V2.0/Manual.pdf";
				Application.OpenURL (url);
			}

		}
	}
}