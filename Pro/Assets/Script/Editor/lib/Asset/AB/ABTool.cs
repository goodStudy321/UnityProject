/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2015/4/27 02:28:24
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;
using Debug = UnityEngine.Debug;

namespace Loong.Edit
{
    /// <summary>
    /// 资源包工具
    /// </summary>
    public static partial class ABTool
    {
        #region 字段
        private static ABView data = null;

        private static ElapsedTime et = new ElapsedTime();
        /// <summary>
        /// 菜单优先级
        /// </summary>
        public const int Pri = MenuTool.AssetPri + 50;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "资源包工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "资源包工具/";

        /// <summary>
        /// AB 变体后缀名
        /// </summary>
        public static readonly string variant = Suffix.AB.Replace(".", string.Empty);

        /// <summary>
        /// 资源数据
        /// </summary>
        public static ABView Data
        {
            get
            {
                if (data == null)
                {
                    data = AssetDataUtil.Get<ABView>();
                }
                return data;
            }
        }
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        /// <summary>
        /// 获取打包设置
        /// </summary>
        /// <returns></returns>
        private static BuildAssetBundleOptions GetBuildOpts()
        {
            var opts = Data.AbForce ? BuildAssetBundleOptions.ForceRebuildAssetBundle : BuildAssetBundleOptions.None;
            if (!Data.Compress) opts = opts | BuildAssetBundleOptions.UncompressedAssetBundle;
            //opts = opts | BuildAssetBundleOptions.DisableWriteTypeTree;
            return opts;
        }



        private static string GetOutput(BuildTarget target)
        {
            string outputFolder = Data.Output;
            string outputDir = outputFolder + "/" + EditUtil.GetPlatform(target);
            if (!Directory.Exists(outputDir)) Directory.CreateDirectory(outputDir);
            return outputDir;
        }


        private static void SetName(bool force)
        {

            Object[] objs = AssetUtil.GetFiltered();
            if (objs == null || objs.Length == 0) return;
            string[] depends = AssetUtil.GetDepends(objs);
            float len = depends.Length;
            for (int i = 0; i < len; i++)
            {
                string path = depends[i];
                float pro = i / len;
                ABNameUtil.Set(path, force);
                ProgressBarUtil.Show("", "正在玩命设置中···", pro);
            }

            UIEditTip.Warning("设置完成\n若有无效资源,请见控制台红色输出");

            ProgressBarUtil.Clear();
            EditorUtility.UnloadUnusedAssetsImmediate();
            AssetDatabase.RemoveUnusedAssetBundleNames();
            AssetDatabase.Refresh();
        }

        /// <summary>
        /// 设置资源的AB名称
        /// </summary>
        [MenuItem(menu + "设置资源包名称/引用资源已设则跳过 #&j", false, Pri + 2)]
        [MenuItem(AMenu + "设置资源包名称/引用资源已设则跳过", false, Pri + 2)]
        private static void SetNameSkip()
        {
            SetName(false);
        }

        /// <summary>
        /// 设置资源的AB名称
        /// </summary>
        [MenuItem(menu + "设置资源包名称/强制 #&r", false, Pri + 3)]
        [MenuItem(AMenu + "设置资源包名称/强制", false, Pri + 3)]
        private static void SetNameForce()
        {
            SetName(true);
        }

        /// <summary>
        /// 取消资源包设置
        /// </summary>
        [MenuItem(menu + "取消资源包名称", false, Pri + 4)]
        [MenuItem(AMenu + "取消资源包名称", false, Pri + 4)]
        private static void SetNone()
        {
            Object[] objs = AssetUtil.GetFiltered();
            if (objs == null || objs.Length == 0) return;
            float len = objs.Length;
            for (int i = 0; i < len; i++)
            {
                string path = AssetDatabase.GetAssetPath(objs[i]);
                string suffix = Suffix.Get(path);
                ProgressBarUtil.Show("", "正在玩命设置中···", i / len);
                if (!AssetUtil.IsValidSfx(suffix)) continue;
                Remove(path);
            }
            UIEditTip.Warning("设置完成");
            ProgressBarUtil.Clear();
            AssetDatabase.Refresh();
        }

