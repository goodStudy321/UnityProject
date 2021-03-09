using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class RushEffect
{
    public static readonly RushEffect instance = new RushEffect();

    private RushEffect() { }
    #region 字段
    /// <summary>
    /// 冲刺特效
    /// </summary>
    private GameObject mRushEffect = null;
    #endregion

    #region 公有方法
    /// <summary>
    /// 显示特效
    /// </summary>
    public void ShowEffect(Unit unit)
    {
        if (mRushEffect != null)
        {
            if (mRushEffect.transform.parent == null)
                SetEffectPostion(unit);
            mRushEffect.SetActive(true);
            return;
        }
        AssetMgr.LoadPrefab("FX_Player01_ChongCI", (obj) =>
        {
            mRushEffect = obj;
            SetEffectPostion(unit);
            AssetMgr.Instance.SetPersist("FX_Player01_ChongCI", Suffix.Prefab);
        });
    }

    /// <summary>
    /// 设置特效
    /// </summary>
    public void SetEffectPostion(Unit unit)
    {
        Transform trans = mRushEffect.transform;
        trans.parent = unit.UnitTrans;
        trans.localPosition = Vector3.zero;
        trans.localEulerAngles = Vector3.zero;
        trans.localScale = Vector3.one;
        mRushEffect.SetActive(true);
    }

    /// <summary>
    /// 隐藏特效
    /// </summary>
    public void HideEffect()
    {
        if (mRushEffect == null)
            return;
        if (!mRushEffect.activeSelf)
            return;
        mRushEffect.SetActive(false);
    }
    #endregion
}
