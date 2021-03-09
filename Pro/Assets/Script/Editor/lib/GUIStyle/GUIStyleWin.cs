using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.5.12
    /// BG:内置皮肤查看器
    /// </summary>
    public class GUIStyleWin : EditorWindow
    {
        #region 字段
        private Vector2 scroll = Vector2.zero;

        private List<GUIStyleInfo> skins = new List<GUIStyleInfo>();
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法


        private void OnEnable()
        {
            var arr = Enum.GetValues(typeof(EditorSkin));
            int length = arr.Length;
            for (int i = 0; i < length; i++)
            {
                var skin = (EditorSkin)arr.GetValue(i);
                GUISkin guiSkin = EditorGUIUtility.GetBuiltinSkin(skin);
                if (guiSkin == null) continue;
                if (guiSkin.customStyles == null) continue;
                if (guiSkin.customStyles.Length == 0) continue;
                GUIStyleInfo info = new GUIStyleInfo();
                info.Skin = guiSkin;
                skins.Add(info);
            }
        }

        private void OnGUI()
        {
            EditorGUILayout.BeginVertical(StyleTool.Bg);
            scroll = EditorGUILayout.BeginScrollView(scroll);
            int length = skins.Count;
            for (int i = 0; i < length; i++)
            {
                skins[i].OnGUI();
            }
            EditorGUILayout.EndScrollView();
            GUILayout.FlexibleSpace();
            EditorGUILayout.EndVertical();
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 显示窗口
        /// </summary>
        [MenuItem(MenuTool.ALoong + "内置皮肤预览窗口", false, MenuTool.NormalPri + 2)]
        [MenuItem(MenuTool.Loong + "内置皮肤预览窗口", false, MenuTool.NormalPri + 2)]
        public static void Open()
        {
            GUIStyleWin win = EditorWindow.GetWindow<GUIStyleWin>();
            win.SetSize(600, Screen.currentResolution.height);
            win.autoRepaintOnSceneChange = true;
        }
        #endregion
    }
}