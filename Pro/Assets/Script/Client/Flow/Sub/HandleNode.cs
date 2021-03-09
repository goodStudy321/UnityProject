//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/2/21 21:01:07
//=============================================================================

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
    /// HandleNode
    /// </summary>
    [System.Serializable]
    public class HandleNode : FlowChartNode
    {
        #region 字段
        public List<string> nodeNames = new List<string>();
        #endregion

        #region 属性

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            int length = nodeNames.Count;
            for (int i = 0; i < length; i++)
            {
                var nodeName = nodeNames[i];
                if (string.IsNullOrEmpty(nodeName))
                {
                    continue;
                }
                var node = flowChart.Get(nodeName);
                if (node == null)
                {
                    Debug.LogError(Format("can't find node with name:{0}", nodeName));
                }
                else
                {
                    Handle(node);
                }
            }
            Complete();
        }

        protected virtual void Handle(FlowChartNode node)
        {

        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            int length = br.ReadInt32();
            for (int i = 0; i < length; i++)
            {
                var it = "";
                ExString.Read(ref it, br);
                nodeNames.Add(it);
            }
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            int length = nodeNames.Count;
            bw.Write(length);
            for (int i = 0; i < length; i++)
            {
                var it = nodeNames[i];
                //bw.Write(it);
                ExString.Write(it, bw);
            }
        }
        #endregion


        #region 编辑器字段/方法/属性
#if UNITY_EDITOR
        private string pickNode = null;
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as HandleNode;
            if (node == null) return;
            int length = node.nodeNames.Count;
            for (int i = 0; i < length; i++)
            {
                nodeNames.Add(node.nodeNames[i]);
            }
        }
        /// <summary>
        /// 拾取节点改变
        /// </summary>
        private void PickChange()
        {
            if (pickNode == null) return;
            var node = flowChart.Get(pickNode);
            if (node == null) return;
            var typeName = node.GetType().Name;

            string msg = string.Format("确定拾取类型:{0}?", typeName);
            if (!EditorUtility.DisplayDialog("", msg, "确定", "取消")) return;
            nodeNames.Clear();
            int length = flowChart.Nodes.Count;
            for (int i = 0; i < length; i++)
            {
                var it = flowChart.Nodes[i];
                if (it.GetType().Name == typeName)
                {
                    nodeNames.Add(it.name);
                }
            }
            UIEditTip.Log("添加了{0}个", nodeNames.Count);
        }


        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 1";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            UIEditLayout.HelpWaring("此节点将释放指定的节点");
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.TextField("拾取节点类型:", ref pickNode, o, PickChange);
            EditorGUILayout.EndVertical();
            UIDrawTool.StringLst(o, nodeNames, "DisposeNodes", "释放节点列表");
        }
#endif
        #endregion
    }
}