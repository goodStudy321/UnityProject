#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;
using System;
using System.IO;

[CustomEditor (typeof(SetupAfs))]
public class SetupAfsEditor : Editor {
	// Serialize
	private SerializedObject SetupAFS;
	// Specular Lighting
	private SerializedProperty AfsSpecFade;
	//
	private SerializedProperty Foliage_WindPrimaryStrength;
	private SerializedProperty Foliage_WindSecondaryStrength;
	private SerializedProperty Foliage_WaveSize;
	private SerializedProperty Foliage_LeafTurbulence;
	//
	private SerializedProperty Grass_WindStrength;
	private SerializedProperty Grass_WaveSize;
	private SerializedProperty Grass_WindSpeed;
	private SerializedProperty Grass_WindJitterVariation;
	private SerializedProperty Grass_WindJitterScale;
	//
	private SerializedProperty Trees_WindPrimaryStrength;
	private SerializedProperty Trees_WindSecondaryStrength;
	// Rain
	private SerializedProperty RainAmount;
	// Terrain Detail Vegetation Settings
	private SerializedProperty TerrainLegacyBending;
	private SerializedProperty VertexLitTranslucency;
	private SerializedProperty VertexLitAlphaCutOff;
	private SerializedProperty VertexLitSpecularReflectivity;
	private SerializedProperty VertexLitVariationMultipilier;
	private SerializedProperty VertexLitLeafTurbulence;
	private SerializedProperty VertexLitBackfaceSmoothness;
	private SerializedProperty VertexLitColorVariation;
	private SerializedProperty VertexLitHorizonFade;
	private SerializedProperty TerrainFoliageNrmSpecMap;
	private SerializedProperty GrassMinSmoothness;
	private SerializedProperty GrassMaxSmoothness;
	// Grass, Tree and Billboard settings
	private SerializedProperty AutoSyncToTerrain;
	private SerializedProperty SyncedTerrain;
	private SerializedProperty DetailDistanceForGrassShader;
	private SerializedProperty BillboardStart;
	private SerializedProperty BillboardFadeLenght;
	private SerializedProperty GrassWavingTint;
	// Tree Render settings
	private SerializedProperty TreeColor;
	private SerializedProperty BillboardFadeOutLength;
	private SerializedProperty BillboardAdjustToCamera;
	private SerializedProperty BillboardAngleLimit;
	// Culling
	private SerializedProperty EnableCameraLayerCulling;
	private SerializedProperty SmallDetailsDistance;
	private SerializedProperty SmallDetailsLayer;
	private SerializedProperty MediumDetailsDistance;
	private SerializedProperty MediumDetailsLayer;
	// Special Render Settings
	private SerializedProperty AllGrassObjectsCombined;
//

//	Temp variables
	private Cubemap tempCube;
	private Texture2D tempTex;
	private Vector2 specFade;
	private Vector4 tempWind;
	//private bool fadeLenghtReseted = false;
	private Terrain[] allTerrains;

//	private Light[] DirLights;

	private Camera MainCamera;
	
	private string toolTip;
	private bool isProSkin;

	public enum fogMode {
		Linear = 0,
        Exponential = 1,
        Exp2 = 2
	}

	private fogMode m_fogMode;

	private static string baseURL = "https://docs.google.com/document/d/164MTEnV_-krBdMr-20QhPttY1bY5H46FtpSDM1UQdRk/view?pref=2&pli=1#heading=";

//	Icons
	private Texture icnLight;
	private Texture icnSpec;
	private Texture icnFog;
	private Texture icnWind;
	private Texture icnRain;
	private Texture icnTerr;
	//private Texture icnTree;
	private Texture icnCulling;
	private Texture icnCamera;

