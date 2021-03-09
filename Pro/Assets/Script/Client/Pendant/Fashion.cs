using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;
using System;

/// <summary>
/// ʱװ
/// </summary>
public class Fashion : PendantBase
{
    #region ˽���ֶ�
    //������ɻص�
    private Action LoadDone = null;
    #endregion

    #region ˽�з���
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
    /// ����Ĭ��Ƥ��
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
            //��λ��Ϣ����
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
            //������װ���
            if (PendantMgr.instance.FashionChangeDone != null) PendantMgr.instance.FashionChangeDone(mMtpParent);
            //��ʼ�������ű�
            mMtpParent.InitHitComponent();
            //����������������
            if (mMtpParent.UnitUID == User.instance.MapData.UID)
                CameraMgr.UpdateOperation(CameraType.Player, mMtpParent.UnitTrans, true);
            //Ѫ��������������
            TopBarFty.ResetTopObject(mMtpParent);
            //�Ҽ�����
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
    /// ����ģ�����
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
    /// ��ȡ��ģ����
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
    /// ���û�װ��ɶ���
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

    #region ���з���
    /// <summary>
    /// ����
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
