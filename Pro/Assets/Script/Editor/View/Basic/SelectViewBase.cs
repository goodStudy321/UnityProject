using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.9.28
    /// BG:选择窗口基类
    /// </summary>
    public class SelectViewBase<T> : EditViewBase where T : SelectInfo
    {
        #region 字段

        /// <summary>
        /// 信息绘制选项
        /// </summary>
        private GUILayoutOption[] infoOptions = new GUILayoutOption[] { GUILayout.Height(30) };

        /// <summary>
        /// 选择的条目
        /// </summary>
        [SerializeField]
        protected int selectIndex = -1;

        /// <summary>
        /// 最后绘制的UI范围
        /// </summary>
        protected Rect lastRect = default(Rect);

        /// <summary>
        /// 选择信息
        /// </summary>
        [SerializeField]
        protected List<T> infos = new List<T>();

        /// <summary>
        /// 选择编辑操作
        /// </summary>
        public Action<T> editorHandler;
        #endregion

        #region 属性

        /// <summary>
        /// 选择信息
        /// </summary>
        public T Select
        {
            get
            {
                if (selectIndex == -1) return null;
                return infos[selectIndex];
            }
        }

        /// <summary>
        /// true:可以多选
        /// </summary>
        public virtual bool CanMultiSelect
        {
            get { return false; }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 编辑条目
        /// </summary>
        private void Edit()
        {
            if (!CheckSelect()) return;
            T info = infos[selectIndex];
            EditCustom(info);
            if (editorHandler == null) return;
            editorHandler(info);
        }

        #endregion

        #region 保护方法
        protected bool CheckSelect()
        {
            if (Select == null)
            {
                ShowTip("没有选择条目");
                return false;
            }
            return true;
        }


        /// <summary>
        /// 设置信息
        /// </summary>
        protected virtual void SetInfos()
        {

        }

        /// <summary>
        /// 自定义编辑
        /// </summary>
        /// <param name="info"></param>
        protected virtual void EditCustom(T info)
        {

        }

        /// <summary>
        /// 自定义上下文菜单
        /// </summary>
        protected virtual void ContextClickCustom(GenericMenu menu)
        {

        }

        /// <summary>
        /// 绘制标题
        /// </summary>
        protected virtual void DrawHeader()
        {

        }

        /// <summary>
        /// 当没有任何条目时的显示
        /// </summary>
        protected virtual void ShowNothing()
        {
            UIEditLayout.HelpInfo("没有任何信息");
        }


        protected override void ContextClick()
        {
            GenericMenu menu = new GenericMenu();
            menu.AddItem("编辑", false, Edit);
            menu.AddSeparator("");
            ContextClickCustom(menu);
            menu.ShowAsContext();
        }

        protected override void OpenCustom()
        {
            Win.SetTitle("选择视图");
        }

        protected override void OnGUICustom()
        {
            EditorGUILayout.BeginHorizontal();
            DrawHeader();
            EditorGUILayout.EndHorizontal();
            int length = infos.Count;

            if (length == 0) ShowNothing();
            for (int i = 0; i < length; i++)
            {
                GUILayout.Space(3);
                var info = infos[i];
                string style = (info.IsSelect ? SelectStyle() : NormalStyle());
                EditorGUILayout.BeginHorizontal(style, infoOptions);
                info.OnGUI(this);
                GUILayout.FlexibleSpace();
                EditorGUILayout.EndHorizontal();

                if (e.type == EventType.MouseDown && e.button == 0)
                {
                    if (GUILayoutUtility.GetLastRect().Contains(e.mousePosition))
                    {
                        if (CanMultiSelect)
                        {
                            info.IsSelect = !info.IsSelect;

                        }
                        else
                        {
                            if (i == selectIndex) break;
                            info.IsSelect = true;
                            var lastIdx = selectIndex;
                            if (lastIdx > -1) infos[lastIdx].IsSelect = false;
                        }
                        selectIndex = i;
                        lastRect = GUILayoutUtility.GetLastRect();
                        e.Use();
                    }
                }
            }
            if (e.type == EventType.ContextClick)
            {
                ContextClick();
            }



        }

        protected virtual string SelectStyle()
        {
            return StyleTool.NodeOn2;
        }

        protected virtual string NormalStyle()
        {
            return StyleTool.Node1;
        }
        #endregion

        #region 公开方法
        public override void Initialize()
        {
            base.Initialize();
            Refresh();
        }

        public override void Refresh()
        {
            infos.Clear(); SetInfos();
        }
        #endregion
    }
}