// optimized version of the original "combine children" script which lets you destroy all child objects
// after combining as we ussually do not need them (in case they do not have any colliders attached)
// in case you have added any collider attached to your prefabs simply uncheck "destroyChildObjectsInPlaymode"

using UnityEngine;
using System.Collections;

#if UNITY_EDITOR
using UnityEditor;
using System.Collections.Generic;
using System.IO;
#endif


[AddComponentMenu("AFS/Mesh/AFS Combine Children")]
public class CombineChildrenAFS : MonoBehaviour {

	public bool hideChildren = false;
	
	public Terrain UnderlayingTerrain;
	[Range(0.0f, 4.0f)]
	public float GroundMaxDistance = 0.25f;
	
	public bool bakeGroundLightingGrass = false;
	public Color HealthyColor = new Color(1,1,1,1);
	public Color DryColor = new Color(1,1,1,1);
	[Range(0.0f, 1.0f)]
	public float NoiseSpread = 0.1f;
	
	public bool bakeGroundLightingFoliage = false;
	[Range(0.0f, 1.0f)]
	public float randomBrightness = 0.25f;
	[Range(0.0f, 1.0f)]
	public float randomPulse = 0.3f;
	[Range(0.0f, 1.0f)]
	public float randomBending = 0.3f;
	[Range(0.0f, 1.0f)]
	public float randomFluttering = 0.3f;
	[Range(0.0f, 1.0f)]
	public float NoiseSpreadFoliage = 0.1f;
	public bool bakeScale = true;

	public bool bakePivots = true;
	
	public bool debugNormals = false;
	
	public bool destroyChildObjectsInPlaymode = true;
	public bool CastShadows = true;
	public bool UseLightprobes = false;
	
	public float RealignGroundMaxDistance = 4.0f;
	public bool ForceRealignment = false;
	

	public bool createUniqueUV2 = false;
	private bool createUniqueUV2playmode = false;

	public bool isStaticallyCombined = false;
	
	public bool simplyCombine = false;
	public bool useUV4 = false;


	void Start()
	{
		Combine();
	}


	[ContextMenu ("Realign Objects")]
	
	public void Realign () {
		Component[] filters = GetComponentsInChildren(typeof(MeshFilter));
		for (int i=0;i<filters.Length;i++) {
			Renderer curRenderer  = filters[i].GetComponent<Renderer>();
			
			// Sample ground normal
			Vector3 objectPos = curRenderer.transform.position;
			RaycastHit hit;

			bool hadCollider = false;
			if (filters[i].GetComponent<Collider>() ) {
				hadCollider = true;
				filters[i].GetComponent<Collider>().enabled = false;
			}

			if (!Physics.Raycast(objectPos + (Vector3.up * GroundMaxDistance * 0.5f), Vector3.down, out hit, GroundMaxDistance ) || ForceRealignment ) {
				
				// If ground is too far away...
				if (Physics.Raycast(objectPos + (Vector3.up * RealignGroundMaxDistance * 0.5f), Vector3.down, out hit, RealignGroundMaxDistance)) {
					curRenderer.transform.position = hit.point;
					Quaternion originalRotation = curRenderer.transform.rotation;
					curRenderer.transform.rotation = Quaternion.FromToRotation(Vector3.up, hit.normal);
					originalRotation = new Quaternion(curRenderer.transform.rotation.x, originalRotation.y, curRenderer.transform.rotation.z, curRenderer.transform.rotation.w);
					curRenderer.transform.rotation = originalRotation; 
				}
			}

			if (hadCollider ) {
				filters[i].GetComponent<Collider>().enabled = true;
			}
		}
	}
	
	public bool GetDebugNormalsScript () {
		GameObject CombineObj = gameObject;
		Component DebugNormalsScript = CombineObj.GetComponent<DebugNormalsInEditmode>();
		if ( DebugNormalsScript == null ){
			return false;
		}
		return true;
	}
	
	public void EnableDebugging() {
		GameObject CombineObj = gameObject;
		if (GetDebugNormalsScript() == false) {
			CombineObj.AddComponent<DebugNormalsInEditmode>();
		}
		CombineObj.GetComponent<DebugNormalsInEditmode>().enabled = true;
	}
	
	public void DisableDebugging() {
		GameObject CombineObj = gameObject;
		if (GetDebugNormalsScript() == true) {
			CombineObj.GetComponent<DebugNormalsInEditmode>().enabled = false;
		}
	}

