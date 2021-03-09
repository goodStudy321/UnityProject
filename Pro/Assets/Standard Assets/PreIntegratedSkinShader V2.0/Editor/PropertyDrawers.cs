using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System.Linq;

namespace JBrothers.PreIntegratedSkinShader2 {

	public class PSSProfileReference : MaterialPropertyDrawer {
//		private ProfileEditor profileEditor;

		private string GetWarnings(PreIntegratedSkinProfile[] profiles, out float height) {
			// Ideally I'd use GUIStyle.CalcHeight, but Unity 4.3 doesn't have it yet. Also it needs to know the width,
			// which isn't known in GetPropertyHeight. Please someone explain to me why did UT decide NOT to use dynamic
			// layouts for materials!

			if (profiles.Length == 1) {
				PreIntegratedSkinProfile profile = profiles[0];
				if (profile == null) {
					height = 40f;
					return "No diffusion profile set. You can create one from project panel using menu create->Pre-Integrated Skin Profile.";
				}
			} else {
				// don't show anything in mult-edit mode
			}

			height = 0;
			return null;
		}

		private PreIntegratedSkinProfile[] GetDistinctTargetProfiles(MaterialProperty prop) {
			var targets = prop.targets;

			Dictionary<int, PreIntegratedSkinProfile> profiles = new Dictionary<int, PreIntegratedSkinProfile>(targets.Length);
			foreach (Material mat in targets.OfType<Material>()) {
				PreIntegratedSkinProfile p = ProfileUtils.GetMaterialProfile(mat);
				if (p != null) {
					int id = p.GetInstanceID();
					if (!profiles.ContainsKey(id))
						profiles.Add(id, p);
				} else {
					// important: keep track if there's any target material without a profile
					if (!profiles.ContainsKey(0))
						profiles.Add(0, null);
				}
			}
			return profiles.Values.ToArray();
		}

		private bool profileEditorExpanded = false;

		public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor) {
			var targetProfiles = GetDistinctTargetProfiles(prop);

			PreIntegratedSkinProfile profile;
			if (targetProfiles.Length > 1) {
				EditorGUI.showMixedValue = true;
				profile = null;
			} else {
				EditorGUI.showMixedValue = false;
				profile = targetProfiles[0];
			}

			float warningsHeight;
			string warnings = GetWarnings(targetProfiles, out warningsHeight);
			if (warnings != null) {
				Rect r = new Rect(position.x, position.yMax-warningsHeight, position.width, warningsHeight);

				position.height = position.height - warningsHeight;

				EditorGUI.HelpBox(r, warnings, MessageType.Warning);
			}

			EditorGUI.BeginChangeCheck();

			if (profile != null) {
				EditorGUI.indentLevel++;

				Rect r1 = position;
				r1.width = 100f;
				r1.height = EditorGUIUtility.singleLineHeight;

				Rect r2 = position;
				r2.xMin = r1.xMax+10;
				r2.xMax = position.xMax;
				r2.height = EditorGUIUtility.singleLineHeight;

				Rect r3 = position;
				r3.yMin = r2.yMax;
				r3.height = ProfileEditor.MinHeight;

				profileEditorExpanded = EditorGUI.Foldout(r1, profileEditorExpanded, label, true);
//				EditorGUILayout.BeginVertical();
//				profileEditorExpanded = EditorGUILayout.Foldout(profileEditorExpanded, "");
				profile = EditorGUI.ObjectField(r2, profile, typeof(PreIntegratedSkinProfile), false) as PreIntegratedSkinProfile;
//				EditorGUILayout.EndVertical();

				EditorGUI.indentLevel--;

				if (profileEditorExpanded) {
					SerializedObject obj = new SerializedObject(targetProfiles);
					//ProfileEditor.DrawInspectorGUI(obj, r3);

					ProfileEditor profileEditor = (ProfileEditor)Editor.CreateEditor(targetProfiles, typeof(ProfileEditor));
					try {
						profileEditor.DrawInspectorGUI(obj, r3);
					} finally {
						Object.DestroyImmediate(profileEditor);
					}
				}
			} else {
				// null profile or multiple profiles
				profile = EditorGUI.ObjectField(position, label, profile, typeof(PreIntegratedSkinProfile), false) as PreIntegratedSkinProfile;
			}

			if (EditorGUI.EndChangeCheck()) {
				prop.textureValue = profile != null ? profile.referenceTexture : null;

				foreach (Material mat in prop.targets.OfType<Material>()) {
					ProfileUtils.SetMaterialProfile(mat, profile);
					if (profile != null)
						profile.ApplyProfile(mat);
					EditorUtility.SetDirty(mat);
				}
			}

		}
		
