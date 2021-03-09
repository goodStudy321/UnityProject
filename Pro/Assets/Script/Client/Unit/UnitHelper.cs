using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Phantom.Protocal;
using ProtoBuf;
using Loong.Game;
using System;

public class UnitHelper
{
    public static readonly UnitHelper instance = new UnitHelper();

    private UnitHelper()
    {

    }
    #region 私有变量
    private RaycastHit hitObj;
    private Ray ray = new Ray(Vector3.zero, Vector3.down);
    #endregion

    #region 公有方法

    /// <summary>
    /// 获取单位高度
    /// </summary>
    /// <param name="u"></param>
    /// <returns></returns>
    public float GetHeight(Unit u)
    {
        if (u == null) return 0;
        float ht = 0;
        if (u.Collider != null)
        {
            ht = u.Collider.bounds.size.y;
        }
        if (ht == 0)
        {
            var uas = u.ActionStatus;
            if (uas == null) return 0;
            ht = uas.ActionGroupData.BoundingHeight * 0.01f;
        }
        return ht;
    }

    /// <summary>
    /// 获取方向
    /// </summary>
    /// <param name="srcPos"></param>
    /// <param name="desPos"></param>
    /// <returns></returns>
    public Vector3 GetForward(Vector3 srcPos, Vector3 desPos)
    {
        srcPos.y = desPos.y = 0;
        Vector3 forward = desPos - srcPos;
        return forward.normalized;
    }

    /// <summary>
    /// 检查触碰地面
    /// </summary>
    /// <returns>如果距离范围内检查到地面返回地面的高度</returns>
    public float GetTerrainHeight(Vector3 oriPos)
    {
        oriPos.Set(oriPos.x, oriPos.y + 200, oriPos.z);
        ray.origin = oriPos;
        string LayerMaskLayer = "Ground";
        if (Physics.Raycast(ray, out hitObj, 500, 1 << LayerMask.NameToLayer(LayerMaskLayer)))
            return hitObj.point.y;
        return 0;
    }

    /// <summary>
    /// 设置单位位置
    /// </summary>
    public void SetRayHitPosition(Vector3 bornPos, Unit unit)
    {
        RaycastHit hit;
        Ray ray = new Ray(bornPos + new Vector3(0, 200, 0), Vector3.down);
        if (Physics.Raycast(ray, out hit, 500, 1 << UnityEngine.LayerMask.NameToLayer("Ground")))
            unit.Position = hit.point;
        else
            unit.Position = bornPos;
    }

    /// <summary>
    /// 但是是否可用
    /// </summary>
    /// <param name="unit"></param>
    /// <returns></returns>
    public bool CanUseUnit(Unit unit)
    {
        if (UnitIsNull(unit))
            return false;
        if (unit.Dead)
            return false;
        return true;
    }

    /// <summary>
    /// 单位是否为空
    /// </summary>
    /// <param name="unit"></param>
    /// <returns></returns>
    public bool UnitIsNull(Unit unit)
    {
        if (unit == null)
            return true;
        if (unit.UnitTrans == null)
            return true;
        return false;
    }

    /// <summary>
    /// 是否自己
    /// </summary>
    /// <param name="unit"></param>
    /// <returns></returns>
    public bool IsOwner(Unit unit)
    {
        if (unit == null)
            return false;
        long ownId = User.instance.MapData.UID;
        if (unit.UnitUID == ownId)
            return true;
        Unit parent = unit.ParentUnit;
        if (parent != null && parent.UnitUID == ownId)
            return true;
        return false;
    }

    /// <summary>
    /// 亲属关系单位
    /// </summary>
    /// <param name="finder"></param>
    /// <param name="target"></param>
    /// <returns></returns>
    public bool RelativesUnit(Unit finder, Unit target)
    {
        if (finder == null)
            return false;
        if (target == null)
            return false;
        if (target.UnitUID == finder.UnitUID)
            return true;
        Unit parent = finder.ParentUnit;
        if (parent != null && target.UnitUID == parent.UnitUID)
            return true;
        parent = target.ParentUnit;
        if (parent != null && finder.UnitUID == parent.UnitUID)
            return true;
        return false;
    }

