using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BossBatMgr
{
    public static readonly BossBatMgr instance = new BossBatMgr();

    private BossBatMgr() { }

    #region 私有变量
    /// <summary>
    /// 目标字典
    /// </summary>
    private Dictionary<long, bool> TargetDic = new Dictionary<long, bool>();
    /// <summary>
    /// 当前选择目标ID
    /// </summary>
    private long mCurSltId;
    /// <summary>
    /// 当前场景boss唯一ID
    /// </summary>
    private long mCurBossId = 0;
    #endregion

    #region 公有方法
    /// <summary>
    /// 设置当前选择目标Id
    /// </summary>
    /// <param name="id"></param>
    public void SetCurSltId(long id)
    {
        if (!IsWBScene())
            return;
        if (id == User.instance.MapData.UID)
            return;
        mCurSltId = id;
    }

    public void SetCurBossId(long id)
    {
        if (!IsWBScene())
            return;
        AddTarget(id);
        mCurBossId = id;
    }
    /// <summary>
    /// 是否是世界Boss场景
    /// </summary>
    public bool IsWBScene()
    {
        SceneSubType subType = GameSceneManager.instance.MapSubType;
        if (subType == SceneSubType.WordBoss)
            return true;
        if (subType == SceneSubType.WorldBossGuid)
            return true;
        return false;
    }
    /// <summary>
    /// 添加目标
    /// </summary>
    /// <param name="unitId"></param>
    public void AddTarget(long unitId)
    {
        if (!IsWBScene())
            return;
        if (unitId == User.instance.MapData.UID)
            return;
        if (unitId == 0)
            return;
        if (TargetDic.ContainsKey(unitId))
            return;
        TargetDic.Add(unitId,true);
    }

    /// <summary>
    /// 移除目标
    /// </summary>
    /// <param name="unitId"></param>
    public void RemoveTarget(long unitId)
    {
        if (!IsWBScene())
            return;
        SetAtkBoss(unitId);
        if (!TargetDic.ContainsKey(unitId))
            return;
        TargetDic.Remove(unitId);
    }

    /// <summary>
    /// 获取攻击目标
    /// </summary>
    /// <returns></returns>
    public Unit GetTarget()
    {
        if (!IsWBScene())
            return null;
        Unit target = UnitMgr.instance.FindUnitByUid(mCurSltId);
        if (BossExclCndt(target))
            return target;
        target = UnitMgr.instance.FindUnitByUid(mCurBossId);
        if (BossExclCndt(target))
            return target;
        return null;
    }

    /// <summary>
    /// 设置攻击Boss
    /// </summary>
    public void SetAtkBoss(long unitId)
    {
        if (unitId != mCurSltId)
            return;
        if (unitId == mCurBossId)
            return;
        SetCurSltId(mCurBossId);
        HangupMgr hgMgr = HangupMgr.instance;
        if (!hgMgr.IsAutoHangup && !hgMgr.IsSituFight)
            return;
        SelectRoleMgr.instance.StartNavPath(mCurSltId, 1);
    }

    /// <summary>
    /// 是否满足boss专属条件
    /// </summary>
    /// <returns></returns>
    public bool BossExclCndt(Unit target)
    {
        if (target == null)
            return false;
        if (target.Dead)
            return false;
        long unitId = target.UnitUID;
        if (TargetDic.ContainsKey(unitId))
            return true;
        return false;
    }

    /// <summary>
    /// 满足boss专属条件
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="target"></param>
    /// <param name="dis"></param>
    /// <returns></returns>
    public bool TarStyBossExcl(Unit attacker, Unit target, float dis)
    {
        if (!BossExclCndt(target))
            return false;
        if (!SkillHelper.instance.IsInDistance(attacker, target, dis))
            return false;
        return true;
    }

    /// <summary>
    /// 重置数据
    /// </summary>
    public void ResetData()
    {
        mCurSltId = 0;
        TargetDic.Clear();
        AddTarget(mCurBossId);
    }

    /// <summary>
    /// 清除全部数据
    /// </summary>
    public void Clear()
    {
        mCurBossId = 0;
        mCurSltId = 0;
        TargetDic.Clear();
    }
    #endregion
}
