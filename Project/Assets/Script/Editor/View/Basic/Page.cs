using System;
using System.IO;
using Hello.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Xml.Serialization;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Hello.Edit
{
    /// <summary>
    /// 翻页
    /// </summary>
    [Serializable]
    public class Page<T> where T : class
    {
        #region 字段
        /// <summary>
        /// 最大页
        /// </summary>
        private int max = 0;

        /// <summary>
        /// 当前页
        /// </summary>
        public int index = 0;

        /// <summary>
        /// 一页最大数量
        /// </summary>
        public int count = 100;

        [XmlArrayItem("it")]
        public List<T> lst = new List<T>();

        private Vector2 scroll = Vector2.zero;

        private GUILayoutOption[] scrOp = null;

        #endregion

        #region 属性

        [XmlIgnore]
        public virtual bool UseScrollHt
        {
            get { return true; ; }
        }

        [XmlIgnore]
        public GUILayoutOption[] ScrOp
        {
            get
            {
                if (scrOp == null)
                {
                    scrOp = GetScrOp();
                }
                return scrOp;
            }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法


        private void PrePage()
        {
            index -= 1;
            if (index < 0) index = 0;
            Event.current.Use();
        }

        private void NextPage()
        {
            index += 1;
            if (index >= max) index = max - 1;
            Event.current.Use();
        }

        public void FirstPage()
        {
            index = 0;
            Event.current.Use();
        }

        public void LastPage()
        {
            index = max - 1;
            if (index < 0) index = 0;
            Event.current.Use();
        }

        private void RemoveDialog(Object obj, int i)
        {
            if (!EditorUtility.DisplayDialog("", "移除?", "是", "否")) return;
            Remove(obj, i);
        }

        private void Remove(Object obj, int i)
        {
            EditUtil.RegisterUndo(this.GetType().Name, obj);
            lst.RemoveAt(i);
            Event.current.Use();
        }

        #endregion

        #region 保护方法
        protected void SetPage()
        {
            if (index >= max)
            {
                index = max - 1;
            }
            if (index < 0)
            {
                index = 0;
            }
        }

        protected virtual GUILayoutOption[] GetScrOp()
        {
            return new GUILayoutOption[] { GUILayout.MinHeight(400) };

        }
        /// <summary>
        /// 绘制标题
        /// </summary>
        protected virtual void DrawTitle(Object obj)
        {
            EditorGUILayout.BeginHorizontal(EditorStyles.toolbar);
            EditorGUILayout.LabelField("页数:", UIOptUtil.smallWd);
            EditorGUILayout.LabelField(max.ToString(), UIOptUtil.smallWd);
            EditorGUILayout.LabelField("当前页:", UIOptUtil.smallWd);
            EditorGUILayout.LabelField(index.ToString(), UIOptUtil.smallWd);
            if (TitleBtn("上页")) PrePage();
            if (TitleBtn("下页")) NextPage();
            if (TitleBtn("首页")) FirstPage();
            if (TitleBtn("最后页")) LastPage();
            EditorGUILayout.LabelField("总数:" + (lst == null ? 0 : lst.Count));
            GUILayout.FlexibleSpace();
            EditorGUILayout.EndHorizontal();
        }

        protected virtual void BegTitle()
        {
            EditorGUILayout.BeginHorizontal(EditorStyles.toolbar);
        }

        protected virtual void EndTitle()
        {
            EditorGUILayout.EndHorizontal();
        }

        protected virtual bool TitleBtn(string btn)
        {
            return GUILayout.Button(btn, EditorStyles.toolbarButton, UIOptUtil.btn);
        }

        /// <summary>
        /// 绘制条目
        /// </summary>
        /// <param name="i"></param>
        protected virtual void DrawItem(Object obj, int i)
        {

        }

        #endregion

        #region 公开方法
        public virtual void OnGUI(Object obj)
        {
            DrawTitle(obj);
            if (UseScrollHt)
            {
                scroll = EditorGUILayout.BeginScrollView(scroll, ScrOp);
            }
            else
            {
                scroll = EditorGUILayout.BeginScrollView(scroll);
            }

            if (lst == null || lst.Count == 0)
            {
                UIEditLayout.HelpInfo("无信息");
            }
            else
            {
                var length = lst.Count;
                max = Mathf.CeilToInt(length * 1.0f / count);
                for (int i = count - 1; i > -1; --i)
                {
                    index = (index < 0 ? 0 : index);
                    var idx = index * count + i;
                    if (idx >= length) continue;
                    EditorGUILayout.BeginHorizontal();
                    EditorGUILayout.LabelField(idx.ToString(), UIOptUtil.smallWd);
                    if (lst[idx] == null)
                    {
                        EditorGUILayout.LabelField("null or empty");
                    }
                    else
                    {
                        DrawItem(obj, idx);
                    }
                    if (GUILayout.Button("", StyleTool.Minus, UIOptUtil.plusWd))
                    {
                        RemoveDialog(obj, idx);
                    }
                    EditorGUILayout.EndHorizontal();
                }
            }
            GUILayout.FlexibleSpace();
            EditorGUILayout.EndScrollView();
        }


        public void SetLst(List<T> lst)
        {
            this.lst = lst;
            index = 0;
        }
        #endregion
    }
}