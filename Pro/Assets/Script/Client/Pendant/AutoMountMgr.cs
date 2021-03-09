using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class AutoMountMgr
{
    public static readonly AutoMountMgr instance = new AutoMountMgr();

    private AutoMountMgr()
    {
        mTimer = ObjPool.Instance.Get<Timer>();
    }
    #region ˽���ֶ�
    /// <summary>
    /// ��ʱ��
    /// </summary>
    private Timer mTimer;
    #endregion

    #region ˽�з���
    /// <summary>
    /// ʱ�����
    /// </summary>
    private void TimeOut()
    {
        Unit unit = InputMgr.instance.mOwner;
        if (unit == null)
            return;
        mTimer.complete -= TimeOut;
        StopTimer(unit);
        if (unit.Mount != null)
            return;
        PendantMgr.instance.RequestShowMount();
    }
    #endregion

    #region ���з���
    /// <summary>
    /// ����ʱ��
    /// </summary>
    public void StartTimer(Unit unit)
    {
        CopyType copyType = GameSceneManager.instance.CurCopyType;
        if (copyType == CopyType.Offl1v1)
            return;
        if (PendantHelper.instance.FbPdt(PendantSystemEnum.Mount))
            return;
        int systemId = (int)PendantSystemEnum.Mount;
        if (!User.instance.SystemOpenList.Contains(systemId))
            return;
        if (unit == null)
            return;
        if (unit != InputMgr.instance.mOwner)
            return;
        if (mTimer == null)
            return;
        if (mTimer.Running)
            return;
        mTimer.Seconds = 1.5f;
        mTimer.complete += TimeOut;
        mTimer.Start();
    }

    /// <summary>
    /// ֹͣʱ��
    /// </summary>
    public void StopTimer(Unit unit)
    {
        if (unit == null)
            return;
        if (unit != InputMgr.instance.mOwner)
            return;
        if (mTimer == null)
            return;
        if (!mTimer.Running)
            return;
        mTimer.complete -= TimeOut;
        mTimer.Stop();
    }
    #endregion
}
