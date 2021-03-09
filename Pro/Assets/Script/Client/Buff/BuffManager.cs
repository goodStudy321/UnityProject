using System.Collections.Generic;
using UnityEngine;
using System;

/// <summary>
/// unit的buff管理器
/// </summary>
public class BuffManager
{
    #region 私有字段
    //单位自己
    private Unit mOwner;
    //buff列表
    private List<BufSetup> mBuffSetupList = new List<BufSetup>();
    #endregion

    #region 公有字段
    #endregion

    #region 属性
    #endregion

    #region 私有方法
    /// <summary>
    /// 添加Buff到列表
    /// </summary>
    /// <param name="buffId"></param>
    /// <param name="addbuffType"></param>
    /// <param name="data"></param>
    /// <returns></returns>
    private BufSetup AddBuffToList(uint buffId, int startTime, int endTime, int value)
    {
        BuffBase bf = BuffBaseManager.instance.Find(buffId);
        if (bf == null)
            return null;
        BufSetup buf = mBuffSetupList.Find(delegate (BufSetup s) { return s.mBufBaseInfo.buffId == buffId; });
        if (buf == null)
        {
            buf = new BufSetup(mOwner, buffId, startTime, endTime, value);
            mBuffSetupList.Add(buf);
        }
        else
        {
            buf.SetActiveTime(endTime);
            buf.Value = value;
        }
        BufValOnChange(buffId, value);
        return buf;
    }

    /// <summary>
    /// buff值改变
    /// </summary>
    private void BufValOnChange(uint buffId,int value)
    {
        if (mOwner.UnitUID != User.instance.MapData.UID)
            return;
        EventMgr.Trigger(EventKey.BufValOnChange, buffId, value);
    }

    /// <summary>
    /// 删除Buff
    /// </summary>
    /// <param name="idx"></param>
    private void DelBufIdx(int idx)
    {
        if (idx == -1)
            return;
        BuffBase buff = mBuffSetupList[idx].mBufBaseInfo;
        if (buff != null)
        {
            EventMgr.Trigger(EventKey.BufValOnDel, buff.buffId);
        }
        mBuffSetupList[idx].OnDestroy();
        mBuffSetupList.RemoveAt(idx);
    }


    /// <summary>
    /// 检测是否可以添加buff
    /// </summary>
    /// <param name="buffId"></param>
    /// <returns></returns>
    private bool CheckCanAddBuff(uint buffId)
    {
        if (mOwner == null) return false;
        if (mOwner.Dead) return false;
        return true;
    }
    #endregion


    #region 公有方法
    /// <summary>
    /// 初始化
    /// </summary>
    /// <param name="owner"></param>
    public void Init(Unit owner)
    {
        mOwner = owner;
    }

    /// <summary>
    /// 初始化Buff
    /// </summary>
    /// <param name="actData"></param>
    public void InitBuff(ActorData actData)
    {
        if (actData == null)
            return;
        if (actData.BuffList == null)
            return;
        for(int i = 0; i < actData.BuffList.Count; i++)
        {
            AddBuff((uint)actData.BuffList[i], 0, 0, 0);
        }
    }

    /// <summary>
    /// 添加buff
    /// </summary>
    /// <param name="buffId"></param>
    /// <param name="startTime"></param>
    /// <param name="endTime"></param>
    /// <returns></returns>
    public BufSetup AddBuff(uint buffId, int startTime, int endTime, int value)
    {
        if (!CheckCanAddBuff(buffId)) return null;
        BufSetup bufSetup = AddBuffToList(buffId, startTime, endTime, value);
        return bufSetup;
    }

    /// <summary>
    /// 删除buff
    /// </summary>
    /// <param name="buffId"></param>
    public void DelBuf(uint buffId)
    {
        int index = mBuffSetupList.FindIndex(delegate(BufSetup s) { return s.mBufBaseInfo.buffId == buffId; });
        DelBufIdx(index);
    }

    /// <summary>
    /// 根据buffId获取buff
    /// </summary>
    /// <param name="buffId"></param>
    /// <returns></returns>
    public BufSetup GetBuffById(uint buffId)
    {
        BufSetup buff = mBuffSetupList.Find(delegate (BufSetup s) { return s.mBufBaseInfo.buffId == buffId; });
        return buff;
    }