    /// <summary>
    /// 单位是否是屏蔽状态
    /// </summary>
    /// <param name="unit"></param>
    /// <returns></returns>
    public bool IsUnitShield(Unit unit)
    {
        if (unit == null)
            return true;
        Transform trans = unit.UnitTrans;
        if (trans == null)
            return true;
        if (!trans.gameObject.activeSelf)
            return true;
        return false;
    }

    /// <summary>
    /// 前提条件是否能通过
    /// </summary>
    /// <param name="unit"></param>
    /// <returns></returns>
    public bool PreConCanPass(Unit unit)
    {
        if (!InputMgr.instance.CanInput)
            return false;
        if (unit == null)
            return false;
        if (unit.Dead)
            return false;
        if (unit.ActionStatus == null)
            return false;
        if (unit.ActionStatus.IsStraightState())
            return false;
        return true;
    }

    /// <summary>
    /// 是否可移动
    /// </summary>
    /// <param name="unit"></param>
    /// <returns></returns>
    public bool CanMove(Unit unit)
    {
        if (unit == null)
            return false;
        if (unit.Dead)
            return false;
        if (unit.UnitTrans == null)
            return false;
        if (unit.mUnitBuffStateInfo.IsDizziness)
            return false;
        if (unit.mUnitBuffStateInfo.IsTieUp)
            return false;
        if (unit.mUnitBuffStateInfo.IsForbitMove)
            return false;
        return true;
    }

    /// <summary>
    /// 是否可移动(不好含死亡情况)
    /// </summary>
    /// <param name="unit"></param>
    /// <returns></returns>
    public bool CanMoveExceptDead(Unit unit)
    {
        if (unit == null)
            return false;
        if (unit.UnitTrans == null)
            return false;
        if (unit.mUnitBuffStateInfo.IsDizziness)
            return false;
        if (unit.mUnitBuffStateInfo.IsTieUp)
            return false;
        if (unit.mUnitBuffStateInfo.IsForbitMove)
            return false;
        return true;
    }

    /// <summary>
    /// 是否能播放普通攻击
    /// </summary>
    /// <param name="unit"></param>
    /// <returns></returns>
    public bool CanPlayNormalAttack(Unit unit)
    {
        if (unit == null)
            return false;
        if (unit.Dead)
            return false;
        if (unit.mUnitBuffStateInfo.IsDizziness)
            return false;
        if (unit.mUnitBuffStateInfo.IsForbitNormalAttack)
            return false;
        return true;
    }

    /// <summary>
    /// 是否能播放技能攻击
    /// </summary>
    /// <param name="unit"></param>
    /// <returns></returns>
    public bool CanPlaySkillAttack(Unit unit)
    {
        if (unit == null)
            return false;
        if (unit.Dead)
            return false;
        if (unit.mUnitBuffStateInfo.IsDizziness)
            return false;
        if (unit.mUnitBuffStateInfo.IsForbitSkillAttack)
            return false;
        return true;
    }

    /// <summary>
    /// 是否能战斗
    /// </summary>
    /// <param name="unit"></param>
    /// <returns></returns>
    public bool CanFight(Unit unit)
    {
        if (unit == null)
            return false;
        if (unit.Dead)
            return false;
        if (unit.mUnitBuffStateInfo.IsDizziness)
            return false;
        if (unit.mUnitBuffStateInfo.IsForbitFight)
            return false;
        return true;
    }

    /// <summary>
    /// 设置死亡方向
    /// </summary>
    /// <param name="unit"></param>
    public void SetDeadForward(Unit unit)
    {
        if (unit == null)
            return;
        if (unit.ActionStatus == null)
            return;
        if (!unit.ActionStatus.ActiveAction.FaceToTarget)
            return;
        if (unit.mLastAttacker == null)
            return;
        if (unit.mLastAttacker.UnitTrans == null)
            return;
        Vector3 forward = unit.mLastAttacker.Position - unit.Position;
        float orient = Mathf.Atan2(forward.x, forward.z);
        unit.SetOrientation(orient);
    }
    
