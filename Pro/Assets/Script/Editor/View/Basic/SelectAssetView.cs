using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Reflection;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.8.28
    /// BG:资源选择视图
    /// </summary>
    public class SelectAssetView<T> : SelectViewBase<SelectAssetInfo> where T : ScriptableObject
    {
        #region 字段

        #endregion

        #region 属性

        /// <summary>
        /// 资源保存目录
        /// </summary>
        public virtual string AssetDir
        {
            get { return null; }
        }

        /// <summary>
        /// 资源默认名称
        /// </summary>
        public virtual string AssetName
        {
            get { return null; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private Object GetAsset()
        {
            Object obj = CreateInstance<T>();
            return obj;
        }

        /// <summary>
        /// 创建
        /// </summary>
        private void Create()
        {
            if (!Check()) return;
            string fileName = AssetNameTool.GetUniqueName(AssetDir, AssetName);
            string tempPath = EditorUtility.SaveFilePanel("", AssetDir, fileName, "asset");
            string assetPath = FileUtil.GetProjectRelativePath(tempPath);
            if (string.IsNullOrEmpty(assetPath)) { this.ShowTip("无效的路径"); return; }
            string fullDir = AssetPathUtil.CurDir + AssetDir;
            if (!Directory.Exists(fullDir)) Directory.CreateDirectory(fullDir);
            Object a1 = GetAsset();
            if (a1 == null) return;
            AssetDatabase.CreateAsset(a1, assetPath);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            Object a2 = AssetDatabase.LoadAssetAtPath<T>(assetPath);
            SelectAssetInfo info = new SelectAssetInfo();
            info.Asset = a2;
            infos.Add(info);
            selectIndex = infos.Count - 1;
        }

        /// <summary>
        /// 删除
        /// </summary>
        private void Delete()
        {
            if (!CheckSelect()) return;
            string msg = string.Format("确定删除:{0}?", Select.Asset.name);
            if (!EditorUtility.DisplayDialog("", msg, "确定", "取消")) return;
            string assetPath = AssetDatabase.GetAssetPath(Select.Asset);
            infos.RemoveAt(selectIndex); selectIndex = -1;
            AssetDatabase.DeleteAsset(assetPath);
            AssetDatabase.Refresh();
        }

        /// <summary>
        /// 定位
        /// </summary>
        private void Ping()
        {
            if (!CheckSelect()) return;
            EditUtil.Ping(Select.Asset);
        }

        /// <summary>
        /// 检查有效性
        /// </summary>
        /// <returns>true:有效</returns>
        private bool Check()
        {
            if (string.IsNullOrEmpty(AssetDir))
            {
                ShowTip("请重写资源保存目录属性");
                return false;
            }
            if (string.IsNullOrEmpty(AssetName))
            {
                ShowTip("请重写资源默认名称属性");
                return false;
            }
            return true;
        }

        #endregion

        #region 保护方法
        protected override void ContextClickCustom(GenericMenu menu)
        {
            menu.AddItem("创建", false, Create);
            menu.AddSeparator("");
            menu.AddItem("删除", false, Delete);
            menu.AddSeparator("");
            menu.AddItem("定位", false, Ping);
            menu.AddSeparator("");
        }
        protected override void SetInfos()
        {
            if (!Check()) return;
            infos.Clear();
            string fullDir = AssetPathUtil.CurDir + AssetDir;
            if (!Directory.Exists(fullDir))
            {
                Directory.CreateDirectory(fullDir); return;
            }
            string[] files = Directory.GetFiles(fullDir, "*.asset");
            if (files == null || files.Length == 0) return;
            int length = files.Length;
            for (int i = 0; i < length; i++)
            {
                string filePath = files[i];
                string assetPath = FileUtil.GetProjectRelativePath(filePath);
                Object t = AssetDatabase.LoadAssetAtPath<T>(assetPath);
                if (t == null) continue;
                SelectAssetInfo info = new SelectAssetInfo();
                info.Asset = t;
                infos.Add(info);
            }
        }
        #endregion

        #region 公开方法

        #endregion
    }
}