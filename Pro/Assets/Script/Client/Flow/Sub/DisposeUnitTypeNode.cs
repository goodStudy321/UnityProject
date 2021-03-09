using System.IO;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;

#if UNITY_EDITOR
using UnityEditor;
#endif
namespace Phantom
{
    /// <summary>
    /// AU:Loong
    /// TM:2016.06.13,19:43:22
    /// CO:nuolan1.ActionSoso1
    /// BG:释放不同阵营类型的单位
    /// </summary>
    [System.Serializable]
    public class DisposeUnitTypeNode : FlowChartNode
    {
        #region 字段
        /// <summary>
        /// 类型
        /// </summary>

        public UnitCamp type = UnitCamp.Enemy;
        #endregion

        #region 属性

        #endregion

        #region 私有方法
        /// <summary>
        /// 释放出生点
        /// </summary>
        private void DisposeSpawnNode()
        {
            var spawns = flowChart.FindNodes<SpawnNode>();
            if (spawns == null || spawns.Count == 0) return;
            int length = spawns.Count;
            for (int i = 0; i < length; i++)
            {
                var node = spawns[i];
                node.Dispose();
            }
        }

        private void DisposeUnits(List<Unit> units)
        {

        }

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            DisposeSpawnNode();
            var units = UnitMgr.instance.UnitList;
            int length = units.Count;
            CampType camp = (CampType)User.instance.MapData.Camp;
            for (int i = 0; i < length; i++)
            {
                Unit unit = units[i];
                if (type == UnitCamp.Friend)
                    if (camp != unit.Camp) continue;
                    else
                    if (camp == unit.Camp) continue;
                UnitMgr.instance.SetUnitDead(unit);
            }
            Complete();
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            type = (UnitCamp)br.ReadInt32();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write((int)type);
        }
        #endregion

        #region 编辑器字段/方法/属性
#if UNITY_EDITOR
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as DisposeUnitTypeNode;
            if (node == null) return;
            type = node.type;
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 2";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical("box");
            type = (UnitCamp)EditorGUILayout.Popup("阵营类型:", (int)type, DefineTool.unitCampArr);
            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }
}