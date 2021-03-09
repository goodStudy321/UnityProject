/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2014/4/15 10:51:58
 ============================================================================*/

#if UNITY_EDITOR
using System;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;
using System.Reflection;
using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// 编辑器工具
    /// </summary>
    public static class EditUtil
    {
        #region 字段
        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "通用工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "通用工具/";
        #endregion

        #region 属性
        /// <summary>
        /// 编辑器文件存放路径
        /// </summary>
        public static string FileDir
        {
            get { return Directory.GetCurrentDirectory() + "/EditorFile/"; }
        }
        /// <summary>
        /// 编辑器资源文件存放路径
        /// </summary>
        public static string AssetDir
        {
            get { return "Assets/Script/Editor/Asset/"; }
        }
        #endregion

        #region 私有方法

        [MenuItem(menu + "释放编辑器无用资源", false, MenuTool.NormalPri + 5)]
        [MenuItem(AMenu + "释放编辑器无用资源", false, MenuTool.NormalPri + 5)]
        private static void EditorGCCollect()
        {
#if UNITY_4
            EditorUtility.UnloadUnusedAssets();
#else
            EditorUtility.UnloadUnusedAssetsImmediate();
#endif
        }
        #endregion

        #region 公开方法

        /// <summary>
        /// 获取选择的制定类型的资源数组
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <returns></returns>
        public static T[] GetFiltered<T>() where T : class
        {
            return UnityEditor.Selection.GetFiltered(typeof(T), SelectionMode.DeepAssets) as T[];
        }

        /// <summary>
        /// 保存并刷新工程
        /// </summary>
        [MenuItem(menu + "刷新并保存工程 #&S", false, MenuTool.NormalPri + 6)]
        [MenuItem(AMenu + "刷新并保存工程", false, MenuTool.NormalPri + 6)]
        public static void SaveAssets()
        {
            SaveAssets(true);
        }

        /// <summary>
        /// 保存并刷新工程
        /// </summary>
        /// <param name="showTip">true:显示提示</param>
        public static void SaveAssets(bool showTip)
        {
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            if (showTip) UIEditTip.Log("已刷新");
        }

        /// <summary>
        /// 清理控制台
        /// </summary>
        [MenuItem(menu + "清理控制台 &C", false, MenuTool.NormalPri + 7)]
        [MenuItem(AMenu + "清理控制台", false, MenuTool.NormalPri + 7)]
        public static void ClearDebug()
        {
            string methodName = "Clear";
            var asm = Assembly.GetAssembly(typeof(SceneView));
            var logEntries = asm.GetType("UnityEditor.LogEntries");
            var flags = BindingFlags.Static | BindingFlags.Public;
            var clearMethod = logEntries.GetMethod(methodName, flags);
            if (clearMethod == null)
            {
                UIEditTip.Error("清理失败,反射没有发现方法:{0}", methodName);
            }
            else
            {
                clearMethod.Invoke(null, null);
                UIEditTip.Log("已清理控制台");
            }
        }

        /// <summary>
        /// 对指定的对象列表注册一个可撤销操作
        /// </summary>
        /// <param name="name">操作名称</param>
        /// <param name="objs">对象列表</param>
        public static void RegisterUndo(string name, params Object[] objs)
        {
            if (objs == null || objs.Length == 0) return;
            Undo.RecordObjects(objs, name);
            int length = objs.Length;
            for (int i = 0; i < length; i++)
            {
                SetDirty(objs[i]);
            }
        }

        /// <summary>
        /// 设置指定对象脏数据
        /// </summary>
        /// <param name="target">对象</param>
        public static void SetDirty(Object target)
        {
            if (target != null) EditorUtility.SetDirty(target);
        }

        /// <summary>
        /// 定位指定路径的资源
        /// </summary>
        /// <param name="assetPath">资源路径</param>
        public static void Ping(string assetPath)
        {
            if (string.IsNullOrEmpty(assetPath)) return;
            Object obj = AssetDatabase.LoadAssetAtPath<Object>(assetPath);
            Ping(obj);
        }

        /// <summary>
        /// 定位指定对象
        /// </summary>
        /// <param name="obj">对象</param>
        public static void Ping(Object obj)
        {
            if (obj == null) return;
            EditorGUIUtility.PingObject(obj);
        }

        /// <summary>
        /// 获取不同平台的对应文件夹
        /// </summary>
        /// <param name="target">平台</param>
        /// <returns></returns>
        public static string GetPlatform(BuildTarget target)
        {
            switch (target)
            {
                case BuildTarget.Android:
                    return "Android";
                case BuildTarget.iOS:
                    return "iOS";
                case BuildTarget.StandaloneWindows:
                case BuildTarget.StandaloneWindows64:
                    return "Windows";
                //case BuildTarget.StandaloneOSXIntel:
                //case BuildTarget.StandaloneOSXIntel64:
                case BuildTarget.StandaloneOSX:
                    return "OSX";
                default:
                    return "Other";
            }
        }

        /// <summary>
        /// 获取工程设置平台对应的文件夹
        /// </summary>
        /// <returns></returns>
        public static string GetPlatform()
        {
            return GetPlatform(EditorUserBuildSettings.activeBuildTarget);
        }
        #endregion
    }
}
#endif