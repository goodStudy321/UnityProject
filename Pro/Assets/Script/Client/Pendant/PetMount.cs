using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class PetMount : PendantBase
{
    #region 私有变量
    /// <summary>
    /// 宠物坐骑变换
    /// </summary>
    private Transform mTrans = null;
    #endregion

    #region 公有变量

    #endregion

    #region 公有方法
    /// <summary>
    /// 穿戴
    /// </summary>
    /// <param name="mtpParent"></param>
    /// <param name="unitTypeId"></param>
    /// <param name="state"></param>
    /// <param name="data"></param>
    /// <returns></returns>
    public override Unit PutOn(Unit mtpParent, uint unitTypeId, PendantStateEnum state, ActorData data = null)
    {
        base.PutOn(mtpParent, unitTypeId, state, data);
        if (!UnitHelper.instance.CanUseUnit(mtpParent))
            return null;
        PetMountInfo petMInfo = PetMountInfoManager.instance.Find(mBaseId);
        if (petMInfo == null)
            return null;
        mMountPoint = (MountPoint)petMInfo.mountPoint;
        string modelName = null;
        RoleBase roleInfo = RoleBaseManager.instance.Find(petMInfo.modelId);
        if (roleInfo != null) modelName = roleInfo.modelPath;
        if (string.IsNullOrEmpty(modelName))
            return null;
        AssetMgr.LoadPrefab(modelName, (obj) =>
        {
            if (mMtpParent == null || mMtpParent.DestroyState)
            {
                GbjPool.Instance.Add(obj);
                return;
            }
            if (obj == null)
                return;
            mTrans = obj.transform;
            mTrans.parent = null;
            obj.SetActive(true);
            SetPersist(obj, modelName);
            SetPosition();
            mMtpParent.mPetMount = this;
        });
        return null;
    }

    /// <summary>
    /// 脱下
    /// </summary>
    /// <param name="data"></param>
    public override void TakeOff(ActorData data)
    {
        if (UnitHelper.instance.UnitIsNull(mMtpParent))
            return;
        mMtpParent.mPetMount = null;
        if (mTrans == null)
            return;
        GameObject.Destroy(mTrans.gameObject);
    }

    /// <summary>
    /// 设置位置
    /// </summary>
    public override void SetPosition()
    {
        if (mMtpParent == null)
            return;
        if(UnitHelper.instance.UnitIsNull(mMtpParent.Pet))
        {
            mTrans.position = BackPos;
            mTrans.forward = mMtpParent.UnitTrans.forward;
            return;
        }
        Assemble(mMtpParent.Pet);
    }

    /// <summary>
    /// 组装
    /// </summary>
    /// <param name="pet"></param>
    public void Assemble(Unit pet)
    {
        if (UnitHelper.instance.UnitIsNull(pet))
            return;
        if (mTrans == null)
            return;
        Transform parent = GetParent(pet);
        TransTool.AddChild(parent, mTrans);
        mTrans.forward = pet.UnitTrans.forward;
        mTrans.gameObject.SetActive(true);
    }

    /// <summary>
    /// 拆装
    /// </summary>
    public void UnAssemble()
    {
        if (mTrans == null)
            return;
        mTrans.parent = null;
        mTrans.gameObject.SetActive(false);
    }
    #endregion

    #region 私有方法

    #endregion
}
