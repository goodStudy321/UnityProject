using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Phantom.Protocal;
using Loong.Game;

public class NetAttr
{
    #region 公有方法
    /// <summary>
    /// 等级经验更新
    /// </summary>
    public static void RespRoleLevelUpdate(object obj)
    {
        m_role_level_toc resp = obj as m_role_level_toc;
        if (obj == null) return;
        User.instance.MapData.UpdateExpAndLevel(resp);
    }

    /// <summary>
    /// 角色属性更新
    /// </summary>
    public static void RespBaseProperty(object obj)
    {
        m_role_base_toc resp = obj as m_role_base_toc;
        if (resp == null) return;
        RoleBaseUpdate(resp.role_base);
        RoleFightValueUpdate(resp.role_powers);
    }

    /// <summary>
    /// 属性更新
    /// </summary>
    public static void RespPropertyUpdate(object obj)
    {
        m_map_actor_attr_change_toc resp = obj as m_map_actor_attr_change_toc;
        User.instance.UpdateProperty(resp);

    }

    /// <summary>
    /// 世界boss归属更新
    /// </summary>
    /// <param name="obj"></param>
    public static void RespWBossOwner(object obj)
    {
        m_world_boss_owner_update_toc resp = obj as m_world_boss_owner_update_toc;
        if (resp == null)
            return;
        p_world_boss_owner info = resp.world_boss_owner;
        long ownerId = 0;
        int level = 0;
        string name = "";
        int teamId = 0;
        long familyId = 0;
        if (info != null)
        {
            ownerId = info.owner_id;
            level = info.owner_level;
            name = info.owner_name;
            teamId = info.team_id;
            familyId = info.family_id;
        }
        PickIcon.CheckShowIcon(resp.actor_id, ownerId);
        EventMgr.Trigger(EventKey.MonsterExtra, ownerId);
        EventMgr.Trigger(EventKey.BossBelonger, ownerId, level, name, teamId, familyId);
    }

    /// <summary>
    /// 更新个人属性
    /// </summary>
    /// <param name="obj"></param>
    public static void RespPsnPro(object obj)
    {
        m_role_attr_change_toc resp = obj as m_role_attr_change_toc;
        User.instance.UpdatePersonalPro(resp);
    }
    
    /// <summary>
    /// 所有单位血量改变(升级血量改变，其他导致的属性变化)
    /// </summary>
    /// <param name="obj"></param>
    public static void RespActorInfoChangeUpdate(object obj)
    {
        m_actor_info_change_toc resp = obj as m_actor_info_change_toc;
        long uid = resp.actor_id;
        long hp = resp.hp;
        long maxHp = resp.max_hp;
        Unit unit = UnitMgr.instance.FindUnitByUid(uid);
        if (unit == null)
            return;
        if (hp <= 0)
        {
            if (uid == User.instance.MapData.UID)
                User.instance.MapData.Hp = hp;
            //UnitMgr.instance.SetUnitDead(unit);
        }
        else
        {
            unit.MaxHP = maxHp;
            unit.HP = hp;
            if (uid == User.instance.MapData.UID)
            {
                User.instance.MapData.MaxHp = maxHp;             
                User.instance.MapData.Hp = hp;
            }
        }
        EventMgr.Trigger(EventKey.ChangeOffLInfo, false, uid, hp);
    }

    /// <summary>
    /// 角色基础属性
    /// </summary>
    public static  void RoleBaseUpdate(List<p_kdv> list)
    {
        var info = list.GetEnumerator();
        while (info.MoveNext())
        {
            if ((PropertyBaseType)info.Current.id == PropertyBaseType.HP)
            {
                User.instance.MapData.MaxHp = info.Current.val ;
            }
            User.instance.MapData.UpdateBaseProperty(info.Current.id, info.Current.val);
        }
        EventMgr.Trigger(EventKey.OnUpdateProEnd);
    }

    /// <summary>
    /// 更新战斗力
    /// </summary>
    public static void RoleFightValueUpdate(List<p_kv> fightValueList)
    {
        for (int i = 0; i < fightValueList.Count; i++)
        {
            FightValEnum key = (FightValEnum)fightValueList[i].id;
            int value = fightValueList[i].val;
            User.instance.MapData.UpdateFightValue(key, value);
        }
        EventMgr.Trigger(EventKey.OnUpdateFightEnd);
    }
    #endregion
}
