using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{

    /// <summary>
    /// AU:Loong
    /// TM:2013.5.12
    /// BG:内置皮肤信息
    /// </summary>
    public class GUIStyleInfo
    {
        #region 字段
        private int index = 0;

        /// <summary>
        /// 页总数量
        /// </summary>
        private int totalPage = 0;

        /// <summary>
        /// 每页数量
        /// </summary>
        private int pageCount = 20;

        /// <summary>
        /// 页索引
        /// </summary>
        private int pageIndex = 0;

        private GUISkin skin = null;

        private string indexStr = "0/0";

        private Vector2 scroll = Vector2.zero;

        #endregion

        #region 属性

        /// <summary>
        /// 内置皮肤
        /// </summary>
        public GUISkin Skin
        {
            get { return skin; }
            set { skin = value; }
        }

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void FirstPage()
        {
            pageIndex = 0; indexStr = string.Format("{0}/{1}", pageIndex, totalPage);
        }

        private void LastPage()
        {
            pageIndex = totalPage; indexStr = string.Format("{0}/{1}", pageIndex, totalPage);
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
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 绘制UI
        /// </summary>
        public void OnGUI()
        {
            if (Skin == null) return;
            if (totalPage == 0) totalPage = Mathf.FloorToInt(skin.customStyles.Length / pageCount);
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
        #endregion
    }
}