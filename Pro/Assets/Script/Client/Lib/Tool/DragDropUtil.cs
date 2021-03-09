#if UNITY_EDITOR
using System;
using System.IO;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Hello.Game
{
    public static class DragDropUtil
    {
       private static string[] Update()
        {
            var cur = Event.current;
            var rect = GUILayoutUtility.GetLastRect();
            if (rect.Contains(cur.mousePosition))
            {
                if(cur.type == EventType.DragUpdated)
                {
                    DragAndDrop.visualMode = DragAndDropVisualMode.Generic;
                }
                if(cur.type == EventType.DragPerform)
                {
                    var paths = DragAndDrop.paths;
                    return paths;
                }
            }
            return null;
        }

        private static List<string> GetPaths(string[] paths,bool file)
        {
            if (paths == null || paths.Length < 1) return null;
            List<string> lst = null;
            int length = paths.Length;
            for (int i = 0; i < length; i++)
            {
                var path = paths[i];
                var sfx = Path.GetExtension(path);
                if (file)
                {
                    if (!string.IsNullOrEmpty(sfx))
                    {
                        if (lst == null) lst = new List<string>();
                        lst.Add(path);
                    }
                }
                else
                {
                    if (string.IsNullOrEmpty(sfx))
                    {
                        if (lst == null) lst = new List<string>();
                        lst.Add(path);
                    }
                }
            }
            return lst;
        }

        public static void Filter(Action<List<string>> cb,bool file,bool dialog = true)
        {
            if (cb == null) return;
            var paths = Update();
            if (paths == null) return;
            if (dialog)
            {
                if (!EditorUtility.DisplayDialog("", "添加", "确定", "取消"))
                {
                    return;
                }
            }
            var lst = GetPaths(paths, file);
            if (Event.current != null) Event.current.Use();
            cb(lst);
        }

        public static void Add(List<string> src, bool file, bool dialog = true)
        {
            if (src == null) return;
            var paths = Update();
            if (paths == null) return;
            if (dialog)
            {
                if (!EditorUtility.DisplayDialog("", "添加", "确定", "取消")) return;
            }
            var lst = GetPaths(paths, file);
            if (lst == null || lst.Count < 1)
            {
                UIEditTip.Log("无可添加路径");
            }
            else
            {
                int length = lst.Count;
                for (int i = 0; i < length; i++)
                {
                    var path = lst[i];
                    if (src.Contains(path)) continue;
                    src.Add(path);
                }
                UIEditTip.Log("添加成功");
                if (Event.current != null) Event.current.Use();
            }
        }

        public static void Files(Action<List<string>> cb, bool dialog = true)
        {
            if (cb == null) return;
            Filter(cb, true, dialog);
        }

        public static void Dirs(Action<List<string>> cb, bool dialog = true)
        {
            if (cb == null) return;
            Filter(cb, false, dialog);
        }

        public static void AddFiles(List<string> src, bool dialog = true)
        {
            if (src == null) return;
            Add(src, true, dialog);
        }

        public static void AddDirs(List<string> src, bool dialog = true)
        {
            if (src == null) return;
            Add(src, false, dialog);
        }

        public static void Filter(Object obj, ref string path, bool file, bool dialog = true)
        {
            var paths = Update();
            if (paths == null) return;
            if (dialog)
            {
                if (!EditorUtility.DisplayDialog("", "设置", "确定", "取消")) return;
            }
            var lst = GetPaths(paths, file);
            if (lst == null || lst.Count < 1) return;
            EditUtil.RegisterUndo("SetPathOrDir", obj);
            path = lst[0];
            if (Event.current != null) Event.current.Use();
        }

        public static void SetPath(Object obj, ref string path, bool dialog = true)
        {
            Filter(obj, ref path, true, dialog);
        }

        public static void SetDir(Object obj, ref string dir, bool dialog = true)
        {
            Filter(obj, ref dir, false, dialog);
        }
    }
}

#endif
