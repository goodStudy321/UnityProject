using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class TaskTarHelper
{
    public static readonly TaskTarHelper instance = new TaskTarHelper();
    private TaskTarHelper() { }
    #region 私有变量
    /// <summary>
    /// 检测CD计时器
    /// </summary>
    private Timer mTimer = new Timer();
    #endregion

    #region 公有变量
    public bool TaskTimeRun()
    {
        if (mTimer.Running)
            return true;
        return false;
    }

    public void StartTimer()
    {
        mTimer.Seconds = 0.3f;
        mTimer.Start();
    }

    /// <summary>
    /// 清除计时器
    /// </summary>
    public void ClearTimer()
    {
        mTimer.Stop();
    }
    /// <summary>
    /// 任务目标击杀
    /// </summary>
    /// <returns></returns>
    public bool TaskTarKill()
    {
        if (!HangupMgr.instance.IsMisKill)
            return false;
        if (SelectRoleMgr.instance.TarRoleUId != 0)
            return true;
        if (User.instance.MissTargetID != 0)
            return true;
        return false;
    }

    /// <summary>
    /// 是否选择了攻击目标
    /// </summary>
    /// <returns></returns>
    public bool IsSelectRole()
    {
        if (!HangupMgr.instance.IsMisKill)
            return false;
        if (SelectRoleMgr.instance.TarRoleUId != 0)
            return true;
        return false;
    }

    /// <summary>
    /// 是否是任务目标
    /// </summary>
    /// <param name="target"></param>
    /// <returns></returns>
    public bool IsTaskTar(Unit target)
    {
        if (target == null)
            return false;
        long id = SelectRoleMgr.instance.TarRoleUId;
        if (target.UnitUID == id)
            return true;
        id = User.instance.MissTargetID;
        if (target.mUnitAttInfo.UnitTypeId == id)
            return true;
        return false;
    }
    #endregion
}