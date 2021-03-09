using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;
using System;

/// <summary>
/// 时装
/// </summary>
public class Fashion : PendantBase
{
    #region 私有字段
    //加载完成回调
    private Action LoadDone = null;
    #endregion

    #region 私有方法
    private void ResetWeapon()
    {
        if (mMtpParent == null)
            return;
        ActorData actData = User.instance.MapData;
        if (mMtpParent.UnitUID != User.instance.MapData.UID)
        {
            actData = User.instance.OtherRoleDic[mMtpParent.UnitUID];
            if (actData == null)
                return;
        }
        PendantHelper.instance.CreateDefaultWeapon(mMtpParent, actData);
    }

    /// <summary>
    /// 创建默认皮肤
    /// </summary>
    private void CreateDfSkin(uint unitTypeId, ActorData data = null)
    {
        ushort modelId = UnitHelper.instance.GetUnitModeId(unitTypeId, data);
        ushort oldModId = mMtpParent.ModelId;
        mMtpParent.ModelId = modelId;
        string modelName = null;
        RoleBase roleInfo = RoleBaseManager.instance.Find(modelId);
        if (roleInfo != null) modelName = roleInfo.modelPath;
        if (string.IsNullOrEmpty(modelName))
            return;
        Vector3 position = mMtpParent.Position;

        AssetMgr.LoadPrefab(modelName, (obj) =>
        {
            if(mMtpParent == null || mMtpParent.DestroyState || mMtpParent.mFashionID != mUnitTypeId)
            {
                GbjPool.Instance.Add(obj);
                return;
            }
            Transform trans = obj.transform;
            trans.parent = null;
            obj.SetActive(true);
            SetPersist(obj, modelName);
            Transform go = mMtpParent.UnitTrans;
            go.name = GetOldName(oldModId);
            go.parent = null;
            //单位信息重置
            UnitHelper.instance.ChangeFashionBeforeClear(mMtpParent);
            mMtpParent.SetUnitTransInfo(trans);
            if (UnitHelper.instance.IsOwner(mMtpParent))
                UnitMgr.instance.SetUnitAllAssetsPersist(mMtpParent);
            var iname = mMtpParent.Name + mMtpParent.UnitUID;
            mMtpParent.UnitTrans.name = iname;
            mMtpParent.Position = position;
            if (mMtpParent.Mount == null)
            {
                float orientation = mMtpParent.Orientation;
                mMtpParent.SetOrientation(orientation);
            }
            else if (mMtpParent.Mount.UnitTrans == null)
            {
                float orientation = mMtpParent.Orientation;
                mMtpParent.SetOrientation(orientation);
            }
            else
            {
                mMtpParent.SetForward(mMtpParent.Mount.UnitTrans.forward);
            }

            if (!go.gameObject.activeSelf)
                SettingMgr.instance.HideRole(mMtpParent);
            if (LoadDone != null) LoadDone();
            //触发换装完成
            if (PendantMgr.instance.FashionChangeDone != null) PendantMgr.instance.FashionChangeDone(mMtpParent);
            //初始化攻击脚本
            mMtpParent.InitHitComponent();
            //摄像机跟随对象重置
            if (mMtpParent.UnitUID == User.instance.MapData.UID)
                CameraMgr.UpdateOperation(CameraType.Player, mMtpParent.UnitTrans, true);
            //血条或名称条重置
            TopBarFty.ResetTopObject(mMtpParent);
            //挂件重置
            for (int i = 0; i < mMtpParent.Children.Count; i++)
            {
                Unit unit = mMtpParent.Children[i];
                if (unit.mPendant == null)
                    continue;
                if (unit.mPendant is Pet)
                    continue;
                if (unit.mPendant is MagicWeapon)
                    continue;
                unit.mPendant.SetPosition();
            }
            ResetWeapon();
            UnitShadowMgr.instance.SetShadow(mMtpParent);
            GbjPool.Instance.Add(go.gameObject);
            mMtpParent.mUnitOutline.SetRenderer(mMtpParent);
            var uanim = mMtpParent.mUnitAnimation;
            if (uanim == null) return;
            var delay = ObjPool.Instance.Get<UnitAnimDelayEnable>();
            delay.Start(uanim.Animation);
            PlayAnimation();
        });
    }

    /// <summary>
    /// 加载模型完成
    /// </summary>
    private void LoadMDone()
    {
        if (mMtpParent == null)
            return;
        if (mMtpParent.mFashionID == 0)
            mMtpParent.mPendant = null;
        else
            mMtpParent.mPendant = this;
    }

    /// <summary>
    /// 获取旧模型名
    /// </summary>
    /// <returns></returns>
    private string GetOldName(ushort modId)
    {
        string modName = "BadMod";
        if (mMtpParent == null)
            return modName;
        RoleBase roleBase = RoleBaseManager.instance.Find(modId);
        if (roleBase == null)
            return modName;
        return roleBase.modelPath;
    }

    /// <summary>
    /// 设置换装完成动画
    /// </summary>
    private void PlayAnimation()
    {
        if (mMtpParent == null)
            return;
        ActionStatus actStt = mMtpParent.ActionStatus;
        if (actStt == null)
            return;
        if (actStt.ActiveAction == null)
            return;
        actStt.ChangeAction(actStt.ActiveAction.AnimID, 0);
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 穿戴
    /// </summary>
    /// <param name="mtpParent"></param>
    public override Unit PutOn(Unit mtpParent, uint unitTypeId, PendantStateEnum state, ActorData data = null)
    {
        base.PutOn(mtpParent, unitTypeId, state);
        if (!UnitHelper.instance.CanUseUnit(mtpParent))
            return null;
        LoadDone = LoadMDone;
        mtpParent.mFashionID = unitTypeId;
        FashionInfo fashionInfo = FashionInfoManager.instance.Find(mBaseId);
        if (fashionInfo == null)
            return null;
        CreateDfSkin(unitTypeId, data);
        return null;
    }

    public override void TakeOff(ActorData data)
    {
        CreateDfSkin(mMtpParent.TypeId, data);
        mMtpParent.mFashionID = 0;
    }
    #endregion
}
