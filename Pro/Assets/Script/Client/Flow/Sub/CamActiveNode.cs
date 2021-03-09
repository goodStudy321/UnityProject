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
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        c9405e9b-aea5-420a-a566-778eacc88c0e
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/12/4 12:31:37
    /// BG:
    /// </summary>
    [System.Serializable]
    public class CamActiveNode : FlowChartNode
    {
        #region 字段
        public bool activeCam = false;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public CamActiveNode()
        {
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            base.ReadyCustom();
            CameraMgr.Main.gameObject.SetActive(activeCam);
            Complete();
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            activeCam = br.ReadBoolean();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(activeCam);
        }
        #endregion

        #region 编辑器字段/属性/方法
#if UNITY_EDITOR
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as CamActiveNode;
            if (node == null) return;
            activeCam = node.activeCam;
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
            UIEditLayout.Toggle("激活:", ref activeCam, o);
            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }
}