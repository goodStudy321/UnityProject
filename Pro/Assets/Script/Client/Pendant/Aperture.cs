using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class Aperture: PendantBase
{
    //OnTakeOffMount
    #region 字段
    /// <summary>
    /// 光圈变换对象
    /// </summary>
    private Transform mTrans = null;
    /// <summary>
    /// 模型名
    /// </summary>
    private string mModName;

    public int mCurConfine = 0;
    #endregion

    #region 属性
    /// <summary>
    /// 模型名
    /// </summary>
    public string ModName
    {
        get { return mModName; }
    }

    /// <summary>
    /// 模型名
    /// </summary>
    public Transform ModTrans
    {
        get { return mTrans; }
    }

    /// <summary>
    /// 光环相对出生位置
    /// </summary>
    public Vector3 BornPos
    {
        get
        {
            Vector3 pos = mMtpParent.UnitTrans.position;
            pos.y = pos.y + 0.2f;
            return pos;
        }
    }
    #endregion

    #region 公有方法

    /// <summary>
    /// 穿戴
    /// </summary>
    /// <param name="mtpParent"></param>
    public override Unit PutOn(Unit mtpParent, uint unitTypeId, PendantStateEnum state, ActorData data = null)
    {
        base.PutOn(mtpParent, unitTypeId, state, data);
        if (!UnitHelper.instance.CanUseUnit(mtpParent))
            return null;
        mBaseId = unitTypeId;
        Confine m_confine = ConfineManager.instance.Find(unitTypeId);
        if (m_confine != null) mModName = m_confine.aperturePath;
        if (string.IsNullOrEmpty(mModName))
            return null;
        if (mTrans && mTrans.name == mModName)
        {
            return null;
        }
        if (mCurConfine == unitTypeId)
        {
            return null;
        }
        if (mCurConfine == 0)
        {
            return null;
        }
        mCurConfine = (int)unitTypeId;
        AssetMgr.LoadPrefab(mModName, (obj) =>
        {
            EventMgr.Add("OnTakeOffMount", SetModelActive);
            if (mMtpParent == null || mMtpParent.DestroyState)
            {
                GbjPool.Instance.Add(obj);
                return;
            }
            if (obj == null)
                return;
            mTrans = obj.transform;
            mTrans.parent = mMtpParent.UnitTrans;
            obj.SetActive(true);
            mTrans.name = mModName;
            SetPersist(obj, mModName);
            Object.DontDestroyOnLoad(mTrans);
            mTrans.position = BornPos;
            mMtpParent.mAperture = this;
        });
        return null;
    }

    public override void TakeOff(ActorData data)
    {
        EventMgr.Remove("OnTakeOffMount", SetModelActive);
        if (UnitHelper.instance.UnitIsNull(mMtpParent))
            return;
        mMtpParent.mAperture = null;
        mModName = null;
        if (mTrans == null)
            return;
        GameObject.Destroy(mTrans.gameObject);
        mTrans = null;
        mCurConfine = 0;
    }

    public void Dispose()
    {
        if (mTrans)
        {
            mTrans.parent = null;
            GameObject.Destroy(mTrans.gameObject);
            mTrans = null;
            mCurConfine = 0;
        }
    }
    #endregion

    #region 私有变量


    private void SetModelActive(params object[] args)
    {
        if (mTrans == null) return;
        bool bActive = (bool)args[0];
        mTrans.gameObject.SetActive(bActive);
        
    }
    #endregion
}
