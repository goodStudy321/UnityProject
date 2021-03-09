#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using System.IO;

public enum TextureSplit {
	OneByOne,
	TwoByOne,
	Other
}
public enum BendingModes {
    VertexColors_Legacy = 1,
    VertexColorsAndUV4 = 2,
    VertexColors = 3
}
public enum Set1stBendingModes {
    AlongY_Axis = 1,
    RelativeToPivot = 2
}
public enum Mask2ndBendingModes {
    AlongY_Axis = 1,
    ByVertexColorBlue = 2
}
public enum AFSDebugMode {
    RGB,
    Red,
    Green,
    Blue,
    Alpha
}
[ExecuteInEditMode]
[AddComponentMenu("AFS/Mesh/AFS Foliage Tool")]
public class AfsFoliageTool : MonoBehaviour {

	public Mesh originalMesh;

	public GameObject Master;
	public bool usingMastersBounds = false;

	public bool UseDebugMaterial = false;
	public AFSDebugMode DebugMode = AFSDebugMode.RGB;

	public Color[] SnapShotColors;
	public bool SnapShotAvailable = false;

	public BendingModes BendingModeSelected = BendingModes.VertexColors;
	public float Scale = 2.0f;
	public bool hasBeenSaved = false;
	public string savePath = "";
	public string fileName = "AfsPlantMesh.asset";

	public bool hasSubmeshes = false;
	public bool mergeSubMeshes = false;
	public bool has2ndUV = false;
	public bool delete2ndUV = false;
	public bool storeUV4 = false;

	//public int toolbarSelector = 0;
	public bool convert2simpletree = false;
	public bool convert2foliage = false;

	public Texture2D sourceTex0;
	public Texture2D sourceTex1;
	public Texture2D sourceTexDiffuse;
	public bool textureSplitHalf = false;
	public bool showTextureCombine = false;
	public TextureSplit TextureSplitSelected = TextureSplit.OneByOne;

	public bool generateUV2 = false;

	public string diffuseTexPath = "";
	public string transTexPath = "";
	public string combinedTexPath = "";

	public bool simpleTreeConverted = false;
	public bool foliageTreeConverted = false;
	public bool foliageTreeUV4Converted = false;

	public Set1stBendingModes Set1stBendingSelected = Set1stBendingModes.AlongY_Axis;
	public Mask2ndBendingModes Mask2ndBendingSelected = Mask2ndBendingModes.AlongY_Axis;

	public bool adjustScale = false;
	public bool adjustVertexColors = false;
	public bool adjustBending = false;
	public bool FoldSetBending = false;
	public bool showGizmos = true;

	//public bool editVertices = false;
	[Range(0.0f, 1.0f)]
	public float maxBendingValueY = 0.1f;
	[Range(0.0f, 1.0f)]
	public float maxBendingValueX = 0.0f;
	public AnimationCurve curvY = new AnimationCurve(new Keyframe(0, 0), new Keyframe(1, 1));
	public AnimationCurve curvX = new AnimationCurve(new Keyframe(0, 0), new Keyframe(1, 1));
	public AnimationCurve curvZ = new AnimationCurve(new Keyframe(0, 0), new Keyframe(1, 1));

	private Vector3 tempPos;
	
	public AnimationCurve curvRed = AnimationCurve.Linear(0.0f,0.0f,1.0f,1.0f);
	public AnimationCurve curvGreen = AnimationCurve.Linear(0.0f,0.0f,1.0f,1.0f);
	public AnimationCurve curvBlue = AnimationCurve.Linear(0.0f,0.0f,1.0f,1.0f);
	public AnimationCurve curvAlpha = AnimationCurve.Linear(0.0f,0.0f,1.0f,1.0f);

	public bool Set1stBendingAlongY = true;
	public bool Set1stBendingRelative2Pivot = false;

	public float[] VertexBlueVals;
	public bool VertexBlueValsStored = false;
	
