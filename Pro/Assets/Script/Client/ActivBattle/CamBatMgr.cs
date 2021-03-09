using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class CamBatMgr
{
    public static readonly CamBatMgr instance = new CamBatMgr();
    private CamBatMgr() { }
    #region 私有字段
    /// <summary>
    /// 阵营名
    /// </summary>
    private Dictionary<CampType, string> mCampDic = new Dictionary<CampType, string>();
    #endregion

    #region 私有方法
    /// <summary>
    /// 修改状态
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="animID"></param>
    private void ChgState(Unit unit, string animID)
    {
        unit.ActionStatus.ChangeAction(animID, 0);
        if (unit.TopBar != null)
            unit.TopBar.Dispose();
    }
    #endregion

    #region 公有方法
    public void Initialize()
    {
        if (GameSceneManager.instance.MapSubType != SceneSubType.CampMap)
            return;
        mCampDic.Clear();
        mCampDic.Add(CampType.CampType1, Phantom.Localization.Instance.GetDes(690041));
        mCampDic.Add(CampType.CampType2, Phantom.Localization.Instance.GetDes(690042));
        mCampDic.Add(CampType.CampType3, Phantom.Localization.Instance.GetDes(690043));
    }
    public void SetPileInfo(Unit unit, long value)
    {
        if (GameSceneManager.instance.MapSubType != SceneSubType.CampMap)
            return;
        if (unit == null)
            return;
        if (unit.ActionStatus == null)
            return;
        if (unit.UnitTrans == null)
            return;
        if (unit.mUnitAttInfo.UnitTypeId != 200199)
            return;
        if(value == 0)
            ChgState(unit,"N0000");
        else
        {
            if (value == long.MaxValue)
            {
                if (!User.instance.MonsterDic.ContainsKey(unit.UnitUID))
                    return;
                ActorData actorData = User.instance.MonsterDic[unit.UnitUID];
                value = actorData.MonsterExtra.battle_owner;
            }
            CampType campType = (CampType)value;
            if(value == 0)
                ChgState(unit, "N0000");
            else
            {
                ChgState(unit, "N0001");
                string name = string.Format("{0}({1})", unit.Name, GetCampName(campType));
                string campName = GetCampName(campType);
                if (unit.TopBar != null) unit.TopBar.Dispose();
                unit.TopBar = CommenNameBar.Create(unit.UnitTrans, "", name, TopBarFty.OtherPlayerBarStr);
                EventMgr.Trigger(EventKey.GetPolyCard, campName);
            }
        }
    }

    /// <summary>
    /// 获取阵营名
    /// </summary>
    /// <param name="campType"></param>
    /// <returns></returns>
    public string GetCampName(CampType campType)
    {
        if (mCampDic.ContainsKey(campType))
            return mCampDic[campType];
        return "";
    }
    #endregion
}
