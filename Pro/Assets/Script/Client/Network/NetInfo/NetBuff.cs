using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Phantom.Protocal;
using System;
using Loong.Game;

public class NetBuff
{
    #region Client --> Server
    /// <summary>
    /// 请求移动buff
    /// </summary>
    /// <param name="opType">1 开始移动buff，0 停止移动buff</param>
    public static void ReqMoveBuff(int opType)
    {
        m_role_auto_tos buff = ObjPool.Instance.Get<m_role_auto_tos>();
        buff.op_type = opType;
        NetworkClient.Send<m_role_auto_tos>(buff);
    }

    #endregion

    #region Server --> Client
    /// <summary>
    /// 同步buff
    /// </summary>
    /// <param name="obj"></param>
    public static void ResponeBuff(object obj)
    {
        m_actor_buff_change_toc buff = obj as m_actor_buff_change_toc;
        Unit unit = UnitMgr.instance.FindUnitByUid(buff.actor_id);
        if (unit == null)
            return;
        if (unit.UnitTrans == null)
            return;
        for (int i = 0; i < buff.del_list.Count; i++)
        {
            unit.mBuffManager.DelBuf((uint)buff.del_list[i]);
            EventMgr.Trigger(EventKey.DelBuff, buff.del_list[i]);
        }
        for (int i = 0; i < buff.update_list.Count; i++)
        {
            p_buff pBuff = buff.update_list[i];
            int startTime = pBuff.start_time;
            int endTime = pBuff.end_time;
            unit.mBuffManager.AddBuff((uint)pBuff.buff_id, startTime, endTime, pBuff.value);
            EventMgr.Trigger(EventKey.AddBuff, pBuff.buff_id, startTime, endTime, pBuff.value);
        }
    }

    /// <summary>
    /// 响应buff血量改变
    /// </summary>
    /// <param name="obj"></param>
    public static void ResponeBuffHpChange(object obj)
    {
        m_buff_change_hp_toc buffChangeHp = obj as m_buff_change_hp_toc;
        Unit unit = UnitMgr.instance.FindUnitByUid(buffChangeHp.actor_id);
        if (!UnitHelper.instance.CanUseUnit(unit))
            return;
        bool isOwner = unit.UnitUID == User.instance.MapData.UID ? true : false;
        bool isRole = unit.mUnitAttInfo.UnitType == UnitType.Role ? true : false;
        if (buffChangeHp.type == (int)HarmType.PoisonReductionHp)
        {
            unit.HP -= buffChangeHp.val;
            SymbolMgr.Damage(unit,buffChangeHp.val, isOwner, isRole);
        }
        else if(buffChangeHp.type == (int)HarmType.CureAddHp)
        {
            unit.HP += buffChangeHp.val;
            SymbolMgr.RestoreHp(unit, buffChangeHp.val);
        }
        if (isOwner)
            User.instance.MapData.Hp = unit.HP;
    }

    /// <summary>
    /// 响应请求移动buff
    /// </summary>
    /// <param name="obj"></param>
    public static void RespMoveBuff(object obj)
    {

    }
    #endregion
}
