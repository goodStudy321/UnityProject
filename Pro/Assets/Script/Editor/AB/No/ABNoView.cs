/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/3 15:57:23
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// ABNoView
    /// </summary>
    public class ABNoView : EditViewBase
    {
        #region 字段
        public List<string> dirs = new List<string>();
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private void Search()
        {
            if (dirs.Count < 1)
            {
                UIEditTip.Error("无搜索目录");
            }
            else
            {
                var paths = ABNameUtil.GetPathsNone(dirs);
                if (paths == null || paths.Count < 1)
                {
                    UIEditTip.Error("无匹配文件");
                }
                else
                {
                    ObjsWin.Open(paths);
                }
            }
        }

        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            EditorGUILayout.BeginHorizontal(EditorStyles.toolbar);
            GUILayout.FlexibleSpace();
            if (GUILayout.Button("搜索", EditorStyles.toolbarButton, UIOptUtil.toolBarBtn))
            {
                Search();
            }
            EditorGUILayout.EndHorizontal();
            UIEditLayout.HelpWaring("可拖拽到此区域添加");
            DragDropUtil.AddDirs(dirs);
            UIDrawTool.StringLst(this, dirs, "ANNoDirs", "搜索目录列表");
        }
        #endregion

        #region 公开方法

        #endregion
    }
}