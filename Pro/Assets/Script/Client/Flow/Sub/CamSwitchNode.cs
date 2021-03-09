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
    /// TM:2016.05.13,12:07:37
    /// CO:nuolan1.ActionSoso1
    /// BG:
    /// </summary>
    [System.Serializable]
    public class CamSwitchNode : FlowChartNode
    {
        #region 字段
        public int on = 0;
        #endregion

        #region 属性

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            CameraMgr.Lock = ((on == 0) ? true : false);
            Complete();
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            on = br.ReadInt32();

        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(on);

        }
        #endregion


        #region 编辑器字段/属性/方法
#if UNITY_EDITOR

        private string[] arr = new string[] { "关", "开" };

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as CamSwitchNode;
            if (node == null) return;
            on = node.on;
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 4";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);

            EditorGUILayout.BeginVertical(GUI.skin.box);

            on = EditorGUILayout.Popup("相机更新:", on, arr);

            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }
}