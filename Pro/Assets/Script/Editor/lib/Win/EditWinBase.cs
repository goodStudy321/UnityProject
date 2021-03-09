using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace Hello.Edit
{
    /// <summary>
    /// 窗口基类
    /// </summary>
    public class EditWinBase : EditorWindow
    {
        private bool compile = false;

        [SerializeField]
        private List<string> keys = new List<string>();

        [SerializeField]
        private List<EditViewBase> views = new List<EditViewBase>();

        private Dictionary<string, EditViewBase> dic = new Dictionary<string, EditViewBase>();

        /// <summary>
        /// true:编译中
        /// </summary>
        public bool Compile
        {
            get { return compile; }
            private set { compile = value; }
        }

        private void SetDic()
        {
            dic.Clear();
            int length = keys.Count;
            for (int i = 0; i < length; i++)
            {
                string key = keys[i];
                var value = views[i];
                dic.Add(key, value);
            }
        }

        private void CheckCompile()
        {
            if (EditorApplication.isCompiling)
            {
                GUI.enabled = false;
                if (Compile) return;
                Compile = true;
                this.ShowTip("正在编译中,请稍候···");
            }
            else
            {
                if (Compile)
                {
                    Compile = false;
                    Compiled();
                }
            }
        }

        private void Compiled()
        {
            int length = views.Count;
            for (int i = 0; i < length; i++)
            {
                var view = views[i];
                view.Win = this;
                view.OnCompiled();
            }
            OnCompiled();
        }


        private void PlaymodeChanged()
        {
            if (EditorApplication.isPlayingOrWillChangePlaymode)
            {
                if (EditorApplication.isPlaying)
                {
                    PlaymodeChanged(true);
                }
            }
            else
            {
                if (!EditorApplication.isPlaying)
                {
                    PlaymodeChanged(false);
                }
            }
        }


        private void PlaymodeChanged(bool playing)
        {
            int length = views.Count;
            for (int i = 0; i < length; i++)
            {
                var view = views[i];
                view.OnPlaymodeChanged(playing);
            }
            OnPlaymodeChanged(playing);
        }

        protected virtual void OnGUI()
        {
            CheckCompile();
            int length = views.Count;
            for (int i = 0; i < length; i++)
            {
                var view = views[i];
                if (view.Active) view.OnGUI();
            }
            GUI.enabled = true;
        }

        protected virtual void Update()
        {
            int length = views.Count;
            for (int i = 0; i < length; i++)
            {
                var view = views[i];
                if (view.Active) view.Update();
            }
        }

        protected virtual void OnEnable()
        {
            SetDic();
#pragma warning disable 618
            EditorApplication.playmodeStateChanged += PlaymodeChanged;
#pragma warning restore
            UnityEditor.SceneView.duringSceneGui += OnSceneGUI;
            int length = views.Count;
            for (int i = 0; i < length; i++)
            {
                var view = views[i];
                view.OnEnable();
            }
        }

        protected virtual void OnDisable()
        {
            int length = views.Count;
            for (int i = 0; i < length; i++)
            {
                var view = views[i];
                view.OnDisable();
            }
        }

        protected virtual void OnDestroy()
        {
            UnityEditor.SceneView.duringSceneGui -= OnSceneGUI;
#pragma warning disable 618
            EditorApplication.playmodeStateChanged -= PlaymodeChanged;
#pragma warning restore
            int length = views.Count;
            for (int i = 0; i < length; i++)
            {
                var view = views[i];
                view.OnDestroy();
            }
        }

        protected virtual void OnHierarchyChange()
        {
            int length = views.Count;
            for (int i = 0; i < length; i++)
            {
                var view = views[i];
                view.OnHierarchyChange();
            }
        }

        /// <summary>
        /// 自定义编译结束
        /// </summary>
        protected virtual void OnCompiled()
        {

        }

        /// <summary>
        /// 自定义播放模式改变
        /// </summary>
        /// <param name="playing">true:运行中</param>
        protected virtual void OnPlaymodeChanged(bool playing)
        {

        }

        protected virtual void OnSceneGUI(UnityEditor.SceneView sceneView)
        {
            int length = views.Count;
            for (int i = 0; i < length; i++)
            {
                var view = views[i];
                if (view.Active) view.OnSceneGUI(sceneView);
            }
        }

        public virtual void Init()
        {

        }

        public T Get<T>() where T : EditViewBase
        {
            var view = Get(typeof(T));
            if (view == null) return null;
            T t = view as T;
            return t;
        }

        public EditViewBase Get(Type type)
        {
            if (type == null) return null;
            return Get(type.Name);
        }

        public EditViewBase Get(string name)
        {
            if (string.IsNullOrEmpty(name)) return null;
            if (dic.ContainsKey(name)) return dic[name];
            return null;
        }

        public void Open<T>() where T : EditViewBase
        {
            Open(typeof(T));
        }

        public void Open(Type type)
        {
            if (type == null) return;
            Open(type.Name);
        }

        public void Open(string name)
        {
            if (string.IsNullOrEmpty(name)) return;
            if (dic.ContainsKey(name))
            {
                dic[name].Open();
            }
        }

        public void Close<T>() where T : EditViewBase
        {
            Close(typeof(T));
        }

        /// <summary>
        /// 根据视图类型关闭视图
        /// </summary>
        /// <param name="type">视图类型</param>
        public void Close(Type type)
        {
            if (type == null) return;
            Close(type.Name);
        }

        /// <summary>
        /// 根据视图名称关闭视图
        /// </summary>
        /// <param name="name">视图名称</param>
        public void Close(string name)
        {
            if (string.IsNullOrEmpty(name)) return;
            if (dic.ContainsKey(name))
            {
                dic[name].Close();
            }
        }

        /// <summary>
        /// 根据视图类型打开视图并关闭其它视图
        /// </summary>
        /// <typeparam name="T"></typeparam>
        public void Switch<T>() where T : EditViewBase
        {
            Switch(typeof(T));
        }

        /// <summary>
        /// 根据视图类型打开视图并关闭其它视图
        /// </summary>
        /// <param name="type"></param>
        public void Switch(Type type)
        {
            if (type == null) return;
            Switch(type.Name);
        }

        /// <summary>
        /// 根据视图名称打开视图并关闭其它视图
        /// </summary>
        /// <param name="name">视图名称</param>
        public void Switch(string name)
        {
            int length = keys.Count;
            for (int i = 0; i < length; i++)
            {
                string key = keys[i];
                var view = views[i];
                if (key == name)
                {
                    view.Open();
                }
                else
                {
                    view.Close();
                }
            }
        }

        /// <summary>
        /// 添加视图,视图并以资源的形式保存在本地
        /// </summary>
        /// <typeparam name="T"></typeparam>
        public void Add<T>() where T : EditViewBase
        {
            string key = typeof(T).Name;
            if (dic.ContainsKey(key)) return;
            string parentFolder = this.GetType().Name;
            T t = AssetDataUtil.Get<T>(parentFolder);
            Add(t);
        }

        /// <summary>
        /// 添加视图
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="t"></param>
        public void Add<T>(T t) where T : EditViewBase
        {
            Add(typeof(T).Name, t);
        }

        /// <summary>
        /// 添加视图
        /// </summary>
        /// <param name="view">视图</param>
        public void Add(EditViewBase view)
        {
            if (view == null) return;
            Add(view.GetType().Name, view);
        }

        /// <summary>
        /// 添加指定名称的视图
        /// </summary>
        /// <param name="name">视图名称</param>
        /// <param name="view">试图</param>
        public void Add(string name, EditViewBase view)
        {
            if (dic.ContainsKey(name)) return;
            if (view == null) return;
            view.Win = this;
            view.Initialize();
            keys.Add(name);
            views.Add(view);
            dic.Add(name, view);
        }

        /// <summary>
        /// 根据视图类型移除视图
        /// </summary>
        /// <returns></returns>
        public void Remove<T>() where T : EditViewBase
        {
            string name = typeof(T).Name;
            Remove(name);
        }

        /// <summary>
        /// 移除制定名称的视图
        /// </summary>
        /// <param name="name">视图名称</param>
        public void Remove(string name)
        {
            if (string.IsNullOrEmpty(name)) return;
            if (!dic.ContainsKey(name)) return;
            var view = dic[name];
            views.Remove(view);
            keys.Remove(name);
            dic.Remove(name);
            view.OnDestroy();
        }

        /// <summary>
        /// 设置指定类型的视图,如果已经存在相同名称的视图则将此名称的视图重新赋值
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="t"></param>
        public void Set<T>(T t) where T : EditViewBase
        {
            Set(typeof(T).Name, t);
        }

        /// <summary>
        /// 设置指定名称的视图,如果已经存在相同名称的视图则将此名称的视图重新赋值
        /// </summary>
        /// <param name="name">视图名称</param>
        /// <param name="view">视图</param>
        public void Set(string name, EditViewBase view)
        {
            if (dic.ContainsKey(name))
            {
                if (view == null) return;
                int index = keys.IndexOf(name);
                var old = views[index];
                views[index] = view;
                dic[name] = view;
                view.Win = this;
                view.Initialize();
                old.OnDestroy();
            }
            else
            {
                Add(name, view);
            }
        }

        /// <summary>
        /// 刷新所有子视图
        /// </summary>
        public virtual void Refresh()
        {
            int length = views.Count;
            for (int i = 0; i < length; i++)
            {
                var view = views[i];
                view.Refresh();
            }
        }

        /// <summary>
        /// 显示视图信息
        /// </summary>
        /// <returns></returns>
        public override string ToString()
        {
            var sb = new StringBuilder();
            int keyLen = keys.Count;
            int viewLen = views.Count;
            int dicLen = dic.Count;
            sb.Append("键值数量:").Append(keyLen).Append("{");
            for (int i = 0; i < keyLen; i++)
            {
                sb.Append("<").Append(i).Append(",");
                sb.Append(keys[i]).Append(">");
            }
            sb.Append("}").AppendLine();
            sb.Append("窗口数量:").Append(viewLen).Append("{");
            for (int i = 0; i < viewLen; i++)
            {
                sb.Append("<").Append(i).Append(",");
                sb.Append(views[i].GetType().Name).Append(">");
            }
            sb.Append("}").AppendLine();
            sb.Append("字典数量:").Append(dicLen).Append("{");
            var em = dic.GetEnumerator();
            while (em.MoveNext())
            {
                var item = em.Current;
                sb.Append("<").Append(item.Key).Append(",");
                sb.Append(item.Value.GetType().Name).Append(">");
            }
            sb.Append("}");
            return sb.ToString();
        }

    }

    
}

