using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class UIEffBinding : MonoBehaviour {

    UIWidget mParentWidget;
    [SerializeField]
    public UIWidget specifyWidget = null;

    int mCurrentRenderQueue = -1;
    //int mCurrentRenderNum = 0;
    public string mNameLayer = "UI";

    public bool mUnderDrawcall = true;
    public bool mIsUsedMaterials = false;
    
    private Renderer[] mRenders;

    private void ResetMaterialRenderQueue(int queue, int renderOrder, Renderer[] renders)
    {
//        if (renders.Length == mCurrentRenderNum)
//            return;

        if (mUnderDrawcall == false)
            queue += 2;

        gameObject.layer = LayerMask.NameToLayer(mNameLayer);

        if (mIsUsedMaterials)
            mRenders = renders;
        
        for (int i = 0; i < renders.Length; i++)
        {
            renders[i].sortingOrder = renderOrder;
            renders[i].gameObject.layer = LayerMask.NameToLayer(mNameLayer);

            if (mIsUsedMaterials)
            {
                for (int iMat = 0; iMat < renders[i].materials.Length; iMat++)
                {
                    if (renders[i].materials[iMat] != null)
                        renders[i].materials[iMat].renderQueue = queue;
                }
            }
            else
            {
                for (int iMat = 0; iMat < renders[i].sharedMaterials.Length; iMat++)
                {
                    if (renders[i].sharedMaterials[iMat] != null)
                        renders[i].sharedMaterials[iMat].renderQueue = queue;
                }
            }
        }

        mCurrentRenderQueue = queue;
        //mCurrentRenderNum = renders.Length;
    }

    // Use this for initialization
	void Start ()
    {
        if(specifyWidget != null)
        {
            mParentWidget = specifyWidget;
        }
        else
        {
            mParentWidget = gameObject.GetComponentInParent<UIWidget>();
        }

        if (mParentWidget != null && mParentWidget.drawCall != null)
        {
            Renderer[] renders = gameObject.GetComponentsInChildren<Renderer>(true);
            ResetMaterialRenderQueue(mParentWidget.drawCall.finalRenderQueue, mParentWidget.drawCall.sortingOrder, renders);
        }
    }
	
	// Update is called once per frame
	void Update () {
        if (mParentWidget != null && mParentWidget.drawCall != null)
        {
            if (mCurrentRenderQueue != mParentWidget.drawCall.finalRenderQueue)
            {
                Renderer[] renders = gameObject.GetComponentsInChildren<Renderer>(true);
                ResetMaterialRenderQueue(mParentWidget.drawCall.finalRenderQueue, mParentWidget.drawCall.sortingOrder, renders);
            }
        }
	}

    private void OnDestroy()
    {
        if (!mIsUsedMaterials)
            return;
        if (mRenders == null)
            return;

        int renderLenght = mRenders.Length;
        for (int i = 0; i < renderLenght; i++)
        {
            if(mRenders[i] == null || mRenders[i].materials == null)
                continue;

            int matLenght = mRenders[i].materials.Length;
            for (int iMat = 0; iMat < matLenght; iMat++)
            {
                if (mRenders[i].materials[iMat] != null)
                {
                    DestroyImmediate(mRenders[i].materials[iMat]);
                }
            }
        }
    }
}
