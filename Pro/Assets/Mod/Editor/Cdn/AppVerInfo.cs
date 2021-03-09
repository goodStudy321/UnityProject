//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/31 15:47:22
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using System.Text;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    using Object = UnityEngine.Object;

    /// <summary>
    /// 资源版本号信息
    /// </summary>
    [Serializable]
    public class AppVerInfo
    {
        #region 字段
        /// <summary>
        /// 内部版本号
        /// </summary>
        public int verCode = 0;

        /// <summary>
        /// 用户版本号
        /// </summary>
        public string verName = "1.0.0";

        /// <summary>
        /// 0:非强制更新,1强制跟新
        /// </summary>
        public int op = 0;


        public string content = null;


        private string[] opArr = new string[] { "否", "是" };
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public AppVerInfo()
        {
            SetContent();
        }
        #endregion

        #region 私有方法

        private void SetContent()
        {
            content = ToString();
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void Reset()
        {
            verCode = 0;
            verName = "1.0.0";
            op = 0;
            SetContent();
        }

        public void OnGUI(Object o)
        {
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.UIntField("安装包版本号:", ref verCode, o, SetContent);
            EditorGUILayout.LabelField("用于确定是否是更新安装包");
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            UIEditLayout.TextField("用户版本号:", ref verName, o, SetContent);
            EditorGUILayout.LabelField("显示给用户的版本号");
            EditorGUILayout.EndHorizontal();

            UIEditLayout.Popup("强制更新", ref op, opArr, o, SetContent);

            if (string.IsNullOrEmpty(content)) SetContent();
            EditorGUILayout.TextField("版本号内容:", content);
        }

        public override string ToString()
        {
            return string.Format("{0},{1},{2}", verCode, verName, op);
        }

        public string GetInitStr()
        {
            return "0,1.0.0,0";
        }
        #endregion
    }
}