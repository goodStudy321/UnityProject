using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UnitOutLine
{
    #region 私有字段
    /// <summary>
    /// 发光单位
    /// </summary>
    private Unit mOwner;
    /// <summary>
    /// 发光材质
    /// </summary>
    private List<Material> mOlMaterials = new List<Material>();
    /// <summary>
    /// 外发光渲染
    /// </summary>
    private List<SkinnedMeshRenderer> mRenders = new List<SkinnedMeshRenderer>();
    /// <summary>
    /// 发光属性名
    /// </summary>
    private string mOlProName = "_Hitpoint";
    /// <summary>
    /// 发光时间
    /// </summary>
    private float mOlTime = 0;
    /// <summary>
    /// 当前时间
    /// </summary>
    private float mCurTime = 0;
    /// <summary>
    /// 是否升序叠加发光参数
    /// </summary>
    private bool isAscending = true;
    /// <summary>
    /// 是否发光完成
    /// </summary>
    private bool isOlDone = true;
    /// <summary>
    /// 外发光最低值
    /// </summary>
    private float mMixVal = 1;
    /// <summary>
    /// 外发光差值
    /// </summary>
    private float mOlVal = 1;
    #endregion

    #region 私有方法
    /// <summary>
    /// 刷新渲染组件
    /// </summary>
    /// <param name="trans"></param>
    private void FrshRenderers(Transform trans)
    {
        if (trans == null)
            return;
        SkinnedMeshRenderer[] renderers = trans.GetComponentsInChildren<SkinnedMeshRenderer>();
        if (renderers == null)
            return;
        mRenders.Clear();
        mRenders.AddRange(renderers);
    }

    /// <summary>
    /// 查找单个材质
    /// </summary>
    /// <param name="mat"></param>
    private void SetMaterial(Material mat)
    {
        if (mat == null)
            return;
        if (!mat.HasProperty(mOlProName))
            return;
        mOlMaterials.Add(mat);
    }


    /// <summary>
    /// 重找材质
    /// </summary>
    /// <param name="trans"></param>
    private void ReFindMats()
    {
        if (mRenders == null)
            return;
        int count = mRenders.Count;
        if (count == 0)
            return;
        mOlMaterials.Clear();
        for (int i = 0; i < count; i++)
        {
            SetMaterial(mRenders[i].material);
        }
    }

    /// <summary>
    /// 执行发光
    /// </summary>
    private void DoOutline()
    {
        if (isOlDone)
            return;
        if (mOlMaterials == null)
            return;
        int count = mOlMaterials.Count;
        if (count == 0)
            return;
        float olValue = mCurTime / mOlTime;
        float radio = Mathf.Clamp01(olValue);
        if (isAscending)
        {
            if (olValue >= 1)
            {
                isAscending = false;
                mCurTime = 0;
            }
            olValue = mMixVal + mOlVal * radio;
        }
        else
        {
            if(olValue >= 1)
                isOlDone = true;
            olValue = mMixVal + (mOlVal - mOlVal * radio);
        }
        for (int i = 0; i < count; i++)
            mOlMaterials[i].SetFloat(mOlProName, olValue);
        mCurTime += Time.deltaTime;
    }

    /// <summary>
    /// 恢复材质参数
    /// </summary>
    private void RecoverMatParam()
    {
        if (mOlMaterials == null)
            return;
        int count = mOlMaterials.Count;
        if (count == 0)
            return;
        for (int i = 0; i < count; i++)
            mOlMaterials[i].SetFloat(mOlProName, mMixVal);
    }

    /// <summary>
    /// 是否可以发光
    /// </summary>
    /// <returns></returns>
    private bool CanOutline()
    {
        if (mOwner == null)
            return false;
        if (mOwner.DestroyState)
            return false;
        return true;
    }

    /// <summary>
    /// 单位是否隐藏
    /// </summary>
    /// <returns></returns>
    private bool IsUnitHide()
    {
        Transform trans = mOwner.UnitTrans;
        if (trans == null)
            return true;
        if (!trans.gameObject.activeSelf)
            return true;
        return false;
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 设置材质
    /// </summary>
    /// <param name="unit"></param>
    public void SetRenderer(Unit unit)
    {
        mOwner = unit;
        if (!CanOutline())
            return;
        FrshRenderers(unit.UnitTrans);
    }
    
    /// <summary>
    /// 设置发光时间
    /// </summary>
    /// <param name="maxVal">发光最大值</param>
    /// <param name="olTime">发光时间</param>
    public void SetOutLine(float maxVal, float olTime)
    {
        if (!CanOutline())
            return;
        if (IsUnitHide())
            return;
        mCurTime = 0;
        mOlTime = olTime * 0.001f;
        mOlVal = maxVal - mMixVal;
        isAscending = true;
        isOlDone = false;
        ReFindMats();
    }

    /// <summary>
    /// 更新
    /// </summary>
    public void Update()
    {
        if (!CanOutline())
            return;
        DoOutline();
    }

    /// <summary>
    /// 清除数据
    /// </summary>
    public void Clear()
    {
        RecoverMatParam();
        mOwner = null;
        mOlMaterials.Clear();
        mRenders.Clear();
        mOlTime = 0;
        mCurTime = 0;
        isAscending = true;
        isOlDone = true;
    }

    /// <summary>
    /// 设置外发光皮肤
    /// </summary>
    public static void SetOutlineSkin(Unit unit)
    {
        float olVal = 5;
        float olTime = 70;
        float[] args = ActionHelper.GetActOutlineParam(unit, "N0010", "OutLineSkin");
        if(args != null)
        {
            olVal = args[0];
            olTime = args[1];
        }
        unit.mUnitOutline.SetOutLine(olVal, olTime);
    }
    #endregion
}