        /// <summary>
        /// 取消资源包设置
        /// </summary>
        [MenuItem(menu + "取消资源包名称(包含依赖)", false, Pri + 5)]
        [MenuItem(AMenu + "取消资源包名称(包含依赖)", false, Pri + 5)]
        private static void SetNoneDependsAsk()
        {
            DialogUtil.Show("", "取消资源包名称(包含依赖)?", SetNoneDepends);
        }

        private static void SetNoneDepends()
        {
            var paths = SelectUtil.GetDepends<Object>();
            if (paths == null) return;
            float len = paths.Length;
            for (int i = 0; i < len; i++)
            {
                var path = paths[i];
                var sfx = Suffix.Get(path);
                ProgressBarUtil.Show("", "正在玩命取消中···", i / len);
                if (!AssetUtil.IsValidSfx(sfx)) continue;
                Remove(path);
            }
            UIEditTip.Warning("设置完成");
            ProgressBarUtil.Clear();
            AssetDatabase.Refresh();
        }

        /// <summary>
        /// 编辑器内创建所有资源包
        /// </summary>
        private static void Build(BuildTarget target)
        {
            et.Beg();
            ProgressBarUtil.Show("请稍候", "搜集资源中···", 0.5f);
            var localTarget = EditorUserBuildSettings.activeBuildTarget;
            if (target != localTarget)
            {
                string msg = string.Format("当前工程设置为:{0},而资源包目标平台是:{1},如果强制打包,所有资源将重新导入目标平台,过程会很慢，继续打包?", localTarget, target);
                if (!EditorUtility.DisplayDialog("", msg, "继续", "取消")) return;
            }
            var output = GetOutput(target);
            if (string.IsNullOrEmpty(output)) return;
            var opts = GetBuildOpts();
            var mf = BuildPipeline.BuildAssetBundles(output, opts, target);

            var str = (mf == null ? "无资源" : "创建完成");
            UIEditTip.Warning(str);
            AssetDatabase.Refresh();
            et.End("Build AB");
        }

        [MenuItem(menu + "创建资源包/选择文件  &%l", false, Pri + 7)]
        [MenuItem(AMenu + "创建资源包/选择文件  &%l", false, Pri + 7)]
        private static void BuildSelect()
        {
            var title = "选择文件创建AB,只对已经设置过的包名有效,新增/修改/删除依赖等无效,若有意外发生请使用全局打包?";
            if (!EditorUtility.DisplayDialog("", title, "是", "否")) return;
            et.Beg();
            var objs = Selection.GetFiltered<Object>(SelectionMode.DeepAssets);
            if (objs == null || objs.Length == 0)
            {
                UIEditTip.Error("未选择任何资源");
                return;
            }
            var target = EditorUserBuildSettings.activeBuildTarget;
            var output = GetOutput(target);
            if (string.IsNullOrEmpty(output)) return;
            var opts = GetBuildOpts();

            float length = objs.Length;
            var builds = new List<AssetBundleBuild>();
            title = "搜集资源";
            for (int i = 0; i < length; i++)
            {
                var path = AssetDatabase.GetAssetPath(objs[i]);
                ProgressBarUtil.Show(title, path, i / length);
                if (string.IsNullOrEmpty(path)) continue;
                var sfx = Path.GetExtension(path);
                if (!AssetUtil.IsValidSfx(sfx)) continue;
                var ai = AssetImporter.GetAtPath(path);
                if (string.IsNullOrEmpty(ai.assetBundleName))
                {
                    Debug.LogErrorFormat("Loong, {0} 未设置包名", path);
                }
                else
                {
                    var abb = new AssetBundleBuild();
                    abb.assetBundleName = ai.assetBundleName;
                    abb.assetBundleVariant = ai.assetBundleVariant;
                    abb.assetNames = new string[] { path };
                    builds.Add(abb);
                }
            }
            ProgressBarUtil.Clear();
            if (builds.Count < 1)
            {
                UIEditTip.Error("无任何打包文件");
            }
            else
            {
                var plat = EditUtil.GetPlatform(target);
                var abPath = Path.Combine(output, plat);
                var abMfPath = abPath + Suffix.Manifest;
                var tmpAbPath = abPath + "_tmp";
                var tmpAbMfPath = tmpAbPath + Suffix.Manifest;
                File.Copy(abPath, tmpAbPath, true);
                File.Copy(abMfPath, tmpAbMfPath, true);
                var mf = BuildPipeline.BuildAssetBundles(output, builds.ToArray(), opts, target);
                var msg = (mf == null ? "无资源" : "创建完成");
                UIEditTip.Warning(msg);
                AssetDatabase.Refresh();
                File.Copy(tmpAbPath, abPath, true);
                File.Copy(tmpAbMfPath, abMfPath, true);
            }
            et.End("build select ab");
        }


        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 通过包名获取文件的完整路径
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public static string GetPath(string name)
        {
            var srcDir = Data.Output;
            srcDir = Path.GetFullPath(srcDir);
            var plat = EditUtil.GetPlatform();
            var dir = Path.Combine(srcDir, plat);
            var path = Path.Combine(dir, name);
            return path;
        }

