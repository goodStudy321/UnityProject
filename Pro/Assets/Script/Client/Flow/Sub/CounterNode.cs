using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{

    /// <summary>
    /// AU:Loong
    /// TM:2015.11.04,10:27:47
    /// CO:nuolan1.ActionSoso1
    /// BG:计数器
    /// </summary>
    [Serializable]
    public class CounterNode : FlowChartNode
    {
        #region 字段
        private int count = 0;

        /// <summary>
        /// 0:活着 1:死亡
        /// </summary>
        public int option = 1;

        /// <summary>
        /// 数量
        /// </summary>
        public int totalCount = 0;

        /// <summary>
        /// 单位TypeID
        /// </summary>
        public int typeID = 0;


        #endregion

        #region 属性

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法



        /// <summary>
        /// 对活着计数
        /// </summary>
        protected virtual void CounterAlive()
        {
            List<Unit> units = UnitMgr.instance.UnitList;
            int unitsLen = units.Count;
            uint utypeID = (uint)typeID;
            for (int i = 0; i < unitsLen; i++)
            {
                Unit u = units[i];
                if (u.TypeId == utypeID)
                {
                    ++count;
                    if (count == totalCount)
                    {
                        Complete();
                    }
                }
            }
        }

        protected override void ReadyCustom()
        {
            if (option == 0)
            {
                CounterAlive(); return;
            }
            if (totalCount == 0)
            {
                Debug.LogError(Format("计数信息列表为空"));
                Complete();
            }
            else
            {
#if UNITY_EDITOR
                dieLst.Clear();
#endif
                UnitEventMgr.die += OnUnitDie;
            }

        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            if (option == 1)
            {
                UnitEventMgr.die -= OnUnitDie;
            }
            count = 0;
        }

        #endregion

        #region 公开方法

        public override void Read(BinaryReader br)
        {
            base.Read(br);
            option = br.ReadInt32();
            totalCount = br.ReadInt32();
            typeID = br.ReadInt32();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(option);
            bw.Write(totalCount);
            bw.Write(typeID);
        }
        public void OnUnitDie(Unit u)
        {
            if (Transition != TransitionState.Update) return;
            uint uTypeID = (uint)typeID;
            if (u.TypeId == uTypeID)
            {
                ++count;
#if UNITY_EDITOR
                dieLst.Add(u.UnitUID);
#endif
                if (count == totalCount)
                {
                    Complete();
                }
            }
        }

        public override void Preload()
        {

        }

        public override void Dispose()
        {
            UnitEventMgr.die -= OnUnitDie;
        }

        #endregion


        #region 编辑器字段/属性/方法

#if UNITY_EDITOR

        /// <summary>
        /// 已杀死的怪
        /// </summary>
        private List<long> dieLst = new List<long>();

        private string[] liveArr = new string[] { "活着", "死亡" };


        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as CounterNode;
            if (node == null) return;
            option = node.option;
            totalCount = node.totalCount;
            typeID = node.typeID;
        }

        protected override void EditDrawDebug(Object o)
        {
            UIDrawTool.LongLst(o, dieLst, "DieLst", "已杀死单位UID列表");
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 1";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.Popup("生死类型:", ref option, liveArr, o);
            UIEditLayout.UIntField("单位TypeID:", ref typeID, o);
            UIEditLayout.IntSlider("总数量:", ref totalCount, 1, 666, o);


            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }
}