    /// <summary>
    /// 获取单位模型id
    /// </summary>
    /// <param name="unitTypeId"></param>
    /// <returns></returns>
    public ushort GetUnitModeId(UInt32 unitTypeId,ActorData data = null)
    {
        if (data == null) data = User.instance.MapData;
        UnitSex unitSex = (UnitSex)data.Sex;
        if (unitTypeId > 10000 && unitTypeId <= 99999)
        {
            RoleAtt roleAtt = RoleAttManager.instance.Find(unitTypeId);
            if (roleAtt == null)
                return 0;
            return roleAtt.modelId;
        }
        else if (unitTypeId > 100000 && unitTypeId <= 199999)
        {
            NPCInfo npcInfo = NPCInfoManager.instance.Find(unitTypeId);
            if (npcInfo == null)
                return 0;
            return npcInfo.modeId;
        }
        else if (unitTypeId > 200000 && unitTypeId <= 299999)
        {
            MonsterAtt monsterAtt = MonsterAttManager.instance.Find(unitTypeId);
            if (monsterAtt == null)
                return 0;
            return monsterAtt.modelId;
        }
        else if (unitTypeId >= 3070000 && unitTypeId <= 3079999)
        {
            Summon summon = SummonManager.instance.Find(unitTypeId);
            if (summon == null)
                return 0;
            return summon.modelId;
        }
        else if (unitTypeId > 3000000 && unitTypeId <= 3069999
            || unitTypeId > 3080000 && unitTypeId <= 3099999
            || unitTypeId >= 30200000 && unitTypeId <= 30299999)
        {
            PendantSystemEnum type = PendantHelper.instance.GetPandentType((uint)unitTypeId);
            uint baseId = unitTypeId / 100;
            if (type == PendantSystemEnum.Artifact)
            {
                ArtifactInfo artifactInfo = ArtifactInfoManager.instance.Find(baseId);
                if (artifactInfo == null)
                    return 0;
                if (unitSex == UnitSex.WoMan)
                    return artifactInfo.modelIdWoman;
                else
                    return artifactInfo.modelIdMan;
            }
            else if (type == PendantSystemEnum.FashionableDress
                || type == PendantSystemEnum.FootPrint)
            {
                FashionInfo fashionInfo = FashionInfoManager.instance.Find(baseId);
                if (fashionInfo == null)
                    return 0;
                if (unitSex == UnitSex.WoMan)
                    return fashionInfo.modelIdWoman;
                else
                    return fashionInfo.modelIdMan;
            }
            else if (type == PendantSystemEnum.MagicWeapon)
            {
                baseId = unitTypeId / 1000;
                MagicWeaponInfo mwInfo = MagicWeaponInfoManager.instance.Find(baseId);
                if (mwInfo == null)
                    return 0;
                return mwInfo.modelId;
            }
            else if (type == PendantSystemEnum.Mount)
            {
                MountInfo mountInfo = MountInfoManager.instance.Find(baseId);
                if (mountInfo == null)
                    return 0;
                return mountInfo.modelId;
            }
            else if (type == PendantSystemEnum.Pet)
            {
                PetInfo petInfo = PetInfoManager.instance.Find(baseId);
                if (petInfo == null)
                    return 0;
                return petInfo.modelId;
            }
            else if (type == PendantSystemEnum.Wing)
            {
                WingBase wingInfo = WingBaseManager.instance.Find(baseId);
                if (wingInfo == null)
                    return 0;

                if(User.instance.MapData.Sex == 0)
                    return (ushort)wingInfo.modelF;
                else
                    return (ushort)wingInfo.modelM;
            }
            else if(type == PendantSystemEnum.PetMount)
            {
                PetMountInfo petMInfo = PetMountInfoManager.instance.Find(baseId);
                if (petMInfo == null)
                    return 0;
                return petMInfo.modelId;
            }
        }
        else if (unitTypeId > 1000 && unitTypeId <= 9999)
        {
            Confine con = ConfineManager.instance.Find(unitTypeId);
            if (con == null)
                return 0;
            return 10;
        }
        return 0;
    }


