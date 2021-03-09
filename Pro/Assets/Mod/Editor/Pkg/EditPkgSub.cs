//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/4/8 16:51:09
//*****************************************************************************

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Threading;
using System.Collections.Generic;

namespace Loong.Edit
{
    using ResDic = Dictionary<string, Md5Info>;

    /// <summary>
    /// EditPkgSub
    /// </summary>
    public abstract class EditPkgSub : EditPkg
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

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 判断是否有效后缀
        /// </summary>
        /// <param name="sfx"></param>
        /// <returns></returns>
        public bool Invalid(string sfx)
        {
            if (string.IsNullOrEmpty(sfx)) return true;
            if (sfx == Suffix.CS) return true;
            if (sfx == Suffix.Js) return true;
            return false;
        }

        /// <summary>
        /// 获取首包资源清单字典
        /// </summary>
        /// <param name="targetVer">资源版本</param>
        /// <param name="containUpgs">包含所有热更资源</param>
        public ResDic GetSubDic(int targetVer = 0, bool containUpgs = true)
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

            var streaming = AssetPathUtil.Streaming;
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

            AssetDatabase.Refresh();
            return baseDic;
        }


        /// <summary>
        /// 获取首包资源清单信息
        /// </summary>
        /// <param name="targetVer"></param>
        /// <returns></returns>
        public Md5Set GetSubInfo(int targetVer = 0, bool containUpgs = true)
        {
            var baseMfPath = AssetPathUtil.Streaming + AssetMf.BaseName;
            var info = AssetMfUtil.ReadCompdSet(baseMfPath);
            return info;
        }

        /// <summary>
        /// 获取整包资源清单信息
        /// </summary>
        /// <returns></returns>
        public Md5Set GetAllInfo(int targetVer = 0)
        {
            var upgData = AssetUpgUtil.Data;
            var srcMfPath = upgData.GetCompMd5Path(targetVer);
            if (!File.Exists(srcMfPath))
            {
                iTrace.Error("Loong", "{0},清单文件{1}不存在", Des, srcMfPath); return null;
            }

            var info = AssetMfUtil.ReadCompdSet(srcMfPath);
            return info;
        }


        public void CopyAllMf(int targetVer = 0)
        {
            var upgData = AssetUpgUtil.Data;
            var srcMfPath = upgData.GetCompMd5Path(targetVer);
            var destMfPath = AssetPathUtil.Streaming + AssetMf.Name;
            if (File.Exists(srcMfPath))
            {
                File.Copy(srcMfPath, destMfPath, true);
            }
            else
            {
                iTrace.Error("Loong", "{0} not exist");
            }
        }

        #endregion
    }
}