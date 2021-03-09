using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;
using Loong.Game;

/// <summary>
/// 中毒buff
/// </summary>
public class PoisoningBuff : BuffUnit
{
    #region 字段
    /// <summary>
    /// 单位材质
    /// </summary>
    private List<Material> mUnitMats = new List<Material>();
    /// <summary>
    /// shader属性名
    /// </summary>
    private string mProName = "_poisonPower";
    /// <summary>
    /// 属性值
    /// </summary>
    private float mProVal = 0.7f;
    #endregion

    #region 私有方法
    #endregion

    #region 公有方法
    public PoisoningBuff(BufSetup bufSetup, Unit owner, object[] param)
        : base(bufSetup, owner, param)
    {
        UnitMatHelper.FindSetMats(mOwner.UnitTrans, mProName, mUnitMats);
        UnitMatHelper.SetShaderFltPro(mUnitMats, mProName, mProVal);
    }

     public override void Update(float DeltaTime)
     {
         
     }

     public override void OnBeginHit(Unit attacker, HitAction hitDefinition, ActionCommon.HitData hitData)
     {
         
     }

     public override void OnDestroy()
     {
        UnitMatHelper.SetShaderFltPro(mUnitMats, mProName, 0);
    }
    #endregion
}

