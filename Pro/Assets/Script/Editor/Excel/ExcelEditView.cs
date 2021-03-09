/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2014/9/28
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

using NPOI;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;

namespace Loong.Edit
{
    /// <summary>
    /// Excel编辑视图
    /// </summary>
    public class ExcelEditView : EditViewBase
    {
        #region 字段

        #endregion

        #region 属性
        /// <summary>
        /// 表单名称
        /// </summary>
        public virtual string SheetName { get { return "Sheet1"; } }

        /// <summary>
        /// Excel文件相对路径
        /// </summary>
        protected virtual string RelativePath { get { return ""; } }

        /// <summary>
        /// Excel文件绝对路径
        /// </summary>
        public string FullPath { get { return Path.GetFullPath(RelativePath); } }
        #endregion

        #region 私有方法
        /// <summary>
        /// 返回/有对话框
        /// </summary>
        private void ReturnWithDialog()
        {
            DialogUtil.Show("", "数据保存了吗", Return);
        }

        #endregion

        #region 



        protected override void OpenCustom()
        {
            Read();
        }


        protected override void ContextClick()
        {
            GenericMenu menu = new GenericMenu();
            menu.AddItem("保存", false, Write);
            menu.AddSeparator("");
            menu.AddItem("返回", false, ReturnWithDialog);
            menu.AddSeparator("");
            menu.AddItem("打开Excel", false, OpenExcel);
            ContextClickCustom(menu);
            menu.ShowAsContext();
        }

        protected virtual void ContextClickCustom(GenericMenu menu)
        {

        }

        /// <summary>
        /// 从Excel中读取数据
        /// </summary>
        protected virtual void Read()
        {

        }

        /// <summary>
        /// 向Excel中写入数据
        /// </summary>
        protected virtual void Write()
        {

        }


        /// <summary>
        /// 返回/无对话框
        /// </summary>
        protected virtual void Return()
        {

        }

        /// <summary>
        /// 打开Excel
        /// </summary>
        protected virtual void OpenExcel()
        {
            ExcelTool.Open(FullPath);
        }



        /// <summary>
        /// 绘制场景视图UI
        /// </summary>
        protected virtual void DrawSceneGUI()
        {

        }

        /// <summary>
        /// 绘制场景视图操作
        /// </summary>
        protected virtual void DrawSceneHandle()
        {

        }

        #endregion

        #region 公开方法

        public override void OnSceneGUI(SceneView sceneView)
        {
            Handles.BeginGUI();
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.BeginVertical();
            GUILayout.FlexibleSpace();
            EditorGUILayout.BeginVertical(GUI.skin.window, GUILayout.Width(180));
            DrawSceneGUI();
            GUILayout.EndVertical();
            EditorGUILayout.Space();
            EditorGUILayout.Space();
            EditorGUILayout.Space();
            EditorGUILayout.EndVertical();
            GUILayout.FlexibleSpace();
            EditorGUILayout.EndHorizontal();
            Handles.EndGUI();
            DrawSceneHandle();
        }
        #endregion
    }
}