		public override float GetPropertyHeight (MaterialProperty prop, string label, MaterialEditor editor) {
			float height = EditorGUIUtility.singleLineHeight;

			var targetProfiles = GetDistinctTargetProfiles(prop);

			float warningsHeight;
			GetWarnings(targetProfiles, out warningsHeight);
			height += warningsHeight;

			if (targetProfiles.Length == 1 && targetProfiles[0] != null && profileEditorExpanded)
				height += ProfileEditor.MinHeight;

			return height;
		}

		public override void Apply(MaterialProperty prop) {
			base.Apply(prop);
			foreach (Material mat in prop.targets.OfType<Material>()) {
				PreIntegratedSkinProfile profile = ProfileUtils.GetMaterialProfile(mat);
				if (profile != null)
					profile.ApplyProfile(mat);
			}
		}
	}

	public class PSSSeparator : MaterialPropertyDrawer {
		public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor) {
			// empty space...
		}
	}

//	public class PSSBeginDisableGroup : MaterialPropertyDrawer {
//		public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor) {
//			EditorGUI.BeginDisabledGroup(true);
//		}
//
//		public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor) {
//			return 0f;
//		}
//	}
//
//	public class PSSEndDisableGroup : MaterialPropertyDrawer {
//		public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor) {
//			EditorGUI.EndDisabledGroup();
//		}
//
//		public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor) {
//			return 0f;
//		}
//	}

	public class PSSTitle : MaterialPropertyDrawer {
		private readonly float topMargin;
		private readonly Texture2D helpIcon;

		public PSSTitle() : this(5.0f) {

		}

		public PSSTitle(float topMargin) : base() {
			this.topMargin = topMargin;
			this.helpIcon = EditorGUIUtility.FindTexture("_Help");
		}

		public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor) {
			position.yMin += topMargin;
			GUI.Label(position, label, EditorStyles.boldLabel);

			if (GUI.Button(new Rect(position.xMax - helpIcon.width, position.y, helpIcon.width, helpIcon.height), new GUIContent(helpIcon, "Help"), GUIStyle.none))
				EditorUtils.OpenManual(label);
		}

		public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor) {
			return base.GetPropertyHeight (prop, label, editor) + topMargin;
		}
	}

	public class PSSFoldableTitle : MaterialPropertyDrawer {
		private readonly float topMargin;
		private readonly Texture2D helpIcon;
		
		public PSSFoldableTitle() : this(5.0f) {
			
		}
		
		public PSSFoldableTitle(float topMargin) : base() {
			this.topMargin = 5f;
			this.helpIcon = EditorGUIUtility.FindTexture("_Help");
		}
		
		public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor) {
			position.yMin += topMargin;

			bool expanded = prop.floatValue > 0f;

//			GUI.Label(position, label, EditorStyles.boldLabel);

			var st = EditorStyles.foldout;
			st.fontStyle = FontStyle.Bold;
			expanded = EditorGUI.Foldout(new Rect(position.x, position.y, position.width-helpIcon.width, position.height), expanded, label, true, st);

			prop.floatValue = expanded ? 1f : 0f;
			
			if (GUI.Button(new Rect(position.xMax - helpIcon.width, position.y, helpIcon.width, helpIcon.height), new GUIContent(helpIcon, "Help"), GUIStyle.none))
				EditorUtils.OpenManual(label);
		}
		
		public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor) {
			return base.GetPropertyHeight (prop, label, editor) + topMargin;
		}
	}

	public class PSSInternal : MaterialPropertyDrawer {
		public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor) {
			if (prop.targets.Length == 1) {
				Material mat = (Material)prop.targets[0];
				float f = mat.GetFloat("_PSSInternalExpanded"); // FIXME use name id
				if (f > 0f)
					editor.DefaultShaderProperty(position, prop, label);
			}
		}
		
		public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor) {
			if (prop.targets.Length == 1) {
				Material mat = (Material)prop.targets[0];
				float f = mat.GetFloat("_PSSInternalExpanded"); // FIXME use name id
				if (f > 0f)
					return MaterialEditor.GetDefaultPropertyHeight(prop);
			}
			return 0f;
		}
	}

