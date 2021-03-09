/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/31 19:43:51
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
    using FileTool = Loong.Game.FileTool;
    using ResDic = Dictionary<string, Md5Info>;
    /// <summary>
    /// 首包工具
    /// </summary>
    public static class AssetFirstPack
    {
        #region 字段
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = AssetPackUtil.Pri + 10;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = AssetPackUtil.menu + "首包/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = AssetPackUtil.AMenu + "首包/";
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 拷贝指定文件
        /// </summary>
        /// <param name="src"></param>
        /// <param name="dest"></param>
        /// <param name="title"></param>
        private static void CopyFile(string src, string dest, string title)
        {
            if (!File.Exists(src)) return;
            FileTool.CheckDir(dest);
            ProgressBarUtil.Show(title, dest, 1f);
            File.Copy(src, dest, true);
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public static void Copy()
        {
            var srcDir = ABTool.Data.Output;
            if (!Directory.Exists(srcDir)) return;
            var dirs = Directory.GetDirectories(srcDir);
            int dirLen = dirs.Length;
            var plat = EditUtil.GetPlatform();
            var packDir = GetAssetDir();
            if (Directory.Exists(packDir)) Directory.Delete(packDir, true);

            for (int i = 0; i < dirLen; i++)
            {
                var dir = dirs[i];
                var folder = Path.GetFileName(dir);
                if (folder.Equals(plat)) continue;
                var destDir = Path.Combine(packDir, folder);
                DirUtil.Check(destDir);
                EditDirUtil.Copy(dir, destDir);
            }

            var files = Directory.GetFiles(srcDir);
            var title = "拷贝首包必须文件";
            float fileLen = files.Length;
            for (int i = 0; i < fileLen; i++)
            {
                var file = files[i];
                ProgressBarUtil.Show(title, file, i / fileLen);
                var name = Path.GetFileName(file);
                if (name == CSHotfixUtil.fileName) continue;
                var newPath = Path.Combine(packDir, name);
                File.Copy(file, newPath, true);
            }


            var srcABDir = Path.Combine(srcDir, plat);
            var desABtDir = Path.Combine(packDir, plat);
            var srcABMf = Path.Combine(srcABDir, plat);
            var desABMf = Path.Combine(desABtDir, plat);
            CopyFile(srcABMf, desABMf, "拷贝AB清单");

            var srcLuaAB = Path.Combine(srcABDir, ABNameUtil.luaName);
            var desLuaAB = Path.Combine(desABtDir, ABNameUtil.luaName);
            CopyFile(srcLuaAB, desLuaAB, "拷贝Lua");


            if (ABNameUtil.oneShader)
            {
                var shdName = ABNameUtil.shaderName;
                var srcShdAB = Path.Combine(srcABDir, shdName);
                var desShdAB = Path.Combine(desABtDir, shdName);
                CopyFile(srcShdAB, desShdAB, "拷贝Shader");
            }


            CopyByCfg();
            GenManifest();
        }


        /// <summary>
        /// 获取首包资源清单字典
        /// </summary>
        /// <param name="targetVer">资源版本</param>
        /// <param name="containUpgs">包含所有热更资源</param>
        public static ResDic GetDic(int targetVer = 0, bool containUpgs = true)
        {
            var srcDir = Path.GetFullPath(ABTool.Data.Output);
            if (!Directory.Exists(srcDir)) return null;
            ProgressBarUtil.Max = 50;
            var srcDirLen = srcDir.Length + 1;
            var upgData = AssetUpgUtil.Data;
            var curVer = targetVer;
            var srcMfPath = upgData.GetCompMd5Path(curVer);
            if (!File.Exists(srcMfPath))
            {
                UIEditTip.Error("{0} not exist!", srcMfPath); return null;
            }

            var curDic = AssetMfUtil.ReadComped(srcMfPath);
            var plat = EditUtil.GetPlatform();

            //要拷贝的资源名称列表
            var keys = new List<string>();

            //添加除了AB资源目录的所有的名称
            var dirs = Directory.GetDirectories(srcDir);
            int dirLen = dirs.Length;
            float proLen = dirLen;
            var title = "拷贝必须资源";
            for (int i = 0; i < dirLen; i++)
            {
                var dir = dirs[i];
                var folder = Path.GetFileName(dir);
                if (folder.Equals(plat)) continue;
                ProgressBarUtil.Show(title, folder, i / proLen);
                var files = Directory.GetFiles(dir);
                var fileLen = files.Length;
                for (int j = 0; j < fileLen; j++)
                {
                    var file = files[j];
                    var fk = file.Substring(srcDirLen);
                    keys.Add(fk);
                }
            }

            //设置AB清单
            var abMf = Path.Combine(plat, plat);
            keys.Add(abMf);

            //设置luaAB
            var luaAB = Path.Combine(plat, ABNameUtil.luaName);
            keys.Add(luaAB);

            //设置ShaderAB
            if (ABNameUtil.oneShader)
            {
                var shaderAB = Path.Combine(plat, ABNameUtil.shaderName);
                keys.Add(shaderAB);
            }

            //设置首包配置(AB)
            var pm = AssetPackUtil.Read();
            var firstPack = pm.packs[0];
            title = "获取首包配置依赖,请稍候";
            ProgressBarUtil.Show(title, "···", 1f);
            var depends = firstPack.GetDepends();
            title = "设置首包配置依赖(AB)";
            proLen = depends.Length;
            for (int i = 0; i < proLen; i++)
            {
                var path = depends[i];
                ProgressBarUtil.Show(title, path, i / proLen);
                var sfx = Path.GetExtension(path);
                if (Invalid(sfx)) continue;
                var ai = AssetImporter.GetAtPath(path);
                if (ai == null) continue;
                var abName = ai.assetBundleName;
                var variant = ai.assetBundleVariant;
                if (!string.IsNullOrEmpty(variant))
                {
                    abName = abName + "." + variant;
                }
                var k = plat + "/" + abName;
                keys.Add(k);
            }

            //设置首包清单字典
            Md5Info info = null;
            var baseDic = new ResDic();
            proLen = keys.Count;
            for (int i = 0; i < proLen; i++)
            {
                var k = keys[i];
                k = k.Replace('\\', '/');
                //不拷贝热更文件
                if (k == CSHotfixUtil.fileName) continue;
                info = (curDic.ContainsKey(k) ? curDic[k] : null);
                if (info == null) continue;
                if (baseDic.ContainsKey(k)) continue;
                baseDic.Add(k, info);
            }

            //将所有已更新资源添加到首包清单内
            if (targetVer > 0 && containUpgs)
            {
                var curEm = curDic.GetEnumerator();
                while (curEm.MoveNext())
                {
                    var cur = curEm.Current;
                    var k = cur.Key;
                    info = cur.Value;
                    if (info.Ver < 1) continue;
                    if (baseDic.ContainsKey(k)) continue;
                    baseDic.Add(k, info);
                }
            }
            return baseDic;
        }


        /// <summary>
        /// 拷贝已压缩资源
        /// </summary>
        /// <param name="targetVer">资源版本</param>
        /// <param name="containUpgs">包含所有热更资源</param>
        public static void CopyComped(int targetVer = 0, bool containUpgs = true)
        {
            var baseDic = GetDic(targetVer, containUpgs);
            if (baseDic.Count < 1) return;
            ProgressBarUtil.Max = 50;
            var upgData = AssetUpgUtil.Data;
            var srcMfPath = upgData.GetCompMd5Path(targetVer);


            //拷贝所有首包清单内的资源到流目录
            Md5Info info = null;
            var title = "拷贝到流目录";
            var compDir = upgData.GetCompDir();
            var streaming = AssetPathUtil.Streaming;
            ProgressBarUtil.Refresh();
            var baseEm = baseDic.GetEnumerator();
            var proLen = baseDic.Count;
            int idx = 0;
            while (baseEm.MoveNext())
            {
                ++idx;
                var cur = baseEm.Current;
                var k = cur.Key;
                info = cur.Value;
                ProgressBarUtil.Show(title, k, idx / proLen);
                var ver = info.Ver;
                var srcPath = string.Format("../{0}{1}/{2}", compDir, ver, k);
                var destPath = string.Format("{0}{1}", streaming, k);
                var dir = Path.GetDirectoryName(destPath);
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                File.Copy(srcPath, destPath, true);

            }

            //生成首包清单到流目录
            title = "生成首包清单";
            var temp = AssetPathUtil.Temp;
            var baseMfName = AssetMf.BaseName;
            var srcBaseMfPath = temp + baseMfName;
            var destBaseMfPath = streaming + baseMfName;
            ProgressBarUtil.Show(title, baseMfName, 1f);
            AssetMf.Write(baseDic, srcBaseMfPath);
            var comp = CompFty.Create();
            comp.Src = srcBaseMfPath;
            comp.Dest = destBaseMfPath;
            if (!comp.Execute())
            {
                Debug.LogErrorFormat("Loong, comp {0} fail", destBaseMfPath);
            }

            //拷贝总清单
            var destMfPath = streaming + AssetMf.Name;
            File.Copy(srcMfPath, destMfPath, true);
            ProgressBarUtil.Clear();
            AssetDatabase.Refresh();
        }

        /// <summary>
        /// 判断是否有效后缀
        /// </summary>
        /// <param name="sfx"></param>
        /// <returns></returns>
        public static bool Invalid(string sfx)
        {
            if (string.IsNullOrEmpty(sfx)) return true;
            if (sfx == Suffix.CS) return true;
            if (sfx == Suffix.Js) return true;
            return false;
        }


        /// <summary>
        /// 通过配置拷贝资源文件
        /// </summary>
        public static void CopyByCfg()
        {
            var pm = AssetPackUtil.Read();
            if (pm == null || pm.packs.Count < 1)
            {
                iTrace.Error("Loong", "无首包配置"); return;
            }
            var firstPack = pm.packs[0];
            var title = "获取首包配置依赖";
            ProgressBarUtil.Show(title, "", 1f);
            var paths = firstPack.GetDepends();
            float length = paths.Length;
            var plat = EditUtil.GetPlatform();
            title = "拷贝首包配置资源";
            var srcDir = ABTool.Data.Output;
            srcDir = Path.GetFullPath(srcDir);
            srcDir = Path.Combine(srcDir, plat);
            var destDir = GetAssetDir();
            destDir = Path.Combine(destDir, plat);
            for (int i = 0; i < length; i++)
            {
                var path = paths[i];
                ProgressBarUtil.Show(title, path, i / length);
                var sfx = Path.GetExtension(path);
                if (sfx == Suffix.CS) continue;
                if (sfx == Suffix.Js) continue;
                var ai = AssetImporter.GetAtPath(path);
                if (ai == null) continue;
                var abName = ai.assetBundleName;
                var variant = ai.assetBundleVariant;
                if (!string.IsNullOrEmpty(variant))
                {
                    abName = string.Format("{0}{1}", abName, Suffix.AB);
                }
                var fullPath = Path.Combine(srcDir, abName);
                if (!File.Exists(fullPath)) continue;
                var newPath = Path.Combine(destDir, abName);
                File.Copy(fullPath, newPath, true);
            }
            ProgressBarUtil.Clear();
        }

        /// <summary>
        /// 生成首包清单文件
        /// </summary>
        public static void GenManifest()
        {
            var packDir = GetAssetDir();
            if (!Directory.Exists(packDir)) return;
            var files = Directory.GetFiles(packDir, "*.*", SearchOption.AllDirectories);
            if (files == null || files.Length < 1) return;

            var srcDir = ABTool.Data.Output;
            var mfPath = Path.Combine(srcDir, AssetMf.Name);
            if (!File.Exists(mfPath)) return;

            var dic = AssetMf.Read(mfPath);
            var packDirLen = packDir.Length + 1;
            var infos = new List<Md5Info>();
            var length = files.Length;
            for (int i = 0; i < length; i++)
            {
                var path = files[i];
                var rPath = path.Substring(packDirLen);
                rPath = rPath.Replace('\\', '/');
                Md5Info info = null;
                if (dic.ContainsKey(rPath))
                {
                    info = dic[rPath];
                }
                else
                {
                    continue;
                    //info = new Md5Info();
                    //info.path = rPath;
                }
                infos.Add(info);
            }
            infos.Sort();
            var baseMfPath = GetBaseMfPath();
            AssetMf.Write(infos, baseMfPath);
        }

        /// <summary>
        /// 获取首包资源存放目录
        /// </summary>
        /// <returns></returns>
        public static string GetAssetDir()
        {
            var dir = AssetPackUtil.Data.dir;
            var assetDir = Path.Combine(dir, "Assets");
            assetDir = Path.GetFullPath(assetDir);
            assetDir = assetDir.Replace('\\', '/');
            return assetDir;
        }

        /// <summary>
        /// 获取首包资源清单路径
        /// </summary>
        /// <returns></returns>
        public static string GetBaseMfPath()
        {
            var dir = GetAssetDir();
            var path = Path.Combine(dir, AssetMf.BaseName);
            return path;
        }

        /// <summary>
        /// 压缩
        /// </summary>
        public static void Comp()
        {
            AssetPkgUtil.CompAll();
        }


        /// <summary>
        /// 拷贝&压缩
        /// </summary>
        public static void CompCopy()
        {
            Comp();
            CopyComped();
        }

        /// <summary>
        /// 拷贝当前本地更新版本的首包资源
        /// </summary>
        public static void CopyCompedLocalAssetVer()
        {
            CopyComped();
        }


        /// <summary>
        /// 拷贝有对话框
        /// </summary>
        [MenuItem(menu + "拷贝", false, Pri)]
        [MenuItem(AMenu + "拷贝", false, Pri)]
        public static void CopyHasDialog()
        {
            DialogUtil.Show(null, "拷贝首包资源？", CopyCompedLocalAssetVer);
        }


        /// <summary>
        /// 压缩有对话框
        /// </summary>
        [MenuItem(menu + "压缩", false, Pri + 2)]
        [MenuItem(AMenu + "压缩", false, Pri + 2)]
        public static void CompHasDialog()
        {
            DialogUtil.Show(null, "压缩首包资源,其实就是0版本资源？", Comp);
        }

        /// <summary>
        /// 拷贝&压缩对话框
        /// </summary>
        [MenuItem(menu + "压缩&拷贝", false, Pri + 3)]
        [MenuItem(AMenu + "压缩&拷贝", false, Pri + 3)]
        public static void CompCopyHasDialog()
        {
            DialogUtil.Show(null, "拷贝&压缩首包资源？", CompCopy);
        }

        /// <summary>
        /// 删除资源
        /// </summary>
        [MenuItem(menu + "删除", false, Pri + 4)]
        [MenuItem(AMenu + "删除", false, Pri + 4)]
        public static void Delete()
        {
            var dir = GetAssetDir();
            if (Directory.Exists(dir))
            {
                Directory.Delete(dir, true);
                AssetPkgUtil.Delete();
                UIEditTip.Log("删除成功");
            }
            else
            {
                UIEditTip.Warning("无需删除");
            }
        }

        /// <summary>
        /// 拷贝&压缩对话框
        /// </summary>
        [MenuItem(menu + "拷贝首包资源", false, Pri + 3)]
        [MenuItem(AMenu + "拷贝首包资源", false, Pri + 3)]
        public static void CopyAssetHasDialog()
        {
            DialogUtil.Show(null, "拷贝首包资源？", Copy);
        }
        #endregion
    }
}