//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/11/8 12:24:47
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Xml.Serialization;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// UILabelInfo
    /// </summary>
    [Serializable]
    public class UILabelInfo
    {
        #region 字段
        public UILabel lbl = null;

        public string path = null;

        public int lblIdx = 0;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public UILabelInfo()
        {

        }

        public UILabelInfo(UILabel lbl)
        {
            this.lbl = lbl;
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        public void ClearText()
        {
            lbl.text = null;
        }

        public void ClearTextWithTip()
        {
            ClearText();
            UIEditTip.Log("已清除");
        }
        protected virtual void OnClickLbl()
        {
            ++lblIdx;
            if (lblIdx >= StyleTool.Labels.Length)
            {
                lblIdx = 0;
            }
            if (Event.current != null) Event.current.Use();
        }
        #endregion

        #region 公开方法
        public void OnGUI(Object o)
        {
            EditorGUILayout.BeginHorizontal(StyleTool.Box);
            if (lbl == null)
            {
                EditorGUILayout.LabelField("this label is missing!");
            }
            else
            {
                EditorGUILayout.TextField(lbl.name, UIOptUtil.btn);
                EditorGUILayout.TextField(path);
                EditorGUILayout.TextField(lbl.text);

                if (GUILayout.Button("", StyleTool.GreenActivePing, UIOptUtil.plus))
                {
                    EditUtil.Ping(lbl.gameObject);
                }
                if (GUILayout.Button("", StyleTool.Labels[lblIdx], UIOptUtil.smallWd))
                {
                    OnClickLbl();
                }
                else if (GUILayout.Button("清除", UIOptUtil.btn))
                {
                    DialogUtil.Show("", "清除标签的文本内容?", ClearTextWithTip);
                }

                EditorGUILayout.Space();
            }
            EditorGUILayout.EndHorizontal();

        }
        #endregion
    }
}