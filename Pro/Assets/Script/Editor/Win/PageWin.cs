//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/2/23 10:39:16
//=============================================================================

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// PageWin
    /// </summary>
    public class PageWin<T1, T2> : EditorWindow where T1 : Page<T2>, new() where T2 : class
    {
        #region 字段
        public T1 page = new T1();
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
        protected virtual void OnGUI()
        {
            EditorGUILayout.BeginVertical(StyleTool.Bg);
            page.OnGUI(this);
            EditorGUILayout.EndVertical();
        }


        #endregion

        #region 公开方法
        public virtual void Init(List<T2> objs)
        {
            this.SetSize(600, 800);
            page.SetLst(objs);
            Show();
        }

        public virtual void Init(T2[] arr)
        {
            List<T2> lst = (arr == null ? null : new List<T2>(arr));
            Init(lst);
        }
        #endregion
    }
}