	void getIcons() {

		string folder = "Assets/Advanced Foliage Shaders v5/Scripts/Icons/";

		if (EditorGUIUtility.isProSkin) {
			if (icnLight == null) icnLight = AssetDatabase.LoadAssetAtPath(folder + "icnLight.png", typeof(Texture)) as Texture;
			//if (icnSpec == null) icnSpec = AssetDatabase.LoadAssetAtPath(folder + "icnSpec.png", typeof(Texture)) as Texture;
			if (icnFog == null) icnFog = AssetDatabase.LoadAssetAtPath(folder + "icnFog.png", typeof(Texture)) as Texture;
			if (icnWind == null) icnWind = AssetDatabase.LoadAssetAtPath(folder + "icnWind.png", typeof(Texture)) as Texture;
			if (icnRain == null) icnRain = AssetDatabase.LoadAssetAtPath(folder + "icnRain.png", typeof(Texture)) as Texture;
			if (icnTerr == null) icnTerr = AssetDatabase.LoadAssetAtPath(folder + "icnTerrain.png", typeof(Texture)) as Texture;
			//if (icnTree == null) icnTree = AssetDatabase.LoadAssetAtPath(folder + "icnTree.png", typeof(Texture)) as Texture;
			if (icnCulling == null) icnCulling = AssetDatabase.LoadAssetAtPath(folder + "icnCulling.png", typeof(Texture)) as Texture;
			if (icnCamera == null) icnCamera = AssetDatabase.LoadAssetAtPath(folder + "icnCamera.png", typeof(Texture)) as Texture;
		}
		else {
			if (icnLight == null) icnLight = AssetDatabase.LoadAssetAtPath(folder + "icnLight_br.png", typeof(Texture)) as Texture;
			//if (icnSpec == null) icnSpec = AssetDatabase.LoadAssetAtPath(folder + "icnSpec_br.png", typeof(Texture)) as Texture;
			if (icnFog == null) icnFog = AssetDatabase.LoadAssetAtPath(folder + "icnFog_br.png", typeof(Texture)) as Texture;
			if (icnWind == null) icnWind = AssetDatabase.LoadAssetAtPath(folder + "icnWind_br.png", typeof(Texture)) as Texture;
			if (icnRain == null) icnRain = AssetDatabase.LoadAssetAtPath(folder + "icnRain_br.png", typeof(Texture)) as Texture;
			if (icnTerr == null) icnTerr = AssetDatabase.LoadAssetAtPath(folder + "icnTerrain_br.png", typeof(Texture)) as Texture;
			//if (icnTree == null) icnTree = AssetDatabase.LoadAssetAtPath(folder + "icnTree_br.png", typeof(Texture)) as Texture;
			if (icnCulling == null) icnCulling = AssetDatabase.LoadAssetAtPath(folder + "icnCulling_br.png", typeof(Texture)) as Texture;
			if (icnCamera == null) icnCamera = AssetDatabase.LoadAssetAtPath(folder + "icnCamera_br.png", typeof(Texture)) as Texture;
		}
	}

	
	public override void OnInspectorGUI () {
        SetupAFS = new SerializedObject(target);
		GetProperties();
		SetupAfs script = (SetupAfs)target;

		//if(icnLight == null) {
			getIcons();
		//}


//	///////////////////////////////////////////////////
//	Style Settings
		// Colors for Pro
		Color myCol = new Color(.5f, .8f, .0f, 1f); // Light Green // new Color(.6f, .9f, .22f, 1f); // Light Green
		Color myBgCol = myCol; //new Color(.5f, .75f, .24f, 1f);
		Color SplitterCol = new Color(1f, 1f, 1f, 0.075f);
		Color SplitterCol1 = new Color(.6f, .9f, .22f, .005f);
		Color myCol01 = new Color(0.30f,0.47f,1.0f,1.0f);
		// Colors for Indie
		if (!EditorGUIUtility.isProSkin) {
			myCol = new Color(0.05f,0.45f,0.0f,1.0f); // Dark Green
			myBgCol = new Color(0.94f,0.94f,0.94f,1.0f);
			SplitterCol = new Color(0f, 0f, 0f, 0.125f);
			SplitterCol1 = new Color(1f, 1f, 1f, 0.5f);
			myCol01 = Color.blue;
		}
		//Color myBlue = new Color(0.5f,0.7f,1.0f,1.0f);

		// Custom Foldout
		GUIStyle myFoldoutStyle = new GUIStyle(EditorStyles.foldout);
		myFoldoutStyle.fontStyle = FontStyle.Bold;
		myFoldoutStyle.fontSize = 12;

		myFoldoutStyle.normal.textColor = myCol;
		myFoldoutStyle.onNormal.textColor = myCol;
		//myFoldoutStyle.hover.textColor = Color.white;
		//myFoldoutStyle.onHover.textColor = Color.white;
		myFoldoutStyle.active.textColor = myCol;
		myFoldoutStyle.onActive.textColor = myCol;
		myFoldoutStyle.focused.textColor = myCol;
		myFoldoutStyle.onFocused.textColor = myCol;

		GUIStyle myRegularFoldoutStyle = new GUIStyle(myFoldoutStyle);
		myRegularFoldoutStyle.fontStyle = FontStyle.Normal;

		// Custom Label
		GUIStyle myLabel = new GUIStyle(EditorStyles.label);
		myLabel.normal.textColor = myCol;
		myLabel.onNormal.textColor = myCol;

		// Default icon Size
		EditorGUIUtility.SetIconSize( new Vector2(16,16));

		GUIStyle myMiniHelpBtn = new GUIStyle(EditorStyles.miniButton);
		myMiniHelpBtn.padding = new RectOffset(0, 0, 2, 2);
		myMiniHelpBtn.normal.background = null;
		myMiniHelpBtn.normal.textColor = myCol01;
		myMiniHelpBtn.onNormal.textColor = myCol01;
		myMiniHelpBtn.active.textColor = myCol01;
		myMiniHelpBtn.onActive.textColor = myCol01;
		myMiniHelpBtn.focused.textColor = myCol01;
		myMiniHelpBtn.onFocused.textColor = myCol01;

		GUILayout.Space(8);

//	///////////////////////////////////////////////////
//	Wind settings
		GUILayout.Space(4);
		GUI.backgroundColor = myBgCol;
		EditorGUILayout.BeginVertical("Box");
		// Foldout incl. Icon
		EditorGUILayout.BeginHorizontal();
			GUILayout.Space(-2);
			EditorGUI.indentLevel++;
			EditorGUILayout.BeginVertical();
				script.FoldWind  = EditorGUILayout.Foldout(script.FoldWind, "Wind Settings", myFoldoutStyle);
			EditorGUILayout.EndVertical();
			EditorGUI.indentLevel--;

			if (GUILayout.Button("Help", myMiniHelpBtn, GUILayout.Width(40))) {
				Application.OpenURL(baseURL + "h.rxwg5xlcsukv");
			}

			EditorGUILayout.BeginVertical(GUILayout.Width(20) );
				// Label needs width!
				EditorGUILayout.LabelField(new GUIContent(icnWind), GUILayout.Width(20), GUILayout.Height(20));
			EditorGUILayout.EndVertical();
			GUI.backgroundColor = Color.white;
		EditorGUILayout.EndHorizontal();
		GUILayout.Space(-2);
		EditorGUILayout.EndVertical();
				// FoldoutContent
		if (script.FoldWind) {
			GUILayout.Space(-5);
			EditorGUILayout.BeginVertical("Box");
				DrawSplitter1(EditorGUILayout.GetControlRect(false, 4), SplitterCol1);
				EditorGUILayout.BeginHorizontal();
					GUILayout.Space(13);
					EditorGUILayout.BeginVertical();
						
					//	Foliage
						GUILayout.Label ("Wind Settings for Foliage Shaders", myLabel);
						GUILayout.Space(2);
							toolTip = "Multiplier to adjust the Bending of Foliage independently from Grass and Trees.";
						EditorGUILayout.PropertyField(Foliage_WindPrimaryStrength, new GUIContent("Main Strength", toolTip) );
						EditorGUILayout.PropertyField(Foliage_WindSecondaryStrength, new GUIContent("Turbulence Strength", toolTip) );
						GUILayout.Space(4);
							toolTip = "Factor the original frequency of the secondary bending gets multiplied with. It determines the max frequency leaves might bend in when effected by strong winds.";
						EditorGUILayout.PropertyField(Foliage_LeafTurbulence, new GUIContent("Leaf Turbulence*", toolTip) );
						toolTip = "The shader adds some variation to the bending taking the vertex position in world space and the 'Wave Size Foliage' "+
							"parameter into account. So smaller wave sizes will add more variety to a given area but also lead to slightly different amounts of bending on each vertex even of a single mesh. This might cause some strange distortion of your models – especially large models. " +
							"For this reason you should set the 'Wave Size' to at least 2 or even 3 times the bounding box size of the largest model.";
						EditorGUILayout.PropertyField(Foliage_WaveSize, new GUIContent("Wave Size*", toolTip) );
					
					//	Grass	
						GUILayout.Space(6);
						GUILayout.Label ("Wind Settings for Grass Shaders", myLabel);
						GUILayout.Space(2);
							toolTip = "Multiplier to adjust the Bending of Grass independently from Foliage and Trees.";
						EditorGUILayout.PropertyField(Grass_WindStrength, new GUIContent("Strength", toolTip) );
							toolTip = "Defines the Speed of the wind animation on grass.";
						EditorGUILayout.PropertyField(Grass_WindSpeed, new GUIContent("Speed", toolTip) );
							toolTip = "Similar to the terrain's original 'Size' parameter: The size of the 'ripples' on grassy areas as the wind blows over them.\n*Do not change at run time.";
						EditorGUILayout.PropertyField(Grass_WaveSize, new GUIContent("Wave Size*", toolTip) );
						
						GUILayout.Space(4);
							toolTip = "Breaks up the uniform movement defined by 'Size'.\n*Do not change at run time.";
						EditorGUILayout.PropertyField(Grass_WindJitterVariation, new GUIContent("Turbulence*", toolTip) );
							toolTip = "Defines the Strength of the second wind animation.";
						EditorGUILayout.PropertyField(Grass_WindJitterScale, new GUIContent("Jitter", toolTip) );

					//	Trees
						GUILayout.Space(6);
						GUILayout.Label ("Wind Settings for Tree Creator Shaders", myLabel);
						GUILayout.Space(2);
							toolTip = "Multiplier to adjust the Bending of the Tree Creator Shaders independently from Foliage and Grass.";
						EditorGUILayout.PropertyField(Trees_WindPrimaryStrength, new GUIContent("Main Strength", toolTip) );
						EditorGUILayout.PropertyField(Trees_WindSecondaryStrength, new GUIContent("Turbulence Strength", toolTip) );

						GUILayout.Space(4);
					EditorGUILayout.EndVertical();
				EditorGUILayout.EndHorizontal();
			EditorGUILayout.EndVertical();
		}

//	///////////////////////////////////////////////////
//	Terrain Vegetation Settings	
		GUILayout.Space(4);
		GUI.backgroundColor = myBgCol;
		EditorGUILayout.BeginVertical("Box");
		// Foldout incl. Icon
		EditorGUILayout.BeginHorizontal();
			GUILayout.Space(-2);
			EditorGUI.indentLevel++;
			EditorGUILayout.BeginVertical();
				script.FoldVegTerrain  = EditorGUILayout.Foldout(script.FoldVegTerrain, "Terrain Vegetation Settings", myFoldoutStyle);
			EditorGUILayout.EndVertical();
			EditorGUI.indentLevel--;

			if (GUILayout.Button("Help", myMiniHelpBtn, GUILayout.Width(40))) {
				Application.OpenURL(baseURL + "h.fh0ejrtye3qo");
			}

			EditorGUILayout.BeginVertical(GUILayout.Width(20) );
				// GUILayout.Space(2);
				// Label needs width!
				EditorGUILayout.LabelField(new GUIContent(icnTerr), GUILayout.Width(20), GUILayout.Height(20));
			EditorGUILayout.EndVertical();
			GUI.backgroundColor = Color.white;
		EditorGUILayout.EndHorizontal();
		GUILayout.Space(-2);
		EditorGUILayout.EndVertical();
		
		// FoldoutContent
		if (script.FoldVegTerrain) {
			GUILayout.Space(-5);
			EditorGUILayout.BeginVertical("Box");
				DrawSplitter1(EditorGUILayout.GetControlRect(false, 4), SplitterCol1);
				EditorGUILayout.BeginHorizontal();
					GUILayout.Space(13);

					EditorGUILayout.BeginVertical();
						// General Billboard settings
						EditorGUILayout.LabelField("Sync Settings with Terrain", myLabel);
						GUILayout.Space(2);
					
						EditorGUILayout.BeginHorizontal();
							//script.AutoSyncToTerrain = EditorGUILayout.Toggle("", script.AutoSyncToTerrain, GUILayout.Width(14) );
							EditorGUILayout.PropertyField(AutoSyncToTerrain, GUIContent.none, GUILayout.Width(14) );
							EditorGUILayout.LabelField("Automatically sync with Terrain");
						EditorGUILayout.EndHorizontal();
					
						if(AutoSyncToTerrain.boolValue) {
							EditorGUI.indentLevel++;
								EditorGUILayout.PropertyField(SyncedTerrain, new GUIContent(" Specify Terrain") );
							EditorGUI.indentLevel--;
							if(SyncedTerrain.objectReferenceValue != null){
								GUI.enabled = false;
							}
							else {
								EditorGUILayout.HelpBox("Please assign a terrain.", MessageType.Warning, true);
							}
						}
						else {
							GUILayout.Space(4);
							EditorGUILayout.HelpBox("Please make sure that the parameters marked with * match those in your terrain settings. Otherwise shading might look corrupted.\nYou may also check: 'Automatically sync with Terrain'. ", MessageType.Warning, true);
						}
						GUI.enabled = true;
						
						GUILayout.Space(6);
						EditorGUILayout.LabelField("Grass and Detail Settings", myLabel);
						GUILayout.Space(2);
						if(AutoSyncToTerrain.boolValue) {
							GUI.enabled = false;
						}
							toolTip = "The distance (from camera) towards which grass will fade out (should fit your terrain’s settings).";
						EditorGUILayout.PropertyField(DetailDistanceForGrassShader, new GUIContent("Detail Distance*", toolTip));
							toolTip = "Overall color tint applied to grass objects (should fit your terrain’s settings).";
						EditorGUILayout.PropertyField(GrassWavingTint, new GUIContent("Grass Waving Tint*", toolTip));
						GUI.enabled = true;

					//	Tree and Billboard Render settings
						GUILayout.Space(6);
						EditorGUILayout.LabelField("Tree and Billboard Settings", myLabel);
						GUILayout.Space(2);
						if(AutoSyncToTerrain.boolValue) {
							GUI.enabled = false;
						}
						//
							toolTip = "The distance (from camera) at which 3D tree objects will be replaced by billboard images (should fit your terrain’s settings).";
						EditorGUILayout.PropertyField(BillboardStart, new GUIContent("Billboard Start*", toolTip));
							toolTip = "Fade length for translucency and real time shadows.";
						EditorGUILayout.PropertyField(BillboardFadeLenght, new GUIContent("Fade Length*", toolTip) );
						GUI.enabled = true;

						EditorGUILayout.BeginHorizontal();
								toolTip = "Usually tree are simply tinted with black if you set the „color variation“ > 0 while painting trees. You may replace this color by any one you like using this color field.";
							EditorGUILayout.PropertyField(TreeColor, new GUIContent("Tint Color", toolTip));
						EditorGUILayout.EndHorizontal();
						
						GUILayout.Space(2);
						EditorGUILayout.BeginHorizontal();
							EditorGUILayout.PropertyField(BillboardAdjustToCamera, GUIContent.none, GUILayout.Width(14) );
							EditorGUILayout.LabelField("Align Billboards to Camera");
						EditorGUILayout.EndHorizontal();
						if (BillboardAdjustToCamera.boolValue) {
							EditorGUI.indentLevel++;
								toolTip = "Defines the angle (when viewed from above) the billboard shader will fade to the 'classical' upright oriented billboards in order to reduce distortion artifacts. The standard value is '30'.";
							EditorGUILayout.PropertyField(BillboardAngleLimit, new GUIContent(" Angle Limit", toolTip));
							EditorGUI.indentLevel--;
						}
						GUILayout.Space(2);
							toolTip = "Instead of simply culling the billboards beyond the 'Tree distance' specified in the terrain settings you may define a length over which the billboards will smoothly fade out. Please note: This only works if you use the alpha blending Billboardshader.";
						EditorGUILayout.PropertyField(BillboardFadeOutLength, new GUIContent("Billboard Fade Length", toolTip));
						GUILayout.Space(4);

					//	General Vegetation settings
						GUILayout.Space(6);
						EditorGUILayout.LabelField("Terrain Detail Vegetation Settings", myLabel);
						
						GUILayout.Space(6);
							toolTip = "Enable legacy bending on 'detail meshes' using the built in vertexLit shader.";
						EditorGUILayout.PropertyField(TerrainLegacyBending, new GUIContent("Legacy Bending", toolTip));
						
						GUILayout.Space(6);

							toolTip = "Lets you you define a color which gets multiplied on top of the albedo and varies from instance to instance. Alpha defines the maximum strength.";
						EditorGUILayout.PropertyField(VertexLitColorVariation, new GUIContent("Color Variation", toolTip));
							toolTip = "Cutoff value for all models placed as 'detail mesh' using the built in terrain engine.";
						EditorGUILayout.PropertyField(VertexLitAlphaCutOff, new GUIContent("Alpha Cutoff", toolTip));

						EditorGUILayout.BeginHorizontal();
				        	EditorGUILayout.PrefixLabel("Combined Detail Atlas");
				        	EditorGUI.BeginChangeCheck();
				        	tempTex = (Texture2D)EditorGUILayout.ObjectField(TerrainFoliageNrmSpecMap.objectReferenceValue, typeof(Texture2D), false, GUILayout.MinHeight(64), GUILayout.MinWidth(64), GUILayout.MaxWidth(64));
				        	if (EditorGUI.EndChangeCheck()) {
				        		if (tempTex != null) {
									TerrainFoliageNrmSpecMap.objectReferenceValue = tempTex;
								}
								else {
									string[] guIDS = AssetDatabase.FindAssets ("Afs default Terrain [Normal] [Smoothness] [Trans]");
									if (guIDS.Length > 0) {
										TerrainFoliageNrmSpecMap.objectReferenceValue = (Texture2D)AssetDatabase.LoadAssetAtPath( AssetDatabase.GUIDToAssetPath(guIDS[0]), typeof(Texture2D));
									}
								}
							}
				       	EditorGUILayout.EndHorizontal();

				       	GUILayout.Space(4);

				       		toolTip = "Specular Color for all models placed as 'detail mesh' using the built in terrain engine.";
						EditorGUILayout.PropertyField(VertexLitSpecularReflectivity, new GUIContent("Specular Color", toolTip));
							toolTip = "Translucency multiplier for all models placed as 'detail mesh' using the built in terrain engine.";
						EditorGUILayout.PropertyField(VertexLitTranslucency, new GUIContent("Translucency Strength", toolTip));
							toolTip = "Lets you adjust the smoothness on backfaces. This feature only works with single sided leaf geometry.";
						EditorGUILayout.PropertyField(VertexLitBackfaceSmoothness, new GUIContent("Backface Smoothness", toolTip));
							toolTip = "Lets you suppress 'wrong' ambient specular reflections on all models placed as 'detail mesh' using the built in terrain engine.";
						EditorGUILayout.PropertyField(VertexLitHorizonFade, new GUIContent("Horizon Fade", toolTip));

						GUILayout.Space(6);

							toolTip = "Global factor for all plants using the vertex lit shader. Increasing Leaf Turbulence will make those parts of the plants which are affected by secondary bending sway faster if the wind blows stronger.\n*Do not change at run time.";
						EditorGUILayout.PropertyField(VertexLitLeafTurbulence, new GUIContent("Leaf Turbulence*", toolTip));
							toolTip = "Larger Terrains need larger values.";
						EditorGUILayout.PropertyField(VertexLitVariationMultipilier, new GUIContent("Variation", toolTip));
							
						GUILayout.Space(6);
						EditorGUILayout.LabelField("Grass Settings", myLabel);
						GUILayout.Space(6);

				        	toolTip = "Base Smoothness of Grass masked by Translucency.";
						EditorGUILayout.PropertyField(GrassMinSmoothness, new GUIContent("Min Smoothness", toolTip));
							toolTip = "Max Smoothness of wet Grass masked by Translucency.";
						EditorGUILayout.PropertyField(GrassMaxSmoothness, new GUIContent("Max Smoothness", toolTip));

						GUILayout.Space(2);

					EditorGUILayout.EndVertical();
				EditorGUILayout.EndHorizontal();
				GUILayout.Space(4);
			EditorGUILayout.EndVertical();
		}

//	///////////////////////////////////////////////////
//	Rain settings
		GUILayout.Space(4);
		GUI.backgroundColor = myBgCol;
		EditorGUILayout.BeginVertical("Box");
			// Foldout incl. Icon
			EditorGUILayout.BeginHorizontal();
				GUILayout.Space(-2);
				EditorGUI.indentLevel++;
				EditorGUILayout.BeginVertical();
					script.FoldRain  = EditorGUILayout.Foldout(script.FoldRain, "Rain Settings", myFoldoutStyle);
				EditorGUILayout.EndVertical();
				EditorGUI.indentLevel--;

				if (GUILayout.Button("Help", myMiniHelpBtn, GUILayout.Width(40))) {
					Application.OpenURL(baseURL + "h.bgp2x18s4scm");
				}

				EditorGUILayout.BeginVertical(GUILayout.Width(20) );
					// Label needs width!
					EditorGUILayout.LabelField(new GUIContent(icnRain), GUILayout.Width(20), GUILayout.Height(20));
				EditorGUILayout.EndVertical();
				GUI.backgroundColor = Color.white;
			EditorGUILayout.EndHorizontal();
			GUILayout.Space(-2);
		EditorGUILayout.EndVertical();
		// FoldoutContent
		if (script.FoldRain) {
			GUILayout.Space(-5);
			EditorGUILayout.BeginVertical("Box");
				DrawSplitter1(EditorGUILayout.GetControlRect(false, 4), SplitterCol1);
				EditorGUILayout.BeginHorizontal();
					GUILayout.Space(13);
					EditorGUILayout.PropertyField(RainAmount, new GUIContent("Rain Amount") );
				EditorGUILayout.EndHorizontal();
				GUILayout.Space(4);
			EditorGUILayout.EndVertical();
		}

//	///////////////////////////////////////////////////
//	Lighting settings
		GUILayout.Space(4);
		GUI.backgroundColor = myBgCol;
		EditorGUILayout.BeginVertical("Box");
		// Foldout incl. Icon
		EditorGUILayout.BeginHorizontal();
			GUILayout.Space(-2);
			EditorGUI.indentLevel++;
			EditorGUILayout.BeginVertical();
				script.FoldLighting = EditorGUILayout.Foldout(script.FoldLighting, "Lighting Settings", myFoldoutStyle);
			EditorGUILayout.EndVertical();
			EditorGUI.indentLevel--;

			if (GUILayout.Button("Help", myMiniHelpBtn, GUILayout.Width(40))) {
				Application.OpenURL(baseURL + "h.ak1o9whdfzet");
			}

			EditorGUILayout.BeginVertical(GUILayout.Width(20) );
				// Label needs width!
				EditorGUILayout.LabelField(new GUIContent(icnLight), GUILayout.Width(20), GUILayout.Height(20));
			EditorGUILayout.EndVertical();
			GUI.backgroundColor = Color.white;
		EditorGUILayout.EndHorizontal();
		GUILayout.Space(-2);
		EditorGUILayout.EndVertical();
		// FoldoutContent
		if (script.FoldLighting) {
			GUILayout.Space(-5);
			EditorGUILayout.BeginVertical("Box");
				DrawSplitter1(EditorGUILayout.GetControlRect(false, 4), SplitterCol1);
				EditorGUILayout.BeginHorizontal();
					GUILayout.Space(13);
					EditorGUILayout.BeginVertical();
						EditorGUILayout.LabelField("Foliage specular and translucent Lighting Settings", myLabel);
						GUILayout.Space(2);
						EditorGUI.BeginChangeCheck();
						specFade.x = EditorGUILayout.Slider("Range", AfsSpecFade.vector2Value.x, 0.0f, 100.0f);
						specFade.y = EditorGUILayout.Slider("Fade Lenght", AfsSpecFade.vector2Value.y, 0.0f, 100.0f);
						if (EditorGUI.EndChangeCheck()) {
							AfsSpecFade.vector2Value = specFade;
						}
					EditorGUILayout.EndVertical();
				EditorGUILayout.EndHorizontal();
				GUILayout.Space(4);
			EditorGUILayout.EndVertical();
		}
		
//	///////////////////////////////////////////////////
//	Layer Culling Settings
		GUILayout.Space(4);
		EditorGUILayout.BeginVertical("Box");
		// Foldout incl. Icon
		EditorGUILayout.BeginHorizontal();
			GUILayout.Space(-2);
			EditorGUI.indentLevel++;
			EditorGUILayout.BeginVertical();
				script.FoldCulling  = EditorGUILayout.Foldout(script.FoldCulling, "Layer Culling Settings", myRegularFoldoutStyle);
			EditorGUILayout.EndVertical();
			EditorGUI.indentLevel--;

			if (GUILayout.Button("Help", myMiniHelpBtn, GUILayout.Width(40))) {
				Application.OpenURL(baseURL + "h.7u07x8g4ibkg");
			}

			EditorGUILayout.BeginVertical(GUILayout.Width(20) );
				// Label needs width!
				EditorGUILayout.LabelField(new GUIContent(icnCulling), GUILayout.Width(20), GUILayout.Height(20));
			EditorGUILayout.EndVertical();
		EditorGUILayout.EndHorizontal();
		// FoldoutContent
		if (script.FoldCulling) {
			DrawSplitter(EditorGUILayout.GetControlRect(false, 4), SplitterCol);
			EditorGUILayout.BeginHorizontal();
				GUILayout.Space(13);
				EditorGUILayout.BeginVertical();
					EditorGUILayout.BeginHorizontal();
						EditorGUI.BeginChangeCheck();
							bool shallEnableCameraLayerCulling = EnableCameraLayerCulling.boolValue;
							shallEnableCameraLayerCulling = EditorGUILayout.Toggle("", shallEnableCameraLayerCulling, GUILayout.Width(14) );
							EditorGUILayout.LabelField("Enable Layer Culling");
						if (EditorGUI.EndChangeCheck()) {
							EnableCameraLayerCulling.boolValue = shallEnableCameraLayerCulling;
							if (!EnableCameraLayerCulling.boolValue) {
								script.afsResetCameraLayerCulling();
							}
						}
					EditorGUILayout.EndHorizontal();
					if (EnableCameraLayerCulling.boolValue) {
						GUILayout.Space(4);
						EditorGUI.BeginChangeCheck();
							EditorGUILayout.PropertyField(SmallDetailsDistance, new GUIContent("Small Details Distance") );
							EditorGUILayout.PropertyField(SmallDetailsLayer, new GUIContent("Small Details Layer") );
							GUILayout.Space(4);
							EditorGUILayout.PropertyField(MediumDetailsDistance, new GUIContent("Medium Detail Distance") );
							EditorGUILayout.PropertyField(MediumDetailsLayer, new GUIContent("Medium Details Layer") );
						if (EditorGUI.EndChangeCheck()) {
							script.afsSetupCameraLayerCulling();
						}

					}
					GUILayout.Space(4);
				EditorGUILayout.EndVertical();
			EditorGUILayout.EndHorizontal();
		}
		EditorGUILayout.EndVertical();

//	Special Render Settings
		GUILayout.Space(4);
		EditorGUILayout.BeginVertical("Box");
		// Foldout incl. Icon
		EditorGUILayout.BeginHorizontal();
			GUILayout.Space(-2);
			EditorGUI.indentLevel++;
			EditorGUILayout.BeginVertical();
				script.FoldRender  = EditorGUILayout.Foldout(script.FoldRender, "Special Render Settings", myRegularFoldoutStyle);
			EditorGUILayout.EndVertical();
			EditorGUI.indentLevel--;

			if (GUILayout.Button("Help", myMiniHelpBtn, GUILayout.Width(40))) {
				Application.OpenURL(baseURL + "h.sbfb1qqv5amh");
			}
			
			EditorGUILayout.BeginVertical(GUILayout.Width(20) );
				// Label needs width!
				EditorGUILayout.LabelField(new GUIContent(icnCamera), GUILayout.Width(20), GUILayout.Height(20));
			EditorGUILayout.EndVertical();
		EditorGUILayout.EndHorizontal();
		// FoldoutContent
		if (script.FoldRender) {
			DrawSplitter(EditorGUILayout.GetControlRect(false, 4), SplitterCol);
			EditorGUILayout.BeginHorizontal();
				GUILayout.Space(13);
				EditorGUILayout.BeginVertical();
					EditorGUILayout.BeginHorizontal();
						EditorGUILayout.PropertyField(AllGrassObjectsCombined, GUIContent.none, GUILayout.Width(14) );
						EditorGUILayout.LabelField("All Grass Objects Combined");
					EditorGUILayout.EndHorizontal();
					GUILayout.Space(4);
				EditorGUILayout.EndVertical();
			EditorGUILayout.EndHorizontal();
		}
		EditorGUILayout.EndVertical();
		GUILayout.Space(4);

	//	Do another check for detail texture atlas
		if (TerrainFoliageNrmSpecMap.objectReferenceValue == null) {
			string[] guIDS = AssetDatabase.FindAssets ("Afs default Terrain [Normal] [Smoothness] [Trans]");
			if (guIDS.Length > 0) {
				TerrainFoliageNrmSpecMap.objectReferenceValue = (Texture2D)AssetDatabase.LoadAssetAtPath( AssetDatabase.GUIDToAssetPath(guIDS[0]), typeof(Texture2D));
			}
		}
							
//	////////////////////////
		SetupAFS.ApplyModifiedProperties();
	}

//	End Editor

//	///////////////////////////////////////////////////
//	Helper Functions

