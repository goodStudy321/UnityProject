using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public class AutoPlaySkill
{
    public static readonly AutoPlaySkill instance = new AutoPlaySkill();
    private AutoPlaySkill() { }

    #region 私有字段
    /// <summary>
    /// 播放顺序列表
    /// </summary>
    List<uint> mPlayOrderList = new List<uint>();
    /// <summary>
    /// 普通攻击Id
    /// </summary>
    uint mNorSkId;
    #endregion

    #region 私有方法
    /// <summary>
    /// 设置普通攻击
    /// </summary>
    /// <param name="skId"></param>
    private void SetNorSkill(uint skId)
    {
        mNorSkId = skId / 1000;
    }
    /// <summary>
    /// 获取技能
    /// </summary>
    /// <param name="attacker"></param>
    /// <returns></returns>
    private GameSkill GetSkill(Unit attacker)
    {
        if (attacker.mUnitBuffStateInfo.IsForbitSkillAttack)
            return null;
        List<GameSkill> skills = attacker.mUnitSkill.Skills;
        for (int i = 0; i < mPlayOrderList.Count; i++)
        {
            uint skId = mPlayOrderList[i];
            GameSkill skill = skills.Find(sk => sk.SkillID == skId / 1000);
            if (skill == null)
                continue;
            if (AutoFbSkills.instance.CheckFb(attacker, skId))
                continue;
            SkillEnum skillType = (SkillEnum)skill.SkillLevelAttrTable.type;
            if (skillType == SkillEnum.passtive)
                continue;
            if (skill.isCding)
                continue;
            return skill;
        }
        return null;
    }

    /// <summary>
    /// 获取普通攻击
    /// </summary>
    /// <param name="attacker"></param>
    /// <returns></returns>
    private GameSkill GetNorAtk(Unit attacker)
    {
        if (attacker.mUnitBuffStateInfo.IsForbitNormalAttack)
            return null;
        for(int i = 0; i < attacker.mUnitSkill.Skills.Count; i++)
        {
            GameSkill skill = attacker.mUnitSkill.Skills[i];
            if (skill == null)
                continue;
            if (skill.SkillID != mNorSkId)
                continue;
            if (skill.isCding)
                continue;
            return skill;
        }
        return null;
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 初始化
    /// </summary>
    public void Init()
    {
        AddEvent();
    }

    /// <summary>
    /// 添加事件监听
    /// </summary>
    public void AddEvent()
    {
        EventMgr.Add("SkillPlayOrder", AddToList);
    }

    /// <summary>
    /// 增加技能
    /// </summary>
    /// <param name="skId"></param>
    public void AddSkill(uint skId)
    {
        SkillLevelAttr skLvInfo = SkillLevelAttrManager.instance.Find(skId);
        if (skLvInfo == null)
            return;
        SkillEnum skillType = (SkillEnum)skLvInfo.type;
        if (skillType == SkillEnum.passtive)
            return;
        if (skillType == SkillEnum.NormalAtk)
            SetNorSkill(skId);
        else
            EventMgr.Trigger("AddSkill", skId);
    }

    /// <summary>
    /// 移除技能
    /// </summary>
    /// <param name="skId"></param>
    public void RemoveSkill(uint skId)
    {
        EventMgr.Trigger("RemoveSkill", skId);
    }
    
    /// <summary>
    /// 添加到顺序列表
    /// </summary>
    /// <param name="agrs"></param>
    public void AddToList(params object[] agrs)
    {
        if (agrs == null)
            return;
        if (agrs.Length < 2)
            return;
        int index = Convert.ToInt32(agrs[0]);
        index -= 1;
        uint skId = Convert.ToUInt32(agrs[1]);
        if(index < mPlayOrderList.Count)
            mPlayOrderList[index] = skId;
        else
            mPlayOrderList.Add(skId);
    }

    /// <summary>
    /// 获取可释放技能
    /// </summary>
    /// <param name="attacker"></param>
    /// <returns></returns>
    public GameSkill GetPlaySkill(Unit attacker)
    {
        if (attacker == null)
            return null;
        GameSkill skill = GetSkill(attacker);
        if (skill != null)
            return skill;
        skill = GetNorAtk(attacker);
        return skill;
    }

    /// <summary>
    /// 清除数据
    /// </summary>
    public void Clear()
    {
        mPlayOrderList.Clear();
        mNorSkId = 0;
    }
    #endregion
}
