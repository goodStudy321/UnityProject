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
     * GUID:        ccaffb98-84bb-44e6-8cc1-6786684db905
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/11/23 17:47:53
    /// BG:
    /// </summary>
    [Serializable]
    public class MssnEndLsnrNode : FlowChartNode
    {
        #region 字段
        /// <summary>
        /// 任务ID
        /// </summary>
        public int id = 0;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void MssnEndLnsr(params object[] args)
        {
            if (args == null || args.Length < 1) return;
            int cur = Convert.ToInt32(args[0]);
            if (cur != id) return;
            Complete();
        }
        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            if (id < 1)
            {
                Complete();
            }
            else
            {
                EventMgr.Add("MssnEnd", MssnEndLnsr);
            }
        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            EventMgr.Remove("MssnEnd", MssnEndLnsr);
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            id = br.ReadInt32();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(id);
        }

        public override void Stop()
        {
            base.Stop();
            EventMgr.Remove("MssnEnd", MssnEndLnsr);
        }

        public override void Dispose()
        {
            EventMgr.Remove("MssnEnd", MssnEndLnsr);
        }
        #endregion


#if UNITY_EDITOR
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as MssnEndLsnrNode;
            if (node == null) return;
            id = node.id;
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 1";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            UIEditLayout.UIntField("任务ID:", ref id, o);
            if (id < 1) UIEditLayout.HelpError("请输入ID");
        }
#endif
    }
}