//	public class PSSBeginToggleGroup : PSSToggleLeft {
//		public PSSBeginToggleGroup(string keyword) : base(keyword) {
//			// nothing to initialize
//		}
//
//		public PSSBeginToggleGroup(string keyword, string parentKeyword) : base(keyword, parentKeyword) {
//			// nothing to initialize
//		}
//
//		public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor) {
//			base.OnGUI(position, prop, label, editor);
//
////			// check if the keyword is enabled in at least one of selected materials
////			bool keywordEnabled = false;
////			foreach (Material mat in prop.targets.OfType<Material>()) {
////				if (mat.shaderKeywords.Contains(this.keyword)) {
////					keywordEnabled = true;
////					break;
////				}
////			}
//
//			bool value = prop.floatValue != 0.0f;
//			
//			EditorGUI.indentLevel++;
//			EditorGUI.BeginDisabledGroup(!value);
//		}
//	}
//
//	public class PSSEndToggleGroup : MaterialPropertyDrawer {
//		public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor) {
//			EditorGUI.EndDisabledGroup();
//			EditorGUI.indentLevel--;
//		}
//
//		public override float GetPropertyHeight (MaterialProperty prop, string label, MaterialEditor editor) {
//			return base.GetPropertyHeight (prop, label, editor) / 2f;
//		}
//	}

	public class PSSToggleLeft : MaterialPropertyDrawer {
		protected readonly string keyword;
		protected readonly string parentKeyword;

		public PSSToggleLeft(string keyword) : base() {
			this.keyword = keyword;
			this.parentKeyword = null;
		}

		public PSSToggleLeft(string keyword, string parentKeyword) : base() {
			this.keyword = keyword;
			this.parentKeyword = parentKeyword;
		}

		public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor) {
			EditorGUI.BeginChangeCheck ();

			bool value = prop.floatValue != 0.0f;

			EditorGUI.showMixedValue = prop.hasMixedValue;

			value = EditorGUI.ToggleLeft(position, label, value);

			EditorGUI.showMixedValue = false;
			if (EditorGUI.EndChangeCheck ()) {
				// Set the new value if it has changed
				prop.floatValue = value ? 1.0f : 0.0f;
				Apply(prop);
			}
		}

		public override void Apply(MaterialProperty prop) {
			base.Apply(prop);

			bool value = prop.floatValue != 0.0f;

			foreach (Material mat in prop.targets.OfType<Material>()) {
				// only enable if all parent keywords are enabled as well in this material
				bool keywordEnabled = value;
//				if (value && parentKeyword != null) {
////					foreach (string parentKeyword in parentKeywords) {
//						if (!mat.shaderKeywords.Contains(parentKeyword)) {
//							keywordEnabled = false;
//							break;
//						}
////					}
//				}
				
				if (keywordEnabled) {
					HashSet<string> keywords = new HashSet<string>(mat.shaderKeywords);
					keywords.Remove(keyword + "_OFF");
					keywords.Add(keyword + "_ON");
					mat.shaderKeywords = keywords.ToArray();
				} else {
					HashSet<string> keywords = new HashSet<string>(mat.shaderKeywords);
					keywords.Remove(keyword + "_ON");
					keywords.Add(keyword + "_OFF");
					mat.shaderKeywords = keywords.ToArray();
				}

				EditorUtility.SetDirty(mat);
			}
		}
	}

