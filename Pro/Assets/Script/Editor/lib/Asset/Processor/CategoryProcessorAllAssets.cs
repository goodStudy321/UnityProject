using System;
using System.IO;
using Loong.Game;
using System.Text;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.4.27
    /// BG:分类资源处理器
    /// </summary>
    public static class CategoryProcessorAllAssets
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        /// <summary>
        /// 设置所有资源的依赖
        /// </summary>
        /// <param name="assets">需要分类的资源列表</param>
        private static void SetAllDepends(List<string> assets)
        {
            if (assets == null || assets.Count == 0) return;
            string[] assetArr = assets.ToArray();
            string curDir = Directory.GetCurrentDirectory();
            string[] allDepends = AssetDatabase.GetDependencies(assetArr);
            int length = allDepends.Length;
            for (int i = 0; i < length; i++)
            {
                string assetPath = allDepends[i];
                string filePath = string.Format("{0}/{1}", curDir, assetPath);
                if (!File.Exists(filePath)) continue;
                CategoryFolder(assetPath);
            }
        }

        /// <summary>
        /// 设置导入列表
        /// </summary>
        private static void SetImports(string[] imports)
        {
            int importLen = imports.Length;
            List<string> importList = new List<string>();
            for (int i = 0; i < importLen; i++)
            {
                string importPath = imports[i];
                if (!EditSceneView.Contains(importPath)) continue;
                if (!AssetProcessor.CheckPath(importPath)) continue;
                //iTrace.Log("Loong", string.Format("导入成功:{0}", importPath));
                if (importList.Contains(importPath)) continue;
                importList.Add(importPath);
            }
            SetAllDepends(importList);
        }

        /// <summary>
        /// 设置删除列表
        /// </summary>
        /// <param name="deletes"></param>
        private static void SetDeletes(string[] deletes)
        {
            if (deletes == null) return;
            int length = deletes.Length;
            if (length == 0) return;
            ABView data = ABTool.Data;
            string folder = EditUtil.GetPlatform();
            folder = string.Format("{0}/{1}", data.Output, folder);
            for (int i = 0; i < length; i++)
            {
                string path = deletes[i];
                if (!EditSceneView.Contains(path)) continue;
                string fileName = Path.GetFileName(path);
                AssetProcessor.Delete(folder, fileName);
            }
        }

        /// <summary>
        /// 设置移动列表
        /// </summary>
        private static void SetMoves(string[] moveTos, string[] moveFroms)
        {
            int moveFromLen = moveFroms.Length;
            int moveToLen = moveTos.Length;
            if (moveFromLen != moveToLen)
            { iTrace.Error("Loong", "移动资源from和to的数量不一致"); return; }
            List<string> assets = new List<string>();
            for (int i = 0; i < moveToLen; i++)
            {
                //iTrace.Log("Loong", string.Format("移动资源:从:{0},到:{1}", moveFroms[i], moveTos[i]));
                if (!AssetProcessor.CheckPath(moveTos[i])) continue;
                SetMoveFolder(moveFroms[i], moveTos[i], assets);
            }
            SetAllDepends(assets);
        }

        /// <summary>
        /// 对场景文件夹的文件进行分类处理
        /// </summary>
        private static void CategoryFolder(string assetPath)
        {
            if (assetPath.Contains("/Editor/")) return;
            if (assetPath.Contains("/Resources/")) return;
            string sfx = Suffix.Get(assetPath);
            if (!AssetProcessor.CheckSuffix(sfx))
            {
                return;
            }
            if (assetPath.StartsWith(EditSceneView.packPrefix))
            {
                ABNameUtil.Set(assetPath); return;
            }

            string sceneDir = SceneMgr.GetDir(assetPath);

            //检查是否光照贴图
            string lightMapDir = GetLightMapDir(sceneDir);
            if (assetPath.StartsWith(lightMapDir))
            {
                ABNameUtil.Set(assetPath); return;
            }

            //检查不需要分类
            string iNoneDir = GetiNoneDir(sceneDir);
            if (assetPath.Contains(iNoneDir))
            {
                ABNameUtil.Set(assetPath); return;
            }

            //检查需要分类文件
            string targetDir = GetCategoryDir(sfx, sceneDir);
            if (assetPath.StartsWith(targetDir))
            {
                ABNameUtil.Set(assetPath); return;
            }
            else if (sfx == Suffix.Shader)
            {
                if (!assetPath.StartsWith(EditSceneView.prefix))
                {
                    ABNameUtil.Set(assetPath); return;
                }
            }

            string fileName = Path.GetFileName(assetPath);
            string toPath = string.Format("{0}/{1}", targetDir, fileName);
            Object toObj = AssetDatabase.LoadAssetAtPath<Object>(toPath);
            if (toObj == null)
            {
                //iTrace.Log("Loong", string.Format("移动资源从:{0},到:{1},场景目录:{2}", assetPath, toPath, sceneDir));
                AssetDatabase.MoveAsset(assetPath, toPath);
                ABNameUtil.Set(toPath);
            }
            else
            {
                string err = string.Format("无法移动:{0},到:{1},因为已经存在", assetPath, toPath);
                iTrace.Error("Loong", err);
            }

        }

        /// <summary>
        /// 移动文件时对文件进行处理
        /// </summary>
        /// <param name="from">移动位置</param>
        /// <param name="to">目标位置</param>
        /// <param name="assets">需要重新检查资源分类的列表</param>
        private static void SetMoveFolder(string from, string to, List<string> assets)
        {
            if (EditSceneView.Contains(from))
            {
                if (EditSceneView.Contains(to))
                {
                    assets.Add(to);
                }
                else
                {
                    ABTool.Remove(to);
                    AssetProcessor.DeletePath(to);
                }
            }
            else
            {
                if (EditSceneView.Contains(to))
                {
                    assets.Add(to);
                }
            }
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 所有资源导入 之后
        /// </summary>
        /// <param name="imports">导入的资源</param>
        /// <param name="deletes">删除的资源</param>
        /// <param name="moveTos">移动的资源,移动后的位置</param>
        /// <param name="moveFroms">移动的资源,移动前的位置</param>
        public static void Execute(string[] imports, string[] deletes, string[] moveTos, string[] moveFroms)
        {
            if (!AssetProcessor.View.Use) return;
            EditSceneView.CreateShare();
            SetImports(imports);
            SetDeletes(deletes);
            SetMoves(moveTos, moveFroms);
            AssetDatabase.RemoveUnusedAssetBundleNames();
            EditorUtility.UnloadUnusedAssetsImmediate(true);
            AssetDatabase.Refresh();
            //iTrace.Log("Loong", "导入结束");
        }

        /// <summary>
        /// 获取不需分类的目录
        /// </summary>
        /// <param name="sceneDir">场景目录</param>
        /// <returns></returns>
        public static string GetiNoneDir(string sceneDir)
        {
            string dir = string.Format("{0}/{1}", sceneDir, EditSceneView.iNone);
            return dir;
        }

        /// <summary>
        /// 获取光照贴图目录
        /// </summary>
        /// <param name="sceneDir">场景目录</param>
        /// <returns></returns>
        public static string GetLightMapDir(string sceneDir)
        {
            string sceneName = Path.GetFileName(sceneDir);
            string dir = string.Format("{0}/Unity/{1}", sceneDir, sceneName);
            return dir;
        }

        /// <summary>
        /// 获取分类目录
        /// </summary>
        /// <param name="sfx">后缀名</param>
        /// <param name="sceneDir">场景目录</param>
        /// <returns></returns>
        public static string GetCategoryDir(string sfx, string sceneDir)
        {
            string folder = EditSceneView.dic[sfx].folder;
            string dir = string.Format("{0}/{1}", sceneDir, folder);
            return dir;
        }


        #endregion
    }
}