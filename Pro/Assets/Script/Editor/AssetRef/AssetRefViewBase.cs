/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/6/17 17:28:30
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;
using UnityEditor.SceneManagement;

namespace Loong.Edit
{
    /// <summary>
    /// 资源引用视图基类
    /// </summary>
    /// <typeparam name="T">被引用资源类型</typeparam>
    public class AssetRefViewBase<T> : EditViewBase where T : Object
    {
        #region 字段
        /// <summary>
        /// 被引用资源
        /// </summary>
        public T target = null;

        /// <summary>
        /// 引用资源列表
        /// </summary>
        public List<Object> objs = null;

        public ObjPage page = new ObjPage();

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


        protected void Search()
        {
            SetObjs();
            page.SetLst(objs);
            SearchTip();
        }

        protected void SearchTip()
        {
            if (objs == null || objs.Count < 1)
            {
                UIEditTip.Warning("未搜索到");
            }
        }


        protected override void Help()
        {
            UIEditTip.Log("选择指定的文件夹进行搜索");
        }


        protected virtual void SetObjs()
        {

        }

        protected override void Title()
        {
            BegTitle();
            if (TitleBtn("帮助")) Help();
            EndTitle();
        }

        protected virtual void DrawObj(Object obj)
        {
            UIEditLayout.ObjectField<T>("被引用资源:", ref target, obj);
        }

        protected override void OnGUICustom()
        {
            EditorGUILayout.BeginHorizontal(StyleTool.Group);
            DrawObj(this);
            if (GUILayout.Button("查询", UIOptUtil.btn)) Search();
            EditorGUILayout.EndHorizontal();

            page.OnGUI(this);
        }

        protected override void OpenCustom()
        {
            base.OpenCustom();
            Help();
        }

        #endregion

        #region 公开方法

        #endregion
    }
}