using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;
using Phantom.Protocal;

public class NetFightInfo
{
    #region Client --> Server
    /// <summary>
    /// 改变战斗模式
    /// </summary>
    /// <param name="mode"></param>
    public static void RequestChangeFightMode(int mode)
    {
        m_change_pk_mode_tos changeMode = ObjPool.Instance.Get<m_change_pk_mode_tos>();
        changeMode.pk_mode = mode;
        NetworkClient.Send<m_change_pk_mode_tos>(changeMode);
    }
    #endregion

    #region Server --> Client
    /// <summary>
    /// 反馈战斗模式改变
    /// </summary>
    /// <param name="obj"></param>
    public static void ResponeChangeFightMode(object obj)
    {
        m_change_pk_mode_toc changeMode = obj as m_change_pk_mode_toc;
        if(changeMode.err_code != 0)
        {
            string err = ErrorCodeMgr.GetError(changeMode.err_code);
            iTrace.Error(changeMode.err_code.ToString(), err);
            return;
        }
        User.instance.MapData.FightType = changeMode.pk_mode;
        Unit unit = InputMgr.instance.mOwner;
        if(unit != null)
            unit.FightType = changeMode.pk_mode;
        EventMgr.Trigger(EventKey.UpdateFightMode, changeMode.pk_mode - 1);
        ClearTargetData();
    }

    public static void ResponePKValueTime(object obj)
    {
        m_pk_value_time_toc pkValueTime = obj as m_pk_value_time_toc;
        User.instance.MapData.PkValueTime = pkValueTime.pk_value_time;
    }
    #endregion

    #region 私有变量
    /// <summary>
    /// 清除目标数
    /// </summary>
    private static void ClearTargetData()
    {
        InputMgr.instance.mLockTarget = null;
        Unit unit = InputMgr.instance.mOwner;
        if (unit == null)
            return;
        if (unit.Pet == null)
            return;
        var mp = unit.Pet.mPendant;
        if (mp == null) return;
        Pet petPendant = mp as Pet;
        if (petPendant == null)
            return;
        petPendant.TargetList.Clear();
    }
    #endregion
}
