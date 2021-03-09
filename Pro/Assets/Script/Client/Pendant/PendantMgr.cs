using System.Collections;
using System.Collections.Generic;
using System;
using UnityEngine;
using Loong.Game;

public class PendantMgr 
{
    public static readonly PendantMgr instance = new PendantMgr();

    private PendantMgr()
    {

    }
    #region 私有字段
    /// <summary>
    /// 挂载点字典
    /// </summary>
    private Dictionary<MountPoint, string> mMountPointDic = new Dictionary<MountPoint, string>();
    /// <summary>
    /// 挂件单位列表
    /// </summary>
    private Dictionary<string, Unit> mPendantUnitList = new Dictionary<string, Unit>();
    #endregion

    #region 公有字段
    /// <summary>
    /// 换装事件
    /// </summary>
    public Action<Unit> FashionChangeDone;
    /// <summary>
    /// 挂件显示控制(false时由流程控制，true时由其他情况控制)
    /// </summary>
    public bool ShowContrl = true;
    #endregion

    #region 属性
    /// <summary>
    /// 挂载点字典
    /// </summary>
    public Dictionary<MountPoint, string> MountPointDic
    {
        get { return mMountPointDic; }
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 执行卸下
    /// </summary>
    private void DoTakeOff(Unit mtpParent, uint unitTypeId, ActorData actData)
    {
        string key = mtpParent.UnitUID.ToString() + unitTypeId;
        RemoveFromPendantUnitList(key);
        if (PendantHelper.instance.CheckFashion(mtpParent, unitTypeId))
        {
            if (mtpParent.mPendant == null)
                return;
            mtpParent.mPendant.TakeOff(actData);
            return;
        }
        if(PendantHelper.instance.CheckPetMount(unitTypeId))
        {
            if (mtpParent.mPetMount == null)
                return;
            mtpParent.mPetMount.TakeOff(actData);
            mtpParent.mPetMount = null;
            return;
        }
        if(PendantHelper.instance.CheckFootPrint(unitTypeId))
        {
            if (mtpParent.mFootPrint == null)
                return;
            mtpParent.mFootPrint.TakeOff(actData);
            mtpParent.mFootPrint = null;
        }
        if (unitTypeId > 1000 && unitTypeId <= 9999)
        {
            if (mtpParent.mAperture != null && mtpParent.mAperture.mCurConfine > 0)
            {
                mtpParent.mAperture.TakeOff(actData);
                mtpParent.mAperture = null;
            }
        }
        List<Unit> children = mtpParent.Children.FindAll((Unit unit) => { return unit.TypeId == unitTypeId; });
        for (int i = 0; i < children.Count; i++)
        {
            if (children[i].mPendant != null)
                children[i].mPendant.TakeOff(actData);
            children[i].mUnitMove.StopNav();
            children[i].Destroy();
        }
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 初始化
    /// </summary>
    public void Init()
    {
        mMountPointDic.Clear();
        mMountPointDic.Add(MountPoint.MountBack, "Bip001 AssPosition");
        mMountPointDic.Add(MountPoint.RightHand, "Bip001 Prop1");
        mMountPointDic.Add(MountPoint.RoleBack, "Bip001 Spine1");
        mMountPointDic.Add(MountPoint.Root, "");
        mMountPointDic.Add(MountPoint.PetMount, "Pet_Mount");
        GestureMgr.One.upSwipe += RequestManualShowMount;
        GestureMgr.One.downSwipe += ReqestManualHideMount;
    }

    /// <summary>
    /// 创建挂件外观
    /// </summary>
    /// <param name="mountParent"></param>
    /// <param name="actorData"></param>
    public void CreatePendants(Unit mtpParent, ActorData actorData)
    {
        PendantHelper.instance.CreateDefaultWeapon(mtpParent,actorData);
        //PendantHelper.instance.CreateDefaultAperture(actorData);
        PutOn(mtpParent, (uint)actorData.Confine, actorData.PdState, actorData);
        int count = actorData.SkinList.Count;
        if (count == 0)
            return;
        for (int i = 0; i < count; i++)
        {
            uint unitTypeId = (uint)actorData.SkinList[i];
            Unit pdtUnit = PendantHelper.instance.GetUnitPdt(mtpParent, unitTypeId);
            if (PendantHelper.instance.ChkFbPdt(unitTypeId))
            {
                if (pdtUnit == null)
                    continue;
                TakeOff(mtpParent, unitTypeId, actorData);
                continue;
            }
            if(pdtUnit != null)
            {
                if (!SetPendantActive(pdtUnit, true))
                    continue;
                pdtUnit.mPendant.SetPosition();
                continue;
            }
            if (PendantHelper.instance.CheckFashion(mtpParent, unitTypeId))
                continue;
            if (PendantHelper.instance.ChkWeapon(actorData,unitTypeId,i))
                continue;
            PutOn(mtpParent, unitTypeId, actorData.PdState,actorData);
        }
    }
    
    /// <summary>
    /// 穿戴
    /// </summary>
    /// <param name="mtpParent">挂载父体</param>
    /// <param name="unitTypeId">挂件类型id</param>
    public void PutOn(Unit mtpParent, uint unitTypeId, PendantStateEnum pendantState = PendantStateEnum.Normal,ActorData data = null)
    {
        if (!UnitHelper.instance.CanUseUnit(mtpParent))
            return;
        if (!PendantHelper.instance.AssetExist(unitTypeId, data))
        {
            unitTypeId = PendantHelper.instance.GetDftPdtTypeId(mtpParent, unitTypeId);
            if(unitTypeId == 0)
                return;
        }
        IPendant ipd = CreatePendantFty.CreatePendant(unitTypeId);
        if (ipd == null)
            return;
        TakeOff(mtpParent, unitTypeId,data);
        Unit pendant = ipd.PutOn(mtpParent, unitTypeId, pendantState,data);
        AddToPendantUnitList(mtpParent, pendant);
    }

    /// <summary>
    /// 脱下
    /// </summary>
    /// <param name="mtpParent"></param>
    /// <param name="unitTypeId"></param>
    public void TakeOff(Unit mtpParent, uint unitTypeId,ActorData data = null)
    {
        if (mtpParent == null)
            return;
        DoTakeOff(mtpParent, unitTypeId, data);
        if (!mtpParent.OldPendantDic.ContainsKey(unitTypeId))
            return;
        uint oldTypeId = mtpParent.OldPendantDic[unitTypeId];
        mtpParent.OldPendantDic.Remove(unitTypeId);
        if (oldTypeId == 0)
            return;
        DoTakeOff(mtpParent, oldTypeId, data);
    }

    /// <summary>
    /// 脱下所有挂件外观
    /// </summary>
    /// <param name="mtpParent"></param>
    public void TakeOffAllPendant(Unit mtpParent)
    {
        if (mtpParent == null)
            return;
        string key = mtpParent.UnitUID.ToString();
        List<Unit> children = mtpParent.Children;
        for (int i = 0; i < children.Count; i++)
        {
            Unit child = children[i];
            key += child.TypeId;
            RemoveFromPendantUnitList(key);
            if (child.mPendant != null)
                child.mPendant.TakeOff(null);
            child.mUnitMove.StopNav();
            child.Destroy();
        }
        if (mtpParent.mPetMount == null)
            return;
        mtpParent.mPetMount.TakeOff(null);
        mtpParent.mPetMount = null;
    }

    /// <summary>
    /// 下马
    /// </summary>
    /// <param name="unit"></param>
    public void TakeOffMount(Unit unit)
    {
        if (unit == null)
            return;
        if (unit.Mount == null)
            return;
        NetPendant.RequestChangeMount(0);
        TakeOff(unit, unit.Mount.TypeId);
    }

    /// <summary>
    /// 执行下坐骑事件
    /// </summary>
    /// <param name="args"></param>
    public void ExcuTakeOffMountEvent(params object[] args)
    {
        TakeOffMount(InputMgr.instance.mOwner);
    }

    /// <summary>
    /// 添加监听事件
    /// </summary>
    public void AddListener()
    {
        EventMgr.Add(EventKey.ReqBegCollect, ExcuTakeOffMountEvent);
    }

    /// <summary>
    /// 添加到挂件单位列表
    /// </summary>
    /// <param name="pendant"></param>
    public void AddToPendantUnitList(Unit mtpParent, Unit pendant)
    {
        if (pendant == null)
            return;
        if (pendant.mPendant is MagicWeapon || pendant.mPendant is Pet)
        {
            string key = mtpParent.UnitUID.ToString() + pendant.TypeId;
            if (mPendantUnitList.ContainsKey(key))
                RemoveFromPendantUnitList(key);
            mPendantUnitList.Add(key, pendant);
        }
    }

    /// <summary>
    /// 从挂件单位列表删除
    /// </summary>
    /// <param name="pendant"></param>
    public void RemoveFromPendantUnitList(string key)
    {
        if (!mPendantUnitList.ContainsKey(key))
            return;
        mPendantUnitList.Remove(key);
    }

    /// <summary>
    /// 通过单位从挂件列表中移除
    /// </summary>
    /// <param name="unit"></param>
    public void RemoveFromPendantUnitListByUnit(Unit unit)
    {
        if (unit == null)
            return;
        if (unit.mPendant == null)
            return;
        if (unit.ParentUnit == null)
            return;
        string key = unit.ParentUnit.UnitUID.ToString() + unit.TypeId;
        RemoveFromPendantUnitList(key);
    }
    /// <summary>
    /// 重置摄像机对象
    /// </summary>
    /// <param name="user"></param>
    /// <param name="camTar"></param>
    public void ResetCameraTarget(long unitId, Unit camTar)
    {
        if (unitId != User.instance.MapData.UID)
            return;
        CameraMgr.UpdateOperation(CameraType.Player, camTar.UnitTrans, true);
    }

    /// <summary>
    /// 设置本地挂件显示状态
    /// </summary>
    public void SetLocalPendantsShowState(Unit pendantParentUnit, bool isShow, OpStateType opStateType)
    {
        if (!ShowContrl)
            return;
        if (opStateType == OpStateType.Jump ||
            opStateType == OpStateType.SetUnitActive)
        {
            SetLocalPendantShowState(pendantParentUnit, PendantSystemEnum.Mount, isShow);
            SetLocalPendantShowState(pendantParentUnit, PendantSystemEnum.Pet, isShow);
            SetLocalPendantShowState(pendantParentUnit, PendantSystemEnum.MagicWeapon, isShow);
        }
        else if (opStateType == OpStateType.Revive)
        {
            SetLocalPendantShowState(pendantParentUnit, PendantSystemEnum.Pet, isShow);
            SetLocalPendantShowState(pendantParentUnit, PendantSystemEnum.MagicWeapon, isShow);
            SetLocalPendantShowState(pendantParentUnit, PendantSystemEnum.Wing, isShow);
        }
        else if (opStateType == OpStateType.ChangeScene ||
                 opStateType == OpStateType.MoveToPoint)
        {
            SetLocalPendantShowState(pendantParentUnit, PendantSystemEnum.Pet, isShow);
            SetLocalPendantShowState(pendantParentUnit, PendantSystemEnum.MagicWeapon, isShow);
        }
        if(pendantParentUnit!=null)
        EventMgr.Trigger("SetLocalPendantsShowState", (int)opStateType, isShow,pendantParentUnit.UnitUID);
    }

    /// <summary>
    /// 设置本地挂件显示状态
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="result"></param>
    public void SetLocalPendantShowState(Unit unit, PendantSystemEnum pendantEnum, bool isShow)
    {
        if (unit == null)
            return;
        if (unit.Dead && isShow)
            return;
        if (unit.UnitTrans == null)
            return;
        if (pendantEnum == PendantSystemEnum.Mount)
        {
            Unit mount = unit.Mount;
            if (mount == null)
                return;
            if (isShow)
            {
                if (System.Object.ReferenceEquals(unit, InputMgr.instance.mOwner))
                {
                    Transform trans = unit.UnitTrans;
                   if(trans != null && trans.parent == null)//防止单位隐藏后上了坐骑,单位的位置不正确
                        mount.Position = unit.Position;
                }
                mount.mPendant.SetPosition();
                ResetCameraTarget(unit.UnitUID, mount);
            }
            else
            {
                unit.UnitTrans.parent = null;
                unit.ActionStatus.ignoreGravityGlobal = false;
                unit.Position = mount.Position;
                ResetCameraTarget(unit.UnitUID, unit);
            }
            SetPendantActive(mount, isShow);
            if (mount.ActionStatus != null)
                    mount.ActionStatus.ChangeAction("N0000",0);
        }
        else if(pendantEnum == PendantSystemEnum.Pet)
        {
            Unit pet = unit.Pet;
            if (pet == null)
                return;
            if(isShow)
            {
                Pet petPendant = pet.mPendant as Pet;
                if (petPendant == null)
                    return;
                pet.Position = petPendant.BackPos;
            }
            SetPendantActive(pet, isShow);
            if (pet.ActionStatus == null)
                return;
            pet.ActionStatus.ChangeIdleAction();
        }
        else if(pendantEnum == PendantSystemEnum.MagicWeapon)
        {
            Unit magicWeapon = unit.MagicWeapon;
            if (magicWeapon == null)
                return;
            MagicWeapon mwPendant = unit.MagicWeapon.mPendant as MagicWeapon;
            if (mwPendant == null)
                return;
            if (isShow)
                mwPendant.SetModelPosition(mwPendant.MwBornPos);
            mwPendant.SetModelShowSate(isShow);
        }
        else if(pendantEnum == PendantSystemEnum.Wing)
        {
            Unit wing = unit.Wing;
            if (wing == null)
                return;
            SetPendantActive(wing, isShow);
        }
    }

    /// <summary>
    /// 设置挂件显示隐藏
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="isShow"></param>
    public bool SetPendantActive(Unit unit, bool isShow)
    {
        if (unit == null)
            return false;
        if (unit.UnitTrans == null)
            return false;
        if (unit.UnitTrans.gameObject.activeSelf == isShow)
            return false;
        unit.UnitTrans.gameObject.SetActive(isShow);
        if (unit.TopBar == null) return true;
        if (isShow)
            unit.TopBar.Open();
        else
            unit.TopBar.Close();
        return true;
    }

    /// <summary>
    /// 改变挂件外观动画
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="pendantState"></param>
    public void ChangePendantsAction(Unit unit, PendantStateEnum pendantState)
    {
        if (unit == null)
            return;
        for(int i = 0; i < unit.Children.Count; i++)
        {
            IPendant ipd = unit.Children[i].mPendant;
            if (ipd == null)
                continue;
            bool isWing = ipd is Wing;
            bool isArtifact = ipd is Artifact;
            if (!isWing && !isArtifact)
                continue;
            ipd.ChangePendantAction(unit.Children[i], pendantState);
        }
    }

    /// <summary>
    /// 请求显示坐骑
    /// </summary>
    public void RequestManualShowMount()
    {
        if (!InputMgr.instance.CanInput)
            return;
        float x = Input.mousePosition.x;
        float width = Screen.width / 3;
        if (x < width || x > width * 2)
            return;
        if (PendantHelper.instance.FbPdt(PendantSystemEnum.Mount))
            return;
        RequestShowMount();
    }

    public void ReqestManualHideMount()
    {
        if (!InputMgr.instance.CanInput)
            return;
        float x = Input.mousePosition.x;
        float width = Screen.width / 3;
        if (x < width || x > width * 2)
            return;
        if (JoyStickCtrl.instance.mInputVector != Vector2.zero)
            return;
        RequestHideMount();
    }

    /// <summary>
    /// 请求显示坐骑
    /// </summary>
    public void RequestShowMount()
    {
        CopyType copyType = GameSceneManager.instance.CurCopyType;
        if (copyType == CopyType.Offl1v1)
            return;
        Unit unit = InputMgr.instance.mOwner;
        if (unit == null)
            return;
        if (CollectionMgr.State != CollectionState.None)
            return;
        if (unit.mUnitMove == null)
            return;
        if (unit.mUnitMove.IsJumping)
            return;
        if (unit.ActionStatus == null)
            return;
        if (unit.ActionStatus.ActionState == ActionStatus.EActionStatus.EAS_Attack)
            return;
        if (unit.ActionStatus.ActionState == ActionStatus.EActionStatus.EAS_Skill)
            return;
        NetPendant.RequestChangeMount(1);
    }

    /// <summary>
    /// 请求隐藏坐骑
    /// </summary>
    public void RequestHideMount()
    {
        Unit unit = InputMgr.instance.mOwner;
        if (unit == null)
            return;
        if (unit.Mount == null)
            return;
        Transform trans = unit.Mount.UnitTrans;
        if (trans == null)
            return;
        if (!trans.gameObject.activeSelf)
            return;
        NetPendant.RequestChangeMount(0);
    }
    
    /// <summary>
    /// 更新挂件单位
    /// </summary>
    public void Update()
    {
        int count = mPendantUnitList.Count;
        if (count == 0)
            return;
        foreach(KeyValuePair<string,Unit> item in mPendantUnitList)
        {
            if (item.Value == null)
                continue;
            if (item.Value.mPendant == null)
                continue;
            item.Value.mPendant.Update();
        }
    }
    #endregion
}