    /// <summary>
    /// 获取表中携带技能
    /// </summary>
    /// <param name="unitTypeId"></param>
    /// <returns></returns>
    public List<uint> GetTableCarrySkills(UInt32 unitTypeId)
    {
        UnitType unitType = GetUnitType(unitTypeId);
        if (unitType == UnitType.Role)
        {
            RoleAtt roleAtt = RoleAttManager.instance.Find(unitTypeId);
            if (roleAtt == null)
                return null;
            return roleAtt.skillId.list;
        }
        else if (unitType == UnitType.Monster)
        {
            MonsterAtt monsterAtt = MonsterAttManager.instance.Find(unitTypeId);
            if (monsterAtt == null)
                return null;
            return monsterAtt.skillId.list;
        }
        else if (unitType == UnitType.MagicWeapon)
        {
            uint level = 1;
            MagicWeaponLevel mwInfo = MagicWeaponLevelManager.instance.Find(level);
            if (mwInfo == null)
                return null;
            return mwInfo.skills.list;
        }
        else if (unitType == UnitType.Mount)
        {

        }
        else if (unitType == UnitType.Pet)
        {
            PetDetailInfo petInfo = PetDetailInfoManager.instance.Find(unitTypeId);
            if (petInfo == null)
                return null;
            return petInfo.skills.list;
        }
        else if (unitType == UnitType.Wing)
        {

        }
        else if (unitType == UnitType.Summon)
        {
            Summon summon = SummonManager.instance.Find(unitTypeId);
            if (summon == null)
                return null;
            if (summon.carrySkill == 0)
                return null;
            List<uint> list = new List<uint>() { summon.carrySkill };
            return list;
        }
        return null;
    }

    /// <summary>
    /// 获取单位类型
    /// </summary>
    /// <param name="unitTypeId"></param>
    /// <returns></returns>
    public UnitType GetUnitType(ulong unitTypeId)
    {
        if (unitTypeId > 10000 && unitTypeId <= 99999)
            return UnitType.Role;
        else if (unitTypeId > 200000 && unitTypeId <= 299999)
            return UnitType.Monster;
        else if (unitTypeId >= 3070000 && unitTypeId <= 3079999)
            return UnitType.Summon;
        else if (unitTypeId > 3010000 && unitTypeId <= 3069999
            || unitTypeId > 3080000 && unitTypeId <= 3099999
            || unitTypeId >= 30200000 && unitTypeId < 30299999)
        {
            PendantSystemEnum type = PendantHelper.instance.GetPandentType((uint)unitTypeId);
            if (type == PendantSystemEnum.Artifact)
                return UnitType.Artifact;
            else if (type == PendantSystemEnum.FashionableDress)
            {
                if (unitTypeId <= 3065000)
                    return UnitType.Role;
                else
                    return UnitType.None;
            }
            else if (type == PendantSystemEnum.MagicWeapon)
                return UnitType.MagicWeapon;
            else if (type == PendantSystemEnum.Mount)
                return UnitType.Mount;
            else if (type == PendantSystemEnum.Pet)
                return UnitType.Pet;
            else if (type == PendantSystemEnum.Wing)
                return UnitType.Wing;
            else if (type == PendantSystemEnum.PetMount)
                return UnitType.PetMount;
            else if (type == PendantSystemEnum.FootPrint)
                return UnitType.FootPrint;
        }
        else if (unitTypeId > 100000 && unitTypeId <= 199999)
            return UnitType.NPC;
        else if (unitTypeId > 1000 && unitTypeId <= 9999)
            return UnitType.Aperture;
        return UnitType.Role;
    }

    /// <summary>
    /// 获取网络单位单位ID
    /// </summary>
    /// <param name="mapActor"></param>
    /// <returns></returns>
    public uint GetNetUnitTypeId(ActorData mapActor)
    {
        if (mapActor == null)
            return 0;
        UnitType actorType = (UnitType)mapActor.Type;
        //人物
        if (actorType == UnitType.Role)
        {
            uint unitTypeId = (uint)((mapActor.Category * 10 + mapActor.Sex) * 1000 + mapActor.Level);
            return unitTypeId;
        }
        //怪物
        else if (actorType == UnitType.Monster)
        {
            return (uint)mapActor.MonsterExtra.type_id;
        }
        //召唤体
        else if (actorType == UnitType.Summon)
        {
            return (uint)mapActor.TrapExtra.type_id;
        }
        return 0;
    }

    /// <summary>
    /// 是否时装
    /// </summary>
    /// <param name="unitTypeId"></param>
    /// <returns></returns>
    public bool IsFashion(int unitTypeId)
    {
        if (unitTypeId > 3060000 && unitTypeId <= 3069999)
            return true;
        return false;
    }

    /// <summary>
    /// 是否队友
    /// </summary>
    /// <returns></returns>
    public bool IsTeammate(Unit unitA, Unit unitB)
    {
        if (unitA == null)
            return false;
        if (unitB == null)
            return false;
        if (unitA.TeamId == 0)
            return false;
        if (unitA.TeamId != unitB.TeamId)
            return false;
        return true;
    }

