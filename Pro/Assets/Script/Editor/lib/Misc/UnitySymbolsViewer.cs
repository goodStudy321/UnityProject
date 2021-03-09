using Loong.Game;
using UnityEngine;
using UnityEditor;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.4.28
    /// BG:Unity在当前激活平台所有定义的预处理指令查看器
    /// </summary>
    public class UnitySymbolsViewer : EditorWindow
    {
        /// <summary>
        /// 菜单优先级
        /// </summary>
        public const int Pri = MenuTool.NormalPri + 3;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "预处理指令工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "预处理指令工具/";

        /// <summary>
        /// 打开编辑器窗口
        /// </summary>
        [MenuItem(menu + "查看 #&u", false, Pri)]
        [MenuItem(AMenu + "查看", false, Pri)]
        public static void Open()
        {
            UnitySymbolsViewer win = EditorWindow.GetWindow<UnitySymbolsViewer>(false, "UNITY预处理指令查看器");
            win.autoRepaintOnSceneChange = true;
            win.style = StyleTool.Overlay;
            win.unitySymbols = EditorUserBuildSettings.activeScriptCompilationDefines;
            win.row = Mathf.CeilToInt(Screen.height / 30) - 2;
            win.col = Mathf.CeilToInt((float)(win.unitySymbols.Length) / win.row);
            win.SetSize(win.col * 250, Screen.height);

        }
        private int row;
        private int col;
        private int index;
        private GUIStyle style;
        private string[] unitySymbols;
        private Vector2 scrollPos = Vector2.zero;

        private GUILayoutOption[] lblOpts = new GUILayoutOption[]
        {
            GUILayout.Width(300),
            GUILayout.Height(30)
        };


        private void OnGUI()
        {
            EditorGUILayout.BeginVertical(StyleTool.Bg, GUILayout.Height(position.height));
            scrollPos = EditorGUILayout.BeginScrollView(scrollPos);
            GUILayout.Space(30);
            EditorGUILayout.BeginHorizontal();
            index = 0;
            for (int i = 0; i < col; i++)
            {
                EditorGUILayout.BeginVertical();
                for (int j = 0; j < row; j++)
                {
                    if (index > unitySymbols.Length - 1)
                    {
                        continue;
                    }
                    else
                    {
                        GUILayout.Label(unitySymbols[index], style, lblOpts);
                        index++;
                    }
                }
                EditorGUILayout.EndVertical();
            }
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.EndVertical();
            EditorGUILayout.EndScrollView();

        }
    }
}