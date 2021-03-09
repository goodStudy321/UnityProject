using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using Loong.Game;

public class BufSetup
{
    #region 私有字段
    /// <summary>
    /// 存活时间(单位秒)
    /// </summary>
    private float mliveTime = 0;
    /// <summary>
    /// 激活时间(单位秒)
    /// </summary>
    private float mActiveTime = 0;
    /// <summary>
    /// 开始时间(单位秒)
    /// </summary>
    private int mStartTime = 0;
    /// <summary>
    /// buff值
    /// </summary>
    private int mValue = 0;
    /// <summary>
    /// buff是否过期
    /// </summary>
    private bool outOfDate = false;
    /// <summary>
    /// buff特效实体对象
    /// </summary>
    private GameObject mBufEffectObject;
    #endregion

    #region 公有字段
    /// <summary>
    /// buff配置表信息
    /// </summary>
    public BuffBase mBufBaseInfo = null;
    /// <summary>
    /// buff单位
    /// </summary>
    public Unit mOwner;

    /// <summary>
    /// buff效果
    /// </summary>
    public BuffUnit mBuffEffect;
    #endregion

    #region 属性
    /// <summary>
    /// 存活时间
    /// </summary>
    public float LiveTime
    {
        get { return mliveTime; }
    }

    /// <summary>
    /// 激活时间
    /// </summary>
    public float ActiveTime
    {
        get { return mActiveTime; }
    }

    /// <summary>
    /// 开始时间
    /// </summary>
    public float StartTime
    {
        get { return mStartTime; }
    }

    /// <summary>
    /// buff值
    /// </summary>
    public int Value
    {
        get { return mValue; }
        set { mValue = value; }
    }

    /// <summary>
    /// buff是否过期
    /// </summary>
    public bool OutOfDate
    {
        get { return (mStartTime != 0 && mActiveTime >= mliveTime) || outOfDate; }
    }
    #endregion
    
    #region 公有方法

    public BufSetup(Unit owner, uint buffId, int startTime, int endTime, int value, params object[] BufParams)
    {
        mOwner = owner;
        mBufBaseInfo = BuffBaseManager.instance.Find(buffId);
        mStartTime = startTime;
        mliveTime = mBufBaseInfo.liveTime;
        mValue = value;
        SetActiveTime(endTime);
        if(BuffTypeDefine.mBuffEffectTypeDic.ContainsKey(mBufBaseInfo.effectType))
            mBuffEffect = CreateEffectInstance(BuffTypeDefine.mBuffEffectTypeDic[mBufBaseInfo.effectType], this, mOwner, BufParams);

        //设置UI
        if(CanRefreshUI())
            UIBuff.instance.AddBuff(buffId, mBufBaseInfo.icon);

        CreateBuffEffect();
    }

    /// <summary>
    /// 设置结束时间
    /// </summary>
    /// <param name="endTime"></param>
    public void SetActiveTime(int endTime)
    {
        if (endTime == 0)
            return;
        double curTime = TimeTool.GetServerTimeNow() / 1000;
        double remain = endTime - curTime;
        mActiveTime = (float)(mliveTime - remain);
    }

    public void Update(float DeltaTime)
    {
        mActiveTime += DeltaTime;
        if(mBuffEffect != null) mBuffEffect.Update(DeltaTime);
        UpdateEffPos();
        UpdateEffFwd();
        //设置UI的CD
        if (!CanRefreshUI())
            return;
        float cdTime =1 - mActiveTime / mliveTime;
        UIBuff.instance.SetBuffCD(mBufBaseInfo.buffId, cdTime);
    }

    /// <summary>
    /// 开始受到攻击
    /// </summary>
    /// <param name="Attacker"></param>
    /// <param name="hitDefinition"></param>
    /// <param name="hitData"></param>
    public void OnBeginHit(Unit Attacker, HitAction hitDefinition, ActionCommon.HitData hitData)
    {
        if (mBuffEffect != null) mBuffEffect.OnBeginHit(Attacker, hitDefinition, hitData);
    }

    /// <summary>
    /// 停止受到攻击
    /// </summary>
    /// <param name="Attacker"></param>
    /// <param name="hitDefinition"></param>
    /// <param name="hitData"></param>
    /// <param name="damageInfo"></param>
    public void OnEndHit(Unit Attacker, HitAction hitDefinition, ActionCommon.HitData hitData, DamageInfo damageInfo)
    {
        if (mBuffEffect != null) mBuffEffect.OnEndHit(Attacker, hitDefinition, hitData, damageInfo);
    }

    /// <summary>
    /// 开始发动攻击
    /// </summary>
    /// <param name="target"></param>
    public void OnBeginAttack(Unit target)
    {
        if (mBuffEffect != null) mBuffEffect.OnBeginAttack(target);
    }

    /// <summary>
    /// 结束发动攻击
    /// </summary>
    /// <param name="target"></param>
    /// <param name="damageInfo"></param>
    public void OnEndAttack(Unit target, DamageInfo damageInfo)
    {
        if (mBuffEffect != null) mBuffEffect.OnEndAttack(target, damageInfo);
    }

