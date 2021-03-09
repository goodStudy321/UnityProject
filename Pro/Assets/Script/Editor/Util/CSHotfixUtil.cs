//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/2/25 14:51:56
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.SceneManagement;
using UnityEditor.SceneManagement;

namespace Loong.Edit
{
    using StrDic = Dictionary<string, string>;
    /// <summary>
    /// CSHotfixUtil
    /// </summary>
    public static class CSHotfixUtil
    {
        #region 字段
        private static string libDir = null;
        public const string libName = "CSHotfix";
        public const string fileName = "png.bytes";

        /// <summary>
        /// 菜单优先级
        /// </summary>
        public const int Pri = AssetUpgUtil.Pri + 10;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = AssetUpgUtil.menu + libName + "/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = AssetUpgUtil.AMenu + libName + "/";

        /// <summary>
        /// k:要移动的目录, v:移动到的目录
        /// </summary>
        public static readonly StrDic moveDic = new StrDic
        {
            { "Assets/Script/Client","Assets/Script/Editor" },
            { "Assets/Mod/Client","Assets/Mod/Editor" },
            { "Assets/Source","Assets/Script/Editor" },
            { "Assets/ToLua/BaseType","Assets/ToLua/Editor" },
            { "Assets/ToLua/Core","Assets/ToLua/Editor" },
            { "Assets/ToLua/Misc","Assets/ToLua/Editor" },
            { "Assets/ToLua/Reflection","Assets/ToLua/Editor" },
        };
        #endregion

