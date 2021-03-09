using System.Collections.Generic;

public class UnitSkill
{
    #region 私有变量
    //技能列表
    private List<GameSkill> mSkills = new List<GameSkill>();
    //切换的技能
    private uint switchSkillID = 0;
    #endregion

    #region 属性
    /// <summary>
    /// 技能列表
    /// </summary>
    public List<GameSkill> Skills
    {
        get { return mSkills; }
        set { mSkills = value; }
    }

    /// <summary>
    /// 切换的技能
    /// </summary>
    public uint SwitchSkillID
    {
        get { return switchSkillID; }
        set { switchSkillID = value; }
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 是否有技能切换
    /// </summary>
    /// <param name="iSkillId"></param>
    /// <returns></returns>
    public bool HasSkillInput(int iSkillId)
    {
        if (SwitchSkillID == 0)
            return false;
        if (iSkillId != SwitchSkillID)
            return false;
        SwitchSkillID = 0;
        return true;
    }

    /// <summary>
    /// 设置切换技能
    /// </summary>
    /// <param name="skillID"></param>
    public void SetSwitchSkillID(uint skillID)
    {
        SwitchSkillID = skillID;
    }

    /// <summary>
    /// 处理技能
    /// </summary>
    /// <param name="skillAttr"></param>
    public void ProcessSkill(Unit unit,CurSkillInfo curSkInfo)
    {
        GameSkill gameSkill = SkillManager.instance.FindSkillBySkLvID(unit, curSkInfo.SkLvId);
        if (gameSkill == null)
            return;
        if (gameSkill.isCding)
            return;
        gameSkill.Cast();
    }

    /// <summary>
    /// 技能更新
    /// </summary>
    /// <param name="deltaTime"></param>
    public void Update(float deltaTime)
    {
        for (int i = 0; i < mSkills.Count; ++i)
        {
            mSkills[i].Update(deltaTime);
        }
    }

    public void Dispose()
    {
        mSkills.Clear();
        switchSkillID = 0;
    }
    #endregion
}
