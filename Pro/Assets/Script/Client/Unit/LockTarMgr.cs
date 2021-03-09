using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class LockTarMgr
{
    public static readonly LockTarMgr instance = new LockTarMgr();
    private LockTarMgr() { }
    #region 字段
    /// <summary>
    /// 显示目标
    /// </summary>
    private Unit mShowTar = null;
    private TopBarBase mTopBar = null;
    #endregion

    #region 属性
    #endregion

    #region 私有方法
    /// <summary>
    /// boss玩法地图
    /// </summary>
    /// <returns></returns>
    private bool CanShowRoleBar()
    {
        int sceneId = User.instance.SceneId;
        GlobalData gdata = GlobalDataManager.instance.Find(83);
        if (gdata == null)
            return false;
        List<uint> list = gdata.num2.list;
        if (list == null)
            return false;
        int count = list.Count;
        if (count == 1 && list[0] == 99999)
            return true;
        for(int i = 0; i < count; i++)
        {
            if (list[i] != sceneId)
                continue;
            return true;
        }
        return false;
    }
    /// <summary>
    /// 释放旧头条
    /// </summary>
    /// <param name="target"></param>
    private void DisOldBar(Unit target)
    {
        if (target == null)
            return;
        UnitType tarType = target.mUnitAttInfo.UnitType;
        if (tarType == UnitType.Role)
        {
            Clear();
            if (target.HeadBar == null)
                return;
            target.HeadBar.Dispose();
            target.HeadBar = null;
        }
        else if(tarType == UnitType.Boss)
        {
            Clear();
            if (target.TopBar == null)
                return;
            target.TopBar.Dispose();
            target.TopBar = null;
        }
    }

    /// <summary>
    /// 清除数据
    /// </summary>
    private void Clear()
    {
        mTopBar = null;
        mShowTar = null;
    }

    /// <summary>
    /// 更新距离
    /// </summary>
    private void UpdateDis()
    {
        if (mShowTar == null)
            return;
        Unit unit = InputVectorMove.instance.MoveUnit;
        if (unit == null)
            return;
        float disSqr = Vector3.SqrMagnitude(unit.Position - mShowTar.Position);
        if (disSqr < 40000)
            return;
        InputMgr.instance.mLockTarget = null;
        DisOldBar(mShowTar);
    }

    /// <summary>
    /// 设置信息条
    /// </summary>
    /// <param name="target"></param>
    private void CreateBar(Unit target)
    {
        UnitType tarType = target.mUnitAttInfo.UnitType;
        if(tarType == UnitType.Role)
            mTopBar = UnitHeadBar.Create(target, target.Name);
        else
            mTopBar = TopBarFty.Create(target, target.Name);
        mShowTar = target;
    }

    /// <summary>
    /// 比较现在显示目标
    /// </summary>
    /// <param name="target"></param>
    private void CompairShowTar(Unit target)
    {
        if (mTopBar == null)
            CreateBar(target);
        else
        {
            if (target.UnitUID == mShowTar.UnitUID)
                return;
            DisOldBar(mShowTar);
            CreateBar(target);
        }
    }

    /// <summary>
    /// 创建显示条UI
    /// </summary>
    private void CreateShowBarUI(Unit target)
    {
        if (mShowTar == null)
            CreateBar(target);
        else
        {
            Unit lockTar = InputMgr.instance.mLockTarget;
            if (lockTar == null)
            {
                CompairShowTar(target);
            }
            else
            {
                if (target.UnitUID != lockTar.UnitUID)
                    return;
                CompairShowTar(target);
            }
        }
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 创建锁定目标头像条
    /// </summary>
    /// <param name="target"></param>
    /// <param name="name"></param>
    public void CrtLockTopBar(Unit target, string name)
    {
        if (target == null)
            return;
        UnitType tarType = target.mUnitAttInfo.UnitType;
        if (tarType == UnitType.Role)
        {
            if (!CanShowRoleBar())
                return;
            CreateShowBarUI(target);
        }
        else if (tarType == UnitType.Boss)
            CreateShowBarUI(target);
        else
            TopBarFty.Create(target, target.Name);
    }

    /// <summary>
    /// 释放
    /// </summary>
    /// <param name="target"></param>
    public void DisTopBar(Unit target)
    {
        if (target == null)
            return;
        if (mShowTar == null)
            return;
        if (target.UnitUID != mShowTar.UnitUID)
            return;
        DisOldBar(target);
    }
    public void Update()
    {
        UpdateDis();
    }
    #endregion
}