	static Transform currentSelection;
	static Mesh currentMesh;
	static Collider currentCollider;
	private Mesh currentColliderMesh;
	public bool hasChanged = false;
	
//	http://stackoverflow.com/questions/4811219/pack-four-bytes-in-a-float
//	http://stackoverflow.com/questions/17638800/storing-two-float-values-in-a-single-float-variable
	float Pack(Vector2 input, int precision)
	{
	    Vector2 output = input;
	    output.x = Mathf.Floor(output.x * (precision - 1));
	    output.y = Mathf.Floor(output.y * (precision - 1));
	    return (output.x * precision) + output.y;
	}

	Vector2 Unpack(float input, int precision)
	{
	    Vector2 output = Vector2.zero;
	    output.x = Mathf.Floor(input / precision);
	    output.y = input % precision;
	    return output / (precision - 1);
	}

//	//////////////////////////////////// 

	public void checkSubmeshes () {
		currentMesh = GetComponent<MeshFilter>().sharedMesh;
		if (currentMesh != null) {
			if (currentMesh.subMeshCount > 1) {
				hasSubmeshes = true;
			}
			else {
				hasSubmeshes = false;
				mergeSubMeshes = false;
			}
			if (currentMesh.uv2 != null) {
				has2ndUV = true;
			}
			else {
				delete2ndUV = false;
			}
		}
	}

//	//////////////////////////////////// 

	void OnDrawGizmosSelected()
    {
    	if(showGizmos && adjustBending && !Application.isPlaying) {

    		GUIStyle KeyFrameIndicator = new GUIStyle();
			KeyFrameIndicator.fontSize = 42;
			KeyFrameIndicator.normal.textColor = Color.white;
			KeyFrameIndicator.contentOffset = new Vector2(-12,-26);

			Bounds bounds = GetComponent<MeshFilter>().sharedMesh.bounds;
    		
    		Gizmos.matrix = transform.localToWorldMatrix;
  			Handles.matrix = transform.localToWorldMatrix;
    	
	    	// Draw Bounding Box
			Gizmos.color = Color.red;
			Gizmos.DrawWireCube(bounds.center, bounds.size);

			Vector3 offset;
	
		//	Gizmos for 1st curve: along y
	        if (curvY != null) {
	        	for (int i = 0; i < curvY.keys.Length; i ++) {

	        		offset = new Vector3(0.0f, bounds.size.y * curvY.keys[i].time, 0.0f);
					//Handles.Label(offset, "°◆◁■◉•", mylabelStyle);
					//Handles.Label(offset, "°◉•", mylabelStyle);
					KeyFrameIndicator.normal.textColor = new Color (0.0f, 1.0f, 1.0f, 0.75f);
					Handles.Label(offset, "◉", KeyFrameIndicator);
	        	}
	        }

	    //	Gizmos for 2nd curve: along xw
	        if (curvX != null) {
	        	for (int i = 0; i < curvX.keys.Length; i ++) {
	        		offset = new Vector3(0.0f, bounds.size.y * 0.5f, 0.0f);
	        		float size = (bounds.size.x + bounds.size.z) * 0.25f * Mathf.Max(0.05f, curvX.keys[i].time);
	        		Quaternion rotation = Quaternion.AngleAxis(90, Vector3.right);
					Handles.color = Color.green;
					Handles.CircleHandleCap(0, offset, rotation, size, EventType.Repaint);
	        	}
	        }

		//	Gizmos for 3rd curve: mask along y
	        if (curvZ != null && BendingModeSelected == BendingModes.VertexColorsAndUV4 && Mask2ndBendingSelected == Mask2ndBendingModes.AlongY_Axis ) {
	        	for (int i = 0; i < curvZ.keys.Length; i ++) {
	        		offset = new Vector3(0.0f, bounds.size.y * curvZ.keys[i].time, 0.0f);
	        		KeyFrameIndicator.normal.textColor = Color.red;
					Handles.Label(offset, "◆", KeyFrameIndicator);
	        	}
	        }

        // Reset matrix
            Gizmos.matrix = Matrix4x4.identity; 
            Handles.matrix = Matrix4x4.identity;
        }
    }

//	////////////////////////////////////

