using System.Collections.Generic;

public class UnitSkill
{
    #region ˽�б���
    //�����б�
    private List<GameSkill> mSkills = new List<GameSkill>();
    //�л��ļ���
    private uint switchSkillID = 0;
    #endregion

    #region ����
    /// <summary>
    /// �����б�
    /// </summary>
    public List<GameSkill> Skills
    {
        get { return mSkills; }
        set { mSkills = value; }
    }

    /// <summary>
    /// �л��ļ���
    /// </summary>
    public uint SwitchSkillID
    {
        get { return switchSkillID; }
        set { switchSkillID = value; }
    }
    #endregion

    #region ���з���
    /// <summary>
    /// �Ƿ��м����л�
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
    /// �����л�����
    /// </summary>
    /// <param name="skillID"></param>
    public void SetSwitchSkillID(uint skillID)
    {
        SwitchSkillID = skillID;
    }

    /// <summary>
    /// ������
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
    /// ���ܸ���
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
