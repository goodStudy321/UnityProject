//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/5/10 10:34:17
//=============================================================================

using System;
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
    /// UICopyInfoMainNode
    /// </summary>
    [System.Serializable]
    public class UICopyInfoMainOnNode : FlowChartNode
    {
        #region 字段
        private UICopyMainInfoData data = new UICopyMainInfoData();
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
            UICopyInfoMain.Instance.Open(data);
            Complete();
        }


        #endregion

        #region 公开方法

        public override void Read(BinaryReader br)
        {
            base.Read(br);
            data.Read(br);
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            data.Write(bw);
        }

        public override void Preload()
        {
            UICopyInfoMain.Instance.Preload();
        }

        #endregion

#if UNITY_EDITOR

        public override bool CanFlag
        {
            get
            {
                return true;
            }
        }

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as UICopyInfoMainOnNode;
            if (node == null) return;
            data.Copy(node.data);
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 5";
        }

        public override void EditDrawProperty(UnityEngine.Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical(StyleTool.Group);

            data.Draw(o);
            EditorGUILayout.EndVertical();
        }
#endif
    }
}