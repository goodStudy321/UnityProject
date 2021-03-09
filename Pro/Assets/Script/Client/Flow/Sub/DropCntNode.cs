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
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        7ca4fff0-988d-4838-8778-f809f15bfb05
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/11/10 10:17:18
    /// BG:
    /// </summary>
    [Serializable]
    public class DropCntNode : FlowChartNode
    {
        #region 字段
        /// <summary>
        /// 计数
        /// </summary>
        private int cnt = 0;
        /// <summary>
        /// 拾取记录列表
        /// </summary>
        private List<ulong> pickRcds = new List<ulong>();

        /// <summary>
        /// 目标数量
        /// </summary>
        [SerializeField]
        [HideInInspector]
        private int total = 0;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 设置参数
        /// </summary>
        /// <param name="info"></param>
        private void SetCnt(ulong dropId)
        {
            if (!ChkDropEft(dropId))
                return;
            ++cnt;
            if (cnt < total) return;
            Complete();
        }

        /// <summary>
        /// 检查掉落物有效性
        /// </summary>
        /// <param name="dropId"></param>
        /// <returns></returns>
        private bool ChkDropEft(ulong dropId)
        {
            if (pickRcds.Contains(dropId))
                return false;
            pickRcds.Add(dropId);
            return true;
        }
        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            cnt = 0;
            if (total < 1)
            {
                Complete();
            }
            else
            {
                DropMgr.pickScs += SetCnt;
            }
        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            DropMgr.pickScs -= SetCnt;
            pickRcds.Clear();
        }

        public override void Dispose()
        {
            DropMgr.pickScs -= SetCnt;
            pickRcds.Clear();
        }

        #endregion

        #region 公开方法

        public override void Read(BinaryReader br)
        {
            base.Read(br);
            total = br.ReadInt32();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(total);
        }

        public override void Stop()
        {
            base.Stop();
            DropMgr.pickScs -= SetCnt;
            pickRcds.Clear();
        }
        #endregion
#if UNITY_EDITOR

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as DropCntNode;
            if (node == null) return;
            total = node.total;
        }

        protected override void EditDrawDebug(Object o)
        {
            EditorGUILayout.IntField("已拾取:", cnt);
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
            UIEditLayout.UIntField("数量:", ref total, o);

            EditorGUILayout.EndVertical();
        }
#endif
    }
}