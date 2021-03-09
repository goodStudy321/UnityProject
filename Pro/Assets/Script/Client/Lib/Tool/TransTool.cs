using System;
using System.Text;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Hello.Game
{
    public static class TransTool
    {
        public static Transform Find(string name, HideFlags flags = HideFlags.None)
        {
            if (string.IsNullOrEmpty(name)) return null;
            GameObject go = GameObject.Find(name);
            if (go == null) go = new GameObject(name);
            go.hideFlags = flags;
            return go.transform;
        }

        public static Transform CreateRoot<T>(HideFlags flags = HideFlags.NotEditable) where T : class
        {
            return CreateRoot(typeof(T).Name, flags);
        }

        public static Transform CreateRoot(Type type,HideFlags flags = HideFlags.NotEditable)
        {
            if (type == null) return null;
            return CreateRoot(type.Name, flags);
        }

        public static Transform CreateRoot(string rootName,HideFlags flags = HideFlags.NotEditable)
        {
            if (string.IsNullOrEmpty(rootName)) return null;
            string name = string.Format("Root<{0}>", rootName);
            Transform root = Find(name, flags);
            Object.DontDestroyOnLoad(root.gameObject);
            return root;
        }

        public static GameObject Find(Transform root,string path,string tip = "")
        {
            if (root == null)
            {
                iTrace.Error("Hello", string.Format("{0} 根节点为空", tip)); return null;
            }
            if (string.IsNullOrEmpty(path))
            {
                iTrace.Error("Hello", string.Format("{0} 路径为空", tip)); return null;
            }
            Transform child = root.Find(path);
            if (child == null)
            {
                iTrace.Error("Hello", string.Format("{0} 根节点:{1},未发现路径为:{2}的子物体", tip, root.name, path)); return null;
            }
            return child.gameObject;
        }

        public static GameObject Find(GameObject root,string path,string tip = "")
        {
            return Find(root.transform, path, tip);
        }

        public static void AddChild(Transform parent,Transform child)
        {
            if (child == null) return;
            if (parent == null) return;
            child.parent = parent;
            child.localScale = Vector3.one;
            child.localPosition = Vector3.zero;
            child.localEulerAngles = Vector3.zero;
        }

        public static void ClearChild(Transform parent,string childName)
        {
            Transform child = parent.Find(childName);
            if (child != null) iTool.Destroy(child.gameObject);
        }

        public static void ClearChildren(Transform parent)
        {
            if (parent == null) return;
            while(parent.childCount != 0)
            {
                Transform tran = parent.GetChild(0);
                Object.DestroyImmediate(tran.gameObject);
            }
        }

        public static void SetChildActive(Transform parent,string path,bool active)
        {
            GameObject child = Find(parent, path);
            if (child != null) child.SetActive(active);
        }

        public static void SetChildrenActive(Transform parent,bool active)
        {
            if (parent == null) return;
            int length = parent.childCount;
            for (int i = 0; i < length; i++)
            {
                Transform child = parent.GetChild(i);
                child.gameObject.SetActive(active);
            }
        }

        public static void RenameChildren(Transform parent,string name)
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

        public static string GetPath(Transform tran,int beg = 0)
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
            while(parent != null)
            {
                names.Add(parent.name);
                parent = parent.parent;
            }
            if (beg < 0) beg = 0;
            int length = names.Count;
            int start = length - 1 - beg;
            for (int i = start; i > -1 ; --i)
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

        public static bool IsNull(GameObject go)
        {
            if (go == null) return true;
            if (go.name == "null") return true;
            if (go.Equals(null)) return true;
            return false;
        }

        public static bool IsNull(Transform trans)
        {
            if (trans == null) return true;
            if (trans.name == "null") return true;
            if (trans.Equals(null)) return true;
            return false;
        }

    }
}

