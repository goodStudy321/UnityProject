using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class UnitRedNameInfo
{
    #region 私有字段
    /// <summary>
    /// 单位
    /// </summary>
    private Unit mOwner;
    #endregion

    #region 属性
    /// <summary>
    /// 是否红名
    /// </summary>
    public bool IsRedName
    {
        get
        {
            if (mOwner == null)
                return false;
            return mOwner.PkValue > 0;
        }
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 初始化
    /// </summary>
    /// <param name="unit"></param>
    public void Init(Unit unit)
    {
        mOwner = unit;
        InitPKValue();
    }
    
    /// <summary>
    /// 设置红名
    /// </summary>
    /// <param name="isRed"></param>
    public void SetRedName(ActorData actData)
    {
        if (mOwner == null)
            return;
        if (mOwner.TopBar == null)
            return;
        CommenNameBar bar = mOwner.TopBar as CommenNameBar;
        if (bar == null)
            return;
        bar.ResetNameColor();
        bar.Name = UnitHelper.instance.GetUnitFullName(actData);
    }

    public void Dispose()
    {
        mOwner = null;
    }
    #endregion

    #region 私有方法
    private void InitPKValue()
    {
        float pkValue = 0;
        long uId = mOwner.UnitUID;
        User user = User.instance;
        if (uId == user.MapData.UID)
        {
            pkValue = GetPkVal(user.MapData);
        }
        else
        {
            if (user.OtherRoleDic.ContainsKey(mOwner.UnitUID))
            {
                pkValue = GetPkVal(user.OtherRoleDic[uId]);
            }
        }
        mOwner.PkValue = pkValue;
        mOwner.mUnitRedNameInfo.SetRedName(user.MapData);
    }

    /// <summary>
    /// 获取pk值
    /// </summary>
    /// <param name="actData"></param>
    /// <returns></returns>
    private float GetPkVal(ActorData actData)
    {
        if (actData == null)
            return 0;
        float pkValue = 0;
        int id = (int)PropertyType.ATTR_PK_VALUE;
        if (actData.ValueProperty.ContainsKey(id))
            pkValue = actData.ValueProperty[id];
        else
            pkValue = actData.PkValue;
        return pkValue;
    }
    #endregion
}