	void ResetBillboardFadeLength () {
		allTerrains = FindObjectsOfType(typeof(Terrain)) as Terrain[];
		for (int i = 0; i < allTerrains.Length; i ++) {
			// treeCrossFadeLength must be > 0 otherwise the number of draw calls will explode at steep viewing angles
			allTerrains[i].treeCrossFadeLength = 0.0f; //0.0001f;
		}
	}
	
	void RestoreBillboardFadeLength (float resetValue) {
		allTerrains = FindObjectsOfType(typeof(Terrain)) as Terrain[];
		for (int i = 0; i < allTerrains.Length; i ++) {
			allTerrains[i].treeCrossFadeLength = resetValue;
		}
	}

/*	void FindFirstDirectionalLight () {
		DirLights = FindObjectsOfType(typeof(Light)) as Light[];
		for (int i = 0; i < DirLights.Length; i ++) {
			//allTerrains[i].treeCrossFadeLength = resetValue;
			//Debug.Log(DirLights.transform.name);
		//	Debug.Log(DirLights.Length);
		//	Debug.Log(DirLights[i]);
		//	Debug.Log(DirLights[i].GetComponent<Light>().type);
			if(DirLights[i].GetComponent<Light>().type == LightType.Directional) {
				TerrianLight0.objectReferenceValue = DirLights[i]; //.transform.parent;
				//SetupAFS.TerrianLight0 = DirLights[i];
			//	SetupAFS.FindProperty("TerrianLight0") = TerrianLight0;
				SetupAFS.Update();
				//TerrianLight0.CopyFromSerializedProperty();

// warum klappt das nicht??

				Debug.Log("assigned " + TerrianLight0);
				
				//TerrianLight0 = SetupAFS.FindProperty("TerrianLight0");
				//break;
			}
		}

	} */



//	///////////////////////////////////////////////////
//	Editor Helper Functions