	public void RevertEntireMesh() {
		if(originalMesh != null) {
			currentMesh = GetComponent<MeshFilter>().sharedMesh;
			currentMesh.Clear();
			currentMesh.vertices = originalMesh.vertices;
			currentMesh.colors = originalMesh.colors;
			currentMesh.uv = originalMesh.uv;
			if(originalMesh.uv2 != null) {
				currentMesh.uv2 = originalMesh.uv2;
			}
			currentMesh.normals = originalMesh.normals;
			currentMesh.tangents = originalMesh.tangents;
			currentMesh.triangles = originalMesh.triangles;
		}
	}

	public void ResetToOriginal() {
		if(originalMesh != null) {
			currentMesh = GetComponent<MeshFilter>().sharedMesh;
			if (originalMesh.colors.Length == currentMesh.colors.Length ) {
				currentMesh.colors = originalMesh.colors;
				//// reset values
				curvRed = AnimationCurve.Linear(0.0f,0.0f,1.0f,1.0f);
				curvGreen = AnimationCurve.Linear(0.0f,0.0f,1.0f,1.0f);
				curvBlue = AnimationCurve.Linear(0.0f,0.0f,1.0f,1.0f);
				curvAlpha = AnimationCurve.Linear(0.0f,0.0f,1.0f,1.0f);
			}
			else {
				Debug.Log("Lengths of color arrays do not fit. Aborted.");
			}
		}
	}

	public void TakeSnapShot() {
		currentMesh = GetComponent<MeshFilter>().sharedMesh;
		SnapShotColors = currentMesh.colors;
		SnapShotAvailable = true;
		//// reset values
		curvRed = AnimationCurve.Linear(0.0f,0.0f,1.0f,1.0f);
		curvGreen = AnimationCurve.Linear(0.0f,0.0f,1.0f,1.0f);
		curvBlue = AnimationCurve.Linear(0.0f,0.0f,1.0f,1.0f);
		curvAlpha = AnimationCurve.Linear(0.0f,0.0f,1.0f,1.0f);
	}

	public void EnableDebugShader() {
		GetComponent<Renderer>().sharedMaterial.shader = Shader.Find("Hidden/Foliage Shader Debug");
		UseDebugMaterial = true;
	}
	public void DisableDebugShader() {
		GetComponent<Renderer>().sharedMaterial.shader = Shader.Find("AFS/Foliage Shader");
		UseDebugMaterial = false;
	}

	public void SetDebugMode(int mode) {
		GetComponent<Renderer>().sharedMaterial.SetFloat("_DebugMode", mode);
	}

