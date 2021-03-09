using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /*
     * CO:            
     * Copyright:   2016-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        620af52b-5d9b-4ea1-9be9-743633b0749c
    */

    /// <summary>
    /// AU:Loong
    /// TM:2016/11/7 10:39:41
    /// BG:
    /// </summary>
    [Serializable]
    public class CounterNodeBase : FlowChartNode
    {
        #region 字段
        /// <summary>
        /// 计数数量
        /// </summary
        private int count = 0;

        /// <summary>
        /// 计数目标数量
        /// </summary>
        [SerializeField]
        protected int targetCount = 1;


        /// <summary>
        /// 计数类型选项:0:活着,1:死亡
        /// </summary>
        [SerializeField]
        protected int dieOption = 1;

        /// <summary>
        /// ID集
        /// </summary>
        protected HashSet<UInt64> uidSet = new HashSet<UInt64>();

        /// <summary>
        /// ID列表
        /// </summary>
        public List<string> uidLst = new List<string>();
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法


        #endregion

        #region 保护方法
        /// <summary>
        /// 添加UID
        /// </summary>
        /// <param name="uid"></param>
        protected void Add(UInt64 uid)
        {
            if (uidSet.Contains(uid))
            {
                Debug.LogError(Format(string.Format("重复UID:{0}", uid)));
            }
            else
            {
                uidSet.Add(uid);
            }
        }

        /// <summary>
        /// 添加UID
        /// </summary>
        /// <param name="parameter"></param>
        protected void Add(string parameter)
        {
            UInt64 uid = 0;
            if (UInt64.TryParse(parameter, out uid))
            {
                Add(uid);
            }
            else
            {
                Debug.LogError(Format(string.Format("无效UID:{0}", parameter)));
            }
        }

        protected override void ReadyCustom()
        {
            uidSet.Clear();
            SetUidSet();
            if (dieOption == 1)
            {
                UnitEventMgr.die += OnUnitDie;
            }
            else
            {
                Alive();
            }
        }

        /// <summary>
        /// 设置UID集
        /// </summary>
        protected virtual void SetUidSet()
        {
            int length = uidLst.Count;
            for (int i = 0; i < length; i++)
            {
                string item = uidLst[i];
                Add(item);
            }
        }

        /// <summary>
        /// 判断是否活着
        /// </summary>
        protected void Alive()
        {

            Complete();
        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            UnitEventMgr.die -= OnUnitDie;
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            targetCount = br.ReadInt32();
            dieOption = br.ReadInt32();
            int length = br.ReadInt32();
            for (int i = 0; i < length; i++)
            {
                var it = br.ReadString();
                uidLst.Add(it);
            }
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(targetCount);
            bw.Write(dieOption);
            int length = uidLst.Count;
            bw.Write(length);
            for (int i = 0; i < length; i++)
            {
                var it = uidLst[i];
                bw.Write(it);
            }
        }

        public void OnUnitDie(Unit u)
        {
            if (Transition != TransitionState.Update) return;
            if (uidSet.Contains(u.ModelId)) count++;
            if (count < targetCount) return;
            Complete();
        }

        public override void Dispose()
        {
            UnitEventMgr.die -= OnUnitDie;
        }
        #endregion
        #region 编辑器字段/属性/方法

#if UNITY_EDITOR

        private string[] dieOptionArr = new string[] { "活着", "死亡" };

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as CounterNodeBase;
            if (node == null) return;
            targetCount = node.targetCount;
            dieOption = node.dieOption;
            int length = node.uidLst.Count;
            for (int i = 0; i < length; i++)
            {
                uidLst.Add(node.uidLst[i]);
            }
        }


        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 1";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical("groupbox");
            UIDrawTool.StringLst(o, uidLst, "CounterUidLst", "UID列表");
            dieOption = EditorGUILayout.Popup("计数类型:", dieOption, dieOptionArr);
            targetCount = EditorGUILayout.IntField("计数数量:", targetCount);
            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }
}