    /// <summary>
    /// 创建buff效果实例
    /// </summary>
    /// <param name="conParam"></param>
    /// <param name="param"></param>
    /// <returns></returns>
    public static BuffUnit CreateEffectInstance(BuffTypeDefine.ConstructParam conParam, params object[] param)
    {
        ConstructorInfo constructor = conParam.CreateType.GetConstructor(conParam.CreateParams);
        return (BuffUnit)constructor.Invoke(param);
    }

    /// <summary>
    /// 销毁buff效果
    /// </summary>
    public void OnDestroy()
    {
        if (mBuffEffect != null) mBuffEffect.OnDestroy();

        outOfDate = true;
        //释放特效对象
        if (mBufEffectObject)
        {
            GameObject go = mBufEffectObject;
            mBufEffectObject = null;
            //GbjPool.Instance.Add(go);
            GameObject.Destroy(go);
        }

        //设置UI
        if (!CanRefreshUI())
            return;
        UIBuff.instance.DelBuff(mBufBaseInfo.buffId);
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 是否能刷新UI
    /// </summary>
    /// <returns></returns>
    private bool CanRefreshUI()
    {
        if (mOwner.UnitUID != User.instance.MapData.UID)
            return false;
        if (string.IsNullOrEmpty(mBufBaseInfo.icon))
            return false;
        return true;
    }

    /// <summary>
    /// 创建buff特效
    /// </summary>
    private void CreateBuffEffect()
    {
        if (string.IsNullOrEmpty(mBufBaseInfo.eft))
            return;
        if (UnitHelper.instance.IsUnitShield(mOwner))
            return;
        //加载buff特效实体对象
        AssetMgr.LoadPrefab(mBufBaseInfo.eft, (effect) =>
        {
            effect.transform.parent = null;
            effect.SetActive(true);
            if (outOfDate)
                return;
            if(UnitHelper.instance.IsOwner(mOwner))
                AssetMgr.Instance.SetPersist(mBufBaseInfo.eft, Suffix.Prefab);
            mBufEffectObject = effect;
            mBufEffectObject.transform.parent = mOwner.UnitTrans;
            UpdateEffPos();
            UpdateEffFwd();
        });
    }

    /// <summary>
    /// 更新buff特效实体
    /// </summary>
    private void UpdateEffPos()
    {
        if (mBufEffectObject == null)
            return;
        Transform tr = mBufEffectObject.transform;
        Vector3 position = mOwner.Position;
        UnitPosEnum posEnum = (UnitPosEnum)mBufBaseInfo.eftPos;
        if (posEnum == UnitPosEnum.BoneHead)
        {
            if (mOwner.mUnitBoneInfo.BoneHead)
            {
                position.y = mOwner.mUnitBoneInfo.BoneHead.position.y;
            }
            else
            {
                float unitHeight = UnitHelper.instance.GetHeight(mOwner);
                position.y += unitHeight;
            }
        }
        else if (posEnum == UnitPosEnum.BoneBody)
        {
            if (mOwner.mUnitBoneInfo.BoneBody)
            {
                position.y = mOwner.mUnitBoneInfo.BoneBody.position.y;
            }
            else
            {
                float unitHeight = UnitHelper.instance.GetHeight(mOwner);
                position.y += unitHeight * 0.5f;
            }
        }
        else if (posEnum == UnitPosEnum.BoneFeet)
        {
            if (mOwner.mUnitBoneInfo.BoneFeet)
            {
                position.y = mOwner.mUnitBoneInfo.BoneFeet.position.y;
            }
        }
        else if (posEnum == UnitPosEnum.FeetBotom)
        {
            //默认角色当前位置
        }
        else if (posEnum == UnitPosEnum.HeadTop)
        {
            float unitHeight = UnitHelper.instance.GetHeight(mOwner);
            position.y += unitHeight + 0.5f;
        }
        else if(posEnum == UnitPosEnum.BodyMid)
        {
            float unitHeight = UnitHelper.instance.GetHeight(mOwner);
            position.y += unitHeight * 0.5f;
        }
        tr.position = position;
    }

    /// <summary>
    /// 更新特效方向
    /// </summary>
    private void UpdateEffFwd()
    {
        if (mBufEffectObject == null)
            return;
        if (mBufBaseInfo == null)
            return;
        Transform tr = mBufEffectObject.transform;
        byte fwdIndex = mBufBaseInfo.eftForward;
        if (fwdIndex == 0)
            return;
        else if (fwdIndex == 1)
        {
            Camera cam = CameraMgr.Main;
            if (cam == null)
                return;
            tr.eulerAngles = cam.transform.eulerAngles;
        }
        else if (fwdIndex == 2)
        {
            if (mOwner.UnitTrans == null)
                return;
            tr.forward = mOwner.UnitTrans.forward;
        }
    }
    #endregion
}


