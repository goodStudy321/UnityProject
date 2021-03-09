#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;
using System;
using System.Collections;
using System.IO;

[CustomEditor (typeof(CombineChildrenAFS))]
public class CombineChildrenAFSEditor : Editor {
	// Serialize
	private SerializedObject CombineChildrenAFS;
	private SerializedProperty GroundMaxDistance;
	private SerializedProperty UnderlayingTerrain;
	private SerializedProperty HealthyColor;
	private SerializedProperty DryColor;
	private SerializedProperty NoiseSpread;
	private SerializedProperty randomBrightness;
	private SerializedProperty randomPulse;
	private SerializedProperty randomBending;
	private SerializedProperty randomFluttering;
	private SerializedProperty NoiseSpreadFoliage;
	private SerializedProperty bakeScale;
	private SerializedProperty bakePivots;

	//
	private bool hTerrain = false;
	private bool sGrass = true;
	private bool sFoliage = true;

	private static string baseURL = "https://docs.google.com/document/d/164MTEnV_-krBdMr-20QhPttY1bY5H46FtpSDM1UQdRk/view?pref=2&pli=1#heading=";


	public override void OnInspectorGUI () {
		CombineChildrenAFS = new SerializedObject(target);
		GetProperties();
		CombineChildrenAFS script = (CombineChildrenAFS)target;
		
		Color myBlue = new Color(0.5f,0.7f,1.0f,1.0f);
		Color myCol = new Color(.5f, .8f, .0f, 1f); // Light Green
		Color myCol01 = new Color(0.30f,0.47f,1.0f,1.0f);
		if (!EditorGUIUtility.isProSkin) {
			myCol = new Color(0.05f,0.45f,0.0f,1.0f); // Dark Green
			myCol01 = Color.blue;
		}

		
		GUIStyle myFoldoutStyle = new GUIStyle(EditorStyles.foldout);
		myFoldoutStyle.fontStyle = FontStyle.Bold;

		myFoldoutStyle.normal.textColor = myCol;
		myFoldoutStyle.onNormal.textColor = myCol;	//	Rendering settings for when the control is turned on but lost focus
		//myFoldoutStyle.hover.textColor = Color.white;
		//myFoldoutStyle.onHover.textColor = Color.white;
		myFoldoutStyle.active.textColor = myCol;
		myFoldoutStyle.onActive.textColor = myCol;
		myFoldoutStyle.focused.textColor = myCol;
		myFoldoutStyle.onFocused.textColor = myCol;

		GUIStyle myBoldLabel = new GUIStyle(EditorStyles.label);
		myBoldLabel.fontStyle = FontStyle.Bold;
		myBoldLabel.normal.textColor = myCol;
		myBoldLabel.onNormal.textColor = myCol;

		GUIStyle myMiniHelpBtn = new GUIStyle(EditorStyles.miniButton);
		myMiniHelpBtn.padding = new RectOffset(0, 0, 2, 2);
		myMiniHelpBtn.normal.background = null;
		myMiniHelpBtn.normal.textColor = myCol01;
		myMiniHelpBtn.onNormal.textColor = myCol01;
		myMiniHelpBtn.active.textColor = myCol01;
		myMiniHelpBtn.onActive.textColor = myCol01;
		myMiniHelpBtn.focused.textColor = myCol01;
		myMiniHelpBtn.onFocused.textColor = myCol01;

		//
		if (script.isStaticallyCombined) {
			GUI.enabled = false;
		}
		//

		EditorGUILayout.BeginVertical();
		GUILayout.Space(10);

		EditorGUI.BeginChangeCheck();
			EditorGUILayout.BeginHorizontal();
			script.hideChildren = EditorGUILayout.Toggle("", script.hideChildren, GUILayout.Width(14) );
			GUILayout.Label ("Hide Child Objects in Hierarchy");
			EditorGUILayout.EndHorizontal();


		if (EditorGUI.EndChangeCheck()) {
				script.ShowHideChildren();
		}

		GUILayout.Space(9);
		EditorGUILayout.BeginHorizontal();
		GUILayout.Label ("Ground normal sampling", myBoldLabel);

		if (GUILayout.Button("Help", myMiniHelpBtn, GUILayout.Width(40))) {
			Application.OpenURL(baseURL + "h.zcvf6rdqbn7");
		}
		EditorGUILayout.EndHorizontal();

		GUILayout.Space(4);
		EditorGUILayout.PropertyField(GroundMaxDistance, new GUIContent("Max Ground Distance") );
		GUILayout.Space(4);
		// underlaying terrain
		EditorGUILayout.PropertyField(UnderlayingTerrain, new GUIContent("Underlaying Terrain") );
		GUI.color = myBlue;
		hTerrain = EditorGUILayout.Foldout(hTerrain," Help");
		GUI.color = Color.white;
		if(hTerrain){
			EditorGUILayout.HelpBox("If you place the objects of the cluster (all or just a few of them) on top of a terrain you will have to assign the according terrain in order to make lighting fit 100% the terrain lighting.", MessageType.None, true);
		}
		
		// bake grass
		GUILayout.Space(9);
		EditorGUILayout.BeginVertical();
		EditorGUILayout.BeginHorizontal();
		sGrass = EditorGUILayout.Foldout(sGrass," Grass Shader Settings", myFoldoutStyle );
		if (GUILayout.Button("Help", myMiniHelpBtn, GUILayout.Width(40))) {
				Application.OpenURL(baseURL + "h.95o37b28n0a2");
		}
		EditorGUILayout.EndHorizontal();
		GUILayout.Space(4);
		
		if (sGrass) {
			EditorGUILayout.PropertyField(HealthyColor, new GUIContent("Healthy Color") );
			EditorGUILayout.PropertyField(DryColor, new GUIContent("Dry Color") );
			EditorGUILayout.PropertyField(NoiseSpread, new GUIContent("Noise Spread") );
		}
		EditorGUILayout.EndVertical();
		
		// bake foliage
		GUILayout.Space(9);
		EditorGUILayout.BeginVertical();
		EditorGUILayout.BeginHorizontal();
		sFoliage = EditorGUILayout.Foldout(sFoliage," Foliage Shader Settings", myFoldoutStyle);
		if (GUILayout.Button("Help", myMiniHelpBtn, GUILayout.Width(40))) {
				Application.OpenURL(baseURL + "h.sj78yuqz26ia");
		}
		EditorGUILayout.EndHorizontal();
		GUILayout.Space(4);
		if (sFoliage) {
			EditorGUILayout.PropertyField(randomPulse, new GUIContent("Random Phase") );
			EditorGUILayout.PropertyField(randomBending, new GUIContent("Random Bending") );
			EditorGUILayout.PropertyField(randomBrightness, new GUIContent("Random Occlusion") );
			EditorGUILayout.PropertyField(randomFluttering, new GUIContent("Random Fluttering") );
			EditorGUILayout.PropertyField(NoiseSpreadFoliage, new GUIContent("Noise Spread") );
			GUILayout.Space(4);
			EditorGUILayout.BeginHorizontal();
				EditorGUILayout.BeginHorizontal();
					EditorGUILayout.PropertyField(bakeScale, GUIContent.none, GUILayout.Width(14) );
					GUILayout.Label ("Bake Scale");
				EditorGUILayout.EndHorizontal();
				GUILayout.Space(-8);
				EditorGUILayout.BeginHorizontal();
					GUI.enabled = false;
					EditorGUILayout.PropertyField(bakePivots, GUIContent.none, GUILayout.Width(14) );
					GUILayout.Label ("Bake Pivots");
					GUI.enabled = true;
				EditorGUILayout.EndHorizontal();
			EditorGUILayout.EndHorizontal();
		}
		EditorGUILayout.EndVertical();

		// overall settings
		GUILayout.Space(9);
		EditorGUILayout.BeginHorizontal();
		GUILayout.Label ("Overall Settings", myBoldLabel);
		if (GUILayout.Button("Help", myMiniHelpBtn, GUILayout.Width(40))) {
			Application.OpenURL(baseURL + "h.fiid9a9k7k7k");
		}
		EditorGUILayout.EndHorizontal();

		GUILayout.Space(4);
		EditorGUILayout.BeginHorizontal();
			EditorGUILayout.BeginHorizontal();
				script.CastShadows = EditorGUILayout.Toggle("", script.CastShadows, GUILayout.Width(14) );
				GUILayout.Label ("Cast Shadows" );
			EditorGUILayout.EndHorizontal();
		GUILayout.Space(4);
			EditorGUILayout.BeginHorizontal();
				script.destroyChildObjectsInPlaymode = EditorGUILayout.Toggle("", script.destroyChildObjectsInPlaymode, GUILayout.Width(14) );
				GUILayout.Label ("Destroy Children" );
			EditorGUILayout.EndHorizontal();
		EditorGUILayout.EndHorizontal();
		
		GUILayout.Space(4);
			EditorGUILayout.BeginHorizontal();
				script.UseLightprobes = EditorGUILayout.Toggle("", script.UseLightprobes, GUILayout.Width(14) );
				GUILayout.Label ("Use Lightprobes" );
			EditorGUILayout.EndHorizontal();
			//if (script.UseLightprobes) {
			//	EditorGUILayout.HelpBox("Please make sure that 'Enable IBL' is disabled in the 'Setup Advanced Foliage Shader' script. Otherwise Lightprobes are not supported.", MessageType.Warning, true);
			//}
		GUILayout.Space(4);
		//if (script.destroyChildObjectsInPlaymode) {
		//	EditorGUILayout.BeginHorizontal();
		//	GUILayout.Label ("", GUILayout.Width(16) );
		//	EditorGUILayout.HelpBox("If this option is checked, child objects will also be destroyed if you hit 'Combine statically'.", MessageType.Warning, true);	
		//	EditorGUILayout.EndHorizontal();
		//}
		
			
		// debugging settings
		GUILayout.Space(9);
		EditorGUILayout.BeginHorizontal();
		GUILayout.Label ("Debugging", myBoldLabel);
		if (GUILayout.Button("Help", myMiniHelpBtn, GUILayout.Width(40))) {
			Application.OpenURL(baseURL + "h.e340vcfng4c");
		}
		EditorGUILayout.EndHorizontal();
		
		GUILayout.Space(4);
		EditorGUILayout.BeginHorizontal();
		script.debugNormals = EditorGUILayout.Toggle("", script.debugNormals, GUILayout.Width(14) );
		GUILayout.Label ("Debug sampled Ground Normals" );
		EditorGUILayout.EndHorizontal();
		if (script.debugNormals) {
			script.EnableDebugging();
		}
		else {
			script.DisableDebugging();
		}
		

		// functions
		GUILayout.Space(9);
		EditorGUILayout.BeginHorizontal();
		GUILayout.Label ("Functions", myBoldLabel);
		if (GUILayout.Button("Help", myMiniHelpBtn, GUILayout.Width(40))) {
			Application.OpenURL(baseURL + "h.y4crv27luffe");
		}
		EditorGUILayout.EndHorizontal();
		
		GUILayout.Space(4);
		script.RealignGroundMaxDistance = EditorGUILayout.Slider("Realign Ground max Dist.", script.RealignGroundMaxDistance, 0.0f, 10.0f );
		EditorGUILayout.BeginHorizontal();
			script.ForceRealignment = EditorGUILayout.Toggle("", script.ForceRealignment, GUILayout.Width(14) );
			GUILayout.Label ("Force Realignment" );
		EditorGUILayout.EndHorizontal();
		GUILayout.Space(9);
		EditorGUILayout.BeginHorizontal();
			if (GUILayout.Button( "Realign Objects") ) {
					script.Realign();
			}
			if (GUILayout.Button( "Combine statically") ) {
				if (script.destroyChildObjectsInPlaymode) {
					if ( EditorUtility.DisplayDialog("Combine statically?", "Are you sure you want to combine and destroy all child objects? If you want to be able to edit child objects please uncheck 'Destroy Children' first.\nPlease note: You may have to duplicate the material and set 'Combined Mesh' to 1.", "Combine", "Cancel" ) ) {
						script.Combine();
					}
				}
				else {
					if ( EditorUtility.DisplayDialog("Combine statically?", "All child objects will be deactivated.\nPlease note: You may have to duplicate the material and set 'Combined Mesh' to 1.", "Combine", "Cancel" ) ) {
						script.Combine();
					}
				}
			}
		EditorGUILayout.EndHorizontal();
		GUILayout.Space(9);

		EditorGUILayout.BeginHorizontal();
			script.createUniqueUV2 = EditorGUILayout.Toggle("", script.createUniqueUV2, GUILayout.Width(14) );
			GUILayout.Label ("Create unique UV2 (needed by lightmapper)" );
		EditorGUILayout.EndHorizontal();

		GUI.enabled = true;

		EditorGUILayout.BeginHorizontal();
			script.isStaticallyCombined = EditorGUILayout.Toggle("", script.isStaticallyCombined, GUILayout.Width(14) );
			GUILayout.Label ("Has been statically combined" );
		EditorGUILayout.EndHorizontal();
		GUILayout.Space(9);
		EditorGUILayout.EndVertical();

		if (GUI.changed) {
	   		//script.Update();
	   		EditorUtility.SetDirty(script);
	   		SceneView.RepaintAll();
	  	}
	  	CombineChildrenAFS.ApplyModifiedProperties();
	}
	
	// if the editor looses focus
	void OnDisable() {
		
	}

	//	///////////////////////////////////////////////////
	private void GetProperties() {
		GroundMaxDistance = CombineChildrenAFS.FindProperty("GroundMaxDistance");
		UnderlayingTerrain = CombineChildrenAFS.FindProperty("UnderlayingTerrain");
		HealthyColor = CombineChildrenAFS.FindProperty("HealthyColor");
		DryColor = CombineChildrenAFS.FindProperty("DryColor");
		NoiseSpread = CombineChildrenAFS.FindProperty("NoiseSpread");
		//
		randomBrightness = CombineChildrenAFS.FindProperty("randomBrightness");
		randomPulse = CombineChildrenAFS.FindProperty("randomPulse");
		randomBending = CombineChildrenAFS.FindProperty("randomBending");
		randomFluttering = CombineChildrenAFS.FindProperty("randomFluttering");
		NoiseSpreadFoliage = CombineChildrenAFS.FindProperty("NoiseSpreadFoliage");
		bakeScale = CombineChildrenAFS.FindProperty("bakeScale");
		bakePivots = CombineChildrenAFS.FindProperty("bakePivots");
	}		
}
#endif