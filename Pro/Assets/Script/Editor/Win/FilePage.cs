/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/10/20 0:58:49
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Xml.Serialization;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// FilePage
    /// </summary>
    [Serializable]
    public class FilePage : Page<string>
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
        private void Add(List<string> paths)
        {
            if (paths == null) return;
            int count = 0;
            int length = paths.Count;
            for (int i = 0; i < length; i++)
            {
                var path = paths[i];
                var sfx = Path.GetExtension(path);
                if (sfx == Suffix.Meta) continue;
                if (sfx == Suffix.Manifest) continue;
                path = GetPath(path);
                if (lst.Contains(path))
                {
                    continue;
                }
                ++count;
                lst.Add(path);
            }
            UIEditTip.Log("添加:{0}个", count);
        }

        private void Delete()
        {

        }

        private void Delete(Object obj, int i)
        {
            var path = lst[i];
            if (!EditorUtility.DisplayDialog("删除?", path, "确定", "取消")) return;
            EditorUtility.SetDirty(obj);
            ListTool.Remove<string>(lst, i);
            if (File.Exists(path))
            {
                File.Delete(path);
                UIEditTip.Log("{0} 删除成功", path);
            }
            else
            {
                UIEditTip.Log("{0} 删除失败", path);
            }
        }
        #endregion

        #region 保护方法
        protected virtual string GetPath(string path)
        {
            return null;
        }

        protected override void DrawTitle(Object obj)
        {
            base.DrawTitle(obj);
            if (lst == null || lst.Count < 1)
            {
                UIEditLayout.HelpInfo("拖拽到此处可添加");
                DragDropUtil.Files(Add);
            }
        }

        protected override void DrawItem(Object obj, int i)
        {
            var path = lst[i];
            EditorGUILayout.TextField(path);

            if (GUILayout.Button("删除", UIOptUtil.btn))
            {
                Delete(obj, i);
            }
        }

        public override void OnGUI(Object obj)
        {
            base.OnGUI(obj);
            DragDropUtil.Files(Add);
        }
        #endregion

        #region 公开方法

        #endregion
    }
}