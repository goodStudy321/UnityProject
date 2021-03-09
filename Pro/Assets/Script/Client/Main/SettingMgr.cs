using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;
using System;

public class SettingMgr
{
    public static readonly SettingMgr instance = new SettingMgr();

    private SettingMgr() { }

    #region 私有字段
    /// <summary>
    /// 最大显示数量
    /// </summary>
    private int mMaxShowNum = 20;
    /// <summary>
    /// 检查计时器
    /// </summary>
    private Timer chkTimer = new Timer();
    /// <summary>
    /// 攻击信息字典
    /// </summary>
    private Dictionary<long, HitedInfo> mHitInfoDic = new Dictionary<long, HitedInfo>();
    /// <summary>
    /// 显示单位ID列表
    /// </summary>
    private Dictionary<long, bool> mShowIDDic = new Dictionary<long, bool>();
    #endregion

    #region 属性
    /// <summary>
    /// 最大同屏数量
    /// </summary>
    public int MaxShowNum
    {
        get { return mMaxShowNum; }
        set { mMaxShowNum = value; }
    }
    /// <summary>
    /// 攻击信息字典
    /// </summary>
    public Dictionary<long,HitedInfo> HitInfoDic
    {
        get { return mHitInfoDic; }
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 是否过滤单位
    /// </summary>
    /// <param name="unit"></param>
    /// <returns></returns>
    private bool IsFilterUnit(Unit unit)
    {
        if (unit == null)
            return true;
        if (unit.UnitTrans == null)
            return true;
        UnitType type = UnitHelper.instance.GetUnitType(unit.TypeId);
        if (type != UnitType.Role)
            return true;
        if (UnitHelper.instance.IsOwner(unit))
            return true;
        int curSceneId = User.instance.SceneId;
        if (curSceneId == 20901) return true; //竞技场过滤
        return false;
    }
    #endregion

    #region 公有方法
    public void Init()
    {
        EventMgr.Add(EventKey.OnChgShowNum, ChgShowNum);
        EventMgr.Add(EventKey.OnShieldEff, ShowEffectMgr.instance.ChgShieldEff);
    }

    /// <summary>
    /// 初始化监听
    /// </summary>
    public void InitLsnr()
    {
        if (chkTimer == null)
            return;
        chkTimer.complete += EndCount;
    }

    /// <summary>
    /// 初始化角色显示状态
    /// </summary>
    /// <param name="unit"></param>
    public void InitRoleShwSt(Unit unit)
    {
        if (IsFilterUnit(unit))
            return;
        if (!CanShow())
        {
            HideRole(unit);
            return;
        }
        if (!IsInView(unit.Position))
        {
            HideRole(unit);
            return;
        }
        if (unit.UnitTrans.gameObject.activeSelf)
            return;
        UnitMgr unitMgr = UnitMgr.instance;
        unitMgr.SetUnitActive(unit, true, true);
        if (!mShowIDDic.ContainsKey(unit.UnitUID))
            mShowIDDic.Add(unit.UnitUID, true);
    }

    /// <summary>
    /// 改变显示玩家数量
    /// </summary>
    /// <param name="args"></param>
    public void ChgShowNum(params object[] args)
    {
        if (args == null || args.Length == 0)
            return;
        MaxShowNum = Convert.ToInt32(args[0]);
        Reset();
    }

    /// <summary>
    /// 重置(玩家设置改变时重置）
    /// </summary>
    public void Reset()
    {
        Clear();
        SetUnitsView();
    }

    /// <summary>
    /// 清除数据
    /// </summary>
    public void Clear()
    {
        HideAllRole();
        mShowIDDic.Clear();
        StartTimer();
    }

    /// <summary>
    /// 隐藏所有玩家
    /// </summary>
    public void HideAllRole()
    {
        List<Unit> units = UnitMgr.instance.UnitList;
        for (int i = 0; i < units.Count; i++)
        {
            Unit unit = units[i];
            if (IsFilterUnit(unit))
                continue;
            UnitMgr.instance.SetUnitActive(unit, false, false);
        }
    }

    /// <summary>
    /// 隐藏角色
    /// </summary>
    /// <param name="unit"></param>
    public void HideRole(Unit unit)
    {
        if (IsFilterUnit(unit))
            return;
        unit.UnitTrans.gameObject.SetActive(false);
    }

    /// <summary>
    /// 开始计时器
    /// </summary>
    public void StartTimer()
    {
        if (chkTimer == null)
            return;
        if (chkTimer.Running)
            chkTimer.Stop();
        chkTimer.Seconds = 1;
        chkTimer.Start();
    }

    /// <summary>
    /// 结束计时
    /// </summary>
    public void EndCount()
    {
        SetUnitsView();
        StartTimer();
    }

    /// <summary>
    /// 检查单位视野
    /// </summary>
    /// <param name="unit"></param>
    public void SetUnitsView()
    {
        if (GameSceneManager.instance.SceneLoadState != SceneLoadStateEnum.SceneDone)
            return;
        List<Unit> units = UnitMgr.instance.UnitList;
        HandleRemove(units);
        HandleTeamRole(units);
        HandleHitRole();
        HandleOtherRole(units);
    }

    /// <summary>
    /// 处理出屏
    /// </summary>
    /// <param name="units"></param>
    public void HandleRemove(List<Unit> units)
    {
        for (int i = 0; i < units.Count; i++)
        {
            Unit unit = units[i];
            HandleOfView(unit);
        }
    }
    
    /// <summary>
    /// 处理队友显示
    /// </summary>
    /// <param name="units"></param>
    public void HandleTeamRole(List<Unit> units)
    {
        for (int i = 0; i < units.Count; i++)
        {
            if (!CanShow())
                return;
            Unit unit = units[i];
            if (unit.TeamId == 0)
                continue;
            if (unit.TeamId != User.instance.MapData.TeamID)
                continue;
            HandleInView(unit);
        }
    }

    /// <summary>
    /// 处理自己攻击和被攻击单位
    /// </summary>
    public void HandleHitRole()
    {
        foreach(KeyValuePair<long,HitedInfo> item in mHitInfoDic)
        {
            if (!CanShow())
                return;
            HandleInView(item.Value.mUnit);
        }
    }

    /// <summary>
    /// 处理其他人显示
    /// </summary>
    /// <param name="units"></param>
    public void HandleOtherRole(List<Unit> units)
    {
        for (int i = 0; i < units.Count; i++)
        {
            if (!CanShow())
                return;
            Unit unit = units[i];
            if (unit.TeamId != 0 && unit.TeamId == User.instance.MapData.TeamID)
                continue;
            if (mHitInfoDic.ContainsKey(unit.UnitUID))
                continue;
            HandleInView(unit);
        }
    }

    /// <summary>
    /// 处理屏内单位
    /// </summary>
    /// <param name="unit"></param>
    public void HandleInView(Unit unit)
    {
        if (IsFilterUnit(unit))
            return;
        if (unit.UnitTrans.gameObject.activeSelf)
            return;
        if (!CanShow())
            return;
        UnitMgr unitMgr = UnitMgr.instance;
        if (!IsInView(unit.Position))
            return;
        unitMgr.SetUnitActive(unit, true, true);
        if (!unit.Dead)
            unit.ActionStatus.ChangeIdleAction();
        else
            unit.ActionStatus.ChangeDeathAction();
        if (!mShowIDDic.ContainsKey(unit.UnitUID))
            mShowIDDic.Add(unit.UnitUID, true);
    }

    /// <summary>
    /// 处理出屏单位
    /// </summary>
    /// <param name="unit"></param>
    public void HandleOfView(Unit unit)
    {
        if (IsFilterUnit(unit))
            return;
        if (!mShowIDDic.ContainsKey(unit.UnitUID))
        {
            if (!unit.UnitTrans.gameObject.activeSelf)
                return;
        }
        if (IsInView(unit.Position))
            return;
        UnitMgr unitMgr = UnitMgr.instance;
        unitMgr.SetUnitActive(unit, false, false);
        RmvHit(unit);
        if (mShowIDDic.ContainsKey(unit.UnitUID))
            mShowIDDic.Remove(unit.UnitUID);
    }
    
    /// <summary>
    /// 检查显示
    /// </summary>
    /// <returns></returns>
    public bool CanShow()
    {
        if (mShowIDDic.Count >= MaxShowNum)
            return false;
        return true;
    }

    /// <summary>
    /// 是否在视野内
    /// </summary>
    /// <param name="Pos"></param>
    /// <returns></returns>
    public bool IsInView(Vector3 Pos)
    {
        if (CameraMgr.Main == null)
            return false;
        Transform canTrans = CameraMgr.Main.transform;
        Vector3 viewPos = CameraMgr.Main.WorldToViewportPoint(Pos);
        Vector3 dir = (Pos - canTrans.position).normalized;
        float dot = Vector3.Dot(canTrans.forward, dir);
        if (dot < 0)
            return false;
        Rect rect = new Rect(0, 0, 1, 1);
        if (!rect.Contains(viewPos))
            return false;
        if (viewPos.z < CameraMgr.Main.nearClipPlane)
            return false;
        if (viewPos.z > CameraMgr.Main.farClipPlane)
            return false;
        return true;
    }

    /// <summary>
    /// 添加攻击单位
    /// </summary>
    /// <param name="atker"></param>
    /// <param name="atkee"></param>
    public void AddHit(Unit atker,Unit atkee)
    {
        if (IsFilterUnit(atker))
            AddHitUnit(atkee);
        else if (IsFilterUnit(atkee))
            AddHitUnit(atker);
    }

    public void AddHitUnit(Unit unit)
    {
        UnitHelper helper = UnitHelper.instance;
        if (helper.CanUseUnit(unit))
            return;
        if (mHitInfoDic.ContainsKey(unit.UnitUID))
            mHitInfoDic[unit.UnitUID].Reset();
        else
        {
            HitedInfo info = ObjPool.Instance.Get<HitedInfo>();
            info.SetInfo(unit);
            mHitInfoDic.Add(unit.UnitUID, info);
        }
    }

    /// <summary>
    /// 移除攻击单位
    /// </summary>
    /// <param name="unit"></param>
    public void RmvHit(Unit unit)
    {
        if (unit == null)
            return;
        if (unit.UnitTrans == null)
            return;
        long uid = unit.UnitUID;
        if (!mHitInfoDic.ContainsKey(uid))
            return;
        mHitInfoDic[uid].Dispose();
        mHitInfoDic.Remove(uid);
    }
    #endregion
}
