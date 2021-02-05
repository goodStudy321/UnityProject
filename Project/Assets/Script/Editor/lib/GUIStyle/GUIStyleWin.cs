using System;
using Hello.Game;
using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

namespace Hello.Edit
{
    public class GUIStyleWin : EditorWindow
    {
        private Vector2 scroll = Vector2.zero;

        private List<GUIStyleInfo> skins = new List<GUIStyleInfo>();

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

        [MenuItem(MenuTool.AHello + "内置皮肤预览窗口", false, MenuTool.NormalPri + 2)]
        [MenuItem(MenuTool.Hello + "内置皮肤预览窗口", false, MenuTool.NormalPri + 2)]
        public static void Open()
        {
            GUIStyleWin win = EditorWindow.GetWindow<GUIStyleWin>();
            win.SetSize(600, Screen.currentResolution.height);
            win.autoRepaintOnSceneChange = true;
        }
    }

}

