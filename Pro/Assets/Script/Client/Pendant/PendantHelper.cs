using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class PendantHelper
{
    #region 单例
    public static readonly PendantHelper instance = new PendantHelper();

    private PendantHelper() { }
    #endregion

    #region 公有变量
    /// <summary>
    /// 创建初始武器
    /// </summary>
    public void CreateDefaultWeapon(Unit unit, ActorData actorData)
    {
        if (unit == null)
            return;
        if (unit.UnitTrans == null)
            return;
        UnitType unitType = UnitHelper.instance.GetUnitType(unit.TypeId);
        if (unitType != UnitType.Role)
            return;
        RoleAtt roleAtt = RoleAttManager.instance.Find(unit.TypeId);
        if (roleAtt == null)
            return;
        RoleBase roleBase = RoleBaseManager.instance.Find(roleAtt.weaponModId);
        if (roleBase == null)
            return;
        int count = actorData.SkinList.Count;
        for (int i = 0; i < count; i++)
        {
            uint unitTypeId = (uint)actorData.SkinList[i];
            PendantSystemEnum pType = GetPandentType(unitTypeId);
            if (pType == PendantSystemEnum.Artifact)
            {
                if(AssetExist(unitTypeId, actorData))
                    return;
            }
            if (pType != PendantSystemEnum.FashionableDress)
                continue;
            uint baseId = unitTypeId / 100;
            FashionInfo info = FashionInfoManager.instance.Find(baseId);
            if (info == null)
                continue;
            if ((FashionType)info.type == FashionType.Weapon)
            {
                if (AssetExist(unitTypeId, actorData))
                    return;
            }
        }
        DestroyDefaultWeapon(unit);
        DefaultWpCB dwpcb = new DefaultWpCB();
        dwpcb.Set(unit, roleBase.modelPath);
        AssetMgr.LoadPrefab(roleBase.modelPath, dwpcb.LoadCB);
    }

    /// <summary>
    /// 销毁初始武器
    /// </summary>
    public void DestroyDefaultWeapon(Unit unit)
    {
        if (unit == null)
            return;
        Transform weaponMod = unit.DefaultWeaponMod;
        if (weaponMod == null)
            return;
        weaponMod.parent = null;
        GbjPool.Instance.Add(weaponMod.gameObject);
        unit.DefaultWeaponMod = null;
    }
    
    /// <summary>
    /// 添加宠物攻击目标
    /// </summary>
    public void AddPetHitTarget(Unit petUnit, Unit target)
    {
        if (petUnit == null)
            return;
        if (petUnit.mPendant == null)
            return;
        Pet pet = petUnit.mPendant as Pet;
        if (pet == null)
            return;
        if (!SkillHelper.instance.CompaireHitCondiction(petUnit.ParentUnit, target))
            return;
        Unit tar = pet.TargetList.Find((unit) => { return unit.UnitUID == target.UnitUID; });
        if (tar != null)
            return;
        pet.TargetList.Add(target);
    }

    /// <summary>
    /// 设置挂件战斗类型
    /// </summary>
    public void SetPendantFightType(Unit mtpParent)
    {
        if (mtpParent == null)
            return;
        for (int i = 0; i < mtpParent.Children.Count; i++)
        {
            Unit children = mtpParent.Children[i];
            children.FightType = mtpParent.FightType;
        }
    }

    /// <summary>
    /// 检查场景挂件创建
    /// </summary>
    /// <returns></returns>
    public bool ChkFbPdt(uint unitTypeId)
    {
        PendantSystemEnum pType = GetPandentType(unitTypeId);
        return FbPdt(pType);
    }

    /// <summary>
    /// 禁止挂件
    /// </summary>
    /// <param name="type"></param>
    /// <returns></returns>
    public bool FbPdt(PendantSystemEnum type)
    {
        if (type == PendantSystemEnum.PetMount)//如果是宠物坐骑,直接看宠物是否被禁止
            type = PendantSystemEnum.Pet;
        SceneInfo sceneInfo = SceneInfoManager.instance.Find((uint)User.instance.SceneId);
        if (sceneInfo == null)
            return true;
        int count = sceneInfo.fbUnitList.list.Count;
        if (count == 0)
            return false;
        int index = sceneInfo.fbUnitList.list.FindIndex((t) => { return t == (byte)type; });
        if (index == -1)
            return false;
        return true;
    }

    /// <summary>
    /// 检查单位挂件
    /// </summary>
    /// <returns></returns>
    public Unit GetUnitPdt(Unit unit,uint unitTypeId)
    {
        Unit pdtUnit = unit.Children.Find((Unit u) => { return u.TypeId == unitTypeId; });
        return pdtUnit;
    }

    /// <summary>
    /// 检查时装
    /// </summary>
    /// <param name="unitTypeId"></param>
    /// <returns></returns>
    public bool CheckFashion(Unit unit,uint unitTypeId)
    {
        if (unit.mFashionID == unitTypeId)
            return true;
        return false;
    }

    /// <summary>
    /// 检查宠物坐骑
    /// </summary>
    /// <param name="unitTypeId"></param>
    /// <returns></returns>
    public bool CheckPetMount(uint unitTypeId)
    {
        PendantSystemEnum type = GetPandentType(unitTypeId);
        if (type == PendantSystemEnum.PetMount)
            return true;
        return false;
    }

    /// <summary>
    /// 检查足迹
    /// </summary>
    /// <param name="unitTypeId"></param>
    /// <returns></returns>
    public bool CheckFootPrint(uint unitTypeId)
    {
        PendantSystemEnum type = GetPandentType(unitTypeId);
        if (type == PendantSystemEnum.FootPrint)
            return true;
        return false;
    }

    /// <summary>
    /// 检查是否已经有武器装备(当前索引之前)
    /// </summary>
    /// <param name="unit"></param>
    /// <returns></returns>
    public bool ChkWeapon(ActorData actorData,uint unitTypeId, int index)
    {
        if (!IsWeapon(unitTypeId))
            return false;
        for (int i = 0; i < index; i++)
        {
            uint typeId = (uint)actorData.SkinList[i];
            UnitType unitType = UnitHelper.instance.GetUnitType(typeId);
            if(unitType == UnitType.Artifact)
            {
                return true;
            }
            else if (UnitHelper.instance.IsFashion((int)typeId))
            {
                uint baseId = typeId / 100;
                FashionType type = GetFashionType(baseId);
                if (type == FashionType.Weapon)
                {
                    return true;
                }
            }
        }
        return false;
    }

    /// <summary>
    /// 是否是武器装备(包括神兵/时装武器)
    /// </summary>
    /// <param name="unitTypeId"></param>
    /// <returns></returns>
    public bool IsWeapon(uint unitTypeId)
    {
        UnitType uType = UnitHelper.instance.GetUnitType(unitTypeId);
        if (uType == UnitType.Artifact)
            return true;
        bool isFsh = UnitHelper.instance.IsFashion((int)unitTypeId);
        if (!isFsh)
            return false;
        uint baseId = unitTypeId / 100;
        FashionType type = GetFashionType(baseId);
        if (type == FashionType.Weapon)
            return true;
        return false;
    }

    /// <summary>
    /// 获取挂件类型
    /// </summary>
    /// <returns></returns>
    public PendantSystemEnum GetPandentType(uint unitTypeId)
    {
        if (unitTypeId >= 30200000 && unitTypeId <= 30299999)
        {
            PendantSystemEnum type1 = (PendantSystemEnum)((unitTypeId / 100000) % 300);
            return type1;
        }
        PendantSystemEnum type = (PendantSystemEnum)((unitTypeId / 10000) % 300);
        return type;
    }

    /// <summary>
    /// 获取时装类型
    /// </summary>
    /// <param name="unitTypeId"></param>
    /// <returns></returns>
    public FashionType GetFashionType(uint unitTypeId)
    {
        FashionInfo info = FashionInfoManager.instance.Find(unitTypeId);
        if (info == null)
            return FashionType.None;
        FashionType type = (FashionType)info.type;
        return type;
    }

    /// <summary>
    /// 检查是否存在
    /// </summary>
    /// <param name="unitTypeId"></param>
    /// <param name="actData"></param>
    /// <returns></returns>
    public bool AssetExist(uint unitTypeId, ActorData actData)
    {
        string modelName = null;
        ushort modelId = UnitHelper.instance.GetUnitModeId(unitTypeId, actData);
        RoleBase roleInfo = RoleBaseManager.instance.Find(modelId);
        if (roleInfo != null) modelName = roleInfo.modelPath;
        if (modelId == 10)
        {
            Confine con = ConfineManager.instance.Find(unitTypeId);
            if (con != null)
            {
                modelName = con.aperturePath;
            }
        }
        if (string.IsNullOrEmpty(modelName))
            return false;
        string name = string.Format("{0}.prefab", modelName);
        if (!AssetMgr.Instance.Exist(name))
            return false;
        return true;
    }

    /// <summary>
    /// 获取默认养成类型ID
    /// </summary>
    /// <param name="unitTypeId"></param>
    /// <param name="actData"></param>
    /// <returns></returns>
    public uint GetDftPdtTypeId(Unit parent, uint unitTypeId)
    {
        if (parent == null)
            return 0;
        PdAssetCheck.instance.AddPdAssetLsnr(parent);
        uint dftTypeId = 0;
        PendantSystemEnum type = GetPandentType(unitTypeId);
        if (type == PendantSystemEnum.Artifact)
        {
            dftTypeId = 3040000;
            uint baseId = dftTypeId / 100;
            ArtifactInfo artifactInfo = ArtifactInfoManager.instance.Find(baseId);
            if (artifactInfo == null)
                dftTypeId = 0;
        }
        else if (type == PendantSystemEnum.FashionableDress)
        {
            //没有时装时(时装衣服和时装武器)不添加默认时装
        }
        else if (type == PendantSystemEnum.MagicWeapon)
        {
            dftTypeId = 30200000;
            uint baseId = dftTypeId / 1000;
            MagicWeaponInfo mwInfo = MagicWeaponInfoManager.instance.Find(baseId);
            if (mwInfo == null)
                dftTypeId = 0;
        }
        else if (type == PendantSystemEnum.Mount)
        {
            dftTypeId = 3010001;
            uint baseId = dftTypeId / 100;
            MountInfo mountInfo = MountInfoManager.instance.Find(baseId);
            if (mountInfo == null)
                dftTypeId = 0;
        }
        else if (type == PendantSystemEnum.Pet)
        {
            dftTypeId = 3030101;
            uint baseId = dftTypeId / 100;
            PetInfo petInfo = PetInfoManager.instance.Find(baseId);
            if (petInfo == null)
                dftTypeId = 0;
        }
        else if (type == PendantSystemEnum.Wing)
        {
            dftTypeId = 3050000;
            uint baseId = dftTypeId / 100;
            WingBase wingInfo = WingBaseManager.instance.Find(baseId);
            if (wingInfo == null)
                dftTypeId = 0;
        }
        else if(type == PendantSystemEnum.PetMount)
        {
            dftTypeId = 3080001;
            uint baseId = dftTypeId / 100;
            PetMountInfo petMInfo = PetMountInfoManager.instance.Find(baseId);
            if (petMInfo == null)
                dftTypeId = 0;
        }
        else if(type == PendantSystemEnum.FootPrint)
        {
            dftTypeId = 3090000;
            uint baseId = dftTypeId / 100;
            FashionInfo fashionInfo = FashionInfoManager.instance.Find(baseId);
            if (fashionInfo == null)
                return 0;
        }
        if (!parent.OldPendantDic.ContainsKey(unitTypeId))
            parent.OldPendantDic.Add(unitTypeId, dftTypeId);
        return dftTypeId;
    }
    #endregion
}
