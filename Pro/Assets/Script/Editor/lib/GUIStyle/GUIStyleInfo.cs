using Hello.Game;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace Hello.Edit
{
    public class GUIStyleInfo
    {
        private int index = 0;

        private int totalPage = 0;

        private int pageCount = 20;

        private int pageIndex = 0;

        private GUISkin skin = null;

        private string indexStr = "0/0";

        private Vector2 scroll = Vector2.zero;

        public GUISkin Skin
        {
            get { return skin; }
            set { skin = value; }
        }

        private void FirstPage()
        {
            pageIndex = 0;
            indexStr = string.Format("{0}/{1}", pageIndex, totalPage);
        }

        private void LastPage()
        {
            pageIndex = totalPage;
            indexStr = string.Format("{0}/{1}", pageIndex, totalPage);
        }

        private void PrevPage()
        {
            --pageIndex;
            pageIndex = Mathf.Clamp(pageIndex, 0, totalPage);
            indexStr = string.Format("{0}/{1}", pageIndex, totalPage);
        }

        private void NextPage()
        {
            ++pageIndex;
            pageIndex = Mathf.Clamp(pageIndex, 0, totalPage);
            indexStr = string.Format("{0}/{1}", pageIndex, totalPage);
        }

        public void OnGUI()
        {
            if (Skin == null) return;
            if (totalPage == 0)
            {
                totalPage = Mathf.FloorToInt(skin.customStyles.Length / pageCount);
            }
            if (totalPage == 0) return;
            if (!UIEditTool.DrawHeader(Skin.name, Skin.name, StyleTool.Host)) return;
            scroll = EditorGUILayout.BeginScrollView(scroll);
            GUIStyle[] styles = skin.customStyles;
            for (int i = 0; i < pageCount; i++)
            {
                index = pageIndex * pageCount + i;
                if (index >= styles.Length) break;
                GUIStyle style = styles[index];
                EditorGUILayout.BeginHorizontal(StyleTool.Box);
                EditorGUILayout.LabelField("名称:", GUILayout.Width(60));
                EditorGUILayout.TextField(style.name, GUILayout.Width(200));
                GUILayout.Space(20);

                EditorGUILayout.LabelField("宽度200:", GUILayout.Width(80));
                GUILayout.Button("", style, GUILayout.Width(200));
                GUILayout.Space(20);

                EditorGUILayout.LabelField("无宽度:", GUILayout.Width(80));
                GUILayout.Button("", style);
                EditorGUILayout.Space();
                EditorGUILayout.EndHorizontal();
            }

            EditorGUILayout.EndScrollView();

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField(indexStr);

            if (GUILayout.Button("首页", EditorStyles.toolbarButton))
            {
                FirstPage();
            }
            else if (GUILayout.Button("末页", EditorStyles.toolbarButton))
            {
                LastPage();
            }
            else if (GUILayout.Button("上一页", EditorStyles.toolbarButton))
            {
                PrevPage();
            }
            else if (GUILayout.Button("下一页", EditorStyles.toolbarButton))
            {
                NextPage();
            }
            EditorGUILayout.EndHorizontal();
        }

    }

}