    /// <summary>
    /// 通过系列ID获取buff值(混合属性buff不适用）
    /// </summary>
    /// <param name="seriesId"></param>
    /// <returns></returns>
    public float GetBufValBySrID(int seriesId)
    {
        float value = 0;
        for (int i = 0; i < mBuffSetupList.Count; i++)
        {
            BufSetup bufSetup = mBuffSetupList[i];
            BuffBase baseInfo = bufSetup.mBufBaseInfo;
            if (baseInfo.seriesId != seriesId)
                continue;
            List<BuffBase.Val> attrLst = baseInfo.items.list;
            int count = attrLst.Count;
            if (count == 0)
                continue;
            for (int index = 0; index < count; index++)
            {
                int k = attrLst[index].k;
                int val = attrLst[index].v;
                PropertyName info = PropertyNameManager.instance.Find((uint)k);
                if (info == null)
                    continue;
                if(info.isShowTyp == 0)
                {
                    value += bufSetup.Value * val;
                }
                else if(info.isShowTyp == 1)
                {
                    value += (bufSetup.Value * val * 0.01f);
                }
            }
        }
        return value;
    }

    /// <summary>
    /// 通过系列ID获取buffId((非共存Buff))
    /// </summary>
    /// <param name="seriesId"></param>
    /// <returns></returns>
    public uint GetBuffIdBySrID(int seriesId)
    {
        for (int i = 0; i < mBuffSetupList.Count; i++)
        {
            BufSetup bufSetup = mBuffSetupList[i];
            BuffBase baseInfo = bufSetup.mBufBaseInfo;
            if (baseInfo.seriesId == seriesId)
                return baseInfo.buffId;

        }
        return 0;
    }


    /// <summary>
    /// 开始攻击
    /// </summary>
    /// <param name="target"></param>
    /// <param name="damageInfo"></param>
    public void OnBeginAttack(Unit target, DamageInfo damageInfo)
    {
        if (mBuffSetupList.Count == 0)
            return;

        int iCount = mBuffSetupList.Count;
        for (int i = 0; i < iCount; i++)
        {
            mBuffSetupList[i].OnBeginAttack(target);
        }
    }

    /// <summary>
    /// 结束攻击
    /// </summary>
    /// <param name="target"></param>
    /// <param name="damageInfo"></param>
    public void OnEndAttack(Unit target, DamageInfo damageInfo)
    {
        if (mBuffSetupList.Count == 0)
            return;

        int iCount = mBuffSetupList.Count;
        for (int i = 0; i < iCount; i++)
        {
            mBuffSetupList[i].OnEndAttack(target, damageInfo);
        }
    }

    /// <summary>
    /// 开始受击
    /// </summary>
    /// <param name="Attacker"></param>
    /// <param name="hitDefinition"></param>
    /// <param name="hitData"></param>
    public void OnBeginHit(Unit Attacker, HitAction hitDefinition, ActionCommon.HitData hitData)
    {
        if (mBuffSetupList.Count == 0)
            return;

        int iCount = mBuffSetupList.Count;
        for (int i = 0; i < iCount; i++)
        {
            mBuffSetupList[i].OnBeginHit(Attacker, hitDefinition, hitData);
        }
    }

    /// <summary>
    /// 结束受击
    /// </summary>
    /// <param name="Attacker"></param>
    /// <param name="hitDefinition"></param>
    /// <param name="hitData"></param>
    /// <param name="damageInfo"></param>
    public void OnEndHit(Unit Attacker, HitAction hitDefinition, ActionCommon.HitData hitData, DamageInfo damageInfo)
    {
        if (mBuffSetupList.Count == 0)
            return;

        int iCount = mBuffSetupList.Count;
        for (int i = 0; i < iCount; i++)
        {
            mBuffSetupList[i].OnEndHit(Attacker, hitDefinition, hitData, damageInfo);
        }
    }

    /// <summary>
    /// 更新buff列表
    /// </summary>
    /// <param name="DeltaTime"></param>
    public void UpdateBufferList(float DeltaTime)
    {
        for (int i = 0; i < mBuffSetupList.Count; i++)
        {
            BufSetup buf = mBuffSetupList[i];
            if (buf.OutOfDate)
                continue;
            mBuffSetupList[i].Update(DeltaTime);
        }
    }

    /// <summary>
    /// 销毁
    /// </summary>
    public void DestoryAllBuffs()
    {
        int iCount = mBuffSetupList.Count;
        for (int i = 0; i < iCount; i++)
        {
            BufSetup buf = mBuffSetupList[i];
            buf.OnDestroy();
        }
        mBuffSetupList.Clear();
    }

    public void Dispose()
    {
        mOwner = null;
        mBuffSetupList.Clear();
    }
    #endregion
}
