/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/30 15:12:46
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
    using StrDic = Dictionary<string, string>;
    using AssetDic = Dictionary<string, eAssetInfo>;

    /// <summary>
    /// 资源分包工具
    /// </summary>
    public static class AssetPackUtil
    {
        #region 字段
        private static AssetPackView data = null;

        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = AssetUtil.Pri + 100;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = AssetUtil.menu + "分包工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = AssetUtil.AMenu + "分包工具/";

        /// <summary>
        /// 分包清单文件
        /// </summary>
        public const string packName = "PackManifest.xml";

        /// <summary>
        /// 根据分包导出的详细清单文件
        /// </summary>
        public const string detailName = "DetailManifest.xml";

        #endregion

        #region 属性
        /// <summary>
        /// 数据
        /// </summary>
        public static AssetPackView Data
        {
            get
            {
                if (data == null)
                {
                    data = AssetDataUtil.Get<AssetPackView>();
                }
                return data;
            }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        /// <summary>
        /// 检查材质球
        /// </summary>
        /// <param name="dic"></param>
        /// <param name="nameDic"></param>
        /// <param name="info"></param>
        /// <param name="path"></param>
        private static void ChkMat(AssetDic dic, StrDic nameDic, eAssetInfo info, string path, List<eAssetInfo> infos)
        {
            var matName = Path.GetFileNameWithoutExtension(path).ToLower();
            string togName = null;
            var lht = "_height";
            var lw = "_low";
            if (matName.EndsWith(lht))
            {
                togName = matName.Replace(lht, lw);
            }
            else if (matName.EndsWith(lw))
            {
                togName = matName.Replace(lw, lht);
            }
            if (togName == null) return;

            var dir = Path.GetDirectoryName(path);
            var togPath = string.Format("{0}/{1}{2}", dir, togName, Suffix.Mat);
            if (Add(dic, nameDic, info, togPath))
            {
                var lName = togName;
                if (dic.ContainsKey(lName))
                {
                    var added = dic[lName];
                    if (infos != null) infos.Add(added);
                }
            }
        }

        /// <summary>
        /// 添加到资源字典
        /// </summary>
        /// <param name="dic">资源字典</param>
        /// <param name="nameDic">名称字典</param>
        /// <param name="info">资源关联信息</param>
        /// <param name="dPath">相对路径</param>
        /// <returns>true:添加成功</returns>
        private static bool Add(AssetDic dic, StrDic nameDic, eAssetInfo info, string dPath)
        {
            var di = AssetImporter.GetAtPath(dPath);

            if (di == null)
            {
                var err = string.Format("{0} 不存在", dPath);
                iTrace.Error("Loong", err);
                return false;
            }
            dPath = di.assetPath;
            if (string.IsNullOrEmpty(di.assetBundleName))
            {
                var err = string.Format("{0} 未设置资源包名称", dPath);
                iTrace.Error("Loong", err);
                //suc = false; break;
                return false;
            }
            var name = Path.GetFileName(dPath);
            var lName = name.ToLower();
            if (nameDic.ContainsKey(lName))
            {
                var lPath = nameDic[lName];
                if (!lPath.Equals(dPath))
                {
                    var err = string.Format("{0} 和 {1} 重名", lPath, dPath);
                    iTrace.Error("Loong", err);
                    //suc = false; break;
                    return false;
                }
            }
            else
            {
                nameDic.Add(lName, dPath);
            }
            if (dic.ContainsKey(lName)) return false;
            var newInfo = new eAssetInfo();
            newInfo.CopyFrom(info);
            newInfo.path = dPath;
            dic.Add(lName, newInfo);
            return true;
        }

        private static bool SetAsset(AssetDic dic, StrDic nameDic, eAssetInfo info, List<eAssetInfo> infos)
        {
            var path = info.path;
            if (dic.ContainsKey(path)) return true;

            var ai = AssetImporter.GetAtPath(path);
            if (ai == null)
            {
                iTrace.Error("Loong", path + " 不存在"); return true;
            }
            if (string.IsNullOrEmpty(ai.assetBundleName))
            {
                iTrace.Error("Loong", path + " 未设置包名"); return true;
            }
            bool suc = true;
            var depends = AssetDatabase.GetDependencies(path);
            float length = depends.Length;
            for (int i = 0; i < length; i++)
            {
                var dPath = depends[i];
                ProgressBarUtil.Show(path, dPath, i / length);
                var sfx = Path.GetExtension(dPath);
                if (!IsValidSfx(sfx)) continue;
                Add(dic, nameDic, info, dPath);

                if (sfx == Suffix.Mat)
                {
                    ChkMat(dic, nameDic, info, dPath, infos);
                }
            }
            return suc;
        }


        private static bool SetInfos(AssetDic dic, StrDic nameDic, List<eAssetInfo> infos)
        {
            infos.Sort();
            bool suc = true;
            int length = infos.Count;
            for (int i = 0; i < length; i++)
            {
                var info = infos[i];
                Add(dic, nameDic, info, info.path);
            }
            for (int i = 0; i < length; i++)
            {
                var info = infos[i];
                suc = SetAsset(dic, nameDic, info, infos);
                if (!suc) break;
            }
            return suc;
        }

        private static bool SetMods(AssetDic dic, StrDic nameDic, List<AssetMod> mods)
        {
            bool suc = true;
            int modLen = mods.Count;
            for (int j = 0; j < modLen; j++)
            {
                var mod = mods[j];
                var infos = mod.page.lst;
                suc = SetInfos(dic, nameDic, infos);
                if (!suc) break;
            }
            return true;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 检查后缀有效性
        /// </summary>
        /// <param name="sfx"></param>
        /// <returns></returns>
        public static bool IsValidSfx(string sfx)
        {
            if (sfx == Suffix.CS) return false;
            if (sfx == Suffix.Js) return false;
            if (sfx == Suffix.Meta) return false;
            return true;
        }

        /// <summary>
        /// 获取分包清单路径
        /// </summary>
        /// <param name="dir"></param>
        public static string GetPackPath(string dir)
        {
            var path = Path.Combine(dir, packName);
            return path;
        }

        /// <summary>
        /// 获取分包详细资源清单路径
        /// </summary>
        /// <param name="dir"></param>
        public static string GetDetailPath(string dir)
        {
            var path = Path.Combine(dir, detailName);
            return path;
        }

        /// <summary>
        /// 从配置目录读取分包信息
        /// </summary>
        /// <returns></returns>
        public static PackManifest Read()
        {
            var dir = Data.dir;
            return Read(dir);
        }

        /// <summary>
        /// 从指定目录读取分包信息
        /// </summary>
        /// <param name="dir"></param>
        /// <returns></returns>
        public static PackManifest Read(string dir)
        {
            var path = GetPackPath(dir);
            if (!File.Exists(path)) return null;
            var pm = Loong.Game.XmlTool.Deserializer<PackManifest>(path);
            return pm;
        }

        /// <summary>
        /// 从配置目录读取分包详细信息
        /// </summary>
        /// <param name="dir"></param>
        /// <returns></returns>
        public static PackDetailMenifest ReadDetail()
        {
            var dir = Data.dir;
            return ReadDetail(dir);
        }

        /// <summary>
        /// 从指定目录读取分包详细信息
        /// </summary>
        /// <param name="dir"></param>
        /// <returns></returns>
        public static PackDetailMenifest ReadDetail(string dir)
        {
            var path = GetDetailPath(dir);
            if (!File.Exists(path)) return null;
            var pm = Loong.Game.XmlTool.Deserializer<PackDetailMenifest>(path);
            return pm;
        }

        /// <summary>
        /// 保存分包资源信息
        /// </summary>
        /// <param name="dir">目录</param>
        /// <param name="packs">包数组</param>
        /// <returns></returns>
        public static bool Save(string dir, List<AssetPack> packs)
        {
            if (packs == null || packs.Count < 1) return false;
            PackManifest pm = new PackManifest();
            int length = packs.Count;
            for (int i = 0; i < length; i++)
            {
                var pack = packs[i];
                pm.packs.Add(pack);
            }
            pm.Sort();
            DirUtil.Check(dir);
            var path = GetPackPath(dir);
            XmlTool.Serializer<PackManifest>(path, pm);
            return true;
        }


        /// <summary>
        /// 保存详细信息
        /// </summary>
        /// <param name="dir"></param>
        /// <param name="packs"></param>
        public static bool SaveDetail(string dir, List<AssetPack> packs)
        {
            if (packs == null || packs.Count < 1) return false;
            ProgressBarUtil.Show("保存详细信息", "准备中", 1f);
            var dic = new AssetDic();
            var nameDic = new StrDic();
            int packLen = packs.Count;
            var suc = true;
            for (int i = 0; i < packLen; i++)
            {
                var pack = packs[i];
                var mods = pack.mods;
                suc = SetMods(dic, nameDic, mods);
                if (!suc) break;
            }
            var detail = new PackDetailMenifest();
            var infos = detail.infos;
            SetCS(dic);
            var em = dic.GetEnumerator();
            while (em.MoveNext())
            {
                infos.Add(em.Current.Value);
            }
            infos.Sort();
            var path = GetDetailPath(dir);
            XmlTool.Serializer<PackDetailMenifest>(path, detail);
            ProgressBarUtil.Clear();
            EditorUtility.UnloadUnusedAssetsImmediate();
            return suc;
        }

        public static void SetCS(AssetDic dic)
        {
            if (dic == null) return;
            eAssetInfo info = null;
            var name = CSHotfixUtil.fileName;
            if (dic.ContainsKey(name))
            {
                info = dic[name];
            }
            else
            {
                info = new eAssetInfo();
                info.path = name;
                dic.Add(name, info);
            }
            info.Lv = 0;
        }

        /// <summary>
        /// 保存所有配置
        /// </summary>
        /// <param name="dir"></param>
        /// <param name="packs"></param>
        /// <returns></returns>
        public static bool SaveAll(string dir, List<AssetPack> packs)
        {
            if (!Save(dir, packs)) return false;
            if (!SaveDetail(dir, packs)) return false;
            return true;
        }

        /// <summary>
        /// 最大等级
        /// </summary>
        /// <returns></returns>
        public static int MaxLv()
        {
            return 900;
        }

        /// <summary>
        /// 最大排序
        /// </summary>
        /// <returns></returns>
        public static int MaxSort()
        {
            return 900;
        }
        #endregion
    }
}