	private void DrawSplitter(Rect targetPosition, Color SplitterCol) {
		GUI.color = SplitterCol;
		targetPosition.x -= 4;
		targetPosition.height = 1;
		targetPosition.width += 8;
		GUI.DrawTexture(targetPosition, EditorGUIUtility.whiteTexture);
		GUI.color = Color.white;
		GUILayout.Space(4);
	}

	private void DrawSplitter1(Rect targetPosition, Color SplitterCol) {
		GUI.color = SplitterCol;
		targetPosition.y -= 3;
		targetPosition.x -= 3;
		targetPosition.height = 1;
		targetPosition.width += 6;
		GUI.DrawTexture(targetPosition, EditorGUIUtility.whiteTexture);
		GUI.color = Color.white;
	}

	private void GetProperties() {
		// Specular Lighting
		AfsSpecFade = SetupAFS.FindProperty("AfsSpecFade");
		//
		Foliage_WindPrimaryStrength = SetupAFS.FindProperty("Foliage_WindPrimaryStrength");
		Foliage_WindSecondaryStrength = SetupAFS.FindProperty("Foliage_WindSecondaryStrength");
		Foliage_WaveSize = SetupAFS.FindProperty("Foliage_WaveSize");
		Foliage_LeafTurbulence = SetupAFS.FindProperty("Foliage_LeafTurbulence");
		Grass_WindStrength = SetupAFS.FindProperty("Grass_WindStrength");
		Grass_WaveSize = SetupAFS.FindProperty("Grass_WaveSize");
		Grass_WindJitterVariation = SetupAFS.FindProperty("Grass_WindJitterVariation");
		Grass_WindSpeed = SetupAFS.FindProperty("Grass_WindSpeed");
		Grass_WindJitterScale = SetupAFS.FindProperty("Grass_WindJitterScale");
		Trees_WindPrimaryStrength = SetupAFS.FindProperty("Trees_WindPrimaryStrength");
		Trees_WindSecondaryStrength = SetupAFS.FindProperty("Trees_WindSecondaryStrength");
		// Rain
		RainAmount = SetupAFS.FindProperty("RainAmount");
		// Terrain Detail Vegetation Settings
		TerrainLegacyBending = SetupAFS.FindProperty("TerrainLegacyBending");
		VertexLitTranslucency = SetupAFS.FindProperty("VertexLitTranslucency");
		VertexLitAlphaCutOff = SetupAFS.FindProperty("VertexLitAlphaCutOff");
		VertexLitSpecularReflectivity = SetupAFS.FindProperty("VertexLitSpecularReflectivity");
		VertexLitVariationMultipilier = SetupAFS.FindProperty("VertexLitVariationMultipilier");
		VertexLitLeafTurbulence = SetupAFS.FindProperty("VertexLitLeafTurbulence");
		VertexLitBackfaceSmoothness = SetupAFS.FindProperty("VertexLitBackfaceSmoothness");
		VertexLitColorVariation = SetupAFS.FindProperty("VertexLitColorVariation");
		VertexLitHorizonFade = SetupAFS.FindProperty("VertexLitHorizonFade");
		TerrainFoliageNrmSpecMap = SetupAFS.FindProperty("TerrainFoliageNrmSpecMap");
		GrassMinSmoothness = SetupAFS.FindProperty("GrassMinSmoothness");
		GrassMaxSmoothness = SetupAFS.FindProperty("GrassMaxSmoothness");
		// Grass, Tree and Billboard settings
		AutoSyncToTerrain = SetupAFS.FindProperty("AutoSyncToTerrain");
		SyncedTerrain = SetupAFS.FindProperty("SyncedTerrain");
		DetailDistanceForGrassShader = SetupAFS.FindProperty("DetailDistanceForGrassShader");
		BillboardStart = SetupAFS.FindProperty("BillboardStart");
		BillboardFadeLenght = SetupAFS.FindProperty("BillboardFadeLenght");
		GrassWavingTint = SetupAFS.FindProperty("GrassWavingTint");
		// Tree Render settings
		TreeColor = SetupAFS.FindProperty("AFSTreeColor");
		BillboardFadeOutLength = SetupAFS.FindProperty("BillboardFadeOutLength");
		BillboardAdjustToCamera = SetupAFS.FindProperty("BillboardAdjustToCamera");
		BillboardAngleLimit = SetupAFS.FindProperty("BillboardAngleLimit");
		// Culling
		EnableCameraLayerCulling = SetupAFS.FindProperty("EnableCameraLayerCulling");
		SmallDetailsDistance = SetupAFS.FindProperty("SmallDetailsDistance");
		SmallDetailsLayer = SetupAFS.FindProperty("SmallDetailsLayer");
		MediumDetailsDistance = SetupAFS.FindProperty("MediumDetailsDistance");
		MediumDetailsLayer = SetupAFS.FindProperty("MediumDetailsLayer");
		// Special Render Settings
		AllGrassObjectsCombined = SetupAFS.FindProperty("AllGrassObjectsCombined");
	}

}
#endif
