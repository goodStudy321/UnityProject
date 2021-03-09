using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class LockTarMgr
{
    public static readonly LockTarMgr instance = new LockTarMgr();
    private LockTarMgr() { }
    #region �ֶ�
    /// <summary>
    /// ��ʾĿ��
    /// </summary>
    private Unit mShowTar = null;
    private TopBarBase mTopBar = null;
    #endregion

    #region ����
    #endregion

    #region ˽�з���
    /// <summary>
    /// boss�淨��ͼ
    /// </summary>
    /// <returns></returns>
    private bool CanShowRoleBar()
    {
        int sceneId = User.instance.SceneId;
        GlobalData gdata = GlobalDataManager.instance.Find(83);
        if (gdata == null)
            return false;
        List<uint> list = gdata.num2.list;
        if (list == null)
            return false;
        int count = list.Count;
        if (count == 1 && list[0] == 99999)
            return true;
        for(int i = 0; i < count; i++)
        {
            if (list[i] != sceneId)
                continue;
            return true;
        }
        return false;
    }
    /// <summary>
    /// �ͷž�ͷ��
    /// </summary>
    /// <param name="target"></param>
    private void DisOldBar(Unit target)
    {
        if (target == null)
            return;
        UnitType tarType = target.mUnitAttInfo.UnitType;
        if (tarType == UnitType.Role)
        {
            Clear();
            if (target.HeadBar == null)
                return;
            target.HeadBar.Dispose();
            target.HeadBar = null;
        }
        else if(tarType == UnitType.Boss)
        {
            Clear();
            if (target.TopBar == null)
                return;
            target.TopBar.Dispose();
            target.TopBar = null;
        }
    }

    /// <summary>
    /// �������
    /// </summary>
    private void Clear()
    {
        mTopBar = null;
        mShowTar = null;
    }

    /// <summary>
    /// ���¾���
    /// </summary>
    private void UpdateDis()
    {
        if (mShowTar == null)
            return;
        Unit unit = InputVectorMove.instance.MoveUnit;
        if (unit == null)
            return;
        float disSqr = Vector3.SqrMagnitude(unit.Position - mShowTar.Position);
        if (disSqr < 40000)
            return;
        InputMgr.instance.mLockTarget = null;
        DisOldBar(mShowTar);
    }

    /// <summary>
    /// ������Ϣ��
    /// </summary>
    /// <param name="target"></param>
    private void CreateBar(Unit target)
    {
        UnitType tarType = target.mUnitAttInfo.UnitType;
        if(tarType == UnitType.Role)
            mTopBar = UnitHeadBar.Create(target, target.Name);
        else
            mTopBar = TopBarFty.Create(target, target.Name);
        mShowTar = target;
    }

    /// <summary>
    /// �Ƚ�������ʾĿ��
    /// </summary>
    /// <param name="target"></param>
    private void CompairShowTar(Unit target)
    {
        if (mTopBar == null)
            CreateBar(target);
        else
        {
            if (target.UnitUID == mShowTar.UnitUID)
                return;
            DisOldBar(mShowTar);
            CreateBar(target);
        }
    }

    /// <summary>
    /// ������ʾ��UI
    /// </summary>
    private void CreateShowBarUI(Unit target)
    {
        if (mShowTar == null)
            CreateBar(target);
        else
        {
            Unit lockTar = InputMgr.instance.mLockTarget;
            if (lockTar == null)
            {
                CompairShowTar(target);
            }
            else
            {
                if (target.UnitUID != lockTar.UnitUID)
                    return;
                CompairShowTar(target);
            }
        }
    }
    #endregion

    #region ���з���
    /// <summary>
    /// ��������Ŀ��ͷ����
    /// </summary>
    /// <param name="target"></param>
    /// <param name="name"></param>
    public void CrtLockTopBar(Unit target, string name)
    {
        if (target == null)
            return;
        UnitType tarType = target.mUnitAttInfo.UnitType;
        if (tarType == UnitType.Role)
        {
            if (!CanShowRoleBar())
                return;
            CreateShowBarUI(target);
        }
        else if (tarType == UnitType.Boss)
            CreateShowBarUI(target);
        else
            TopBarFty.Create(target, target.Name);
    }

    /// <summary>
    /// �ͷ�
    /// </summary>
    /// <param name="target"></param>
    public void DisTopBar(Unit target)
    {
        if (target == null)
            return;
        if (mShowTar == null)
            return;
        if (target.UnitUID != mShowTar.UnitUID)
            return;
        DisOldBar(target);
    }
    public void Update()
    {
        UpdateDis();
    }
    #endregion
}
