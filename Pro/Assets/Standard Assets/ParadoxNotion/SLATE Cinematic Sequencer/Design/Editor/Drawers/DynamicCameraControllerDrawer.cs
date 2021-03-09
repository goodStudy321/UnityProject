#if UNITY_EDITOR

using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Linq;

namespace Slate{

	[CustomPropertyDrawer(typeof(DynamicCameraController))]
	public class DynamicCameraControllerDrawer : PropertyDrawer {
		public override float GetPropertyHeight(SerializedProperty prop, GUIContent label){ return -2; }
		public override void OnGUI(Rect rect, SerializedProperty prop, GUIContent label){

			var transposerProp = prop.FindPropertyRelative("_transposer");
			var tModeProp      = prop.FindPropertyRelative("_transposer.trackingMode");
			var composerProp   = prop.FindPropertyRelative("_composer");
			var cModeProp      = prop.FindPropertyRelative("_composer.trackingMode");

			var tModeName = tModeProp.enumNames[ tModeProp.enumValueIndex ];
			var cModeName = cModeProp.enumNames[ cModeProp.enumValueIndex ];

			EditorGUI.indentLevel++;

			GUI.color = new Color(0.5f,0.5f,0.5f,0.2f);
			GUILayout.BeginVertical(Styles.clipBoxStyle);
			GUI.color = Color.white;
			EditorGUILayout.PropertyField(prop, new GUIContent("<b>Dynamic Shot Controller (BETA Feature)</b>"));
			if (prop.isExpanded){

				EditorGUI.indentLevel++;

				//Transposer
				GUI.color = new Color(0.5f,0.5f,0.5f,0.2f);
				GUILayout.BeginVertical(Styles.clipBoxStyle);
				GUI.color = Color.white;

				var tLabel = string.Format("Position Constraint ({0})", tModeName);
				EditorGUILayout.PropertyField(transposerProp, new GUIContent(tLabel));
				if (transposerProp.isExpanded){
					EditorGUILayout.HelpBox("Position Constraint can be used to automate positioning of the shot.\nIf so, keyframing Position Parameter of the shot will be disabled.", MessageType.None);
					EditorGUILayout.PropertyField(tModeProp, GUIContent.none);
					if (tModeProp.intValue != 0){
						var tTargetProp     = prop.FindPropertyRelative("_transposer.target");
						var tOffsetProp     = prop.FindPropertyRelative("_transposer.targetOffset");
						var tOffsetModeProp = prop.FindPropertyRelative("_transposer.offsetMode");
						var tDampProp       = prop.FindPropertyRelative("_transposer.smoothDamping");

						var nullTarget = tTargetProp.objectReferenceValue == null;
						GUI.backgroundColor = nullTarget? Color.red : Color.white;
						EditorGUILayout.PropertyField(tTargetProp);
						GUI.backgroundColor = Color.white;
						GUI.enabled = !nullTarget;
						EditorGUILayout.PropertyField(tOffsetProp);
						EditorGUILayout.PropertyField(tOffsetModeProp);
						EditorGUILayout.PropertyField(tDampProp);
						GUI.enabled = true;
					}
				}

				GUILayout.EndVertical();
				GUILayout.Space(2);

				//Composer
				GUI.color = new Color(0.5f,0.5f,0.5f,0.2f);
				GUILayout.BeginVertical(Styles.clipBoxStyle);
				GUI.color = Color.white;

				var cLabel = string.Format("Aim Constraint ({0})", cModeName);
				EditorGUILayout.PropertyField(composerProp, new GUIContent(cLabel));

				if (composerProp.isExpanded){
					EditorGUILayout.HelpBox("Aim Constraint can be used to automate rotation of the shot.\nIf so, keyframing Rotation Parameter of the shot will be disabled.", MessageType.None);
					EditorGUILayout.PropertyField(cModeProp, GUIContent.none);
					if (cModeProp.intValue != 0){
						var cTargetProp      = prop.FindPropertyRelative("_composer.target");
						var cPointProp       = prop.FindPropertyRelative("_composer.targetOffset");
						var cSizeProp        = prop.FindPropertyRelative("_composer.targetSize");
						var cFrameLeftProp   = prop.FindPropertyRelative("_composer.frameLeft");
						var cFrameRightProp  = prop.FindPropertyRelative("_composer.frameRight");
						var cFrameTopProp    = prop.FindPropertyRelative("_composer.frameTop");
						var cFrameBottomProp = prop.FindPropertyRelative("_composer.frameBottom");
						var cDampProp        = prop.FindPropertyRelative("_composer.smoothDamping");

						var nullTarget = cTargetProp.objectReferenceValue == null;
						GUI.backgroundColor = nullTarget? Color.red : Color.white;
						EditorGUILayout.PropertyField(cTargetProp);
						GUI.backgroundColor = Color.white;
						GUI.enabled = !nullTarget;
						EditorGUILayout.PropertyField(cPointProp);
						EditorGUILayout.PropertyField(cSizeProp);
						EditorGUILayout.PropertyField(cFrameLeftProp);
						EditorGUILayout.PropertyField(cFrameRightProp);
						EditorGUILayout.PropertyField(cFrameTopProp);
						EditorGUILayout.PropertyField(cFrameBottomProp);
						EditorGUILayout.PropertyField(cDampProp);
						GUI.enabled = true;
						EditorGUILayout.HelpBox("You can also view the composition settings live in the Unity Game Window while a clip using this shot is selected and active (cutscene time within clip range).", MessageType.None);
					}
				}
				GUILayout.EndVertical();
				GUILayout.Space(2);
			}

			GUILayout.EndVertical();
			GUILayout.Space(2);

			EditorGUI.indentLevel = 0;
		}
	}
}

#endif