	public void AdjustBending () {
		currentMesh = GetComponent<MeshFilter>().sharedMesh;
		currentSelection = GetComponent<Transform>();
		Vector3[] vertices = currentMesh.vertices;
		Color[] colors = currentMesh.colors;

		Vector2[] myUVs = new Vector2[currentMesh.vertices.Length]; // secondarybending, primarybending

		// create vertex color in case there are no
		if (colors.Length == 0) {
			colors = new Color[vertices.Length];
			for (int i = 0; i < vertices.Length; i++) {
				colors[i] = new Color(0.0f,0.0f,0.0f,1.0f);
			}
		}
		
//		// Recreate vertex color blue array if there is none
//		if (VertexBlueValsStored == false) {
//			VertexBlueVals = new float[colors.Length];
//		}
		
		for (int i = 0; i < vertices.Length; i++) {
			Bounds bounds = currentMesh.bounds;
			
		//	Legacy Bending: Primary and secondary stored in vertex color blue
			if(BendingModeSelected == BendingModes.VertexColors_Legacy) {
				GetComponent<Renderer>().sharedMaterial.SetFloat("_BendingControls", 0.0f);
				if (vertices[i].y <= 0.0f) {
					colors[i].b = 0.0f;
				}
				else {
					colors[i].b = Mathf.Lerp (0.0f, maxBendingValueY, curvY.Evaluate(vertices[i].y/bounds.size.y) ); // primary
					tempPos = new Vector3 (vertices[i].x, 0.0f, vertices[i].z);
					float Length = Vector3.Distance(tempPos, new Vector3(0.0f,0.0f,0.0f) ) / ((bounds.size.x + bounds.size.z) * 0.5f);
					Length = curvX.Evaluate(Length);
					colors[i].b += Mathf.Lerp (0.0f, maxBendingValueX, Length );
					//colors[i].b = Mathf.Lerp (0.0f, maxBendingValueX, Length ); // secondary
				}
			}

		//	New bending: Primary and secondary stored in UV4 or Veretx Colors only 
			//if(BendingModeSelected == BendingModes.VertexColorsAndUV4) {
			else {
				if(BendingModeSelected == BendingModes.VertexColorsAndUV4) {
					GetComponent<Renderer>().sharedMaterial.SetFloat("_BendingControls", 1.0f);
				}
				else {
					GetComponent<Renderer>().sharedMaterial.SetFloat("_BendingControls", 2.0f);	
				}

				// //////////////////////////////
				// Primary Bending 
				
				// Along y-axis
				if (Set1stBendingSelected == Set1stBendingModes.AlongY_Axis) {
					//	UV4
					if(BendingModeSelected == BendingModes.VertexColorsAndUV4) {
						myUVs[i].x = Mathf.Lerp (0.0f, maxBendingValueY, curvY.Evaluate(vertices[i].y/bounds.size.y) );
					}
					//	VertexColors Only
					else {
						colors[i].a = Mathf.Lerp (0.0f, maxBendingValueY, curvY.Evaluate(vertices[i].y/bounds.size.y) );
					}
				}
				// Relative to Pivot
				else {
					float Length = Vector3.Distance(vertices[i], new Vector3(0.0f,0.0f,0.0f) ) / ((bounds.size.x + bounds.size.y + bounds.size.z) * 0.333f);
					Length = curvY.Evaluate(Length);
					//	UV4
					if(BendingModeSelected == BendingModes.VertexColorsAndUV4) {
						myUVs[i].x = Mathf.Lerp (0.0f, maxBendingValueY, Length );
					}
					//	VertexColors Only
					else {
						colors[i].a = Mathf.Lerp (0.0f, maxBendingValueY, Length );
					}
				}
				
				// /////////////////////////////
				// Secondary Bending
				
				// Mask by vertex color blue
				if (Mask2ndBendingSelected == Mask2ndBendingModes.ByVertexColorBlue) {
					// Store original vertex color blue as we have to reset it!
				//	if (VertexBlueValsStored == false) {
				//		VertexBlueVals[i] = colors[i].b;
				//	}
					if(originalMesh != null) {
						Color[] originalColors = originalMesh.colors;
						if (originalColors.Length == colors.Length ) {
							tempPos = new Vector3 (vertices[i].x, 0.0f, vertices[i].z);
							float Length = Vector3.Distance(tempPos, new Vector3(0.0f,0.0f,0.0f) ) / ((bounds.size.x + bounds.size.z) * 0.5f);
							Length = curvX.Evaluate(Length);
						//	UV4
							if(BendingModeSelected == BendingModes.VertexColorsAndUV4) {
								myUVs[i].y = Mathf.Lerp (0.0f, maxBendingValueX, Length ) * originalColors[i].b; //2.0f ???????
								colors[i].b = 0.0f; 
							}
						//	VertexColors Only
							else {
								colors[i].b = Mathf.Lerp (0.0f, maxBendingValueX, Length ) * originalColors[i].b;
							}
						}
						else {
							Debug.Log("Mesh data of current working mesh does not fit to the assigned original mesh.");
						}
					}
				}
				// Mask along y-axis
				else {
					// Store original vertex color blue as we have to reset it!
				//	if (VertexBlueValsStored == false) {
				//		VertexBlueVals[i] = colors[i].b; 
				//	}
					tempPos = new Vector3 (vertices[i].x, 0.0f, vertices[i].z);
					float Length = Vector3.Distance(tempPos, new Vector3(0.0f,0.0f,0.0f) ) / ((bounds.size.x + bounds.size.z) * 0.5f);
					Length = curvX.Evaluate(Length);
				//	UV4
					if(BendingModeSelected == BendingModes.VertexColorsAndUV4) {
						myUVs[i].y = Mathf.Lerp (0.0f, maxBendingValueX, Length ) * curvZ.Evaluate(vertices[i].y/bounds.size.y); // * 2.0f;
						colors[i].b = 0.0f;
					}
				//	VertexColors Only
					else {
						colors[i].b = Mathf.Lerp (0.0f, maxBendingValueX, Length ) * curvZ.Evaluate(vertices[i].y/bounds.size.y);
					}
				}
			}
		}
		//
		VertexBlueValsStored = true;
		//// Update mesh
		currentMesh.colors = colors;
		if(BendingModeSelected == BendingModes.VertexColorsAndUV4) {
			currentMesh.uv4 = myUVs;
		}
	}

//	//////////////////////////////////// 
	
