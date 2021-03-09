using UnityEngine;
using System.Collections;

[AddComponentMenu("投影阴影/投影阴影接收(02)")]
public class DShadowReceiver2 : DShadowReceiver
{
	
	protected override void Start ()
    {
        int index = LayerMask.NameToLayer(PJShadowMgr.ReceiveLayer2);
        if (index < 0)
        {
            return;
        }
        gameObject.layer = index;
	}

    protected override void OnEnable() {
        int index = LayerMask.NameToLayer(PJShadowMgr.ReceiveLayer2);
        if (index < 0)
        {
            return;
        }
        gameObject.layer = index;
	}
}