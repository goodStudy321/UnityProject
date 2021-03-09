using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UnitDissolve
{
    #region 私有字段
    /// <summary>
    /// 溶解单位
    /// </summary>
    private Unit mOwner;
    /// <summary>
    /// 溶解材质
    /// </summary>
    private List<Material> mDlMaterials = new List<Material>();
    /// <summary>
    /// 溶解属性名
    /// </summary>
    private string mDlProName = "_Dissolve_Inteisty";
    /// <summary>
    /// 溶解时间
    /// </summary>
    private float mDlTime = 0;
    /// <summary>
    /// 当前时间
    /// </summary>
    private float mCurTime = 0;
    /// <summary>
    /// 是否升序叠加溶解参数
    /// </summary>
    private bool isAscending = true;
    #endregion

    #region 私有方法
    /// <summary>
    /// 执行溶解
    /// </summary>
    private void ExeDissolve()
    {
        if (mDlMaterials == null)
            return;
        int count = mDlMaterials.Count;
        if (count == 0)
            return;
        float dlValue = mCurTime / mDlTime;
        dlValue = Mathf.Clamp01(dlValue);
        if (!isAscending)
            dlValue = 1 - dlValue;
        for (int i = 0; i < count; i++)
            mDlMaterials[i].SetFloat(mDlProName, dlValue);
        mCurTime += Time.deltaTime;
        if(mCurTime > mDlTime)
        {
            mCurTime = 0;
            mDlTime = 0;
        }
    }

    /// <summary>
    /// 恢复材质参数
    /// </summary>
    private void RecoverMatParam()
    {
        if (mDlMaterials == null)
            return;
        int count = mDlMaterials.Count;
        if (count == 0)
            return;
        for (int i = 0; i < count; i++)
        {
            mDlMaterials[i].SetFloat(mDlProName, 0);
        }
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 初始化
    /// </summary>
    /// <param name="unit"></param>
    public void init(Unit unit)
    {
        mOwner = unit;
        if (mOwner == null)
            return;
        mCurTime = 0;
        UnitMatHelper.FindSetMats(mOwner.UnitTrans, mDlProName,mDlMaterials);
    }

    /// <summary>
    /// 设置溶解时间
    /// </summary>
    /// <param name="dlTime"></param>
    public void SetDissolve(float dlTime, int agr)
    {
        mDlTime = dlTime * 0.001f;
        isAscending = agr == 0 ? true : false;
    }
    
    /// <summary>
    /// 更新
    /// </summary>
    public void Update()
    {
        if (mDlTime == 0)
            return;
        if (mCurTime > mDlTime)
            return;
        ExeDissolve();
    }

    /// <summary>
    /// 清除数据
    /// </summary>
    public void Clear()
    {
        RecoverMatParam();
        mOwner = null;
        mDlMaterials.Clear();
        mDlTime = 0;
        mCurTime = 0;
        isAscending = true;
    }
    #endregion
}
