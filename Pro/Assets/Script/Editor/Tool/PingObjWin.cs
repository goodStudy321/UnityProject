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
    /// AU:Loong
    /// TM:2016.8.1
    /// BG:定位对象窗口
    /// </summary>
    public class PingObjWin : EditorWindow
    {
        #region 字段

        private List<Object> objs = null;

        private Vector2 scroll = Vector2.zero;
        #endregion

        #region 属性

        /// <summary>
        /// 对象列表
        /// </summary>
        public List<Object> Objs
        {
            get { return objs; }
            set { objs = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void OnGUI()
        {
            scroll = EditorGUILayout.BeginScrollView(scroll, StyleTool.Bg);

            if (objs == null || objs.Count == 0)
            {
                UIEditLayout.HelpInfo("无信息");
            }
            else
            {
                int length = objs.Count;
                for (int i = 0; i < length; i++)
                {
                    Object obj = objs[i];
                    if (obj == null) continue;
                    EditorGUILayout.BeginHorizontal(StyleTool.Group);

                    EditorGUILayout.LabelField(obj.name);

                    if (GUILayout.Button("", StyleTool.GreenActivePing, UIOptUtil.plus))
                    {
                        EditUtil.Ping(obj);
                    }
                    else if (GUILayout.Button("", StyleTool.RedActiveX, UIOptUtil.plus))
                    {
                        DialogUtil.Show("", "确定移除?", () =>
                        {
                            objs.RemoveAt(i);
                            Event.current.Use();
                        });
                        break;
                    }

                    EditorGUILayout.EndHorizontal();
                }
            }
            GUILayout.FlexibleSpace();
            EditorGUILayout.EndScrollView();
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 打开定位对象窗口
        /// </summary>
        /// <param name="objs"></param>
        public static void Open(List<Object> objs)
        {
            var win = CreateInstance<PingObjWin>();
            win.SetSize(600, 800);
            win.Objs = objs;
            win.Show();
        }
        #endregion
    }
}