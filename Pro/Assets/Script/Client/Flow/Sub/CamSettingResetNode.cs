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
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        1bb46ced-9b5a-436c-b43d-17bf59695fae
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/28 17:52:04
    /// BG:还原相机设置
    /// </summary>
    [Serializable]
    public class CamSettingResetNode : FlowChartNode
    {
        #region 字段
        /// <summary>
        /// 还原Fov时间
        /// </summary>
        public float resetFovTime = 2f;

        /// <summary>
        /// 还原位置时间
        /// </summary>
        public float resetPositionTime = 2f;

        /// <summary>
        /// 还原角度时间
        /// </summary>
        public float resetEulerAngleTime = 2f;
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
            var old = CameraMgr.CamOperation as CameraPlayerNewOperation;
            old.RestoreCamearInfo(resetPositionTime, resetPositionTime, resetEulerAngleTime, resetEulerAngleTime, resetFovTime);
            Complete();
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            resetFovTime = br.ReadSingle();
            resetPositionTime = br.ReadSingle();
            resetEulerAngleTime = br.ReadSingle();

        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(resetFovTime);
            bw.Write(resetPositionTime);
            bw.Write(resetEulerAngleTime);

        }
        #endregion

        #region 编辑器字段/属性/方法
#if UNITY_EDITOR

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as CamSettingResetNode;
            if (node == null) return;
            resetFovTime = node.resetFovTime;
            resetPositionTime = node.resetPositionTime;
            resetEulerAngleTime = node.resetEulerAngleTime;
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 4";
        }
        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.Slider("还原位置时间:", ref resetPositionTime, 0, 20, o);
            UIEditLayout.Slider("还原角度时间:", ref resetEulerAngleTime, 0, 20, o);
            UIEditLayout.Slider("还原视锥时间:", ref resetFovTime, 0, 20, o);
            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }
}