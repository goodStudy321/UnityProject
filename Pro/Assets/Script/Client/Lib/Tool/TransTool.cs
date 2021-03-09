using System;
using System.Text;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.6.3
    /// BG:变换组件工具
    /// </summary>
    public static class TransTool
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 查找具有指定名称的变换组件,没有查找到时将创建
        /// </summary>
        /// <param name="name">变换组件</param>
        /// <param name="flags">标识</param>
        /// <returns></returns>
        public static Transform Find(string name, HideFlags flags = HideFlags.None)
        {
            if (string.IsNullOrEmpty(name)) return null;
            GameObject go = GameObject.Find(name);
            if (go == null) go = new GameObject(name);
            go.hideFlags = flags;
            return go.transform;
        }


        /// <summary>
        /// 创建根节点Tranform/并且切换场景时不销毁
        /// </summary>
        /// <typeparam name="T">根节点名称和类型名称一致</typeparam>
        /// <returns></returns>
        public static Transform CreateRoot<T>(HideFlags flags = HideFlags.NotEditable) where T : class
        {
            return CreateRoot(typeof(T).Name, flags);
        }

        /// <summary>
        /// 创建根结点Transform
        /// </summary>
        /// <param name="type">根节点名称和类型名称一致</param>
        /// <param name="flags"></param>
        /// <returns></returns>
        public static Transform CreateRoot(Type type, HideFlags flags = HideFlags.NotEditable)
        {
            if (type == null) return null;
            return CreateRoot(type.Name, flags);
        }

        /// <summary>
        /// 创建根节点Tranform/并且切换场景时不销毁
        /// </summary>
        /// <param name="rootName">根节点名称</param>
        /// <returns></returns>
        public static Transform CreateRoot(string rootName, HideFlags flags = HideFlags.NotEditable)
        {
            if (string.IsNullOrEmpty(rootName)) return null;
            string name = string.Format("Root<{0}>", rootName);
            Transform root = Find(name, flags);
            Object.DontDestroyOnLoad(root.gameObject);
            return root;
        }

        /// <summary>
        /// 获取子物体
        /// </summary>
        /// <param name="root">根变换</param>
        /// <param name="path">路径</param>
        /// <param name="tip">提示</param>
        /// <returns></returns>
        public static GameObject Find(Transform root, string path, string tip = "")
        {
            if (root == null)
            {
                iTrace.Error("Loong", string.Format("{0} 根节点为空", tip)); return null;
            }
            if (string.IsNullOrEmpty(path))
            {
                iTrace.Error("Loong", string.Format("{0} 路径为空", tip)); return null;
            }
            Transform child = root.Find(path);
            if (child == null)
            {
                iTrace.Error("Loong", string.Format("{0} 根节点:{1},未发现路径为:{2}的子物体", tip, root.name, path)); return null;
            }
            return child.gameObject;
        }

        /// <summary>
        /// 获取子物体
        /// </summary>
        /// <param name="root">根物体</param>
        /// <param name="path">路径</param>
        /// <param name="tip">提示</param>
        /// <returns></returns>
        public static GameObject Find(GameObject root, string path, string tip = "")
        {
            return Find(root.transform, path, tip);
        }

        /// <summary>
        /// 添加子物体/位置归0,缩放归1
        /// </summary>
        /// <param name="parent">父变换组件</param>
        /// <param name="child">字变换组件</param>
        public static void AddChild(Transform parent, Transform child)
        {
            if (child == null) return;
            if (parent == null) return;
            child.parent = parent;
            child.localScale = Vector3.one;
            child.localPosition = Vector3.zero;
            child.localEulerAngles = Vector3.zero;
        }

        /// <summary>
        /// 删除子物体
        /// </summary>
        /// <param name="parent">父变换组件</param>
        /// <param name="childName">子物体名称</param>
        public static void ClearChild(Transform parent, string childName)
        {
            Transform child = parent.Find(childName);
            if (child != null) iTool.Destroy(child.gameObject);
        }

        /// <summary>
        /// 清除所有的子物体
        /// </summary>
        /// <param name="parent">父变换组件</param>
        public static void ClearChildren(Transform parent)
        {
            if (parent == null) return;
            while (parent.childCount != 0)
            {
                Transform tran = parent.GetChild(0);
                Object.DestroyImmediate(tran.gameObject);
            }
        }

        /// <summary>
        /// 设置子物体激活状态
        /// </summary>
        /// <param name="parent">父变换组件</param>
        /// <param name="path">路径</param>
        /// <param name="active">激活状态</param>
        public static void SetChildActive(Transform parent, string path, bool active)
        {
            GameObject child = Find(parent, path);
            if (child != null) child.SetActive(active);
        }

        /// <summary>
        /// 设置子物体激活状态
        /// </summary>
        /// <param name="parent">父物体</param>
        /// <param name="path">路径</param>
        /// <param name="active">激活状态</param>
        public static void SetChildActive(GameObject parent, string path, bool active)
        {
            GameObject child = Find(parent, path);
            if (child != null) child.SetActive(active);
        }

        /// <summary>
        /// 设置所有子物体激活状态
        /// </summary>
        /// <param name="parent">父变换组件</param>
        /// <param name="active">激活状态</param>
        public static void SetChildrenActive(Transform parent, bool active)
        {
            if (parent == null) return;
            int length = parent.childCount;
            for (int i = 0; i < length; i++)
            {
                Transform child = parent.GetChild(i);
                child.gameObject.SetActive(active);
            }
        }

        /// <summary>
        /// 重命名所有子物体子物体
        /// </summary>
        /// <param name="parent">父变换组件</param>
        /// <param name="name">命名名称</param>
        public static void RenameChildren(Transform parent, string name)
        {
            if (parent == null) return;
            int length = parent.childCount;
            for (int i = 0; i < length; i++)
            {
                Transform child = parent.GetChild(i);
                child.name = name;
            }
        }


        private static List<string> names = new List<string>();

        /// <summary>
        /// 获取变换组件从根节点开始的路径
        /// </summary>
        /// <param name="tran"></param>
        /// <param name="beg">根节点偏移索引</param>
        /// <returns></returns>
        public static string GetPath(Transform tran, int beg = 0)
        {
            if (tran == null) return null;
            Transform parent = tran.parent;
            if (parent == null) return tran.name;

            StringBuilder sb = null;
#if UNITY_EDITOR
            bool playing = Application.isPlaying;
            if (!playing)
            {
                sb = new StringBuilder();
            }
            else
#endif
            {
                sb = ObjPool.Instance.Get<StringBuilder>();
            }
            names.Add(tran.name);
            while (parent != null)
            {
                names.Add(parent.name);
                parent = parent.parent;
            }
            if (beg < 0) beg = 0;
            int length = names.Count;
            int start = length - 1 - beg;
            for (int i = start; i > -1; --i)
            {
                string name = names[i];
                sb.Append(name);
                if (i > 0) sb.Append("/");
            }
            string path = sb.ToString();
#if UNITY_EDITOR
            if (playing)
#endif
            {
                sb.Remove(0, sb.Length);
                ObjPool.Instance.Add(sb);
            }
            names.Clear();
            return path;
        }

        /// <summary>
        /// 判断是否为null或被销毁了
        /// </summary>
        /// <returns></returns>
        public static bool IsNull(GameObject go)
        {
            if (go == null) return true;
            if (go.name == "null") return true;
            if (go.Equals(null)) return true;
            return false;
        }
        /// <returns></returns>
        public static bool IsNull(Transform trans)
        {
            if (trans == null) return true;
            if (trans.name == "null") return true;
            if (trans.Equals(null)) return true;
            return false;
        }
        #endregion
    }
}