        /// <summary>
        /// 设置资源包名称和后缀名,并根据后缀名进行验证,并且包名是唯一的
        /// </summary>
        /// <param name="path">资源路径</param>
        public static void SetUnique(string path)
        {
            string sfx = Path.GetExtension(path);
            if (!AssetUtil.IsValidSfx(sfx)) return;
            string name = Path.GetFileName(path);
            if (name == LightingDataUtil.LightingDataName) return;
            AssetImporter import = AssetImporter.GetAtPath(path);
            if (import == null) return;
            if (import.assetBundleName != name)
            {
                if (CheckUnique(name))
                {
                    import.assetBundleName = name;
                }
                else
                {
                    string tip = string.Format("导入的文件:{0},和其它文件重名", path);
                    iTrace.Error("Loong", tip);
                }
            }
            if (import.assetBundleVariant != variant)
            {
                import.assetBundleVariant = variant;
            }
        }

        /// <summary>
        /// 设置资源包名称和后缀名
        /// </summary>
        /// <param name="path">资源路径</param>
        /// <param name="name">资源包名</param>
        public static void Set(string path, string name)
        {
            AssetImporter import = AssetImporter.GetAtPath(path);
            SetImportBundle(import, name);
        }

        /// <summary>
        /// 设置导入资源的资源包名称和后缀名
        /// </summary>
        /// <param name="import">导入</param>
        /// <param name="name">名称</param>
        public static void SetImportBundle(AssetImporter import, string name)
        {
            if (import == null) return;
            if (import.assetBundleName != name) import.assetBundleName = name;
            if (import.assetBundleVariant != variant) import.assetBundleVariant = variant;
        }

        /// <summary>
        /// 检查是否是唯一名称
        /// </summary>
        /// <param name="name">资源包名</param>
        /// <returns></returns>
        public static bool CheckUnique(string name)
        {
            string[] names = AssetDatabase.GetAllAssetBundleNames();
            int length = names.Length;
            for (int i = 0; i < length; i++)
            {
                if (names[i].Equals(name)) return false;
            }
            return true;
        }

        /// <summary>
        /// 设置资源部名称为空即None
        /// </summary>
        /// <param name="assetPath">资源路径</param>
        public static void Remove(string assetPath)
        {
            AssetImporter importer = AssetImporter.GetAtPath(assetPath);
            if (importer == null) return;
            importer.assetBundleName = null;
        }

