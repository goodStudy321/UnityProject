/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2013/5/12 15:21:10
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{

    /// <summary>
    /// NGUI字体工具
    /// </summary>
    public static class NGUIFontUtil
    {
        #region 字段
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = NGUIUtil.Pri + 10;
        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = NGUIUtil.menu + "字体/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = NGUIUtil.AMenu + "字体/";
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private static void SelectFontCb(Object obj)
        {
            Font font = obj as Font;
            var gos = Selection.gameObjects;
            int length = gos.Length;
            for (int i = 0; i < length; i++)
            {
                SetFont(gos[i], font);
            }
            UIEditTip.Log("设置系统字体完成");
            AssetDatabase.Refresh();
        }

        private static void SelectUIFontCb(Object obj)
        {
            UIFont font = obj as UIFont;
            var gos = Selection.gameObjects;
            int length = gos.Length;
            for (int i = 0; i < length; i++)
            {
                SetFont(gos[i], font);
            }
            UIEditTip.Log("设置UI字体完成");
            AssetDatabase.Refresh();
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        [MenuItem(menu + "设置系统字体", false, Pri)]
        [MenuItem(AMenu + "设置系统字体", false, Pri)]
        public static void SetSystem()
        {
            if (!SelectUtil.CheckGos()) return;
            ObjSelector.Open<Font>(SelectFontCb);
        }

        [MenuItem(menu + "设置UI字体", false, Pri + 1)]
        [MenuItem(AMenu + "设置UI字体", false, Pri + 1)]
        public static void SetUIFont()
        {
            if (!SelectUtil.CheckGos()) return;
            ObjSelector.Open<UIFont>(SelectUIFontCb);
        }

        public static void SetFont(GameObject go, Font font)
        {
            if (go == null) return;
            if (font == null) return;

            UILabel[] labels = go.GetComponentsInChildren<UILabel>(true);
            if (labels == null || labels.Length == 0) return;
            EditorUtility.SetDirty(go);
            float length = labels.Length;
            for (int i = 0; i < length; i++)
            {
                UILabel label = labels[i];
                if (label.bitmapFont != null) continue;
                label.trueTypeFont = font;
                float pro = i / length;
                ProgressBarUtil.Show("", label.name, pro);
            }

            ProgressBarUtil.Clear();
        }

        public static void SetFont(GameObject go, UIFont font)
        {
            if (go == null) return;
            if (font == null) return;

            UILabel[] labels = go.GetComponentsInChildren<UILabel>(true);
            if (labels == null || labels.Length == 0) return;
            EditorUtility.SetDirty(go);
            float length = labels.Length;
            for (int i = 0; i < length; i++)
            {
                UILabel label = labels[i];
                if (label.trueTypeFont != null) continue;
                label.bitmapFont = font;
                float pro = i / length;
                ProgressBarUtil.Show("", label.name, pro);
            }

            ProgressBarUtil.Clear();
        }


        #endregion
    }
}