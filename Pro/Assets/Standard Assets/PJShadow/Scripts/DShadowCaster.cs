using UnityEngine;
using System.Collections;
using System.Collections.Generic;


[AddComponentMenu("投影阴影/投影阴影投射")]
public class DShadowCaster : MonoBehaviour 
{
    /// <summary>
    /// 显示标志
    /// </summary>
    private bool mShow = true;
    /// <summary>
    /// 原始层级索引
    /// </summary>
    private int oriLayerIndex = -1;

    public bool ShowSign
    {
        set
        {
            mShow = value;
            enabled = mShow;
        }
    }
    public int OriLayerIndex
    {
        get { return oriLayerIndex; }
        set { oriLayerIndex = value; }
    }


    private void Awake()
    {
        oriLayerIndex = gameObject.layer;
    }

    private void Start()
    {
        if (mShow == false)
        {
            enabled = false;
            return;
        }

        int index = LayerMask.NameToLayer(PJShadowMgr.CasterLayer);
        if (index < 0)
        {
            return;
        }
        gameObject.layer = index;
    }

    private void OnEnable()
    {
        if (mShow == false)
        {
            enabled = false;
            return;
        }
            

        int index = LayerMask.NameToLayer(PJShadowMgr.CasterLayer);
        if (index < 0)
        {
            return;
        }
        gameObject.layer = index;
    }

    private void OnDisable()
    {
        if(oriLayerIndex >= 0)
        {
            gameObject.layer = oriLayerIndex;
        }
    }

    private void OnDestroy()
    {
        int index = LayerMask.NameToLayer("Default");
        if (index < 0 || gameObject == null)
        {
            return;
        }
        gameObject.layer = index;
    }
}

//                (●°-°●)