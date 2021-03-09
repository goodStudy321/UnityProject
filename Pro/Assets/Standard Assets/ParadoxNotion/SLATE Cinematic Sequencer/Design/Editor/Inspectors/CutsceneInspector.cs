#if UNITY_EDITOR

using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Reflection;
using System.Linq;

namespace Slate{

	[CustomEditor(typeof(Cutscene))]
	public class CutsceneInspector : Editor {

		private bool optionsFold = true;
		private bool actorsFold = false;

		SerializedProperty updateModeProp;
		SerializedProperty wrapModeProp;
		SerializedProperty stopModeProp;
		SerializedProperty explLayersProp;
		SerializedProperty activeLayersProp;
		SerializedProperty playbackSpeedProp;

		private static Editor selectedObjectEditor;
		private static Cutscene cutscene;
		private static bool willResample;
		private static bool willDirty;

		void OnEnable(){
			cutscene = (Cutscene)target;
			selectedObjectEditor = null;
			willResample = false;
			willDirty = false;

			updateModeProp    = serializedObject.FindProperty("_updateMode");
			wrapModeProp      = serializedObject.FindProperty("_defaultWrapMode");
			stopModeProp      = serializedObject.FindProperty("_defaultStopMode");
			explLayersProp    = serializedObject.FindProperty("_explicitActiveLayers");
			activeLayersProp  = serializedObject.FindProperty("_activeLayers");
			playbackSpeedProp = serializedObject.FindProperty("_playbackSpeed");
		}

		void OnDisable(){
			cutscene = null;
			willResample = false;
			willDirty = false;
			if (selectedObjectEditor != null){
				DestroyImmediate(selectedObjectEditor, true);
			}
		}

		public override void OnInspectorGUI(){

			cutscene = (Cutscene)target;

			var e = Event.current;
			GUI.skin.GetStyle("label").richText = true;

			if (e.rawType == EventType.MouseDown && e.button == 0 ){ //generic undo
				Undo.RegisterFullObjectHierarchyUndo(cutscene.groupsRoot.gameObject, "Cutscene Inspector");
				Undo.RecordObject(cutscene, "Cutscene Inspector");
				willDirty = true;
			}

			if (e.rawType == EventType.MouseUp && e.button == 0 || e.rawType == EventType.KeyUp){
				willDirty = true;
				if (CutsceneUtility.selectedObject != null && CutsceneUtility.selectedObject.startTime <= cutscene.currentTime){
					willResample = true;
				}
			}

			GUILayout.Space(5);
			if (GUILayout.Button("EDIT IN SLATE")){
				CutsceneEditor.ShowWindow(cutscene);
			}
			GUILayout.Space(5);

			DoCutsceneInspector();
			DoSelectionInspector();


			if (willDirty){
				willDirty = false;
				EditorUtility.SetDirty(cutscene);
				if (CutsceneUtility.selectedObject as UnityEngine.Object != null){
					EditorUtility.SetDirty( (UnityEngine.Object)CutsceneUtility.selectedObject );
				}
			}

			if (willResample){ //resample after the changes on fresh gui pass
				willResample = false;
				//delaycall so that other gui controls are finalized before resample.
				EditorApplication.delayCall += ()=>{ if (cutscene != null) cutscene.ReSample(); };
			}

			Repaint();

		}

		void DoCutsceneInspector(){

			GUI.color = new Color(0,0,0,0.2f);
			GUILayout.BeginHorizontal(Slate.Styles.headerBoxStyle);
			GUI.color = Color.white;
			GUILayout.Label(string.Format("<b>{0} Cutscene Settings</b>", optionsFold? "▼" : "▶"));
			GUILayout.EndHorizontal();

			var lastRect = GUILayoutUtility.GetLastRect();
			EditorGUIUtility.AddCursorRect(lastRect, MouseCursor.Link);
			if (Event.current.type == EventType.MouseDown && lastRect.Contains(Event.current.mousePosition)){
				optionsFold = !optionsFold;
				Event.current.Use();
			}

			GUILayout.Space(2);
			if (optionsFold){
				serializedObject.Update();
				EditorGUILayout.PropertyField(updateModeProp);
				EditorGUILayout.PropertyField(wrapModeProp);
				EditorGUILayout.PropertyField(stopModeProp);
				EditorGUILayout.PropertyField(playbackSpeedProp);
				EditorGUILayout.PropertyField(explLayersProp);
				if (explLayersProp.boolValue == true){
					EditorGUILayout.PropertyField(activeLayersProp);
				}
				serializedObject.ApplyModifiedProperties();

				DoActorsInspector();
			}
		}

