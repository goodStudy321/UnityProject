using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InputMgr
{
    public static readonly InputMgr instance = new InputMgr();

    private InputMgr()
    {

    }
    #region ˽�б���
    /// <summary>
    /// �Ƿ������
    /// </summary>
    private bool mCanInput = true;
    /// <summary>
    /// �Ƿ���ҡ��ģʽ
    /// </summary>
    private bool mJoyStickControlMdl = true;
    #endregion

    #region ���б���
    /// <summary>
    /// �ٿص�λ
    /// </summary>
    public Unit mOwner;

    /// <summary>
    /// ���ǵ�ǰ����Ŀ��
    /// </summary>
    public Unit mLockTarget = null;
    /// <summary>
    /// �ѻ��е�λ�б�
    /// </summary>
    public List<Unit> mHitedList = new List<Unit>();
    /// <summary>
    /// ��ʼ�Զ��һ���һ�̷�Χ�ڵĵ�λ�б�
    /// </summary>
    public List<Unit> mHgupList = new List<Unit>();
    #endregion

    #region ����
    /// <summary>
    /// �Ƿ������
    /// </summary>
    public bool CanInput
    {
        get { return mCanInput; }
        set
        {
            mCanInput = value;
            if (value)
                return;
            StopAllAction();
        }
    }

    /// <summary>
    /// �Ƿ���ҡ��ģʽ
    /// </summary>
    public bool JoyStickControlMdl
    {
        get { return mJoyStickControlMdl; }
        set
        {
            mJoyStickControlMdl = value;
            if (value == true)
                return;
            Reset();
        }
    }
    #endregion

    #region ���з���
    /// <summary>
    /// ��ʼ��
    /// </summary>
    public void Init(Unit unit)
    {
        mOwner = unit;
        KeyInput.instance.Init();
        JoyStickCtrl.instance.Init();
        MSFrameCount.instance.Init();
        HangupMgr.instance.Init(unit);
    }

    /// <summary>
    /// ����
    /// </summary>
    public void Reset()
    {
        InputVectorMove.instance.Clear();
        JoyStickCtrl.instance.Reset();
        KeyInput.instance.Reset();
    }

    /// <summary>
    /// ֹͣ������Ϊ
    /// </summary>
    public void StopAllAction()
    {
        Reset();
        Unit owner = InputVectorMove.instance.MoveUnit;
        if (owner == null)
            return;
        owner.ActionStatus.ChangeIdleAction();
    }

    /// <summary>
    /// ������п�������
    /// </summary>
    public void ClearAllCtrlData()
    {
        //����ҡ��,ֹͣ��Ϊ,ֹͣѰ·
        Unit owner = InputVectorMove.instance.MoveUnit;
        if (owner != null)
            owner.mUnitMove.StopNav();
        StopAllAction();
        mLockTarget = null;
        mHitedList.Clear();
        //����Զ��һ�����
        HangupMgr.instance.ClearInfo();
        //���ս������
        UnitAttackCtrl.instance.Clear();
        UnitWildRush.instance.Clear();
    }

    /// <summary>
    /// �������Ŀ��
    /// </summary>
    public void ClearTarget(bool bClearList = true)
    {
        if (mOwner != null)
        {
            if (mOwner.ActionStatus == null) return;
            if (mOwner.ActionStatus.FTtarget != null)
                mOwner.ActionStatus.FTtarget = null;
        }
        if (bClearList) mHitedList.Clear();
        if (mLockTarget == null) return;
        mLockTarget = null;
    }

    public void Clear(bool all = true)
    {
        ClearAllCtrlData();
        ClearTarget();
        mCanInput = true;
        if (!all)
            return;
        mOwner = null;
    }

    public void Update()
    {
        if (!CanInput)
            return;
        JoyStickCtrl.instance.Update();
        InputVectorMove.instance.Update();
        UnitAttackCtrl.instance.UpdateAttackAction();
        //mKeyInput.UpdateKeyStatus(Time.deltaTime);
    }
    #endregion
}
