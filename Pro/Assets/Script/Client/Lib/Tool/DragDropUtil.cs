/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/3 11:27:45
 ============================================================================*/

#if UNITY_EDITOR
using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// 拖拽工具
    /// </summary>
    public static class DragDropUtil
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 更新
        /// </summary>
        private static string[] Update()
        {
            var cur = Event.current;
            var rect = GUILayoutUtility.GetLastRect();
            if (rect.Contains(cur.mousePosition))
            {
                if (cur.type == EventType.DragUpdated)
                {
                    DragAndDrop.visualMode = DragAndDropVisualMode.Generic;
                }
                if (cur.type == EventType.DragPerform)
                {
                    var paths = DragAndDrop.paths;
                    return paths;
                }
            }
            return null;
        }

        /// <summary>
        /// 筛选路径
        /// </summary>
        /// <param name="paths">原路径数组</param>
        /// <param name="file">true:文件,false:文件夹</param>
        /// <returns></returns>
        private static List<string> GetPaths(string[] paths, bool file)
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

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 过滤
        /// </summary>
        /// <param name="cb"></param>
        /// <param name="file"></param>
        /// <param name="dialog"></param>
        public static void Filter(Action<List<string>> cb, bool file, bool dialog = true)
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


        /// <summary>
        /// 过滤
        /// </summary>
        /// <param name="src">添加列表</param>
        /// <param name="file"></param>
        /// <param name="dialog"></param>
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

        /// <summary>
        /// 拖拽文件
        /// </summary>
        /// <param name="cb">文件列表回调</param>
        /// <param name="dialog">true:显示对话框</param>
        public static void Files(Action<List<string>> cb, bool dialog = true)
        {
            if (cb == null) return;
            Filter(cb, true, dialog);
        }


        /// <summary>
        /// 拖拽文件夹
        /// </summary>
        /// <param name="cb">文件夹列表回调</param>
        /// <param name="dialog">true:显示对话框</param>
        public static void Dirs(Action<List<string>> cb, bool dialog = true)
        {
            if (cb == null) return;
            Filter(cb, false, dialog);
        }

        /// <summary>
        /// 拖拽文件
        /// </summary>
        /// <param name="src">要添加的文件列表</param>
        /// <param name="dialog">true:显示对话框</param>
        public static void AddFiles(List<string> src, bool dialog = true)
        {
            if (src == null) return;
            Add(src, true, dialog);
        }


        /// <summary>
        /// 拖拽文件夹
        /// </summary>
        /// <param name="cb">要添加的目录列表</param>
        /// <param name="dialog">true:显示对话框</param>
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

        /// <summary>
        /// 设置文件路径
        /// </summary>
        /// <param name="obj"></param>
        /// <param name="path"></param>
        public static void SetPath(Object obj, ref string path, bool dialog = true)
        {
            Filter(obj, ref path, true, dialog);
        }

        /// <summary>
        /// 设置目录
        /// </summary>
        /// <param name="obj"></param>
        /// <param name="dir"></param>
        public static void SetDir(Object obj, ref string dir, bool dialog = true)
        {
            Filter(obj, ref dir, false, dialog);
        }
        #endregion
    }
}
#endif