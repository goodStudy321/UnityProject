/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/10/19 22:58:39
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
    /// ABChkView
    /// </summary>
    public class ABValidView : EditViewBase
    {
        #region 字段
        public string dir = "../Assets";

        public FilePage page = new FilePage();
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void Check()
        {
            if (Directory.Exists(dir))
            {
                var lst = ABUtil.Check(dir);
                page.SetLst(lst);
                if (page.lst == null)
                {
                    UIEditTip.Log("未发现无效资源");
                }
                else
                {
                    UIEditTip.Warning("发现无效资源");
                }
            }
            else
            {
                UIEditTip.Error("未设置目录");
            }
        }
        #endregion

        #region 保护方法
        protected override void Title()
        {
            EditorGUILayout.BeginHorizontal(EditorStyles.toolbar);
            GUILayout.FlexibleSpace();
            if (TitleBtn("检查"))
            {
                DialogUtil.Show("", "确定检查？", Check);
            }
            EditorGUILayout.EndHorizontal();
        }

        protected override void OnGUICustom()
        {
            UIEditLayout.SetFolder("AB目录:", ref dir, this);
            page.OnGUI(this);
        }
        #endregion

        #region 公开方法

        #endregion
    }
}