using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Light))]
[AddComponentMenu("Xyj/LightEffects/XyjSunSpecular")]
public class XyjSunSpecular : MonoBehaviour
{
	public bool m_enableSpecular = true;

	Light m_sun;

	// runtime

	// Use this for initialization
	void Start () {
		SetGlobalShaderProperties();
	}
	
	// Update is called once per frame
	void Update () {
		//SetGlobalShaderProperties();
	}

	void OnDisable()
	{
		Shader.DisableKeyword("_SUNSPECULAR_ON");
	}

	void SetGlobalShaderProperties()
	{
		if (!m_sun)
			m_sun = this.GetComponent<Light>();
		if (m_enableSpecular && m_sun != null && m_sun.enabled) {
			Shader.EnableKeyword("_SUNSPECULAR_ON");
			Shader.SetGlobalVector("_SunDir", -m_sun.transform.forward);
			Shader.SetGlobalColor("_SunColor", m_sun.color * m_sun.intensity);
		} else {
			Shader.DisableKeyword("_SUNSPECULAR_ON");
		}
	}

	void OnRenderObject()
	{
		SetGlobalShaderProperties();
	}
}
