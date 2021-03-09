using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class MSFrameCount
{
    public static readonly MSFrameCount instance = new MSFrameCount();

    private MSFrameCount()
    {

    }
    #region ˽���ֶ�
    /// <summary>
    /// ��ʱ���ֵ�
    /// </summary>
    private Dictionary<SendMoveType, Timer> mTimerDic = new Dictionary<SendMoveType, Timer>();

    #endregion

    #region ˽�б���
    
    #endregion

    #region ���з���
    /// <summary>
    /// ��ʼ��
    /// </summary>
    public void Init()
    {
        ClearTimerDic();
        Timer timer = ObjPool.Instance.Get<Timer>();
        mTimerDic.Add(SendMoveType.SendMoveRoleWalk, timer);
        timer = ObjPool.Instance.Get<Timer>();
        mTimerDic.Add(SendMoveType.SendMovePoint, timer);
        timer = ObjPool.Instance.Get<Timer>();
        mTimerDic.Add(SendMoveType.SendStickMove, timer);
        StartTimer(SendMoveType.SendMoveRoleWalk);
        StartTimer(SendMoveType.SendMovePoint);
    }

    /// <summary>
    /// �����ʱ���ֵ�
    /// </summary>
    public void ClearTimerDic()
    {
        foreach(KeyValuePair<SendMoveType, Timer> item in mTimerDic)
            item.Value.AutoToPool();
        mTimerDic.Clear();
    }

    /// <summary>
    /// ��ʼ��ʱ��
    /// </summary>
    /// <param name="smType"></param>
    public void StartTimer(SendMoveType smType)
    {
        if (!mTimerDic.ContainsKey(smType))
            return;
        Timer timer = mTimerDic[smType];
        if (timer.Running)
            timer.Stop();
        if (smType == SendMoveType.SendStickMove)
            timer.Seconds = 0.2f;
        else
            timer.Seconds = 0.5f;
        timer.Start();
    }

    /// <summary>
    /// ֹͣ��ʱ��
    /// </summary>
    /// <param name="smType"></param>
    public void StopTimer(SendMoveType smType)
    {
        if (!mTimerDic.ContainsKey(smType))
            return;
        Timer timer = mTimerDic[smType];
        if (!timer.Running)
            return;
        timer.Stop();
    }

    /// <summary>
    /// �Ƿ���Է���·��
    /// </summary>
    public bool CanSendPoint(SendMoveType smType)
    {
        if (!mTimerDic.ContainsKey(smType))
            return false;
        if (mTimerDic[smType].Running)
            return false;
        StartTimer(smType);
        return true;
    }
    #endregion
}