	#if UNITY_EDITOR
	public void ShowHideChildren () {
		for(int i=0; i < transform.childCount; i++) {
			if(hideChildren == false) {
				transform.GetChild(i).hideFlags = HideFlags.None;
			}
			else {
				transform.GetChild(i).hideFlags = HideFlags.HideInHierarchy;
			}
		}
		// Does not work!?
		// EditorApplication.RepaintHierarchyWindow();
		// But this works
		EditorApplication.DirtyHierarchyWindowSorting();
	}
	#endif

	#if UNITY_EDITOR
	void OnDrawGizmosSelected()
    {
		if (GetComponent<MeshFilter>() != null) {
			Bounds bounds = GetComponent<MeshFilter>().sharedMesh.bounds;
    		
    		Gizmos.matrix = transform.localToWorldMatrix;
  			Handles.matrix = transform.localToWorldMatrix;
    	
	    	// Draw Bounding Box
			Gizmos.color = Color.red;
			Gizmos.DrawWireCube(bounds.center, bounds.size);

			// Reset matrix
            Gizmos.matrix = Matrix4x4.identity; 
            Handles.matrix = Matrix4x4.identity;
        }
     }
     #endif


	[ContextMenu ("Combine Now")]
	public void Combine () {
		if (isStaticallyCombined) {
			return;	
		}
		Component[] filters = GetComponentsInChildren(typeof(MeshFilter));
		Matrix4x4 myTransform = transform.worldToLocalMatrix;
		Hashtable materialToMesh = new Hashtable();
		
		for (int i=0;i<filters.Length;i++) {
			MeshFilter filter = (MeshFilter)filters[i];
			Renderer curRenderer = filters[i].GetComponent<Renderer>();
			
			// Sample ground normal
			Vector3 objectPos = curRenderer.transform.position;
			RaycastHit hit1;
			if (Physics.Raycast(objectPos + (Vector3.up * GroundMaxDistance * 0.5f), Vector3.down, out hit1, GroundMaxDistance)) {
				if(debugNormals) {
					Debug.DrawLine(objectPos + (Vector3.up * GroundMaxDistance * 0.5f), objectPos - (GroundMaxDistance * Vector3.up * 0.5f), Color.green, 5.0f, false);
					if(debugNormals) {
						Debug.DrawLine(objectPos, objectPos + (hit1.normal), Color.red, 5.0f, false);
					}
					// Is it terrain? That makes a big difference!
					if (UnderlayingTerrain) {
						Vector3 terrainPos = (hit1.point - UnderlayingTerrain.transform.position) / UnderlayingTerrain.terrainData.size.x;
						if (hit1.transform.gameObject.name == UnderlayingTerrain.name ){
							if(debugNormals) {
								Debug.DrawLine(objectPos, objectPos + (UnderlayingTerrain.terrainData.GetInterpolatedNormal(terrainPos.x, terrainPos.z)), Color.blue, 5.0f, false);
							}
							hit1.normal = UnderlayingTerrain.terrainData.GetInterpolatedNormal(terrainPos.x, terrainPos.z);
						}
					}
				}
			}
			else {
				hit1.normal = new Vector3 (0,1,0);
				if(debugNormals) {
					Debug.DrawLine(objectPos, objectPos + (1.0f * hit1.normal), Color.yellow, 5.0f, false);
				}
			}
			MeshCombineUtilityAFS.MeshInstance instance = new MeshCombineUtilityAFS.MeshInstance ();
			instance.mesh = filter.sharedMesh;
			instance.groundNormal = hit1.normal;
			instance.scale = filter.transform.localScale.x;
			instance.pivot = filter.transform.position;
			
			// Store max height in worldspace
			// Bounds bounds = curRenderer.bounds;
			// store max height in local space
			// Bounds bounds = filter.sharedMesh.bounds;
			// instance.maxHeight = bounds.size.y;
			
			if (curRenderer != null && curRenderer.enabled && instance.mesh != null) {
				instance.transform = myTransform * filter.transform.localToWorldMatrix;
				Material[] materials = curRenderer.sharedMaterials;
				for (int m=0;m<materials.Length;m++) {
					instance.subMeshIndex = System.Math.Min(m, instance.mesh.subMeshCount - 1);
					ArrayList objects = (ArrayList)materialToMesh[materials[m]];
					if (objects != null) {
						objects.Add(instance);
					}
					else
					{
						objects = new ArrayList();
						objects.Add(instance);
						materialToMesh.Add(materials[m], objects);
					}
				}
				// Handle dynamic combine
				if (Application.isPlaying) {
					if (destroyChildObjectsInPlaymode) {
						Destroy(curRenderer.gameObject);
					}
				}
				else {
					if (destroyChildObjectsInPlaymode) {
						DestroyImmediate(curRenderer.gameObject);
						isStaticallyCombined = true;
					}
					else {
						#if UNITY_3_5
						curRenderer.gameObject.active = false;
						#else
						curRenderer.gameObject.SetActive(false);
						#endif
						isStaticallyCombined = true;
					}
				}
			}
		}
	
		foreach (DictionaryEntry de in materialToMesh) {
			ArrayList elements = (ArrayList)de.Value;
			MeshCombineUtilityAFS.MeshInstance[] instances = (MeshCombineUtilityAFS.MeshInstance[])elements.ToArray(typeof(MeshCombineUtilityAFS.MeshInstance));
			
			bool isFoliage = false;

			// We have a maximum of one material, so just attach the mesh to our own game object
			if (materialToMesh.Count == 1)
			{
				// Make sure we have a mesh filter & renderer
				if (GetComponent(typeof(MeshFilter)) == null)
					gameObject.AddComponent(typeof(MeshFilter));
				if (!GetComponent("MeshRenderer"))
					gameObject.AddComponent<MeshRenderer>();
				MeshFilter filter = (MeshFilter)GetComponent(typeof(MeshFilter));
				GetComponent<Renderer>().material = (Material)de.Key;
				// Check material and set up the combine script automatically
				bakeGroundLightingGrass = false;
				bakeGroundLightingFoliage = false;
				simplyCombine = false;
				string result;
				if (Application.isPlaying) {
					result = GetComponent<Renderer>().material.GetTag("AfsMode", true, "");
					// RenderTags are: AfsGrassModelSingleSided / AfsGrassModel / AtsFoliage
					if (result == "Grass" || result == "AfsGrassModelSingleSided" ) {
						bakeGroundLightingGrass = true;
					}
					else if (result == "Foliage") {
						isFoliage = true;
						// Just foliage or groundlighting?
						//if (GetComponent<Renderer>().material.HasProperty("_GroundLightingAttunation")) {
						//	bakeGroundLightingFoliage = true;
						//}
						//else {
							simplyCombine = true;
						//}
						if (GetComponent<Renderer>().material.GetFloat("_BendingControls") == 1.0f) {
							useUV4 = true;
						}
						else {
							useUV4 = false;
						}
					}
					filter.mesh = MeshCombineUtilityAFS.Combine(instances, bakeGroundLightingGrass, bakeGroundLightingFoliage, randomBrightness, randomPulse, randomBending, randomFluttering, HealthyColor, DryColor, NoiseSpread, bakeScale, simplyCombine, NoiseSpreadFoliage, createUniqueUV2playmode, useUV4, bakePivots);
					if(isFoliage && bakePivots) {
						GetComponent<Renderer>().material.EnableKeyword("GEOM_TYPE_BRANCH");
					}
				}
				else {
					result = GetComponent<Renderer>().sharedMaterial.GetTag("AfsMode", true, "");
					// RenderTags are: AfsGrassModelSingleSided / AfsGrassModel / AtsFoliage
					if (result == "Grass" || result == "AfsGrassModelSingleSided" ) {
						bakeGroundLightingGrass = true;
					}
					else if (result == "Foliage") {
						isFoliage = true;
						// just foliage of groundlighting?
						//if (GetComponent<Renderer>().sharedMaterial.HasProperty("_GroundLightingAttunation")) {
						//	bakeGroundLightingFoliage = true;
						//}
						//else {
							simplyCombine = true;
						//}
						if (GetComponent<Renderer>().sharedMaterial.GetFloat("_BendingControls") == 1.0f) {
							useUV4 = true;
						}
						else {
							useUV4 = false;
						}
					}
					filter.sharedMesh = MeshCombineUtilityAFS.Combine(instances, bakeGroundLightingGrass, bakeGroundLightingFoliage, randomBrightness, randomPulse, randomBending, randomFluttering, HealthyColor, DryColor, NoiseSpread, bakeScale, simplyCombine, NoiseSpreadFoliage, createUniqueUV2, useUV4, bakePivots);	
				}
				GetComponent<Renderer>().enabled = true;
				if (CastShadows) {
					GetComponent<Renderer>().shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On;
				}
				else {
					GetComponent<Renderer>().shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;	
				}
				if(UseLightprobes) {
					GetComponent<Renderer>().lightProbeUsage = UnityEngine.Rendering.LightProbeUsage.BlendProbes;
				}
				else {
					GetComponent<Renderer>().lightProbeUsage = UnityEngine.Rendering.LightProbeUsage.Off;
				}
			}
			
			// We have multiple materials to take care of, build one mesh / gameobject for each material
			// and parent it to this object
			else
			{
				GameObject go = new GameObject("Combined mesh");
				go.transform.parent = transform;
				go.transform.localScale = Vector3.one;
				go.transform.localRotation = Quaternion.identity;
				go.transform.localPosition = Vector3.zero;
				go.AddComponent(typeof(MeshFilter));
				go.AddComponent<MeshRenderer>();
				go.GetComponent<Renderer>().material = (Material)de.Key;
				go.layer = go.transform.parent.gameObject.layer;
				// Check material and set up the combine script automatically
				bakeGroundLightingGrass = false;
				bakeGroundLightingFoliage = false;
				simplyCombine = false;

				string result;
				if (Application.isPlaying) {
					result = go.GetComponent<Renderer>().material.GetTag("AfsMode", true, "");
				}
				else {
					result = go.GetComponent<Renderer>().sharedMaterial.GetTag("AfsMode", true, "");	
				}
				// RenderTags are: AfsGrassModelSingleSided / AfsGrassModel / AtsFoliage
				if (result == "Grass" || result == "AfsGrassModelSingleSided" ) {
					bakeGroundLightingGrass = true;
				}
				else if (result == "Foliage") {
					isFoliage = true;
					// Just foliage of groundlighting?
					if (Application.isPlaying) {
						//if (go.GetComponent<Renderer>().material.HasProperty("_GroundLightingAttunation")) {
						//	bakeGroundLightingFoliage = true;
						//}
						//else {
							simplyCombine = true;
						//}
						if (go.GetComponent<Renderer>().material.GetFloat("_BendingControls") == 1.0f) {
							useUV4 = true;
						}
						else {
							useUV4 = false;
						}
					}
					else {
						//if (go.GetComponent<Renderer>().sharedMaterial.HasProperty("_GroundLightingAttunation")) {
						//	bakeGroundLightingFoliage = true;
						//}
						//else {
							simplyCombine = true;
						//}
						if (go.GetComponent<Renderer>().sharedMaterial.GetFloat("_BendingControls") == 1.0f) {
							useUV4 = true;
						}
						else {
							useUV4 = false;
						}
					}
				}

				MeshFilter filter = (MeshFilter)go.GetComponent(typeof(MeshFilter));
		
		//	An instanced material will be applied
				if (Application.isPlaying) {
					filter.mesh = MeshCombineUtilityAFS.Combine(instances, bakeGroundLightingGrass, bakeGroundLightingFoliage, randomBrightness, randomPulse, randomBending, randomFluttering, HealthyColor, DryColor, NoiseSpread, bakeScale, simplyCombine, NoiseSpreadFoliage, createUniqueUV2playmode, useUV4, bakePivots);
		//	filter.mesh.RecalculateBounds();
					if(isFoliage && bakePivots) {
						go.GetComponent<Renderer>().material.EnableKeyword("GEOM_TYPE_BRANCH");
					}
				}
				else {
					filter.sharedMesh = MeshCombineUtilityAFS.Combine(instances, bakeGroundLightingGrass, bakeGroundLightingFoliage, randomBrightness, randomPulse, randomBending, randomFluttering, HealthyColor, DryColor, NoiseSpread, bakeScale, simplyCombine, NoiseSpreadFoliage, createUniqueUV2, useUV4, bakePivots);
		//	filter.sharedMesh.RecalculateBounds();
					// go.GetComponent<Renderer>().sharedMaterial.SetFloat("_IsCombined", 1.0f);
				}
				// Copy settings
				if (CastShadows) {
					go.GetComponent<Renderer>().shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On;
				}
				else {
					go.GetComponent<Renderer>().shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
				}
				if(UseLightprobes) {
					go.GetComponent<Renderer>().lightProbeUsage = UnityEngine.Rendering.LightProbeUsage.BlendProbes;
				}
				else {
					go.GetComponent<Renderer>().lightProbeUsage = UnityEngine.Rendering.LightProbeUsage.Off;
				}
			}
		}
	}	
}