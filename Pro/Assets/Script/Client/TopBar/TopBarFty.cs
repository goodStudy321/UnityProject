using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.10.13
    /// BG:头顶显示工厂
    /// </summary>
    public static class TopBarFty
    {
        #region 字段

        /// <summary>
        /// Npc名称条预制件名称
        /// </summary>
        public const string NpcBarStr = "NpcBar";

        /// <summary>
        /// 采集物名称条预制件显示
        /// </summary>
        public const string CollectBarStr = "CollectBar";

        /// <summary>
        /// Boss血条预制件名称
        /// </summary>
        public const string BossLifeBarStr = "BossLifeBar";

        /// <summary>
        /// 人物头像信息预制件名
        /// </summary>
        public const string UnitHeadBar = "UnitHeadBar";

        /// <summary>
        /// 通用血条(怪物)预制件名称
        /// </summary>
        public const string CommenLifeBarStr = "CommenLifeBar";

        /// <summary>
        /// 本地玩家头顶显示预制
        /// </summary>
        public const string LocalPlayerBarStr = "LocalPlayerBar";

        /// <summary>
        /// 非本地玩家头顶显示预制
        /// </summary>
        public const string OtherPlayerBarStr = "OtherPlayerBar";

        /// <summary>
        /// 掉落物头顶名字
        /// </summary>
        public const string DropStr = "DropStr";

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 创建头顶显示
        /// </summary>
        /// <param name="unit">拥有者</param>
        /// <param name="name">名称</param>
        /// <param name="title">称号</param>
        public static TopBarBase Create(Unit unit, string name, string title = "", int titleId = 0, ActorData actor = null )
        {
            UnitType unitType = unit.mUnitAttInfo.UnitType;
            CampType camp = (CampType)User.instance.MapData.Camp;
            TopBarBase topBar = null;
            switch (unitType)
            {
                case UnitType.None:
                    break;
                case UnitType.Role:
                    string barName = LocalPlayerBarStr;
                    if (unit.UnitUID != User.instance.MapData.UID)
                        barName = OtherPlayerBarStr;
                    unit.TopBar = CommenNameBar.Create(unit.UnitTrans, title, name, barName, 0, titleId, actor);
                    topBar = unit.TopBar;
                    break;
                case UnitType.Monster:
                    if (unit.Camp == camp)
                    {
                        string mBarName = OtherPlayerBarStr;
                        unit.TopBar = CommenNameBar.Create(unit.UnitTrans, title, name, mBarName, 1, titleId);
                        topBar = unit.TopBar;
                    }
                    else
                    {
                        if(User.instance.MonsterDic.ContainsKey(unit.UnitUID))
                        {
                            ActorData actData = User.instance.MonsterDic[unit.UnitUID];
                            if (actData != null)
                            {
                                string str = "LV" + actData.Level + "\n";
                                name = str + name;
                            }
                        }
                        topBar = UnitLifeBar.Create(unit, name, CommenLifeBarStr);
                    }
                    break;
                case UnitType.Collection:
                    break;
                case UnitType.NPC:
                    unit.TopBar = CommenNameBar.Create(unit.UnitTrans, title, name, NpcBarStr);
                    topBar = unit.TopBar;
                    break;
                case UnitType.Summon:
                    break;
                case UnitType.VirtualSummon:
                    break;
                case UnitType.Artifact:
                    break;
                case UnitType.MagicWeapon:
                    break;
                case UnitType.Wing:
                    break;
                case UnitType.Mount:
                    break;
                case UnitType.Pet:
                    break;
                case UnitType.Boss:
                    topBar = BossLifeBar.Create(unit, name);
                    break;
                default:
                    break;
            }
            return topBar;
        }

        /// <summary>
        /// 重置头顶条
        /// </summary>
        /// <param name="unit"></param>
        public static void ResetTopObject(Unit unit)
        {
            if (unit.TopBar == null)
                return;
            if (unit.TopBar is CommenNameBar)
            {
                CommenNameBar nameBar = unit.TopBar as CommenNameBar;
                nameBar.Target = unit.UnitTrans;
            }
            else if (unit.TopBar is UnitLifeBar)
            {
                UnitLifeBar lifeBar = unit.TopBar as UnitLifeBar;
                lifeBar.Owner = unit;
            }
        }

        /// <summary>
        /// 预加载
        /// </summary>
        public static void Preload()
        {
            PreloadMgr.prefab.Add(BossLifeBarStr, true);
            PreloadMgr.prefab.Add(NpcBarStr, true);
            PreloadMgr.prefab.Add(CollectBarStr, true);

            PreloadMgr.prefab.Add(LocalPlayerBarStr, true);
            PreloadMgr.prefab.Add(OtherPlayerBarStr, true);
            PreloadMgr.prefab.Add(CommenLifeBarStr, true);

            PreloadMgr.prefab.Add(DropStr, true);

        }
        #endregion
    }
}