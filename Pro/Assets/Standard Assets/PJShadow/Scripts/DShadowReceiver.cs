using UnityEngine;
using System.Collections;

[AddComponentMenu("投影阴影/投影阴影接收")]
public class DShadowReceiver : MonoBehaviour
{
	//MeshFilter _meshFilter;
	//MeshRenderer _meshRenderer;

	
	protected virtual void Awake()
    {
		//_meshFilter = GetComponent<MeshFilter>();
		//_meshRenderer = GetComponent<MeshRenderer>();
	}

    protected virtual void Start ()
    {
        int index = LayerMask.NameToLayer(PJShadowMgr.ReceiveLayer);
        if (index < 0)
        {
            return;
        }
        gameObject.layer = index;

        
	}

    protected virtual void OnEnable() {
        int index = LayerMask.NameToLayer(PJShadowMgr.ReceiveLayer);
        if (index < 0)
        {
            return;
        }
        gameObject.layer = index;
	}

    protected virtual void OnDisable() {
		
	}


    protected virtual void OnDestroy() {
        int index = LayerMask.NameToLayer("Default");
        if (index < 0 || gameObject == null)
        {
            return;
        }
        gameObject.layer = index;
	}
}