        #region 属性
        /// <summary>
        /// 库目录
        /// </summary>
        public static string LibDir
        {
            get
            {
                if (libDir == null)
                {
                    var rDir = "../" + libName + "/" + libName + "/";
                    libDir = Path.GetFullPath(rDir);
                }
                return libDir;
            }
        }
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 移动运行时脚本
        /// </summary>
        /// <param name="toEditor">true:移动到Editor,false:从Editor移出</param>
        private static void MoveRuntime(bool toEditor)
        {
            var em = moveDic.GetEnumerator();
            while (em.MoveNext())
            {
                var src = em.Current.Key;
                var name = Path.GetFileName(src);
                var dest = em.Current.Value + "/" + name;
                if (toEditor)
                {
                    FileUtil.MoveFileOrDirectory(src, dest);
                }
                else
                {
                    FileUtil.MoveFileOrDirectory(dest, src);
                }
            }
            AssetDatabase.Refresh();
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 获取热更文件在流目录的路径
        /// </summary>
        /// <returns></returns>
        public static string GetStreamPath()
        {
            return Path.Combine(Application.streamingAssetsPath, fileName);
        }

        public static string GetCodePath()
        {
            var srcDir = ABTool.Data.Output;
            var path = Path.Combine(srcDir, fileName);
            return path;
        }

        /// <summary>
        /// 拷贝热更文件到流目录
        /// </summary>
        public static void CopyToStream()
        {
            var srcPath = GetCodePath();
            if (File.Exists(srcPath))
            {
                var destPath = GetStreamPath();
                File.Copy(srcPath, destPath, true);
            }
            else
            {
                Debug.LogErrorFormat("Loong, {0} not exist!", srcPath);
            }
        }

        /// <summary>
        /// 删除流目录内的热更文件
        /// </summary>
        public static void DeleteFromStream()
        {
            var destPath = GetStreamPath();
            if (File.Exists(destPath))
            {
                File.Delete(destPath);
            }
        }

        /// <summary>
        /// 删除编辑器中的Runtime脚本
        /// </summary>
        public static void DeleteFromEditor()
        {
            var em = moveDic.GetEnumerator();
            var curDir = Directory.GetCurrentDirectory() + "/";
            while (em.MoveNext())
            {
                var src = em.Current.Key;
                var name = Path.GetFileName(src);
                var dest = em.Current.Value + "/" + name;
                var full = curDir + dest;
                if (Directory.Exists(full)) Directory.Delete(full, true);
            }
            AssetDatabase.Refresh();
        }

        public static void MoveToEditor()
        {
            MoveRuntime(true);
        }

        public static void MoveFromEditor()
        {
            MoveRuntime(false);
        }

        public static void MoveToLib()
        {
            var em = moveDic.GetEnumerator();
            var libDir = LibDir;
            while (em.MoveNext())
            {
                var key = em.Current.Key;
                var srcDir = Path.GetFullPath("./" + key);
                var destDir = libDir + key;
                if (Directory.Exists(destDir))
                {
                    Directory.Delete(destDir, true);
                }
                else
                {
                    Directory.CreateDirectory(destDir);
                }
                EditDirUtil.Copy(srcDir, destDir);
            }
            UIEditTip.Log("移动结束");
        }

        public static void DeleteFromLib()
        {
            var em = moveDic.GetEnumerator();
            var libDir = LibDir;
            while (em.MoveNext())
            {
                var key = em.Current.Key;
                var fullDir = libDir + key;
                if (Directory.Exists(fullDir)) Directory.Delete(fullDir, true);
            }
            UIEditTip.Log("删除结束");
        }


        public static void CreateEntryScene()
        {
            var mainPath = "Assets/Main.unity";
            var cur = Directory.GetCurrentDirectory();
            var fullPath = Path.Combine(cur, mainPath);
            if (!File.Exists(fullPath))
            {
                Debug.LogErrorFormat("Loong, {0} not exist!", fullPath);
                return;
            }
            var mainScene = EditorSceneManager.GetSceneByPath(mainPath);
            var entryPath = "Assets/Main_Android.unity";
            EditorSceneManager.SaveScene(mainScene, entryPath, true);

            var entryScene = EditorSceneManager.OpenScene(entryPath);
            var gos = entryScene.GetRootGameObjects();
            int length = gos.Length;
            for (int i = 0; i < length; i++)
            {
                var go = gos[i];
                if (go.name.ToLower() == "main")
                {
                    GameObject.DestroyImmediate(go, true);
                    break;
                }
            }
#if UNITY_ANDROID
            var entryGo = GameObject.Find("Entry");
            if (entryGo != null) GameObject.DestroyImmediate(entryGo, true);
            entryGo = new GameObject("Entry");
            entryGo.AddComponent<Entry>();
#endif
            EditorSceneManager.MarkSceneDirty(entryScene);
            EditorSceneManager.SaveOpenScenes();

        }


        [MenuItem(menu + "拷贝CS_Hotfix到流目录", false, Pri + 3)]
        [MenuItem(AMenu + "拷贝CS_Hotfix到流目录", false, Pri + 3)]
        public static void CopyToStreamDialog()
        {
            DialogUtil.Show("", "拷贝CS_Hotfix到流目录", CopyToStream);
        }

        [MenuItem(menu + "从流目录删除CS_Hotfix", false, Pri + 3)]
        [MenuItem(AMenu + "从流目录删除CS_Hotfix", false, Pri + 3)]
        public static void DeleteFromStreamDialog()
        {
            DialogUtil.Show("", "从流目录删除CS_Hotfix", DeleteFromStream);
        }

        [MenuItem(menu + "移动Runtime脚本到Editor下", false, Pri + 4)]
        [MenuItem(AMenu + "移动Runtime脚本到Editor下", false, Pri + 4)]
        public static void MoveToEditorDialog()
        {
            DialogUtil.Show("", "移动Runtime脚本到Editor下", MoveToEditor);
        }

        [MenuItem(menu + "从Editor目录移出Runtime脚本", false, Pri + 5)]
        [MenuItem(AMenu + "从Editor目录移出Runtime脚本", false, Pri + 5)]
        public static void MoveFromEditorDialog()
        {
            DialogUtil.Show("", "从Editor目录移出Runtime脚本", MoveFromEditor);
        }


        [MenuItem(menu + "从Editor目录删除Runtime脚本", false, Pri + 5)]
        [MenuItem(AMenu + "从Editor目录删除Runtime脚本", false, Pri + 5)]
        public static void DeleteFromEditorDialog()
        {
            DialogUtil.Show("", "从Editor目录删除Runtime脚本", DeleteFromEditor);
        }

        [MenuItem(menu + "从库中删除热更代码", false, Pri + 5)]
        [MenuItem(AMenu + "从库中删除热更代码", false, Pri + 5)]
        public static void DeleteFromLibDialog()
        {
            DialogUtil.Show("", "从库中删除热更代码", DeleteFromLib);
        }


        [MenuItem(menu + "移动热更代码到库中", false, Pri + 5)]
        [MenuItem(AMenu + "移动热更代码到库中", false, Pri + 5)]
        public static void MoveToLibDialog()
        {
            DialogUtil.Show("", "移动热更代码到库中", MoveToLib);
        }

        [MenuItem(menu + "创建入口场景", false, Pri + 5)]
        [MenuItem(AMenu + "创建入口场景", false, Pri + 5)]
        public static void CreateEntrySceneDialog()
        {
            DialogUtil.Show("", "创建入口场景", CreateEntryScene);
        }

        public static void Ready()
        {
#if CS_HOTFIX_ENABLE

#else
            DeleteFromEditor();
            DeleteFromStream();
#endif
        }


        public static void Move()
        {
#if CS_HOTFIX_ENABLE
            CopyToStream();
            MoveToEditor();
#endif
        }
        #endregion
    }
}