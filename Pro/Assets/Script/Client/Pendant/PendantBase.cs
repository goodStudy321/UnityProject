using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class PendantBase : IPendant
{
    #region ˽���ֶ�
    #endregion

    #region �����ֶ�
    /// <summary>
    /// ��λ����ID
    /// </summary>
    protected uint mUnitTypeId;
    /// <summary>
    /// ��λ����Id
    /// </summary>
    protected uint mBaseId;
    
    /// <summary>
    /// ���ص�
    /// </summary>
    protected MountPoint mMountPoint;
    /// <summary>
    /// ���ص�λ����
    /// </summary>
    protected Unit mMtpParent;
    /// <summary>
    /// �������Լ�
    /// </summary>
    protected Unit mOwner;
    /// <summary>
    /// �ƶ�λ���б�
    /// </summary>
    protected List<Vector3> mMovePosList = new List<Vector3>();
    #endregion

    #region ����
    /// <summary>
    /// �Ҽ���̬
    /// </summary>
    public PendantStateEnum mState;

    /// <summary>
    /// ���ﱳ��λ��
    /// </summary>
    public Vector3 BackPos
    {
        get
        {
            Vector3 pos = mMtpParent.Position + mMtpParent.UnitTrans.forward * (-1f);
            pos.y += 1;
            RaycastHit hit;
            Ray ray = new Ray(pos, Vector3.down);
            if (Physics.Raycast(ray, out hit, 10, 1 << Loong.Game.LayerTool.Ground))
                pos = hit.point;
            return pos;
        }
    }
    #endregion

    #region ��������
    /// <summary>
    /// ��ȡ����
    /// </summary>
    /// <param name="srcPos"></param>
    /// <param name="desPos"></param>
    /// <returns></returns>
    protected Vector3 GetForward(Vector3 srcPos, Vector3 desPos)
    {
        srcPos.y = desPos.y = 0;
        Vector3 forward = desPos - srcPos;
        return forward.normalized;
    }

    /// <summary>
    /// �����ƶ�����
    /// </summary>
    protected int GetMoveIndex()
    {
        int index = Random.Range(0, mMovePosList.Count);
        return index;
    }
    #endregion

    #region ���з���
    /// <summary>
    /// ����
    /// </summary>
    public virtual Unit PutOn(Unit mtpParent, uint unitTypeId, PendantStateEnum state,ActorData data = null)
    {
        mUnitTypeId = unitTypeId;
        mBaseId = unitTypeId / 100;
        mState = state;
        mMtpParent = mtpParent;
        return mOwner;
    }

    /// <summary>
    /// ����
    /// </summary>
    /// <param name="pendant"></param>
    public virtual void TakeOff(ActorData data)
    {
        if (mOwner.UnitTrans == null)
            return;
        mOwner.UnitTrans.parent = null;
    }

    /// <summary>
    /// ��Ӽ���
    /// </summary>
    public void AddSkills(List<Phantom.Protocal.p_skill> pSkillList)
    {
        if (mOwner == null)
            return;
        if (pSkillList == null)
            return;
        if (pSkillList.Count == 0)
            return;
        mOwner.mUnitSkill.Skills.Clear();
        for (int i = 0; i < pSkillList.Count; i++)
        {
            float cdTime = 0;
            long serverTime = (long)TimeTool.GetServerTimeNow();
            var skill = pSkillList[i];
            if (skill == null) continue;
            long time = skill.time - serverTime;
            time /= 1000;
            if (time > 0)
                cdTime = time;
            SkillManager.instance.AddSkill(mOwner, (uint)skill.skill_id, cdTime);
        }
    }
    
    /// <summary>
    /// ����λ��
    /// </summary>
    /// <param name="mountParent"></param>
    /// <param name="pendant"></param>
    public virtual void SetPosition()
    {
        if (UnitHelper.instance.UnitIsNull(mOwner))
            return;
        if (UnitHelper.instance.UnitIsNull(mMtpParent))
            return;
        Transform parent = GetParent(mMtpParent);
        TransTool.AddChild(parent, mOwner.UnitTrans);
    }
    
    /// <summary>
    /// �ı�Ľ�����
    /// </summary>
    public void ChangePendantAction(Unit pendant, PendantStateEnum state)
    {
        if (pendant == null)
            return;
        if (pendant.ActionStatus == null)
            return;
        string animationName = null;
        mState = state;
        if (state == PendantStateEnum.Normal)
            animationName = "F0001";
        else if (state == PendantStateEnum.Fighting)
            animationName = "F0000";
        pendant.ActionStatus.ChangeAction(animationName, 0);
    }

    /// <summary>
    /// ������ʾ״̬
    /// </summary>
    public virtual void SetShowState(PendantSystemEnum sEnum)
    {
        if (mMtpParent == null)
            return;
        Transform trans = mMtpParent.UnitTrans;
        if (trans == null)
            return;
        if (trans.gameObject.activeSelf)
            return;
        mOwner.UnitTrans.gameObject.SetActive(false);
    }

    /// <summary>
    /// �ı�ս��ģʽ
    /// </summary>
    public virtual void SetFightType()
    {
        if (mMtpParent == null)
            return;
        if (mOwner == null)
            return;
        mOwner.FightType = mMtpParent.FightType;
    }

    /// <summary>
    /// ����
    /// </summary>
    public virtual void Update()
    {

    }
    #endregion

    #region ��������
    /// <summary>
    /// ��ȡ���ڵ�
    /// </summary>
    /// <param name="parentUnit"></param>
    /// <returns></returns>
    protected virtual Transform GetParent(Unit parentUnit)
    {
        if (!PendantMgr.instance.MountPointDic.ContainsKey(mMountPoint))
            return null;
        if (mMountPoint == MountPoint.Root)
            return parentUnit.UnitTrans;
        string mountPoint = PendantMgr.instance.MountPointDic[mMountPoint];
        Transform parent = Utility.FindNode<Transform>(parentUnit.UnitTrans.gameObject, mountPoint);
        return parent;
    }
    /// <summary>
    /// ǰ������
    /// </summary>
    /// <returns></returns>
    protected virtual bool PreCondition(PendantSystemEnum pdsEnum)
    {
        if (mMtpParent == null)
            return false;
        if (mMtpParent.UnitTrans == null)
            return false;
        if (mOwner == null)
            return false;
        if (mOwner.UnitTrans == null)
            return false;
        if (!mOwner.UnitTrans.gameObject.activeSelf)
            return false;
        if (mMtpParent.Dead)
        {
            PendantMgr.instance.SetPendantActive(mOwner, false);
            return false;
        }
        if (mOwner.ActionStatus == null)
            return false;
        return true;
    }

    /// <summary>
    /// �Ƿ��ڸ��������
    /// </summary>
    /// <param name="followPos"></param>
    /// <param name="followDisSqr"></param>
    /// <returns></returns>
    protected bool InFollowDistance(Vector3 followPos, float followDisSqr)
    {
        followPos.y = mOwner.Position.y;
        Vector3 dir = followPos - mOwner.Position;
        float dis = Vector3.SqrMagnitude(dir);
        if (dis > followDisSqr)
            return false;
        return true;
    }

    /// <summary>
    /// ���ó־û�
    /// </summary>
    /// <param name="go"></param>
    /// <param name="modelName"></param>
    protected void SetPersist(GameObject go, string modelName)
    {
        if (!UnitHelper.instance.IsOwner(mMtpParent))
            return;
        UnityEngine.Object.DontDestroyOnLoad(go);
        AssetMgr.Instance.SetPersist(modelName, Suffix.Prefab);
    }
    #endregion
}