	public void AdjustVertexColors () {
		currentMesh = GetComponent<MeshFilter>().sharedMesh;
		currentSelection = GetComponent<Transform>();
		Vector3[] vertices = currentMesh.vertices;
		Color[] colors = currentMesh.colors; //originalColors; 
		
		// create vertex color in case there are no
		if (colors.Length == 0) {
			colors = new Color[vertices.Length];
			for (int i = 0; i < vertices.Length; i++) {
				colors[i] = new Color(0.0f,0.0f,0.0f,1.0f);
			}
		}
		
		for (int i = 0; i < vertices.Length; i++) {
			if (adjustVertexColors) {
// TODO: CHECK this
				//if(BendingModeSelected != BendingModes.VertexColorsAndUV4) {
					colors[i].b = Mathf.Clamp(curvBlue.Evaluate(SnapShotColors[i].b), 0.0f, 1.0f);
				//}
				colors[i].r = Mathf.Clamp(curvRed.Evaluate(SnapShotColors[i].r), 0.0f, 1.0f);
				colors[i].g = Mathf.Clamp(curvGreen.Evaluate(SnapShotColors[i].g), 0.0f, 1.0f);
				colors[i].a = Mathf.Clamp(curvAlpha.Evaluate(SnapShotColors[i].a), 0.0f, 1.0f);
			}
		}
		//// update mesh
		currentMesh.colors = colors;
	}

//	//////////////////////////////////// 

	public void SetVertexColorsGrass () {
		currentMesh = GetComponent<MeshFilter>().sharedMesh;
		currentSelection = GetComponent<Transform>();
		Vector3[] vertices = currentMesh.vertices;
		Color[] colors = currentMesh.colors; //originalColors; 
		
		// create vertex color in case there are no
		if (colors.Length == 0) {
			colors = new Color[vertices.Length];
			for (int i = 0; i < vertices.Length; i++) {
				colors[i] = new Color(0.0f,0.0f,0.0f,1.0f);
			}
		}
		for (int i = 0; i < vertices.Length; i++) {
			colors[i].r = 1.0f;
			colors[i].g = 1.0f;
			colors[i].b = 1.0f;
		}
		//// update mesh
		currentMesh.colors = colors;
	}

//	////////////////////////////////////
	public void CopytoUV2toUV4 () {
		currentMesh = GetComponent<MeshFilter>().sharedMesh;
		currentSelection = GetComponent<Transform>();
		//Vector3[] vertices = currentMesh.vertices;
		currentMesh.uv4 = currentMesh.uv2;
	}

//	//////////////////////////////////// 
	
	public void grabDiffuse() {
		Renderer currentRenderer = GetComponent<Renderer>();
		Material currentMaterial = currentRenderer.sharedMaterials[1];
		sourceTexDiffuse = currentMaterial.GetTexture("_MainTex") as Texture2D;
	}

//	//////////////////////////////////// 
	
	public void grabNormalSpecular() {
		Renderer currentRenderer = GetComponent<Renderer>();
		Material currentMaterial = currentRenderer.sharedMaterials[1];
		sourceTex0 = currentMaterial.GetTexture("_BumpSpecMap") as Texture2D;
	}

//	//////////////////////////////////// 
	
