/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/27 17:46:56
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AssetLrcView
    /// </summary>
    public class AssetLrcView : EditViewBase
    {
        #region 字段

        private Vector2 pathScroll = Vector2.zero;

        private Vector2 diffScroll = Vector2.zero;

        /// <summary>
        /// 搜索资源类型
        /// </summary>
        public int assetOp = 0;

        /// <summary>
        /// 指定资源
        /// </summary>
        public string assetPath = "";

        /// <summary>
        /// 资源目录
        /// </summary>
        public string targetDir = "";
        /// <summary>
        /// 差异化列表
        /// </summary>
        public List<string> diffs = null;
        /// <summary>
        /// 资源路径列表
        /// </summary>
        public List<string> paths = new List<string>();

        /// <summary>
        /// 删除过滤字符
        /// </summary>
        public List<string> delFilters = new List<string>();

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法


        private void CheckLrc()
        {
            if (!CheckDir()) return;
            if (paths.Count < 1)
            {
                UIEditTip.Error("未设置资源列表"); return;
            }
            diffs = AssetLrcUtil.Get(paths, targetDir);
        }

        private bool CheckDir()
        {
            if (string.IsNullOrEmpty(targetDir))
            {
                UIEditTip.Error("未设置目录"); return false;
            }
            if (!Directory.Exists(targetDir))
            {
                UIEditTip.Error("{0}\n不存在", targetDir); return false;
            }
            var rDir = FileUtil.GetProjectRelativePath(targetDir);
            if (string.IsNullOrEmpty(rDir))
            {
                UIEditTip.Error("非法目录:", targetDir); return false;
            }
            return true;
        }

        private void Add(string path)
        {
            if (string.IsNullOrEmpty(path)) return;
            if (paths.Contains(path))
            {
                UIEditTip.Error("已存在");
            }
            else
            {
                string assetPath = FileUtil.GetProjectRelativePath(path);
                if (string.IsNullOrEmpty(assetPath))
                {
                    UIEditTip.Error("无效路径:\n", path);
                }
                else
                {
                    assetPath = assetPath.Replace('\\', '/');
                    paths.Add(assetPath);
                    UIEditTip.Warning("添加成功:\n", assetPath);
                }
            }
        }

        private void AddType()
        {
            if (!CheckDir()) return;
            var type = (AssetType)assetOp;
            var lst = AssetQueryUtil.Search(targetDir, type);
            if (lst == null || lst.Count < 1)
            {
                UIEditTip.Log("未发现"); return;
            }
            int length = lst.Count;
            for (int i = 0; i < length; i++)
            {
                var path = lst[i];
                if (paths.Contains(path)) continue;
                paths.Add(path);
            }
        }

        private void DrawPaths()
        {
            int length = paths.Count;
            if (length < 1)
            {
                UIEditLayout.HelpWaring("未设置路径"); return;
            }
            for (int i = 0; i < length; i++)
            {
                var path = paths[i];
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.TextField(path);
                if (GUILayout.Button("", StyleTool.Minus, UIOptUtil.plusWd))
                {
                    paths.RemoveAt(i);
                    EditorGUILayout.EndHorizontal();
                }
                if (GUILayout.Button("定位", UIOptUtil.btn))
                {
                    EditUtil.Ping(path);
                }
                EditorGUILayout.EndHorizontal();
            }
        }

        private void DrawDiffs()
        {
            if (diffs == null) return;
            int length = diffs.Count;
            if (length < 1)
            {
                UIEditLayout.HelpWaring("无"); return;
            }
            for (int i = 0; i < length; i++)
            {
                var path = diffs[i];
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.TextField(path);
                if (GUILayout.Button("删除", UIOptUtil.btn))
                {
                    AssetDatabase.DeleteAsset(path);
                    diffs.RemoveAt(i);
                    EditorGUILayout.EndHorizontal();
                    break;
                }
                if (GUILayout.Button("定位", UIOptUtil.btn))
                {
                    EditUtil.Ping(path);
                }
                EditorGUILayout.EndHorizontal();
            }
        }

        private bool IsFilter(string path)
        {
            int filterLen = delFilters.Count;
            for (int j = 0; j < filterLen; j++)
            {
                var filter = delFilters[j];
                if (path.Contains(filter)) return false;
            }
            return true;
        }

        private void DeleteDiff()
        {
            if (diffs == null || diffs.Count < 1)
            {
                UIEditTip.Error("未搜集冗余资源"); return;
            }
            int length = diffs.Count;
            var msg = "确定删除冗余资源?";
            if (!EditorUtility.DisplayDialog("", msg, "是", "否")) return;
            var cur = Directory.GetCurrentDirectory();
            for (int i = length - 1; i > -1; --i)
            {
                var path = diffs[i];
                var fullPath = Path.Combine(cur, path);
                if (IsFilter(path)) continue;
                if (!File.Exists(fullPath)) continue;
                ListTool.Remove<string>(diffs, i);
                if (AssetDatabase.DeleteAsset(path)) continue;
                Debug.LogWarningFormat("Loong,删除:{0} 失败", path);
            }
            UIEditTip.Log("删除完成");
        }


        private void SetAssetPath()
        {
            Add(assetPath);
        }


        private void DrawOneKeyDel()
        {
            UIDrawTool.StringLst(this, delFilters, "lrcOnekeyDelFilters", "一键删除过滤列表");
            if (GUILayout.Button("一键删除冗余资源")) DeleteDiff();
        }


        private void Clear()
        {
            paths.Clear();
            diffs = null;
        }
        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            UIEditLayout.HelpWaring("资源列表中的所有依赖资源和资源目录中的所有资源比对");
            UIEditLayout.SetFolder("资源目录:", ref targetDir, this);

            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.LabelField("一键获取资源目录下的所有指定类型资源,并添加到路径列表");
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.Popup("类型:", ref assetOp, AssetQueryUtil.typeNames, this);
            if (GUILayout.Button("添加到路径")) AddType();
            EditorGUILayout.EndHorizontal();
            UIEditLayout.SetPath("添加指定资源路径:", ref assetPath, this, Suffix.Prefab, true, SetAssetPath);
            //if (string.IsNullOrEmpty(assetPath)) targetDir = "可在此处拖拽添加";
            DragDropUtil.AddFiles(paths);
            EditorGUILayout.EndVertical();


            EditorGUILayout.Space();
            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("清理")) Clear();
            if (GUILayout.Button("比对")) CheckLrc();
            EditorGUILayout.EndHorizontal();

            DrawOneKeyDel();

            EditorGUILayout.Space();

            EditorGUILayout.BeginHorizontal();

            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.HelpWaring("资源列表, 数量: " + paths.Count);
            float wd = Win.position.size.x * 0.475f;
            var wdOp = GUILayout.Width(wd);
            pathScroll = EditorGUILayout.BeginScrollView(pathScroll, wdOp);
            DrawPaths();
            EditorGUILayout.EndScrollView();
            EditorGUILayout.EndVertical();

            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.HelpWaring("冗余资源, 数量:" + (diffs == null ? 0 : diffs.Count));
            diffScroll = EditorGUILayout.BeginScrollView(diffScroll, wdOp);
            DrawDiffs();
            EditorGUILayout.EndScrollView();
            EditorGUILayout.EndVertical();
            EditorGUILayout.Space();
            EditorGUILayout.Space();
            EditorGUILayout.EndHorizontal();
        }

        protected override void CloseCustom()
        {
            base.CloseCustom();
            Clear();
        }
        #endregion

        #region 公开方法

        #endregion
    }
}