//	public class PSSSliderWithValue : MaterialPropertyDrawer {
//		private readonly float overlap = 0.125f;
//		private readonly float power;
//
//		public PSSSliderWithValue() : this(1.0f) {
//		}
//
//		public PSSSliderWithValue(float power) : base() {
//			this.power = power;
//		}
//
//		public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor) {
//			EditorGUI.BeginChangeCheck();
//			EditorGUI.showMixedValue = prop.hasMixedValue;
////			float floatValue = EditorGUI.PowerSlider(position, label, prop.floatValue, prop.rangeLimits.x, prop.rangeLimits.y, 1f);
//			//
//
//			float min, max;
//			if (prop.type == MaterialProperty.PropType.Range) {
//				min = prop.rangeLimits.x;
//				max = prop.rangeLimits.y;
//			} else {
//				min = float.MinValue;
//				max = float.MaxValue;
//			}
////			float floatValue = EditorGUI.Slider(position, label, prop.floatValue, min, max);
//			float floatValue = prop.floatValue;
//
////			Rect labelRect = new Rect(
////				position.x,
////				position.y,
////				position.width/3,
////				position.height
////			);
////			Rect sliderRect = new Rect(
////				position.x + position.width/3,
////				position.y,
////				position.width - position.width/3 - controlSize,
////				position.height
////			);
////
////			Rect boxRect = new Rect(
////				position.x + position.width - controlSize,
////				position.y,
////				controlSize,
////				position.height
////			);
//
////			position.height *= 0.75f;
//
//			Rect labelRect = new Rect(
//				position.x,
//				position.y,
//				position.width,
//				position.height
//			);
//			Rect sliderRect = new Rect(
//				position.x,
//				position.y + position.height * (0.5f-overlap),
//				position.width,
//				position.height * (0.5f+overlap)
//			);
//
//			EditorGUI.HandlePrefixLabel(position, EditorGUI.IndentedRect(labelRect), new GUIContent(label));
////			floatValue = EditorGUI.FloatField(boxRect, floatValue);
//
//			// FIXME EditorGUI.Slider doesn't work correctly with min > max
////			if (max > min) {
//				floatValue = EditorGUI.Slider(sliderRect, prop.floatValue, min, max);
//
////			floatValue = EditorGUI.PowerSlider(sliderRect, label, floatValue, min, max, power);
//
////			int controlID = GUIUtility.GetControlID(EditorGUI.s_SliderHash, EditorGUIUtility.native, position);
////			Rect position2 = EditorGUI.PrefixLabel(position, controlID, label);
////			Rect dragZonePosition = (!EditorGUI.LabelHasContent(label)) ? default(Rect) : EditorGUIUtility.DragZoneRect(position);
////			return EditorGUI.DoSlider(position2, dragZonePosition, controlID, sliderValue, leftValue, rightValue, EditorGUI.kFloatFieldFormatString, power);
//
////			EditorGUI.sl
////			} else {
////				floatValue = -EditorGUI.Slider(sliderRect, -prop.floatValue, -min, -max);
////			}
//
//
//
//			//			editor.RangeProperty(position, prop, null);
//			
//			//						editor.FloatProperty(position, prop, prop.displayName);
//			
//			//			// Setup
//			//			EditorGUI.BeginChangeCheck ();
//			//			var value : boolean = prop.floatValue != 0.0f;
//			//			EditorGUI.showMixedValue = prop.hasMixedValue;
//			//			// Show the toggle control
//			//			value = EditorGUI.Toggle (position, label, value);
//			//			EditorGUI.showMixedValue = false;
//			//
//			//			if (EditorGUI.EndChangeCheck ()) {
//			//				// Set the new value if it has changed
//			//				prop.floatValue = value ? 1.0f : 0.0f;
//			//			}
//
//
//			EditorGUI.showMixedValue = false;
//			if (EditorGUI.EndChangeCheck())
//				prop.floatValue = floatValue;
//
//		}
//
//		public override float GetPropertyHeight (MaterialProperty prop, string label, MaterialEditor editor) {
//			return base.GetPropertyHeight (prop, label, editor) * 1.75f;
//		}
//	}
	
	public class PSSBumpinessBiasSlider : MaterialPropertyDrawer {
		private readonly float overlap = 0.125f;

		public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor) {
			EditorGUI.BeginChangeCheck();
			EditorGUI.showMixedValue = prop.hasMixedValue;
			
			Rect labelRect = new Rect(
				position.x,
				position.y,
				position.width,
				position.height
			);
			Rect sliderRect = new Rect(
				position.x,
				position.y + position.height * (0.5f-overlap),
				position.width,
				position.height * (0.5f+overlap)
			);
			
			Vector4 value = prop.vectorValue;

			EditorGUI.HandlePrefixLabel(position, EditorGUI.IndentedRect(labelRect), new GUIContent(label));

			EditorGUI.MinMaxSlider(sliderRect, ref value.x, ref value.y, 0f, 2f);


			EditorGUI.showMixedValue = false;
			if (EditorGUI.EndChangeCheck())
				prop.vectorValue = value;
		}

		public override float GetPropertyHeight (MaterialProperty prop, string label, MaterialEditor editor) {
			return base.GetPropertyHeight (prop, label, editor) * 1.75f;
		}
	}
}