        /// <summary>
        /// 获取当前平台的清单文件
        /// </summary>
        /// <returns></returns>
        public static AssetBundleManifest GetManifest()
        {
            return GetManifest(EditorUserBuildSettings.activeBuildTarget);
        }

        /// <summary>
        /// 获取指定平台的清单文件
        /// </summary>
        /// <param name="target">平台</param>
        /// <returns></returns>
        public static AssetBundleManifest GetManifest(BuildTarget target)
        {
            string output = Data.Output;
            string platform = EditUtil.GetPlatform(target);
            string manifestPath = string.Format("{0}/{1}/{2}", output, platform, platform);
            if (!File.Exists(manifestPath)) return null;
            AssetBundle ab = AssetBundle.LoadFromFile(manifestPath);
            if (ab == null) return null;
            AssetBundleManifest manifest = ab.LoadAsset<AssetBundleManifest>(typeof(AssetBundleManifest).Name);
            return manifest;
        }



        /// <summary>
        /// 拷贝指定平台的清单文件到指定目录
        /// </summary>
        /// <param name="target"></param>
        /// <param name="destDir"></param>
        public static void CopyManifest(BuildTarget target, string destDir)
        {
            string plat = EditUtil.GetPlatform();
            string srcPath = string.Format("{0}/{1}/{2}", Data.Output, plat, plat);
            if (File.Exists(srcPath)) return;
            Directory.CreateDirectory(destDir);
            string destPath = string.Format("{0}/{1}", destDir, plat);
            File.Copy(srcPath, destPath);
        }


        /// <summary>
        /// 拷贝当前平台的清单文件到指定目录
        /// </summary>
        /// <param name="destDir"></param>
        public static void CopyManifest(string destDir)
        {
            CopyManifest(EditorUserBuildSettings.activeBuildTarget, destDir);
        }


        /// <summary>
        /// 获取指定平台的清单文件路径
        /// </summary>
        /// <param name="target"></param>
        public static string GetManifestPath(BuildTarget target)
        {
            string plat = EditUtil.GetPlatform();
            string manifestPath = string.Format("{0}/{1}/{2}", Data.Output, plat, plat);
            return manifestPath;
        }


        /// <summary>
        /// 获取当前平台的清单文件路径
        /// </summary>
        public static string GetManifestPath()
        {
            return GetManifestPath(EditorUserBuildSettings.activeBuildTarget);
        }


        public static string GetOutput()
        {
            return GetOutput(EditorUserBuildSettings.activeBuildTarget);
        }

        /// <summary>
        /// 指定路径的资源创建资源包
        /// </summary>
        public static void Build(string path)
        {
            SetDependName(path);
            Build(EditorUserBuildSettings.activeBuildTarget);
        }

        /// <summary>
        /// 对指定对象所有依赖的资源进行设置
        /// </summary>
        public static void SetDependName(string path)
        {
            string[] depends = AssetDatabase.GetDependencies(path);
            int length = depends.Length;
            for (int i = 0; i < length; i++)
            {
                ABNameUtil.Set(depends[i]);
            }
        }
        /// <summary>
        /// 删除无用资源包名称
        /// </summary>
        [MenuItem(menu + "删除无用资源包名称", false, Pri + 5)]
        [MenuItem(AMenu + "删除无用资源包名称", false, Pri + 5)]
        public static void RemoveUnusedNames()
        {
            AssetDatabase.RemoveUnusedAssetBundleNames();
        }

        /// <summary>
        /// 创建工程设置平台的资源包
        /// </summary>
        [MenuItem(menu + "创建资源包/工程设置 &%k", false, Pri + 10)]
        [MenuItem(AMenu + "创建资源包/工程设置", false, Pri + 10)]
        public static void BuildUserSettings()
        {
            Build(EditorUserBuildSettings.activeBuildTarget);
        }

        /// <summary>
        /// 打包安卓平台资源包
        /// </summary>
        [MenuItem(menu + "创建资源包/Android &%g", false, Pri + 11)]
        [MenuItem(AMenu + "创建资源包/Android", false, Pri + 11)]
        public static void BuildAndroid()
        {
            Build(BuildTarget.Android);
        }

