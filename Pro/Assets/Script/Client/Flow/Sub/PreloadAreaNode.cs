//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/5/11 10:26:42
//=============================================================================

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
    /// <summary>
    /// PreloadAreaNode
    /// </summary>
    public class PreloadAreaNode : FlowChartNode
    {
        #region 字段
        public int id = 0;
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
            PreloadAreaMgr.Instance.Start((uint)id, Complete);
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
        #endregion


#if UNITY_EDITOR


        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as PreloadAreaNode;
            if (node == null) return;
            id = node.id;
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);

            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.IntField("区域预加载ID:", ref id, o);
            EditorGUILayout.EndVertical();
        }

#endif
    }
}