    /// <summary>
    /// 是否盟友
    /// </summary>
    /// <param name="unitA"></param>
    /// <param name="unitB"></param>
    /// <returns></returns>
    public bool IsSameFml(Unit unitA, Unit unitB)
    {
        if (unitA == null)
            return false;
        if (unitB == null)
            return false;
        if (unitA.FamilyId == 0)
            return false;
        if (unitA.FamilyId != unitB.FamilyId)
            return false;
        return true;
    }

    /// <summary>
    /// 队友或盟友
    /// </summary>
    /// <param name="unitA"></param>
    /// <param name="unitB"></param>
    /// <returns></returns>
    public bool IsTeammateOrFml(Unit unitA, Unit unitB)
    {
        if (IsTeammate(unitA, unitB))
            return true;
        if (IsSameFml(unitA, unitB))
            return true;
        return false;
    }

    /// <summary>
    /// 获取单位模型名
    /// </summary>
    /// <param name="unitModelId"></param>
    /// <returns></returns>
    public string GetUnitModelName(ushort unitModelId)
    {
        RoleBase roleBase = RoleBaseManager.instance.Find(unitModelId);
        if (roleBase == null)
            return null;
        return roleBase.modelPath;
    }

    /// <summary>
    /// 获取单位全名
    /// </summary>
    /// <param name="actData"></param>
    /// <returns></returns>
    public string GetUnitFullName(ActorData actData)
    {
        if (actData == null)
            return "";
        //string confineStr = GetConfineStr((uint)actData.Confine);
        string name = actData.Name;
        if (actData.PkValue > 0)
            name = string.Format("[ff0000]{0}[-]",name);
        //if(!string.IsNullOrEmpty(confineStr))
        //    name = string.Format("{0} {1}", confineStr,name);

        return name;
    }
    /// <summary>
    /// 获取开放等级
    /// </summary>
    /// <param name="key"></param>
    /// <returns></returns>
    public UInt16 GetSystemOpen(UInt16 key)
    {
        return systemopenManager.instance.Find(key).triggerparm;
    }

    /// <summary>
    /// 获取境界名
    /// </summary>
    /// <param name="level"></param>
    /// <returns></returns>
    public string GetConfineStr(uint confine)
    {
        Confine info = ConfineManager.instance.Find(confine);
        if (info == null)
            return "";
        return info.confineStr;
    }
    /// <summary>
    /// 获取称号Texture名字
    /// </summary>
    /// <param name="title"></param>
    /// <returns></returns>
    public string GetTitleTexture(uint title)
    {
        Title info = TitleManager.instance.Find(title);
        if (info == null)
            return null;
        return info.prefab;
    }

    /// <summary>
    /// 获取怪物等级
    /// </summary>
    /// <param name="unitTypeId"></param>
    /// <returns></returns>
    public int GetMonsterLevel(long unitId)
    {
        if (Global.Mode == PlayMode.Local)
        {
            return 1;
        }
        ActorData actData = User.instance.MonsterDic[unitId];
        if (actData == null)
            return 1;
        return actData.MonsterExtra.level;
    }

    //获取召唤体类型ID
    public uint GetSummonTypeId(int skillId)
    {
        List<Summon> list = SummonManager.instance.GetList();
        for(int i = 0; i < list.Count; i++)
        {
            if (list[i].carrySkill == skillId)
                return list[i].baseid;
        }
        return 99999999;
    }

    /// <summary>
    /// 改变时装之前清理
    /// </summary>
    /// <param name="unit"></param>
    public void ChangeFashionBeforeClear(Unit unit)
    {
        if (unit == null)
            return;
        for (int i = 0; i < unit.Children.Count; i++)
        {
            if (unit.Children[i] == null)
                continue;
            if (unit.Children[i].UnitTrans == null)
                continue;
            unit.Children[i].UnitTrans.parent = null;
        }
        unit.mUnitAnimation.Clear();
    }
    
    /// <summary>
    /// 重置单位数据
    /// </summary>
    /// <param name="unit"></param>
    public void ResetUnitData(Unit unit)
    {
        if (unit == null)
            return;
        unit.mUnitMove.SetAutoPathFindTip(false);
        AutoMountMgr.instance.StopTimer(unit);
        NavMoveBuff.instance.StopMoveBuff(unit);
    }
    #endregion
}