	public void grabTranslucencyGloss() {
		Renderer currentRenderer = GetComponent<Renderer>();
		Material currentMaterial = currentRenderer.sharedMaterials[1];
		sourceTex1 = currentMaterial.GetTexture("_TranslucencyMap") as Texture2D;
	}

//	////////////////////////////////////
	
	public void updateSimpleTree () {
		currentSelection = GetComponent<Transform>();
		Renderer currentRenderer = GetComponent<Renderer>();
		// We have to pick the values from the leaf material
		Material currentMaterial = currentRenderer.sharedMaterials[1];
		// Create new Material
		Material newMat = new Material(Shader.Find("Nature/Afs Tree Creator Leaves Optimized"));
		//newMat.SetTexture("_MainTex", currentMaterial.GetTexture("_MainTex"));
		newMat.SetTexture("_MainTex", (Texture2D)AssetDatabase.LoadAssetAtPath(diffuseTexPath, typeof(Texture2D) ) );
		newMat.SetTexture("_BumpSpecMap", currentMaterial.GetTexture("_BumpSpecMap"));
		newMat.SetTexture("_TranslucencyMap", (Texture2D)AssetDatabase.LoadAssetAtPath(transTexPath, typeof(Texture2D) ) );
		newMat.SetFloat("_Cutoff", currentMaterial.GetFloat("_Cutoff"));
		// Save new Material
		string directory;
		if (savePath == "") {
			directory = Application.dataPath;
		}
		else {
			//directory = Path.GetDirectoryName(script.savePath);
			directory = FileUtil.GetProjectRelativePath(savePath);
			directory = Path.GetDirectoryName(directory);		
		}

		AssetDatabase.CreateAsset(newMat, directory + "/" + Path.GetFileNameWithoutExtension(savePath) + "_material.mat");
		AssetDatabase.ImportAsset(AssetDatabase.GetAssetPath(newMat));
		// Remove old leaf Material – brute force...
		UnityEngine.Object.DestroyImmediate(currentRenderer, true);
		gameObject.AddComponent<MeshRenderer>();
		currentRenderer = GetComponent<Renderer>();
		currentRenderer.sharedMaterial = newMat;
	}

//	////////////////////////////////////
	
	public void updateFoliageTree () {
		currentSelection = GetComponent<Transform>();
		Renderer currentRenderer = GetComponent<Renderer>();
		// We have to pick the values from the leaf material
		Material currentMaterial = currentRenderer.sharedMaterials[1];
		// Create new Material
		Material newMat = new Material(Shader.Find("AFS/Foliage Shader"));
		newMat.SetTexture("_MainTex", currentMaterial.GetTexture("_MainTex"));
		newMat.SetTexture("_BumpTransSpecMap", (Texture2D)AssetDatabase.LoadAssetAtPath(combinedTexPath, typeof(Texture2D) ) );
		newMat.SetFloat("_Cutoff", currentMaterial.GetFloat("_Cutoff"));
		
		if(BendingModeSelected == BendingModes.VertexColors) {
			newMat.SetFloat("_BendingControls", 2.0f);	
		}
		else if(BendingModeSelected == BendingModes.VertexColorsAndUV4) {
			newMat.SetFloat("_BendingControls", 1.0f);
		}
		else {
			newMat.SetFloat("_BendingControls", 0.0f);	
		}
		// Save new Material
		string directory;
		if (savePath == "") {
			directory = Application.dataPath;
		}
		else {
			directory = FileUtil.GetProjectRelativePath(savePath);
			directory = Path.GetDirectoryName(directory);	
		}

		//Debug.Log(directory);
		//Debug.Log(directory + "/" + Path.GetFileNameWithoutExtension(savePath) + "_material.mat");

		//string directory_01 = FileUtil.GetProjectRelativePath(savePath);
		//directory_01 = Path.GetDirectoryName(directory_01);
		//Debug.Log(directory_01);

		AssetDatabase.CreateAsset(newMat, directory + "/" + Path.GetFileNameWithoutExtension(savePath) + "_material.mat");
		AssetDatabase.ImportAsset(AssetDatabase.GetAssetPath(newMat));
		// Remove old leaf Material - brute force...
		UnityEngine.Object.DestroyImmediate(currentRenderer, true);
		gameObject.AddComponent<MeshRenderer>();
		currentRenderer = GetComponent<Renderer>();
		currentRenderer.sharedMaterial = newMat;
		// Remove Tree component
		Tree treecomponent = GetComponent<Tree>();
		if (treecomponent !=null) {
			UnityEngine.Object.DestroyImmediate(treecomponent, true);
		}
	}
	
//	//////////////////////////////////// 
	
