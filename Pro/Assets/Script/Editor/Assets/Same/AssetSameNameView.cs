/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/28 23:47:28
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// AssetNameView
    /// </summary>
    public class AssetSameNameView : EditViewBase
    {
        #region 字段
        /// <summary>
        /// 移动到索引
        /// </summary>
        public int toIdx = 0;

        /// <summary>
        /// 移动的索引
        /// </summary>
        public int fromIdx = 0;


        /// <summary>
        /// 关键字
        /// </summary>
        public string keyword = "";

        /// <summary>
        /// 设置单个目录
        /// </summary>
        public string targetDir = "";

        /// <summary>
        /// 检查目录列表
        /// </summary>
        public List<string> dirs = new List<string>();

        /// <summary>
        /// 重名字典
        /// </summary>
        private Dictionary<string, List<string>> sameDic = null;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private void Search()
        {
            if (dirs.Count < 1)
            {
                UIEditTip.Error("未设置目录"); return;
            }
            int length = dirs.Count;
            for (int i = 0; i < length; i++)
            {
                var dir = dirs[i];
                if (!Directory.Exists(dir))
                {
                    UIEditTip.Error("目录:{0} 不存在", dir); return;
                }
            }

            sameDic = AssetSameNameUtil.Find(dirs);
        }
        private bool Delete(string path)
        {
            string msg = "删除:" + path;
            if (!EditorUtility.DisplayDialog("", msg, "是", "否")) return false;
            var suc = AssetDatabase.DeleteAsset(path);
            UIEditTip.Mutex(suc, "删除:{0}", path);
            return true;
        }

        /// <summary>
        /// 一键删除
        /// </summary>
        private void OneKeyDelete()
        {
            if (string.IsNullOrEmpty(keyword))
            {
                UIEditTip.Error("无删除路径的关键字"); return;
            }
            if (sameDic == null || sameDic.Count < 1)
            {
                UIEditTip.Error("无重名资源"); return;
            }
            var msg = string.Format("一键删除路径中具有关键字:{0}的资源", keyword);
            if (!EditorUtility.DisplayDialog("", msg, "是", "否")) return;
            AssetSameNameUtil.Delete(sameDic, keyword);
        }

        private void DrawDirs()
        {
            UIEditLayout.HelpWaring("搜寻目录列表,数量:" + dirs.Count);
            for (int i = 0; i < dirs.Count; i++)
            {
                EditorGUILayout.BeginHorizontal();
                dirs[i] = EditorGUILayout.TextField(dirs[i]);
                if (GUILayout.Button("", StyleTool.Minus, UIOptUtil.plusWd))
                {
                    dirs.RemoveAt(i);
                    EditorGUILayout.EndHorizontal();
                }
                if (GUILayout.Button("定位", UIOptUtil.btn))
                {
                    string rPath = FileUtil.GetProjectRelativePath(dirs[i]);
                    EditUtil.Ping(rPath);
                }
                EditorGUILayout.EndHorizontal();
            }
        }

        /// <summary>
        /// 添加目录
        /// </summary>
        private void AddDir()
        {
            if (string.IsNullOrEmpty(targetDir))
            {
                return;
            }
            targetDir = targetDir.Replace('\\', '/');
            if (dirs.Contains(targetDir))
            {
                UIEditTip.Error("已包含:{0}", targetDir);
            }
            else
            {
                dirs.Add(targetDir);
            }
            Event.current.Use();
        }

        private void Ovrrite(List<string> paths)
        {
            var length = paths.Count;
            if (length < 2)
            {
                UIEditTip.Error("一个资源无需"); return;
            }
            if (toIdx >= length)
            {
                UIEditTip.Error("移动from索引越界"); return;
            }
            if (fromIdx >= length)
            {
                UIEditTip.Error("移动to索引越界"); return;
            }
            if (fromIdx == toIdx)
            {
                UIEditTip.Error("相同索引"); return;
            }
            AssetSameNameUtil.Ovrrite(paths, fromIdx, toIdx);
        }

        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);

            UIEditLayout.SetFolder("添加目录:", ref targetDir, this, true, AddDir);
            if (string.IsNullOrEmpty(targetDir)) targetDir = "可在此处拖拽添加";
            DragDropUtil.AddDirs(dirs);
            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("搜索", UIOptUtil.btn))
            {
                Search();
            }
            UIEditLayout.TextArea("删除关键字:", ref keyword, this);
            if (GUILayout.Button("一键删除", UIOptUtil.btn))
            {
                OneKeyDelete();
            }
            EditorGUILayout.EndHorizontal();

            DrawDirs();
            EditorGUILayout.EndVertical();
            if (sameDic == null)
            {
                UIEditLayout.HelpWaring("无重名资源"); return;
            }
            UIEditLayout.HelpWaring("重名列表总数:" + sameDic.Count);
            var em = sameDic.GetEnumerator();
            while (em.MoveNext())
            {
                var it = em.Current;
                EditorGUILayout.BeginVertical(StyleTool.Group);
                EditorGUILayout.LabelField("名称:", it.Key);
                var lst = it.Value;
                int length = lst.Count;

                for (int i = 0; i < length; i++)
                {
                    var path = lst[i];
                    EditorGUILayout.BeginHorizontal();
                    EditorGUILayout.LabelField(i.ToString(), UIOptUtil.plusWd);
                    EditorGUILayout.TextField(path);
                    if (GUILayout.Button("删除", UIOptUtil.btn))
                    {
                        if (Delete(path))
                        {
                            lst.RemoveAt(i);
                            EditorGUILayout.EndHorizontal();
                            break;
                        }
                    }
                    if (GUILayout.Button("定位", UIOptUtil.btn))
                    {
                        EditUtil.Ping(path);
                    }
                    EditorGUILayout.EndHorizontal();
                }

                EditorGUILayout.BeginHorizontal();
                UIEditLayout.IntField("将索引:", ref fromIdx, this);
                UIEditLayout.IntField("移动到索引:", ref toIdx, this);
                if (GUILayout.Button("移动", UIOptUtil.btn))
                {
                    Ovrrite(lst);
                }
                EditorGUILayout.EndHorizontal();
                EditorGUILayout.EndVertical();
            }
        }
        #endregion

        #region 公开方法

        #endregion
    }
}