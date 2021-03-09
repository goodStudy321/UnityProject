using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public class OffLineBatMgr
{
    public static readonly OffLineBatMgr instance = new OffLineBatMgr();
    private OffLineBatMgr() { }

    #region �¼�����
    public static void AddSlOfflListener()
    {
        EventMgr.Add(EventKey.ChallengeRole, ChallengeRole);
        EventMgr.Add(EventKey.EGToCSharp, EndGame);
    }

    public static void RemoveSlOfflListener()
    {
        EventMgr.Remove(EventKey.ChallengeRole, ChallengeRole);
        EventMgr.Remove(EventKey.EGToCSharp, EndGame);
    }
    #endregion
    #region ˽�б���
    /// <summary>
    /// ��λ����ս���б�
    /// </summary>
    private List<UnitOfflBat> mOffLBatLst = new List<UnitOfflBat>();
    /// <summary>
    /// ����ս��Id
    /// </summary>
    private static long mClgRoleId;
    /// <summary>
    /// ����ս��ս��
    /// </summary>
    private static float mClgFightVal;
    /// <summary>
    /// ����ս��
    /// </summary>
    private static Unit mClgUnit = null;
    #endregion

    #region ����
    #endregion

    #region ˽�з���
    /// <summary>
    /// ����ս������ǰ������
    /// </summary>
    /// <returns></returns>
    private bool PreCondition()
    {
        if (GameSceneManager.instance.SceneLoadState != SceneLoadStateEnum.SceneDone)
            return false;
        if (!SceneCon())
            return false;
        if (!MapPathMgr.instance.MapInit)
            return false;
        if (!User.instance.MapData.HasInitPos)
            return false;
        if (CutscenePlayMgr.instance.IsPlaying)
            return false;
        return true;
    }

    /// <summary>
    /// ��������
    /// </summary>
    /// <returns></returns>
    private bool SceneCon()
    {
        if (GameSceneManager.instance.CurCopyType == CopyType.Offl1v1)
            return true;
        if (GameSceneManager.instance.MapSubType == SceneSubType.OffL1V1Map)
            return true;
        return false;
    }

    /// <summary>
    /// ��Ӿ�������ս��1v1
    /// </summary>
    /// <returns></returns>
    private bool AddBatOTO(Unit unit)
    {
        if (GameSceneManager.instance.CurCopyType != CopyType.Online1v1)
            return false;
        long uid = User.instance.MapData.UID;
        if (unit.UnitUID == uid)
        {
            int level = User.instance.MapData.Level;
            EventMgr.Trigger(EventKey.AddOffLUnit, unit.UnitUID, unit.Name, unit.Category, level, unit.MaxHP, unit.FightVal);
        }
        else
        {
            int level = 0;
            if (User.instance.OtherRoleDic[unit.UnitUID] != null)
                level = User.instance.OtherRoleDic[unit.UnitUID].Level;
            EventMgr.Trigger(EventKey.AddOffLUnit, unit.UnitUID, unit.Name, unit.Category, level, unit.MaxHP, unit.FightVal);
        }
        return true;
    }

    /// <summary>
    /// �����б�
    /// </summary>
    private void UpdateList()
    {
        int count = mOffLBatLst.Count;
        if (count == 0)
            return;
        for (int i = 0; i < count; i++)
            mOffLBatLst[i].Update();
    }

    /// <summary>
    /// ֹͣѰ·
    /// </summary>
    /// <param name="unit"></param>
    private static void StopNav(Unit unit)
    {
        if (unit == null)
            return;
        unit.mUnitMove.StopNav();
    }
    #endregion

    #region ���з���
    /// <summary>
    /// ������ս��λ��Ϣ
    /// </summary>
    /// <param name="args"></param>
    public static void ChallengeRole(params object[] args)
    {
        if (args == null || args.Length == 0)
            return;
        mClgRoleId = Convert.ToInt64(args[0]);
        mClgFightVal = Convert.ToSingle(args[1]);
    }
    /// <summary>
    /// ������ߵ�λ����
    /// </summary>
    /// <param name="unit"></param>
    public void AddBatControl(Unit unit)
    {
        if (AddBatOTO(unit))
            return;
        if (!SceneCon())
            return;
        UnitOfflBat unitOffBat = new UnitOfflBat();
        unitOffBat.Init(unit);
        
        mOffLBatLst.Add(unitOffBat);

        if (unit.UnitUID != mClgRoleId)
        {
            int level = User.instance.MapData.Level;
            EventMgr.Trigger(EventKey.AddOffLUnit, unit.UnitUID, unit.Name, unit.Category, level, unit.MaxHP, unit.FightVal);
            PendantMgr.instance.RequestHideMount();
            PendantMgr.instance.SetLocalPendantShowState(unit, PendantSystemEnum.Pet, false);
        }
        else
        {
            mClgUnit = unit;
            unit.FightVal = mClgFightVal;
            int level = 0;
            if (User.instance.OtherRoleDic[unit.UnitUID] != null)
                level = User.instance.OtherRoleDic[unit.UnitUID].Level;
            EventMgr.Trigger(EventKey.AddOffLUnit, unit.UnitUID, unit.Name, unit.Category, level, unit.MaxHP, unit.FightVal);
        }
    }

    /// <summary>
    /// �����������
    /// </summary>
    /// <param name="args"></param>
    public static void EndGame(params object[] args)
    {
        if (args == null || args.Length == 0)
            return;
        bool isWin = Convert.ToBoolean(args[0]);
        Unit owner = InputMgr.instance.mOwner;
        if (!isWin)
        {
            UnitMgr.instance.SetUnitDead(owner);
            StopNav(mClgUnit);
        }
        else
        {
            UnitMgr.instance.SetUnitDead(mClgUnit);
            StopNav(owner);
        }
        OffLineBatMgr.instance.Clear();
    }

    /// <summary>
    /// ��������1v1Ѫ��ͬ��
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="attackee"></param>
    public void SetOffineBatHp(Unit attacker, Unit attackee)
    {
        if (GameSceneManager.instance.CurCopyType != CopyType.Online1v1)
            return;
        EventMgr.Trigger(EventKey.ChangeOffLInfo, false, attackee.UnitUID.ToString(), attackee.HP);
    }

    /// <summary>
    /// ��������
    /// </summary>
    public void Update()
    {
        if (!PreCondition())
            return;
        UpdateList();
    }

    /// <summary>
    /// �������
    /// </summary>
    public void Clear()
    {
        mOffLBatLst.Clear();
        mClgRoleId = 0;
        mClgFightVal = 0;
        mClgUnit = null;
        Global.Mode = PlayMode.Network;
    }
    #endregion
}