	public void SaveNewPlantMesh () {
		currentMesh = GetComponent<MeshFilter>().sharedMesh;
		currentSelection = GetComponent<Transform>();
		Vector3[] vertices = currentMesh.vertices;
		Color[] colors = currentMesh.colors;

		if (originalMesh == null) {
			originalMesh = currentMesh;
		}

		/// create vertex color in case there are no
		if (colors.Length == 0) {
			colors = new Color[vertices.Length];
			for (int i = 0; i < vertices.Length; i++) {
				colors[i] = new Color(0.0f,0.0f,0.0f,1.0f);
			}
			//// update mesh
			currentMesh.colors = colors;
		}
		///// create a new mesh    
		Mesh newMesh = new Mesh();
		newMesh.vertices = currentMesh.vertices;
		newMesh.colors = currentMesh.colors;
		newMesh.uv = currentMesh.uv;
		
		if (!delete2ndUV && currentMesh.uv2 != null) {
			newMesh.uv2 = currentMesh.uv2;
		}

		if(BendingModeSelected == BendingModes.VertexColorsAndUV4 || currentMesh.uv4 != null ) {
			if(currentMesh.uv4 != null){
				newMesh.uv4 = currentMesh.uv4;	
			}
			// does not get here????
			//else if (currentMesh.uv2 != null){
			//	Debug.Log("uv4 from uv2");
			//	newMesh.uv4 = currentMesh.uv2;
			//}
		}
		// so we need this
		if(storeUV4 == true) {
			newMesh.uv4 = currentMesh.uv2;
		}

		// vertex color bending
/*		if(BendingModeSelected == BendingModes.VertexColors) {
Debug.Log("copy uvs to vertexcolors");
Debug.Log(newMesh.colors.Length);
			for (int i = 0; i < newMesh.colors.Length; i++) {
				newMesh.colors[i].a = currentMesh.uv2[i].x; //primary bending
				newMesh.colors[i].b = currentMesh.uv2[i].y; //secondary bending
			}
		} */

		newMesh.normals = currentMesh.normals;
		newMesh.tangents = currentMesh.tangents;

		if (currentMesh.subMeshCount == 1) {
			newMesh.triangles = currentMesh.triangles;	
		}
		else if (currentMesh.subMeshCount == 2 && mergeSubMeshes == false) {
			newMesh.subMeshCount = 2;
			int[] tri1 = currentMesh.GetTriangles(0);
			int[] tri2 = currentMesh.GetTriangles(1);
			newMesh.SetTriangles(tri1,0);
			newMesh.SetTriangles(tri2,1);
		}
		// Convert tree creator tree
		else if (currentMesh.subMeshCount == 2 && mergeSubMeshes == true) {
			newMesh.subMeshCount = 1;
			int[] tri1 = currentMesh.GetTriangles(0);
			int[] tri2 = currentMesh.GetTriangles(1);
			int[] triCombined = new int[tri1.Length + tri2.Length];
			int counter = 0;

			// We would have to go the long way...
			Color[] TempColors = newMesh.colors;

			for (int i = 0; i < tri1.Length; i++) {
				triCombined[i] = tri1[i];
				counter = i;
				// mask bark by adding vertex colors
				// newMesh.colors[tri1[i]].b = 1.0f;
				// GetTriangles returns a, int[] composed of indexes of vertices from the .vertices array, 3 indexes per triangle.
	//			TempColors[tri1[i]].b = 0.0f;
			}
			counter += 1;
			for (int j = 0; j < tri2.Length; j++) {
				triCombined[counter + j] = tri2[j];
				// mask bark by adding vertex colors
				// newMesh.colors[tri2[j]].b = 0.0f;
	//			TempColors[tri1[j]].b = 1.0f;
			}
			newMesh.SetTriangles(triCombined,0);
			
			// Does not work correctly?
			// newMesh.colors = TempColors;

			// We might have to reset vertex color blue
			if(BendingModeSelected != BendingModes.VertexColors) {
				for (int i = 0; i < TempColors.Length; i++) {
					TempColors[i].b = 0.0f;
				}
			}

			else {
				for (int i = 0; i < TempColors.Length; i++) {
					TempColors[i].a = currentMesh.uv2[i].x; //primary bending
					TempColors[i].b = currentMesh.uv2[i].y; //secondary bending
				}
			}

			newMesh.colors = TempColors;
		}

		// Generate UV2 
		if (generateUV2) {
			Unwrapping.GenerateSecondaryUVSet(newMesh);
			generateUV2 = false;
		}

		// Save and update FinalMesh
		
		string filePath;
		string directory;

		// New mesh
		if (savePath == "") {
			directory = Application.dataPath;
		}
		else {
			directory = Path.GetDirectoryName(savePath);
		}

		//Debug.Log("SavePath " + savePath);
		filePath = EditorUtility.SaveFilePanel("Save new Mesh", directory, fileName, "asset");
		//Debug.Log("filepath " + filePath);

		// Update existing mesh asset
		if (filePath!="" && ( filePath.Substring(Application.dataPath.Length-6) == savePath || filePath == savePath) ) {
			string currentPath = AssetDatabase.GetAssetPath(currentMesh);
			//Debug.Log("Update");
			Mesh updatedMesh = (Mesh)AssetDatabase.LoadAssetAtPath(currentPath, typeof(Mesh));
			updatedMesh.Clear();
            updatedMesh.vertices = newMesh.vertices;
            updatedMesh.triangles = newMesh.triangles;
            updatedMesh.tangents = newMesh.tangents;
            updatedMesh.normals = newMesh.normals;
            updatedMesh.colors = newMesh.colors;
            updatedMesh.uv = newMesh.uv;
            updatedMesh.uv2 = newMesh.uv2;
            if (newMesh.uv4 != null) {
            	updatedMesh.uv4 = newMesh.uv4;	
            }
            AssetDatabase.SaveAssets();
            AssetDatabase.ImportAsset(AssetDatabase.GetAssetPath(updatedMesh));
            // Reassign the mesh to the MeshFilter
            currentSelection.GetComponent<MeshFilter>().sharedMesh = updatedMesh;
            if (currentSelection.GetComponent<MeshCollider>()) {
				currentSelection.GetComponent<MeshCollider>().sharedMesh = updatedMesh;
			}
			//// store filePath
			savePath = filePath;
		}
		// Save new mesh
		else if (filePath!="") {
			filePath = filePath.Substring(Application.dataPath.Length-6);
			UnityEditor.AssetDatabase.DeleteAsset(filePath);
			UnityEditor.AssetDatabase.CreateAsset(newMesh,filePath);
			UnityEditor.AssetDatabase.SaveAssets();
			UnityEditor.AssetDatabase.Refresh();
			fileName = Path.GetFileName(filePath);
			///// assign newMesh
			currentSelection.GetComponent<MeshFilter>().sharedMesh = newMesh;
			if (currentSelection.GetComponent<MeshCollider>()) {
				currentSelection.GetComponent<MeshCollider>().sharedMesh = newMesh;
			}
			//// store filePath
			savePath = filePath;
		}

		//// reset values
		curvRed = AnimationCurve.Linear(0.0f,0.0f,1.0f,1.0f);
		curvGreen = AnimationCurve.Linear(0.0f,0.0f,1.0f,1.0f);
		curvBlue = AnimationCurve.Linear(0.0f,0.0f,1.0f,1.0f);
		curvAlpha = AnimationCurve.Linear(0.0f,0.0f,1.0f,1.0f);
		// take a new snapshot
		TakeSnapShot();
		hasBeenSaved = true;
		hasChanged = false;
		delete2ndUV = false;
	}
}
#endif
