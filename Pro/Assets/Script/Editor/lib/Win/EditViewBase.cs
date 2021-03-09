using Hello.Game;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace Hello.Edit
{
    public class EditViewBase : ScriptableObject
    {
        private bool active = false;

        private EditWinBase win = null;

        private Vector2 scroll = Vector2.zero;

        protected Event e = null;

        public bool Active
        {
            get { return active; }
            private set { active = value; }
        }

        public EditWinBase Win
        {
            get { return win; }
            set { win = value; }
        }

        protected void BegTitle()
        {
            EditorGUILayout.BeginHorizontal(EditorStyles.toolbar);
            GUILayout.FlexibleSpace();
        }

        protected void TitleHelp()
        {
            if (GUILayout.Button("帮助",EditorStyles.toolbarButton,UIOptUtil.btn))
            {
                Help();
            }
        }

        protected void EndTitle()
        {
            EditorGUILayout.EndHorizontal();
        }

        protected virtual void Title()
        {
            BegTitle();
            TitleHelp();
            EndTitle();
        }

        protected virtual void Help()
        {

        }

        protected virtual void ClearUndo()
        {

        }

        protected virtual void OnGUICustom()
        {

        }

        protected virtual void ContextClick()
        {

        }

        protected virtual void OpenCustom()
        {

        }

        protected virtual void CloseCustom()
        {

        }

        protected virtual void OnDestroyCustom()
        {

        }

        public virtual void Initialize()
        {

        }

        public virtual void Update()
        {

        }

        public virtual void OnEnable()
        {

        }

        public virtual void OnDisable()
        {

        }

        public virtual void OnCompiled()
        {

        }

        public virtual void OnHierarchyChange()
        {

        }

        public virtual void OnSceneGUI(UnityEditor.SceneView view)
        {

        }

        public virtual void OnPlaymodeChanged(bool playing)
        {

        }

        public virtual void Refresh()
        {

        }

        public void OnGUI()
        {
            if (!Active)
            {
                return;
            }
            Title();
            scroll = EditorGUILayout.BeginScrollView(scroll, StyleTool.Bg);
            e = Event.current;
            OnGUICustom();
            GUILayout.FlexibleSpace();
            EditorGUILayout.EndScrollView();
        }

        public void ShowTip(string msg)
        {
            if (win == null) return;
            win.ShowTip(msg);
            win.Repaint();
        }

        public void Open()
        {
            Active = true;
            OpenCustom();
        }

        public void Close()
        {
            Undo.ClearUndo(this);
            ClearUndo();
            Active = false;
            CloseCustom();
        }

        public void OnDestroy()
        {
            OnDestroyCustom();
            Undo.ClearUndo(this);
            ClearUndo();
        }

    }
}

