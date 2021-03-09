using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UnitAutoFight 
{
    public static readonly UnitAutoFight instance = new UnitAutoFight();

    private UnitAutoFight()
    {

    }
    #region ˽�б���
    /// <summary>
    /// �Ƿ��ƶ���
    /// </summary>
    private bool isMoving = false;
    #endregion

    #region ����

    /// <summary>
    /// �Ƿ��ƶ���
    /// </summary>
    public bool IsMoving
    {
        get { return isMoving; }
        set { isMoving = value; }
    }
    #endregion

    #region ˽�з���
    #endregion

    #region ���з���
    /// <summary>
    /// ��Ϊ����
    /// </summary>
    public void ActionUpdate(Unit unit)
    {
        UnitWildRush.instance.Update();
        if (UnitWildRush.instance.Excuting)
            return;
        if (!UnitHelper.instance.CanFight(unit))
        {
            UnitAttackCtrl.instance.Clear();
            return;
        }
        if (IsMoving)
            return;
        //if (UnitAttackCtrl.instance.DelayTimer.Running)
        //    return;
        GameSkill skill = AutoPlaySkill.instance.GetPlaySkill(unit);
        if (skill == null)
            return;
        string actionID = SkillHelper.instance.GetItrptActID(unit, skill);
        if (string.IsNullOrEmpty(actionID))
            return;
        float distance = SkillHelper.instance.GetViewDis(unit);
        Unit target = FightModMgr.instance.GetTarget(unit, distance);
        if (target == null)
        {
            ActivBatMgr.instance.MoveToPos();
            CopyBatMgr.instance.Move();
            return;
        }
        if (!SkillHelper.instance.CanHitSafeMons(target))
            return;
        IsMoving = true;
        UnitAttackCtrl.instance.BeginAttackCtrl(unit, target, skill, actionID, true);
    }

    /// <summary>
    /// �����Զ�ս����ʾ
    /// </summary>
    /// <param name="isAutoFight"></param>
    public void SetAutoFightTip(Unit unit, bool isAutoFight)
    {
        EventMgr.Trigger("OnAutoFight", isAutoFight);
        if (unit == null)
            return;
        unit.mUnitMove.SetAutoPathFindTip(false);
    }
    #endregion
}
