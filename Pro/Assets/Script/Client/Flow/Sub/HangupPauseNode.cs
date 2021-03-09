//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/4/4 17:03:47
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /// <summary>
    /// HangupPauseNode
    /// </summary>
    public class HangupPauseNode : FlowChartNode
    {
        #region 字段
        /// <summary>
        /// 0:暂停,1: 恢复
        /// </summary>
        public int option = 0;
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
            HangupMgr.instance.IsPause = (option < 1 ? true : false);
            Complete();
        }
        #endregion

        #region 公开方法

#if UNITY_EDITOR
        private string[] optionArr = new string[] { "暂停", "恢复" };

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as HangupPauseNode;
            if (node == null) return;
            option = node.option;
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 2";
        }

        public override void EditDrawProperty(Object o)
        {
            EditorGUILayout.BeginVertical(StyleTool.Box);
            UIEditLayout.Popup("选项:", ref option, optionArr, o);
            EditorGUILayout.EndVertical();
        }

#endif
        #endregion
    }
}