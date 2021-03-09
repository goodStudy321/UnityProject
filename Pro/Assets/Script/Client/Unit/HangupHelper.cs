using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HangupHelper
{
    public static readonly HangupHelper instance = new HangupHelper();
    private HangupHelper() { }
    #region 公有字段
    /// <summary>
    /// 检查待机状态
    /// </summary>
    /// <param name="unit"></param>
    /// <returns></returns>
    public bool ChkIdleState(Unit unit)
    {
        if (unit == null)
            return false;
        if (unit.ActionStatus == null)
            return false;
        if (unit.ActionStatus.ActionState != ActionStatus.EActionStatus.EAS_Idle)
            return false;
        Unit mount = unit.Mount;
        if (mount != null && mount.ActionStatus != null &&
            mount.ActionStatus.ActionState != ActionStatus.EActionStatus.EAS_Idle)
            return false;
        return true;
    }

    /// <summary>
    /// 检查挂机等级
    /// </summary>
    /// <returns></returns>
    public bool ChkHgLv()
    {
        GameSceneType gsType = (GameSceneType)GameSceneManager.instance.CurSceneType;
        if (User.instance.MapData.Level < 160)
            return false;
        if (gsType == GameSceneType.GST_MainScene)
            return true;
        int sceneId = User.instance.SceneId;
        CopyInfo info = CopyInfoManager.instance.Find((uint)sceneId);
        if (info == null)
            return false;
        if (info.copyType == (int)CopyType.FlowChart)
            return true;
        return false;
    }
    #endregion
}
