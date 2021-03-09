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
     * Copyright:   2018-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        43aa6a4f-2465-46d0-b7ba-4e50bc5f7a66
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/1/9 20:53:58
    /// BG:相机模糊节点
    /// </summary>
    [Serializable]
    public class FxBlurNode : FlowChartNode
    {
        #region 字段
        /// <summary>
        /// 强度
        /// </summary>
        public float strength = 0f;
        /// <summary>
        /// 模糊中心
        /// </summary>
        public Vector2 center = Vector2.zero;

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            CameraMgr.StartBlurEff(center, strength);
            Complete();
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            strength = br.ReadSingle();
            ExVector.Read(ref center, br);
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(strength);
            center.Write(bw);
        }

        public override void Stop()
        {
            base.Stop();
            CameraMgr.StopBlurEff();
        }
        #endregion


#if UNITY_EDITOR
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as FxBlurNode;
            if (node == null) return;
            strength = node.strength;
            center = node.center;
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 4";
        }

        public override void EditDrawProperty(Object o)
        {
            EditorGUILayout.BeginVertical(GUI.skin.box);
            UIEditLayout.Vector2Field("模糊中心:", ref center, o);
            UIEditLayout.Slider("模糊强度:", ref strength, 0, 360, o);
            EditorGUILayout.EndVertical();
        }

#endif
    }
}