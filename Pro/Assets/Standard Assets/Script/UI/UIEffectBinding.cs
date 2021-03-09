using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class UIEffectBinding : MonoBehaviour
{
    /// <summary>
    /// 遮罩面板
    /// </summary>
    //private UIPanel mPanel = null;

    /// <summary>
    /// 直属父级节点
    /// </summary>
    private UIPanel mParentPanel = null;
    /// <summary>
    /// 遮罩滚动框列表
    /// </summary>
    private UIScrollView[] mSVList = null;

    private bool mInit = false;
    //private bool mHasClipPanel = false;
    private Renderer[] mClipRenders = null;
    private List<Material> mMaterials = new List<Material>();
    private int propertyInt = 0;


    UIWidget mParentWidget;
    int mCurrentRenderQueue = -1;
    //int mCurrentRenderNum = 0;
    public string mNameLayer = "UI";

    public bool mUnderDrawcall = true;
    public bool mIsUsedMaterials = false;
    /// <summary>
    /// 取消遮罩效果
    /// </summary>
    public bool noClip = false;

    //[SerializeField]
    private bool mUseShareMat = true;

    private Renderer[] mRenders = null;

    public bool hasEnable = false;

    /// <summary>
    /// 拖动计数
    /// </summary>
    private int mOnDragCount = 0;


    /// <summary>
    /// 查找遮罩面板
    /// </summary>
    private void FindClipPanel()
    {
        //if (noClip == true || mPanel != null || transform.parent == null)
        //    return;

        //mPanel = GetComponentInParent<UIPanel>();
        //if(mPanel != null && mUseShareMat == true && hasEnable == false)
        //{
        //    UIEffectBindingMgr.instance.UIEBActive(mPanel.depth, this);
        //    hasEnable = true;
        //}

        if (noClip == true || (mSVList != null && mSVList.Length > 0) || transform.parent == null)
            return;

        mParentPanel = GetComponentInParent<UIPanel>();
        mSVList = GetComponentsInParent<UIScrollView>();
        if(mSVList != null)
        {
            for (int a = 0; a < mSVList.Length; a++)
            {
                if (mSVList[a] != null)
                {
                    mSVList[a].onDragStarted += DragStart;
                    mSVList[a].onStoppedMoving += DragEnd;
                }
            }

            if (mParentPanel != null && mUseShareMat == true && hasEnable == false)
            {
                hasEnable = true;
                UIEffectBindingMgr.instance.UIEBActive(mParentPanel.depth, this);
            }
        }
    }

    private void ResetMaterialRenderQueue(int queue, int renderOrder, Renderer[] renders)
    {
        if (mUnderDrawcall == false)
            queue += 2;

        gameObject.layer = LayerMask.NameToLayer(mNameLayer);

        if (mIsUsedMaterials)
            mRenders = renders;
        
        for (int i = 0; i < renders.Length; i++)
        {
            renders[i].sortingOrder = renderOrder;
            renders[i].gameObject.layer = LayerMask.NameToLayer(mNameLayer);
            
            if(mUseShareMat == true)
            {
                for (int iMat = 0; iMat < renders[i].sharedMaterials.Length; iMat++)
                {
                    if (renders[i].sharedMaterials[iMat] != null)
                        renders[i].sharedMaterials[iMat].renderQueue = queue;
                }
            }
            else
            {
                for (int iMat = 0; iMat < renders[i].materials.Length; iMat++)
                {
                    if (renders[i].materials[iMat] != null)
                        renders[i].materials[iMat].renderQueue = queue;
                }
            }
        }

        mCurrentRenderQueue = queue;
        //mCurrentRenderNum = renders.Length;
    }

    private void GetParentWidget()
    {
        if (mParentWidget != null)
            return;

        mParentWidget = gameObject.GetComponentInParent<UIWidget>();
        if (mParentWidget != null && mParentWidget.drawCall != null)
        {
            Renderer[] renders = gameObject.GetComponentsInChildren<Renderer>(true);
            ResetMaterialRenderQueue(mParentWidget.drawCall.finalRenderQueue, mParentWidget.drawCall.sortingOrder, renders);
        }
        else
        {
            mParentWidget = null;
        }
    }

    private void Init()
    {
        propertyInt = Shader.PropertyToID("_ClipRange0");

        mClipRenders = GetComponentsInChildren<Renderer>();
        if (mClipRenders != null)
        {
            for (int a = 0; a < mClipRenders.Length; a++)
            {
                if(mUseShareMat == true)
                {
                    mMaterials.Add(mClipRenders[a].sharedMaterial);
                }
                else
                {
                    mMaterials.Add(mClipRenders[a].material);
                }
            }
        }
        else
        {
            Debug.LogError("LY : No render in UIEffectBinding !!! ");
        }

        FindClipPanel();

        mInit = true;
    }

    // Use this for initialization
    void Start()
    {
        GetParentWidget();
        Init();
        SetParticleClip();
    }

    // Update is called once per frame
    void Update ()
    {
        if (mParentWidget == null && transform.parent != null)
        {
            GetParentWidget();
            mCurrentRenderQueue = -1;
        }

        if(mInit == false)
        {
            Init();
            SetParticleClip();
        }

        //if(mPanel == null)
        //{
        //    FindClipPanel();
        //    SetParticleClip();
        //}

        if (mSVList == null || mSVList.Length <= 0)
        {
            FindClipPanel();
            SetParticleClip();
        }

        if (mParentWidget != null && mParentWidget.drawCall != null)
        {
            if (mCurrentRenderQueue != mParentWidget.drawCall.finalRenderQueue)
            {
                Renderer[] renders = gameObject.GetComponentsInChildren<Renderer>(true);
                ResetMaterialRenderQueue(mParentWidget.drawCall.renderQueue, mParentWidget.drawCall.sortingOrder, renders);
            }
        }

        if (mOnDragCount > 0)
        {
            SetParticleClip();
        }
    }

    private void OnEnable()
    {
        mMaterials.Clear();
        mClipRenders = null;

        //mPanel = null;
        mParentPanel = null;
        mSVList = null;
        mParentWidget = null;
        mCurrentRenderQueue = -1;
        mInit = false;

        GetParentWidget();
        Init();
        SetParticleClip();
    }

    void OnDisable()
    {
        //if (mPanel != null)
        //{
        //    mPanel.onClipMove -= UpdateClip;
        //}

        //if (mUseShareMat == true)
        //{
        //    if(mPanel == null || mPanel.gameObject.activeSelf == false || transform.parent == null || transform.parent.gameObject.activeSelf == false)
        //    {
        //        UIEffectBindingMgr.instance.EffectBindingDestory(this);
        //    }
        //    else
        //    {
        //        UIEffectBindingMgr.instance.EffectBindingHide(mPanel.depth, this);
        //    }
        //}

        if (hasEnable == true)
        {
            UIEffectBindingMgr.instance.UIEBDisable(mParentPanel.depth, this);
            hasEnable = false;
        }

        mMaterials.Clear();
        mClipRenders = null;

        //mPanel = null;
        mParentPanel = null;
        if(mSVList != null)
        {
            for(int a = 0; a < mSVList.Length; a++)
            {
                if(mSVList[a] != null)
                {
                    mSVList[a].onDragStarted -= DragStart;
                    mSVList[a].onStoppedMoving -= DragEnd;
                }
            }
        }
        mSVList = null;
        mParentWidget = null;
        mCurrentRenderQueue = -1;
        mInit = false;
        //mHasClipPanel = false;

        FxUvAnimation[] uvAnims = GetComponentsInChildren<FxUvAnimation>();
        if(uvAnims != null)
        {
            for(int a = 0; a < uvAnims.Length; a++)
            {
                uvAnims[a].Reset();
            }
        }

        if (!mIsUsedMaterials)
            return;
        if (mRenders == null)
            return;

        mRenders = null;
    }

    private void OnDestroy()
    {
        if (mUseShareMat == true && hasEnable == true)
        {
            //UIEffectBindingMgr.instance.UIEBDisable(mPanel.depth, this);
            UIEffectBindingMgr.instance.UIEBDisable(mParentPanel.depth, this);
            hasEnable = false;
        }
    }

    private void DragStart()
    {
        mOnDragCount++;
    }

    private void DragEnd()
    {
        mOnDragCount--;
        if(mOnDragCount < 0)
        {
            mOnDragCount = 0;
        }
    }

    public void SetParticleClip()
    {
        if(noClip == true)
        {
            Vector4 tempR = new Vector4(-3000, -3000, 3000, 3000);
            Renderer[] tRens = GetComponentsInChildren<Renderer>();
            for (int a = 0; a < tRens.Length; a++)
            {
                if (mUseShareMat == true)
                {
                    if (tRens[a].sharedMaterial != null)
                    {
                        tRens[a].sharedMaterial.SetVector(propertyInt, tempR);
                    }
                }
                else
                {
                    if (tRens[a].material != null)
                    {
                        tRens[a].material.SetVector(propertyInt, tempR);
                    }
                }
            }

            return;
        }

        if (UICamera.mainCamera != null)
        {
            //if (mPanel != null)
            if(mSVList != null)
            {
                Vector3 bottomLeft = new Vector3(-5000, -5000, 0);
                Vector3 topRight = new Vector3(5000, 5000, 0);
                for(int a = 0; a < mSVList.Length; a++)
                {
                    UIPanel tPanel = mSVList[a].GetComponent<UIPanel>();
                    Vector3 tBL = UICamera.mainCamera.WorldToViewportPoint(tPanel.worldCorners[0]);
                    Vector3 tTR = UICamera.mainCamera.WorldToViewportPoint(tPanel.worldCorners[2]);

                    if(tBL.x > bottomLeft.x)
                    {
                        bottomLeft.x = tBL.x;
                    }
                    if (tBL.y > bottomLeft.y)
                    {
                        bottomLeft.y = tBL.y;
                    }

                    if (tTR.x < topRight.x)
                    {
                        topRight.x = tTR.x;
                    }
                    if (tTR.y < topRight.y)
                    {
                        topRight.y = tTR.y;
                    }
                }

                //if (mPanel.clipping == UIDrawCall.Clipping.SoftClip)
                {
                    //Vector3 bottomLeft = UICamera.mainCamera.WorldToViewportPoint(mPanel.worldCorners[0]);
                    //Vector3 topRight = UICamera.mainCamera.WorldToViewportPoint(mPanel.worldCorners[2]);
                    //WorldToViewportPoint这个函数转换完的范围是0至1，左下是(0, 0) 右上是(1, 1)

                    //Vector4 temp = new Vector4(bottomLeft.x * 2 - 1, bottomLeft.y * 2 - 1, topRight.x * 2 - 1, topRight.y * 2 - 1);
                    Vector4 temp = new Vector4(bottomLeft.x, bottomLeft.y, topRight.x, topRight.y);
                    Renderer[] tRenderers = GetComponentsInChildren<Renderer>();
                    for(int a = 0; a < tRenderers.Length; a++)
                    {
                        if(mUseShareMat == true)
                        {
                            if (tRenderers[a].sharedMaterial != null)
                            {
                                tRenderers[a].sharedMaterial.SetVector(propertyInt, temp);
                            }
                        }
                        else
                        {
                            if (tRenderers[a].material != null)
                            {
                                tRenderers[a].material.SetVector(propertyInt, temp);
                            }
                        }
                    }
                }

                return;
            }
        }
    }
}