		void DoActorsInspector(){
			actorsFold = EditorGUILayout.Foldout(actorsFold, "Affected Group Actors");
			GUI.enabled = cutscene.currentTime == 0;
			if (actorsFold){
				EditorGUI.indentLevel++;
				var exists = false;
				foreach(var group in cutscene.groups.OfType<ActorGroup>()){
					var name = string.IsNullOrEmpty(group.name)? "(No Name Specified)" : group.name;
					group.actor = EditorGUILayout.ObjectField(name, group.actor, typeof(GameObject), true) as GameObject;
					exists = true;
				}
				if (!exists){
					GUILayout.Label("No Actor Groups");
				}
				EditorGUI.indentLevel--;
			}
			GUI.enabled = true;
		}


		static void DoSelectionInspector(){

			TryCreateInspectedEditor();
			if (selectedObjectEditor != null){
				if (CutsceneUtility.selectedObject != null && !CutsceneUtility.selectedObject.Equals(null)){
					EditorTools.BoldSeparator();
					GUILayout.Space(4);
					ShowPreliminaryInspector();
					selectedObjectEditor.OnInspectorGUI();
				}
			}
		}


		static void ShowPreliminaryInspector(){
					
				var type = CutsceneUtility.selectedObject.GetType();
				var nameAtt = type.GetCustomAttributes(typeof(NameAttribute), false).FirstOrDefault() as NameAttribute;
				var name = nameAtt != null? nameAtt.name : type.Name.SplitCamelCase();
				var withinRange = cutscene.currentTime > 0 && cutscene.currentTime >= CutsceneUtility.selectedObject.startTime && cutscene.currentTime <= CutsceneUtility.selectedObject.endTime;
				var keyable = CutsceneUtility.selectedObject is IKeyable && (CutsceneUtility.selectedObject as IKeyable).animationData != null && (CutsceneUtility.selectedObject as IKeyable).animationData.isValid;
				var isActive = CutsceneUtility.selectedObject.isActive;

				GUI.color = new Color(0,0,0,0.2f);
				GUILayout.BeginHorizontal(Slate.Styles.headerBoxStyle);
				GUI.color = Color.white;
				GUILayout.Label(string.Format("<b><size=18>{0}{1}</size></b>", withinRange && keyable && isActive? "<color=#eb5b50>●</color> " : "", name ) );
				GUILayout.EndHorizontal();

				if (Prefs.showDescriptions){
					var descAtt = type.GetCustomAttributes(typeof(DescriptionAttribute), true).FirstOrDefault() as DescriptionAttribute;
					var description = descAtt != null? descAtt.description : null;
					if (!string.IsNullOrEmpty(description)){
						EditorGUILayout.HelpBox(description, MessageType.None);
					}
				}

				GUILayout.Space(2);
		}


		static void TryCreateInspectedEditor(){

			if (selectedObjectEditor == null && CutsceneUtility.selectedObject as Object != null){
				selectedObjectEditor = Editor.CreateEditor( (Object)CutsceneUtility.selectedObject );
				// Editor.CreateCachedEditor( (Object)CutsceneUtility.selectedObject, null, ref selectedObjectEditor);
			}

			if (selectedObjectEditor != null && selectedObjectEditor.target != CutsceneUtility.selectedObject as Object){
				DestroyImmediate(selectedObjectEditor, true);
				if (CutsceneUtility.selectedObject != null){
					selectedObjectEditor = Editor.CreateEditor( (Object)CutsceneUtility.selectedObject );
					// Editor.CreateCachedEditor( (Object)CutsceneUtility.selectedObject, null, ref selectedObjectEditor);
				}
			}
		}
	}
}

#endif