//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/3 13:16:54
//=============================================================================

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
    /// SymbolView
    /// </summary>
    public class SymbolView : EditViewBase
    {
        #region 字段
        [SerializeField]
        private TweenPath tween = null;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private string GetDir()
        {
            var dir = "./Assets/Pkg/ui/Symbol";
            dir = Path.GetFullPath(dir);
            return dir;
        }
        private void Load()
        {
            var dir = GetDir();
            var path = EditorUtility.OpenFilePanel("", dir, "bytes");
            if (string.IsNullOrEmpty(path)) return;
            if (tween == null)
            {
                tween = new TweenPath();
            }
            else
            {
                tween.Points.Clear();
            }
            tween.Read(path);
            UIEditTip.Log("读取:{0}成功", path);
        }

        private void Save()
        {
            if (tween == null)
            {
                UIEditTip.Warning("无需保存"); return;
            }
            var dir = GetDir();
            var path = EditorUtility.SaveFilePanel("", dir, "xxxx", "bytes");
            if (string.IsNullOrEmpty(path)) return;
            var msg = string.Format("保存为:{0}?", path);
            if (!EditorUtility.DisplayDialog("", msg, "是", "否")) return;
            tween.Save(path);
        }
        #endregion

        #region 保护方法
        protected override void Title()
        {
            BegTitle();
            if (TitleBtn("加载"))
            {
                Load();
            }
            else if (TitleBtn("保存"))
            {
                Save();
            }

            EndTitle();
        }

        protected override void OnGUICustom()
        {
            if (tween != null) tween.Draw(this);
        }
        #endregion

        #region 公开方法
        public override void OnSceneGUI(SceneView view)
        {
            if (tween != null) tween.OnSceneGUI(this);
        }
        #endregion
    }
}