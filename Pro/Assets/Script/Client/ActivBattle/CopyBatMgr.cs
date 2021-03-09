using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CopyBatMgr
{
    public static readonly CopyBatMgr instance = new CopyBatMgr();
    private CopyBatMgr() { }
    #region ˽���ֶ�
    /// <summary>
    /// ������λ
    /// </summary>
    private Unit mOwner;
    /// <summary>
    /// ��λ������
    /// </summary>
    private Vector3 mNoPos = new Vector3(100000, 0, 100000);
    /// <summary>
    /// Ŀ���
    /// </summary>
    private Vector3 mDesPos = new Vector3(100000,0,100000);
    #endregion

    #region ˽�з���
    /// <summary>
    /// ��������
    /// </summary>
    /// <returns></returns>
    private bool SceneCon()
    {
        GameSceneType curSType = (GameSceneType)GameSceneManager.instance.CurSceneType;
        if (curSType != GameSceneType.GST_Copy)
            return false;
        return true;
    }

    /// <summary>
    /// ��鶯��״̬
    /// </summary>
    /// <returns></returns>
    private bool CanChangeMoveState()
    {
        if (mDesPos == mNoPos)
            return false;
        if (mOwner == null)
            return false;
        if (mOwner.Mount != null)
        {
            if (IsCanMove(mOwner.Mount))
                return true;
        }
        return IsCanMove(mOwner);
    }

    /// <summary>
    /// �Ƿ�����ƶ�
    /// </summary>
    /// <param name="unit"></param>
    /// <returns></returns>
    private bool IsCanMove(Unit unit)
    {
        if (unit == null)
            return false;
        if (unit.ActionStatus == null)
            return false;
        ActionStatus.EActionStatus actionState = unit.ActionStatus.ActionState;
        if (actionState == ActionStatus.EActionStatus.EAS_Move)
            return false;
        if (actionState == ActionStatus.EActionStatus.EAS_Dead)
            return false;
        if (actionState == ActionStatus.EActionStatus.EAS_Attack)
            return false;
        else if (actionState == ActionStatus.EActionStatus.EAS_Skill)
            return false;
        return true;
    }

    /// <summary>
    /// ��Ŀ�ĵ��ƶ�
    /// </summary>
    private void MoveToDesPos()
    {
        if (mDesPos == mNoPos)
            return;
        Vector3 srcPos = mOwner.Position;
        srcPos.y = mDesPos.y;
        float dis = Vector3.Distance(srcPos, mDesPos);
        float stopDis = 0.5f;
        if (dis <= stopDis)
            return;
        mOwner.mUnitMove.StartNav(mDesPos,stopDis);
    }
    
    #endregion

    #region ���з���
    /// <summary>
    /// ��ʼ��
    /// </summary>
    public void Init(Unit unit)
    {
        if (!SceneCon())
            return;
        mDesPos = mNoPos;
        mOwner = unit;
    }

    /// <summary>
    /// ����Ŀ���
    /// </summary>
    /// <param name="startX"></param>
    /// <param name="startZ"></param>
    /// <param name="endX"></param>
    /// <param name="endZ"></param>
    public void SetDesPos(float startX, float startZ, float endX, float endZ)
    {
        startX = startX * 0.01f;
        startZ = startZ * 0.01f;
        endX = endX * 0.01f;
        endZ = endZ * 0.01f;
        float midX = (startX + endX) / 2;
        float midZ = (startZ + endZ) / 2;
        mDesPos.x = midX;
        mDesPos.z = midZ;
    }

    /// <summary>
    /// �ƶ�
    /// </summary>
    public void Move()
    {
        if (!SceneCon())
            return;
        if (!CanChangeMoveState())
            return;
        MoveToDesPos();
    }
    #endregion
}
