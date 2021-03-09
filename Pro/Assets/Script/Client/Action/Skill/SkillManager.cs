using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class SkillManager
{
    public static readonly SkillManager instance = new SkillManager();

    private SkillManager()
    {

    }
    #region 私有变量
    #endregion

    #region 属性
    #endregion

    #region 公有方法
    /// <summary>
    /// 添加技能
    /// </summary>
    public void AddSkill(Unit unit, uint skLvID, float cdTime)
    {
        GameSkill oldSkill = FindSkillBySkillId(unit, skLvID/1000);
        if (oldSkill != null)
        {
            oldSkill.Init(skLvID, cdTime);
            return;
        }
        GameSkill skill = new GameSkill();
        skill.Init(skLvID, cdTime);
        unit.mUnitSkill.Skills.Add(skill);
        if (unit != UISkill.instance.Owner)
            return;
        UISkill.instance.SetSkills(skill);
    }

    /// <summary>
    /// 删除技能
    /// </summary>
    public void RemoveSkill(Unit unit, uint skLvID)
    {
        GameSkill skill = FindSkillBySkLvID(unit, skLvID);
        if (skill != null)
            unit.mUnitSkill.Skills.Remove(skill);
    }

    /// <summary>
    /// 清理所有技能
    /// </summary>
    public void DisposeSkills(Unit unit)
    {
        if (unit == null)
            return;
        unit.mUnitSkill.Skills.Clear();
    }

    /// <summary>
    /// 查找技能
    /// </summary>
    public GameSkill FindSkillBySkLvID(Unit unit, uint skLvID)
    {
        List<GameSkill> skills = unit.mUnitSkill.Skills;
        for (int i = 0; i < skills.Count; i++)
        {
            if (skills[i].SkillLevelID != skLvID)
                continue;
            return skills[i];
        }
        return null;
    }

    /// <summary>
    /// 根据技能Id查找技能
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="skID"></param>
    /// <returns></returns>
    public GameSkill FindSkillBySkillId(Unit unit, uint skID)
    {
        List<GameSkill> skills = unit.mUnitSkill.Skills;
        for (int i = 0; i < skills.Count; i++)
        {
            if (skills[i].SkillID != skID )
                continue;
            return skills[i];
        }
        return null;
    }

    /// <summary>
    /// 初始化玩家自己技能
    /// </summary>
    public void InitSkill(Unit unit)
    {
        List<Phantom.Protocal.p_skill> skillInfoList = User.instance.MapData.SkillInfoList;
        if (skillInfoList == null)
            return;
        if (skillInfoList.Count == 0)
            return;
        DisposeSkills(unit);

        for (int i = 0; i < skillInfoList.Count; i++)
        {
            float cdTime = 0;
            long serverTime = (long)TimeTool.GetServerTimeNow();
            long time = skillInfoList[i].time - serverTime;
            time /= 1000;
            if (time > 0)
                cdTime = time;
            AddSkill(unit, (uint)skillInfoList[i].skill_id, cdTime);
        }
    }

    /// <summary>
    /// 修改技能目标数量
    /// </summary>
    /// <param name="skillLvId"></param>
    /// <param name="tarNum">攻击目标数量</param>
    public void MdfSkTarNum(uint skillId,int tarNum)
    {
        Unit unit = InputMgr.instance.mOwner;
        if (unit == null)
            return;
        GameSkill skill = FindSkillBySkillId(unit, skillId);
        if (skill == null)
            return;
        skill.SetAddTarNum(tarNum);
    }

    /// <summary>
    /// 修改技能CD
    /// </summary>
    /// <param name="skillId"></param>
    /// <param name="reduceTime">缩减时间</param>
    public void MdfSkCD(uint skillId,int reduceTime)
    {
        Unit unit = InputMgr.instance.mOwner;
        if (unit == null)
            return;
        GameSkill skill = FindSkillBySkillId(unit, skillId);
        if (skill == null)
            return;
        skill.ReduceCD(reduceTime);
    }

    /// <summary>
    /// 播放没有动作技能
    /// </summary>
    /// <param name="unit"></param>
    /// /// <param name="targetId"></param>
    /// <param name="skillLvId"></param>
    public void PlayNoActSkill(Unit unit, long targetId, int skillLvId, int addTarNum)
    {
        if (!UnitHelper.instance.CanUseUnit(unit))
            return;
        ActionStatus ats = unit.ActionStatus;
        if (ats == null)
            return;
        string actionId = SkillHelper.instance.GetActIDFTbl((uint)skillLvId);
        if (string.IsNullOrEmpty(actionId))
            return;
        actionId = "W" + actionId;
        ProtoBuf.ActionData actData = ActionHelper.GetActionByID(ats.ActionGroupData, actionId);
        if (actData == null)
            return;
        int count = actData.EventList.Count;
        if (count == 0)
            return;
        for (int i = 0; i < count; i++)
        {
            ProtoBuf.ActionEventData actEventData = actData.EventList[i];
            ProtoBuf.EventData data = actEventData.EventDetailData;
            ActionCommon.EventType eType = (ActionCommon.EventType)data.EventType;
            if (eType != ActionCommon.EventType.AddUnit)
                continue;
            if (data.UnitID == 0)
                continue;
            Vector3 targetPos = unit.Position;
            if (targetId != 0)
            {
                Unit target = UnitMgr.instance.FindUnitByUid(targetId);
                if(target != null)
                    targetPos = target.Position;
            }
            SummonUnitEvent smnEvt = new SummonUnitEvent(data, targetPos, unit);
            smnEvt.SetAddTarNum(addTarNum);
            GameEventManager.instance.EnQueue(smnEvt);
        }
    }
    #endregion
}
