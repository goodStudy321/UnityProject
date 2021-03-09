using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using ProtoBuf;
using Loong.Game;

public class HitComponent : MonoBehaviour
{
    #region 字段
    List<HitActionRef> mActionList = new List<HitActionRef>();
    List<int> mDestroyList = new List<int>();
    List<int> mDestroyBulletList = new List<int>();
    List<int> mDestroyLaserLineList = new List<int>();
    List<int> mDestroyChainLightningList = new List<int>();

    public Unit mOwner = null;
    #endregion

    #region 公有方法
    /// <summary>
    /// 增加子弹实体
    /// </summary>
    /// <param name="data"></param>
    /// <param name="action"></param>
    /// <param name="isStraightBullet"></param>
    public void AddBulletHit(AttackDefData data, string action, bool isStraightBullet, int harmSection)
    {
        HitAction hitAct = null;
        if (mDestroyBulletList.Count > 0)
        {
            ResetHitInfo(mDestroyBulletList, ref hitAct);
        }
        else
        {
            hitAct = ObjPool.Instance.Get<BulletHit>();
            AddToHitActRefList(hitAct);
        }
        hitAct.Init(data, mOwner, action, harmSection);
    }

    /// <summary>
    /// 增加攻击实体
    /// </summary>
    /// <param name="data"></param>
    /// <param name="action"></param>
    public void AddHit(AttackDefData data, string action, int harmSection)
    {
        HitAction hitAct = null;
        if (mDestroyList.Count > 0)
        {
            ResetHitInfo(mDestroyList, ref hitAct);
        }
        else
        {
            hitAct = ObjPool.Instance.Get<HitAction>();
            AddToHitActRefList(hitAct);
        }

        hitAct.Init(data, mOwner, action, harmSection);
    }
    
    /// <summary>
    /// 增加激光击中实体
    /// </summary>
    /// <param name="data"></param>
    /// <param name="action"></param>
    public void AddLaserLightHit(AttackDefData data, string action, int harmSection)
    {
        HitAction hitAct = null;
        if (mDestroyLaserLineList.Count > 0)
        {
            ResetHitInfo(mDestroyLaserLineList, ref hitAct);
        }
        else
        {
            hitAct = ObjPool.Instance.Get<LaserLightHit>();
            AddToHitActRefList(hitAct);
        }

        hitAct.Init(data, mOwner, action, harmSection);
    }

    /// <summary>
    /// 增加闪电链
    /// </summary>
    public void AddChainLightning(AttackDefData data, string action, int harmSection)
    {
        HitAction hitAct = null;
        if (mDestroyChainLightningList.Count > 0)
        {
            ResetHitInfo(mDestroyChainLightningList, ref hitAct);
        }
        else
        {
            hitAct = ObjPool.Instance.Get<ChainLightning>();
            AddToHitActRefList(hitAct);
        }
        hitAct.Init(data, mOwner, action, harmSection);
    }

    /// <summary>
    /// 销毁
    /// </summary>
    public void OnDestroy()
    {
        for (int i = 0; i < mActionList.Count; i++)
        {
            HitActionRef hitActRef = mActionList[i];
            HitAction hitAct = hitActRef.hitAction;
            hitAct.Destroy();
            hitActRef.bUsing = false;
            hitActRef.hitAction = null;
            ObjPool.Instance.Add(hitAct);
            ObjPool.Instance.Add(hitActRef);
        }
        mActionList.Clear();
        mDestroyList.Clear();
        mDestroyBulletList.Clear();
        mDestroyLaserLineList.Clear();
        mDestroyChainLightningList.Clear();
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 重置攻击信息
    /// </summary>
    /// <param name="list">对应攻击定义记录列表</param>
    private void ResetHitInfo(List<int> list, ref HitAction hitAct)
    {
        int index = list[0];
        list.RemoveAt(0);
        ResetHitActRef(index, ref hitAct);
    }
    /// <summary>
    /// 重置攻击定义相关信息
    /// </summary>
    /// <param name="index">对应攻击定义记录的索引值</param>
    /// <param name="hitAct">攻击定义</param>
    private void ResetHitActRef(int index, ref HitAction hitAct)
    {
        if (index >= mActionList.Count)
            return;
        HitActionRef hitActRef = mActionList[index];
        hitAct = hitActRef.hitAction;
        hitActRef.bUsing = true;
        hitAct.ReInit();
    }

    /// <summary>
    /// 添加到攻击行为引用列表
    /// </summary>
    /// <param name="hitAct"></param>
    private void AddToHitActRefList(HitAction hitAct)
    {
        HitActionRef actionRef = ObjPool.Instance.Get<HitActionRef>();
        actionRef.bUsing = true;
        actionRef.hitAction = hitAct;
        hitAct.ReInit();
        mActionList.Add(actionRef);
    }

    // Update is called once per frame
    void Update()
    {
        for (int i = 0; i < mActionList.Count; i++)
        {
            HitActionRef actionRef = mActionList[i];
            if (!actionRef.bUsing) continue;
            HitAction hitAct = actionRef.hitAction;
            if (!hitAct.OutDate)
            {
                hitAct.Update();
                continue;
            }
            //等待特效加载完成
            if (!hitAct.mIsEffectLoaded) continue;

            if (hitAct.GetType() == typeof(HitAction))
                mDestroyList.Add(i);
            else if (hitAct.GetType() == typeof(BulletHit))
                mDestroyBulletList.Add(i);
            else if (hitAct.GetType() == typeof(LaserLightHit))
                mDestroyLaserLineList.Add(i);
            else if (hitAct.GetType() == typeof(ChainLightning))
                mDestroyChainLightningList.Add(i);

            actionRef.hitAction.Destroy();
            actionRef.bUsing = false;
        }
    }
    #endregion 私有方法
}

