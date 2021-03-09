/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2014/6/23 10:44:55
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{

    /// <summary>
    /// Svn设置视图
    /// </summary>
    public class SvnView : EditViewBase
    {
        #region 字段
        /// <summary>
        /// 根目录
        /// </summary>
        [HideInInspector]
        public string root = "../";

        /// <summary>
        /// Svn路径
        /// </summary>
        [HideInInspector]
        public string svnExe = null;
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void SetProperty()
        {
            if (!UIEditTool.DrawHeader("基础属性", "SvnViewProperty", StyleTool.Host)) return;
            EditorGUILayout.BeginVertical(StyleTool.Box);
            UIEditLayout.SetFolder("根目录:", ref root, this);
            UIEditLayout.SetPath("Svn安装路径:", ref svnExe, this, "exe");
            EditorGUILayout.EndVertical();
        }

        private void ShowCommand()
        {
            if (!UIEditTool.DrawHeader("命令", "SvnViewCommand", StyleTool.Host)) return;
            EditorGUILayout.BeginHorizontal(StyleTool.Box);
            EditorGUILayout.LabelField(string.Format("更新目录:{0}", root));
            if (GUILayout.Button("更新")) SvnUtil.UpdateRoot();
            EditorGUILayout.EndHorizontal();
        }
        #endregion

        #region 保护方法
        /// <summary>
        /// 绘制
        /// </summary>
        protected override void OnGUICustom()
        {
            SetProperty();
            EditorGUILayout.Space();
            ShowCommand();
        }
        #endregion

        #region 公开方法
        /// <summary>
        /// 检查
        /// </summary>
        /// <returns></returns>
        public bool Check()
        {
            if (!File.Exists(svnExe))
            {
                UIEditTip.Error("必须选择有效的Svn启动文件,一般名为:tortoiseproc.exe");
                return false;
            }
            if (!Directory.Exists(root))
            {
                UIEditTip.Error("必须设置有效的更新目录");
                return false;
            }
            return true;
        }
        #endregion
    }
}