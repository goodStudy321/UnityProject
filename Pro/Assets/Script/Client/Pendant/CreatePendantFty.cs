using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CreatePendantFty
{
    #region 公有属性
    /// <summary>
    /// 创建挂件
    /// </summary>
    /// <param name="unitTypeId"></param>
    /// <returns></returns>
    public static IPendant CreatePendant(uint unitTypeId)
    {
        UnitType unitType = UnitHelper.instance.GetUnitType(unitTypeId);
        IPendant ipd = null;
        if (UnitHelper.instance.IsFashion((int)unitTypeId))
        {
            uint baseId = unitTypeId / 100;
            FashionType type = PendantHelper.instance.GetFashionType(baseId);
            if (type == FashionType.Cloth)
                ipd = new Fashion();
            else if(type == FashionType.Weapon)
                ipd = new FashionWp();
            return ipd;
        }
        CopyType copyType = GameSceneManager.instance.CurCopyType;
        switch (unitType)
        {
            case UnitType.Artifact:
                ipd = new Artifact();
                break;
            case UnitType.MagicWeapon:
                ipd = new MagicWeapon();
                break;
            case UnitType.Wing:
                ipd = new Wing();
                break;
            case UnitType.Mount:
                if (copyType == CopyType.Offl1v1)
                    break;
                ipd = new Mount();
                break;
            case UnitType.Pet:
                if (copyType == CopyType.Offl1v1)
                    break;
                ipd = new Pet();
                break;
            case UnitType.PetMount:
                if (copyType == CopyType.Offl1v1)
                    break;
                ipd = new PetMount();
                break;
            case UnitType.FootPrint:
                ipd = new FootPrint();
                break;
            case UnitType.Aperture:
                ipd = new Aperture();
                break;
            default:
                break;
        }
        return ipd;
    }
    #endregion
}
