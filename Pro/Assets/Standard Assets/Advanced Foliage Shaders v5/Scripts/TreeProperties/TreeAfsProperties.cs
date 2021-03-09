using UnityEngine;
using System.Collections;

[AddComponentMenu("AFS/Trees/Afs Properties")]
public class TreeAfsProperties : MonoBehaviour {

	[AfsHeader("Bending")]
	[Range(0.0f, 10.0f)]
	public float ExtraLeafBending = 0.0f;

	[AfsHeader("Dynamic Wetness")]
	public bool EnableDynamicWetness = false;
	[Space(4)]
	[Range(0.0f, 1.0f)]
	public float MaxWetness = 1.0f;
	[Range(0.0f, 0.9f)]
	public float MaxSmoothness = 0.9f;
	[Range(0.0f, 40.0f)]
	public float WetnessOnBarkAlongY = 20.0f;
	[Range(0.0f, 10.0f)]
	public float WetnessOnBarkAtRoots = 1.0f;
	
	void OnValidate () {
		Material [] SharedMats = GetComponent<Renderer>().sharedMaterials;
		for (int i = 0; i < SharedMats.Length; i++) {
			if (SharedMats[i].HasProperty("_AfsXtraBending")) {
				SharedMats[i].SetFloat("_AfsXtraBending", ExtraLeafBending);
			}
			if(EnableDynamicWetness) {
				SharedMats[i].EnableKeyword("EFFECT_BUMP");	
			}
			else {
				SharedMats[i].DisableKeyword("EFFECT_BUMP");
			}
			if (SharedMats[i].HasProperty("_AfsWetnessTree")) {
				SharedMats[i].SetVector("_AfsWetnessTree", new Vector4(MaxWetness, MaxSmoothness, WetnessOnBarkAlongY, WetnessOnBarkAtRoots));
			}
		}
	}
}