        /// <summary>
        /// 打包IOS平台资源包
        /// </summary>
        [MenuItem(menu + "创建资源包/IOS &%i", false, Pri + 12)]
        [MenuItem(AMenu + "创建资源包/IOS", false, Pri + 12)]
        public static void BuildIOS()
        {
            Build(BuildTarget.iOS);
        }


        /// <summary>
        /// 删除资源包/无对话框
        /// </summary>
        public static void Delete(BuildTarget target)
        {
            if (string.IsNullOrEmpty(Data.Output))
            {
                UIEditTip.Error("资源输出目录为空,无需删除");
                return;
            }
            string platform = EditUtil.GetPlatform(target);
            string abDir = string.Format("{0}/{1}", Data.Output, platform);
            if (!Directory.Exists(abDir))
            {
                UIEditTip.Warning("资源输出目录:\n{0}\n不存在,无需删除", abDir);
            }
            else
            {
                Directory.Delete(abDir, true);
                UIEditTip.Log("删除目录:{0},成功", abDir);
            }
        }

        /// <summary>
        /// 删除当前平台的资源包
        /// </summary>
        public static void Delete()
        {
            Delete(EditorUserBuildSettings.activeBuildTarget);
        }

        /// <summary>
        /// 删除资源包/有对话框
        /// </summary>
        [MenuItem(menu + "删除资源包 &d", false, Pri + 13)]
        [MenuItem(AMenu + "删除资源包", false, Pri + 13)]
        public static void DeleteWithDialog()
        {
            string tip = string.Format("确定删除{0}平台的资源包嘛?", EditorUserBuildSettings.activeBuildTarget);
            if (EditorUtility.DisplayDialog("", tip, "确定", "取消"))
            {
                Delete(EditorUserBuildSettings.activeBuildTarget);
            }
        }

        public static void DeleteUnused()
        {
            var output = GetOutput();
            AssetDatabase.RemoveUnusedAssetBundleNames();
            var abs = AssetDatabase.GetAllAssetBundleNames();
            var sets = new HashSet<string>();
            int abLen = abs.Length;
            for (int i = 0; i < abLen; i++)
            {
                sets.Add(abs[i]);
            }
            var files = Directory.GetFiles(output, "*.ab", SearchOption.AllDirectories);
            var title = "删除无用资源包";
            float len = files.Length;
            for (int i = 0; i < len; i++)
            {
                var path = files[i];
                var name = Path.GetFileName(path);
                ProgressBarUtil.Show(title, name, i / len);
                if (sets.Contains(name)) continue;
                if (File.Exists(path)) File.Delete(path);
                var mfPath = path + Suffix.Manifest;
                if (File.Exists(mfPath)) File.Delete(mfPath);
                Debug.LogFormat("删除 {0}", name);
            }

            ProgressBarUtil.Clear();
        }

        /// <summary>
        /// 删除无资源包/有对话框
        /// </summary>
        [MenuItem(menu + "删除无用资源包 &m", false, Pri + 14)]
        [MenuItem(AMenu + "删除无用资源包", false, Pri + 14)]
        public static void DeleteUnusedWithDialog()
        {
            var tip = string.Format("确定删除{0}平台的无用资源包嘛?", EditorUserBuildSettings.activeBuildTarget);
            DialogUtil.Show("", tip, DeleteUnused);
        }

        /// <summary>
        /// 打开输出目录
        /// </summary>
        [MenuItem(menu + "打开输出目录 &o", false, Pri + 14)]
        [MenuItem(AMenu + "打开输出目录", false, Pri + 14)]
        public static void OpenOutput()
        {
            ProcessUtil.Start(Data.Output, "资源");
        }

        /// <summary>
        /// 重新生成
        /// </summary>
        public static void Rebuild()
        {
            Delete();
            BuildUserSettings();
        }
        #endregion
    }
}