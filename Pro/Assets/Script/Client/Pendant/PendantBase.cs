using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class PendantBase : IPendant
{
    #region 私有字段
    #endregion

    #region 保护字段
    /// <summary>
    /// 单位类型ID
    /// </summary>
    protected uint mUnitTypeId;
    /// <summary>
    /// 单位基础Id
    /// </summary>
    protected uint mBaseId;
    
    /// <summary>
    /// 挂载点
    /// </summary>
    protected MountPoint mMountPoint;
    /// <summary>
    /// 挂载单位父体
    /// </summary>
    protected Unit mMtpParent;
    /// <summary>
    /// 挂载体自己
    /// </summary>
    protected Unit mOwner;
    /// <summary>
    /// 移动位置列表
    /// </summary>
    protected List<Vector3> mMovePosList = new List<Vector3>();
    #endregion

    #region 属性
    /// <summary>
    /// 挂件形态
    /// </summary>
    public PendantStateEnum mState;

    /// <summary>
    /// 人物背后位置
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

    #region 保护方法
    /// <summary>
    /// 获取方向
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
    /// 设置移动索引
    /// </summary>
    protected int GetMoveIndex()
    {
        int index = Random.Range(0, mMovePosList.Count);
        return index;
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 穿戴
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
    /// 脱下
    /// </summary>
    /// <param name="pendant"></param>
    public virtual void TakeOff(ActorData data)
    {
        if (mOwner.UnitTrans == null)
            return;
        mOwner.UnitTrans.parent = null;
    }

    /// <summary>
    /// 添加技能
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
    /// 设置位置
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
    /// 改变改建动作
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
    /// 设置显示状态
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
    /// 改变战斗模式
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
    /// 更新
    /// </summary>
    public virtual void Update()
    {

    }
    #endregion

    #region 保护变量
    /// <summary>
    /// 获取父节点
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
    /// 前提条件
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
    /// 是否在跟随距离内
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
    /// 设置持久化
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
