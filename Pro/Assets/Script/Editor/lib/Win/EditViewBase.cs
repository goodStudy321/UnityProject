/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014/9/28,15:39:09
 ============================================================================*/

using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 编辑视图基类
    /// </summary>
    public class EditViewBase : ScriptableObject
    {
        #region 字段
        private bool active = false;

        private EditWinBase win = null;

        private Vector2 scroll = Vector2.zero;

        /// <summary>
        /// 当前事件缓存
        /// </summary>
        protected Event e = null;
        #endregion

        #region 属性
        /// <summary>
        /// true:开启
        /// </summary>
        public bool Active
        {
            get { return active; }
            private set { active = value; }
        }

        /// <summary>
        /// 父窗口
        /// </summary>
        public EditWinBase Win
        {
            get { return win; }
            set { win = value; }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected void BegTitle()
        {
            EditorGUILayout.BeginHorizontal(EditorStyles.toolbar);
            GUILayout.FlexibleSpace();
        }

        protected void EndTitle()
        {
            EditorGUILayout.EndHorizontal();
        }

        /// <summary>
        /// 标题栏
        /// </summary>
        protected virtual void Title()
        {
            BegTitle();
            TitleHelp();
            EndTitle();
        }

        /// <summary>
        /// 标题按钮
        /// </summary>
        /// <param name="btn"></param>
        /// <returns></returns>
        protected virtual bool TitleBtn(string btn)
        {
            return GUILayout.Button(btn, EditorStyles.toolbarButton, UIOptUtil.btn);
        }

        protected void TitleHelp()
        {
            if (GUILayout.Button("帮助", EditorStyles.toolbarButton, UIOptUtil.btn))
            {
                Help();
            }
        }

        protected virtual void Help()
        {

        }

        /// <summary>
        /// 清理撤销更改
        /// </summary>
        protected virtual void ClearUndo()
        {

        }

        /// <summary>
        /// 自定义绘制UI
        /// </summary>
        protected virtual void OnGUICustom() { }

        /// <summary>
        /// 右键上下文菜单
        /// </summary>
        protected virtual void ContextClick() { }

        /// <summary>
        /// 自定义打开
        /// </summary>
        protected virtual void OpenCustom() { }

        /// <summary>
        /// 自定义关闭
        /// </summary>
        protected virtual void CloseCustom() { }

        /// <summary>
        /// 自定义释放
        /// </summary>
        protected virtual void OnDestroyCustom() { }


        #endregion

        #region 公开方法

        /// <summary>
        /// 初始化
        /// </summary>
        public virtual void Initialize()
        {

        }

        /// <summary>
        /// 绘制
        /// </summary>
        public void OnGUI()
        {
            if (!Active) return;
            Title();
            scroll = EditorGUILayout.BeginScrollView(scroll, StyleTool.Bg);
            e = Event.current;
            OnGUICustom();
            GUILayout.FlexibleSpace();
            EditorGUILayout.EndScrollView();
        }

        /// <summary>
        /// 打开
        /// </summary>
        public void Open()
        {
            Active = true;
            OpenCustom();
        }

        /// <summary>
        /// 关闭
        /// </summary>
        public void Close()
        {
            Undo.ClearUndo(this);
            ClearUndo();
            Active = false;
            CloseCustom();
        }

        /// <summary>
        /// 更新
        /// </summary>
        public virtual void Update()
        {

        }

        /// <summary>
        /// 激活
        /// </summary>
        public virtual void OnEnable()
        {

        }


        /// <summary>
        /// 睡眠
        /// </summary>
        public virtual void OnDisable()
        {

        }

        /// <summary>
        /// 编译结束
        /// </summary>
        public virtual void OnCompiled()
        {

        }



        /// <summary>
        /// 层级面板发生改变时
        /// </summary>
        public virtual void OnHierarchyChange()
        {

        }

        /// <summary>
        /// 场景视图UI委托
        /// </summary>
        /// <param name="view"></param>
        public virtual void OnSceneGUI(UnityEditor.SceneView view)
        {

        }
        /// <summary>
        /// 播放模式状态发生改变
        /// </summary>
        /// <param name="playing">true:运行中</param>
        public virtual void OnPlaymodeChanged(bool playing)
        {

        }

        /// <summary>
        /// 刷新数据
        /// </summary>
        public virtual void Refresh()
        {

        }

        /// <summary>
        /// 提示
        /// </summary>
        /// <param name="msg">信息</param>
        public void ShowTip(string msg)
        {
            if (win == null) return;
            win.ShowTip(msg);
            win.Repaint();
        }

        /// <summary>
        /// 销毁
        /// </summary>
        public void OnDestroy()
        {
            OnDestroyCustom();
            Undo.ClearUndo(this);
            ClearUndo();
        }
        #endregion
    }
}