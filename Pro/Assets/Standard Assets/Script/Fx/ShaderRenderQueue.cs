using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShaderRenderQueue : MonoBehaviour
{
    public GameObject Parent;
    public int RenderQueue = 4500;
    public bool includeChild = true;

    void Awake()
    {
    }

    void Start()
    {
        if(Parent != null) RenderQueue = GetParentDepth();
        SetRenderQueue(gameObject);
    }

    private int GetParentDepth()
    {
        UIWidget widget = Parent.GetComponent<UIWidget>();
        if (widget != null)
        {
            int renderQueue = widget.material.renderQueue;
            return renderQueue + widget.depth + 1;
        }
        return RenderQueue;
    }

    private  void SetRenderQueue(GameObject go)
    {
        if (go == null) return;
        Renderer[] renders;
        if (includeChild == true)
        {
            renders = go.GetComponentsInChildren<Renderer>(true);
        }
        else
        {
            renders = go.GetComponents<Renderer>();
        }

        if (renders == null || renders.Length == 0) return;
        int length = renders.Length;
        Renderer render;
        for (int i = 0; i < length; i++)
        {
            render = renders[i];
            render.material.renderQueue = RenderQueue ;
            
        }
    }
}
