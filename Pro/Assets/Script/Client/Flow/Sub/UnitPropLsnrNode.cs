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
     * GUID:        b2e5de50-8bc8-4e46-91de-a67c4444421e
    */

    /// <summary>
    /// AU:Loong
    /// TM:2016/11/4 14:18:28
    /// BG:单位属性监听节点
    /// </summary>
    [Serializable]
    public class UnitPropLsnrNode : FlowChartNode
    {
        #region 字段
        /// <summary>
        /// 完成计数
        /// </summary>
        private int completeCount = 0;

        /// <summary>
        /// 监听列表
        /// </summary>
        private List<UnitPropLsnr> listeners = new List<UnitPropLsnr>();

        /// <summary>
        /// 逻辑类型
        /// </summary>
        public LogicalType logicalType = LogicalType.Or;

        /// <summary>
        /// 监听信息
        /// </summary>
        public List<UnitPropertyInfo> infos = new List<UnitPropertyInfo>();
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        /// <summary>
        /// 结束处理器
        /// </summary>
        private void CompleteHandler()
        {
            completeCount++;
            if (logicalType == LogicalType.Or)
            {
                Complete();
            }
            else if (logicalType == LogicalType.And)
            {
                if (completeCount == infos.Count) Complete();
            }
        }

        /// <summary>
        /// 校验处理器
        /// </summary>
        /// <returns></returns>
        private bool CheckHandler()
        {
            return Transition == TransitionState.Update;
        }
        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            int length = listeners.Count;
            for (int i = 0; i < length; i++)
            {
                UnitPropLsnr listener = listeners[i];
                listener.Add();
                listener.AddCheckEvent(CheckHandler);
                listener.AddCompleteEvent(CompleteHandler);
            }
        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            Dispose();
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            logicalType = (LogicalType)br.ReadInt32();
            int length = br.ReadInt32();
            for (int i = 0; i < length; i++)
            {
                var it = new UnitPropertyInfo();
                it.Read(br);
                infos.Add(it);
            }
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write((int)logicalType);
            int length = infos.Count;
            bw.Write(length);
            for (int i = 0; i < length; i++)
            {
                var it = infos[i];
                it.Write(bw);
            }
        }

        public override void Stop()
        {
            base.Stop();
            Dispose();
        }

        public override void Initialize()
        {
            base.Initialize();
            int length = infos.Count;
            for (int i = 0; i < length; i++)
            {
                var info = infos[i];
                var lsnr = UnitPropLsnrFty.Create(info);
                listeners.Add(lsnr);
            }
        }

        public override void Dispose()
        {
            int length = listeners.Count;
            for (int i = 0; i < length; i++) listeners[i].Dispose();
        }
        #endregion


        #region 编辑器字段/属性/方法

#if UNITY_EDITOR

        private string[] logicalTypeArr = new string[] { "或", "与" };


        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 2";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            logicalType = (LogicalType)EditorGUILayout.Popup("逻辑类型:", (int)logicalType, logicalTypeArr);
            UIEditLayout.HelpError("UID为-1时,代表本地玩家");
            UIDrawTool.IDrawLst<UnitPropertyInfo>(o, infos, "UnitPropertyInfos", "监听列表");
        }

#endif
        #endregion
    }
}