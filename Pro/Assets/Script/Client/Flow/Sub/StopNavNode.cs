using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{

    /// <summary>
    /// AU:Loong
    /// TM:2015.11.03,15:58:24
    /// CO:nuolan1.ActionSoso1
    /// BG:
    /// </summary>
    [System.Serializable]
    public class StopNavNode : FlowChartNode
    {
        #region 字段
        /// <summary>
        /// 0:敌人 1:右方 2:全部
        /// </summary>
        public int option = 0;
        #endregion

        #region 属性

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            List<Unit> lst = UnitMgr.instance.UnitList;
            int length = lst.Count;
            CampType camp = (CampType)User.instance.MapData.Camp;
            for (int i = 0; i < length; i++)
            {
                Unit unit = lst[i];
                switch (option)
                {
                    case 0:
                        if (unit.Camp != camp) unit.mUnitMove.StopNav();
                        break;
                    case 1:
                        if (unit.Camp == camp) unit.mUnitMove.StopNav();
                        break;
                    case 2:
                        unit.mUnitMove.StopNav();
                        break;
                    default:
                        break;
                }
            }
            Complete();
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            option = br.ReadInt32();

        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(option);

        }
        #endregion

        #region 编辑器字段/属性/方法

#if UNITY_EDITOR

        private string[] arr = new string[] { "敌人", "友方", "全部" };
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as StopNavNode;
            if (node == null) return;
            option = node.option;
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 3";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical();

            EditorGUILayout.HelpBox("对所有已经存在的单位停止寻路", MessageType.Info);
            UIEditLayout.Popup("停止类型:", ref option, arr, o);
            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }
}