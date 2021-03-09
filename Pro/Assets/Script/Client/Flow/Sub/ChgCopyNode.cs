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
     * GUID:        ed1da132-a788-48d6-a1db-b38451312163
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/10/19 20:12:23
    /// BG:
    /// </summary>
    [System.Serializable]
    public class ChgCopyNode : FlowChartNode
    {
        #region 字段
        [SerializeField]
        private int id;

        [SerializeField]
        private bool load = true;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public ChgCopyNode()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            Complete();
            NetworkMgr.ReqPreEnter(id, 0);
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            id = br.ReadInt32();
            load = br.ReadBoolean();

        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(id);
            bw.Write(load);

        }
        #endregion

        #region 编辑器字段/属性/方法
#if UNITY_EDITOR

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as ChgCopyNode;
            if (node == null) return;
            id = node.id;
            load = node.load;
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);

            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.UIntField("副本ID:", ref id, o);
            UIEditLayout.Toggle("切换场景:", ref load, o);
            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }
}