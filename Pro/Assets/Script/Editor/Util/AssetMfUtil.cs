/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/9/21 3:29:13
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using System.Text;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    using Md5Dic = Dictionary<string, Md5Info>;
    /// <summary>
    /// 资源清单工具
    /// </summary>
    public static class AssetMfUtil
    {
        #region 字段
        /// <summary>
        /// 菜单优先级
        /// </summary>
        public const int Pri = MenuTool.AssetPri + 23;


        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "资源清单工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "资源清单工具/";


        public const string chkUpgName = "checkUpgInfo.xml";

        /// <summary>
        /// 解压目录
        /// </summary>
        public const string chkDecompDir = "../AssetsMfChk";

        /// <summary>
        /// true:清单被压缩
        /// </summary>
        public const bool isCompress = true;
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
        /// 重新生成
        /// </summary>
        /// <param name="dir">资源目录</param>
        /// <param name="isComp"></param>
        /// <returns>不正确的信息列表</returns>
        public static List<string> Reset(string dir, bool isComp = true)
        {
            if (!Directory.Exists(dir)) return null;
            var mfPath = Path.Combine(dir, AssetMf.Name);
            if (!File.Exists(mfPath)) return null;
            string decompDir = null;
            DecompBase decomp = null;
            if (isComp)
            {
                decomp = DecompFty.Create();
                var dirName = Path.GetFileName(dir);
                decompDir = GetDecompDir(dirName);
            }
            var md5Set = new Md5Set();
            md5Set.Read(mfPath);
            var infos = md5Set.infos;
            if (infos == null || infos.Count < 1) return null;
            List<string> lst = null;
            float length = infos.Count;
            var title = "重新生成清单";
            bool suc = true;
            for (int i = 0; i < length; i++)
            {
                suc = true;
                var info = infos[i];
                var k = info.path;
                var path = string.Format("{0}/{1}", dir, k);
                ProgressBarUtil.Show(title, k, i / length);
                if (File.Exists(path))
                {

                    string md5 = null;
                    if (isComp)
                    {
                        var dest = decompDir + k;
                        var rDir = Path.GetDirectoryName(dest);
                        decomp.SrcStream = File.OpenRead(path);
                        decomp.Dest = rDir;
                        suc = decomp.Execute();
                        if (suc)
                        {
                            md5 = Md5Crypto.GenFile(dest);
                        }

                    }
                    else
                    {
                        md5 = Md5Crypto.GenFile(path);
                    }
                    if (suc)
                    {
                        var fi = new FileInfo(path);
                        info.Sz = (int)fi.Length;
                        info.MD5 = md5;
                    }
                }
                else
                {
                    suc = false;
                }
                if (suc) continue;
                if (lst == null) lst = new List<string>();
                var name = Path.GetFileName(k);
                lst.Add(name);
            }
            md5Set.Save(mfPath);
            GC.Collect();
            ProgressBarUtil.Clear();
            EditorUtility.UnloadUnusedAssetsImmediate();
            return lst;
        }

        /// <summary>
        /// 获取解压目录
        /// </summary>
        /// <param name="folder"></param>
        /// <returns></returns>
        public static string GetDecompDir(string folder)
        {
            return string.Format("{0}/{1}/", chkDecompDir, folder);
        }

        /// <summary>
        /// 检查清单是否正确
        /// </summary>
        /// <param name="dir">资源目录</param>
        /// <param name="isComp">true:再次压缩</param>
        /// <param name="chkSize">true:检查大小</param>
        /// <returns>不正确的信息列表</returns>
        public static List<string> Check(string dir, bool isComp = false, bool chkSize = false)
        {
            if (!Directory.Exists(dir)) return null;
            var mfPath = Path.Combine(dir, AssetMf.Name);
            if (!File.Exists(mfPath)) return null;
            string decompDir = null;
            DecompBase decomp = null;
            if (isComp)
            {
                decomp = DecompFty.Create();
                var dirName = Path.GetFileName(dir);
                decompDir = GetDecompDir(dirName);
            }
            var dic = AssetMf.Read(mfPath);
            var files = Directory.GetFiles(dir, "*.*", SearchOption.AllDirectories);
            if (files == null || files.Length < 1) return null;
            List<string> lst = null;
            var title = "校验清单";
            float length = files.Length;
            int dirLen = dir.Length + 1;
            bool invalid = false;
            for (int i = 0; i < length; i++)
            {
                invalid = false;
                var path = files[i];
                var key = path.Substring(dirLen);
                key = key.Replace('\\', '/');
                ProgressBarUtil.Show(title, "", i / length);
                if (!dic.ContainsKey(key)) continue;
                var info = dic[key];
                string md5Path = null;
                if (isComp)
                {
                    md5Path = decompDir + key;
                    var rDir = Path.GetDirectoryName(md5Path);
                    if (!Directory.Exists(rDir)) Directory.CreateDirectory(rDir);
                    decomp.SrcStream = File.OpenRead(path);
                    decomp.Dest = rDir;
                    if (!decomp.Execute())
                    {
                        Debug.LogErrorFormat("Loong,chk mf ,decomp {0} fail", path);
                        return null;
                    }
                }
                else
                {
                    md5Path = path;
                }
                if (chkSize)
                {
                    var fi = new FileInfo(path);
                    long sz = info.Sz;
                    if (sz != fi.Length)
                    {
                        invalid = true;
                    }
                }
                if (!invalid)
                {
                    var nMd5 = Md5Crypto.GenFile(md5Path);
                    if (nMd5 != info.MD5) invalid = true;
                }
                if (invalid)
                {
                    if (lst == null) lst = new List<string>();
                    lst.Add(key);
                }
            }
            GC.Collect();
            ProgressBarUtil.Clear();
            EditorUtility.UnloadUnusedAssetsImmediate();
            return lst;
        }

        /// <summary>
        /// 检查升级信息
        /// </summary>
        /// <param name="oldPath">旧清单文件</param>
        /// <param name="newPath">新清单文件</param>
        /// <param name="path">升级信息保存路径</param>
        /// <param name="path">true:清单是压缩文件</param>
        /// <returns></returns>
        public static UpgInfo CheckUpg(string oldPath, string newPath, string path, bool isComp, ref Md5Dic oldDic)
        {
            if (!File.Exists(oldPath)) return null;
            if (!File.Exists(newPath)) return null;
            //Md5Dic oldDic = null;
            Md5Dic newDic = null;
            if (isComp)
            {
                var temp = AssetPathUtil.Temp;
                var oldTempPath = temp + "OldUpg" + AssetMf.Name;
                var newTempPath = temp + "NewUpg" + AssetMf.Name;
                oldDic = AssetMf.ReadComped(oldPath, oldTempPath);
                newDic = AssetMf.ReadComped(newPath, newTempPath);
            }
            else
            {
                oldDic = AssetMf.Read(oldPath);
                newDic = AssetMf.Read(newPath);
            }

            if (oldDic == null || newDic == null)
            {
                ShowCompErr(); return null;
            }
            var upgInfo = AssetMf.GetInfo(oldDic, newDic);
            XmlTool.Serializer<UpgInfo>(path, upgInfo);
            return upgInfo;

        }

        public static UpgInfo CheckUpg(string oldPath, string newPath, string path, bool isComp)
        {
            Md5Dic oldDic = null;
            return CheckUpg(oldPath, newPath, path, isComp, ref oldDic);
        }

        /// <summary>
        /// 获取升级大小
        /// </summary>
        /// <param name="upgInfo"></param>
        /// <returns></returns>
        public static float Size(UpgInfo upgInfo)
        {
            var infos = upgInfo.GetFixes();
            if (infos == null) return 0;
            int length = infos.Count;
            long total = 0;
            for (int i = 0; i < length; i++)
            {
                var info = infos[i];
                total += info.Sz;
            }
            var tt = ByteUtil.FmtByCalc(total, 100);
            return tt;
        }

        public static void ShowCompErr()
        {
            UIEditTip.Error("清单是否压缩?若压缩请设置压缩属性!未压缩不要设置压缩属性!");
        }

        /// <summary>
        /// 比较两个清单内同一文件 的大小差值
        /// </summary>
        /// <param name="lhsPath">左操纵清单路径</param>
        /// <param name="rhsPath">右操作清单路径</param>
        /// <returns></returns>
        public static List<AssetMfSizeInfo> CmpSizeInfo(string lhsPath, string rhsPath, int threshold, bool isComp)
        {
            EditorUtility.UnloadUnusedAssetsImmediate();
            GC.Collect();
            if (!File.Exists(lhsPath)) return null;
            if (!File.Exists(rhsPath)) return null;
            Md5Dic lhsDic = null;
            Md5Dic rhsDic = null;

            if (isComp)
            {
                var temp = AssetPathUtil.Temp;
                var lhsTemp = temp + "lhs_" + AssetMf.Name;
                var rhsTemp = temp + "rhs_" + AssetMf.Name;
                lhsDic = AssetMf.ReadCompedByName(lhsPath, lhsTemp);
                rhsDic = AssetMf.ReadCompedByName(rhsPath, rhsTemp);
            }
            else
            {
                lhsDic = Read(lhsPath);
                rhsDic = Read(rhsPath);
            }
            if (lhsDic == null || rhsDic == null)
            {
                ShowCompErr(); return null;
            }
            List<AssetMfSizeInfo> lst = null;
            var em = rhsDic.GetEnumerator();
            while (em.MoveNext())
            {
                var it = em.Current;
                var k = it.Key;
                var name = Path.GetFileName(k);
                if (lhsDic.ContainsKey(k))
                {
                    var lhsInfo = lhsDic[k];
                    var rhsInfo = it.Value;
                    var difSize = lhsInfo.Sz - rhsInfo.Sz;
                    if (difSize < 0) difSize = -difSize;
                    if (difSize < threshold) continue;
                    var info = new AssetMfSizeInfo();
                    if (lst == null) lst = new List<AssetMfSizeInfo>();
                    info.Set(name, lhsInfo.Sz, rhsInfo.Sz);
                    lst.Add(info);
                }
            }
            if (lst != null) lst.Sort();
            return lst;
        }

        /// <summary>
        /// 读取清单字典,键值为文件名
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        public static Md5Dic Read(string path)
        {
            if (!File.Exists(path)) return null;
            var set = new Md5Set();
            set.Read(path);
            var dic = new Md5Dic();
            int length = set.infos.Count;
            for (int i = 0; i < length; i++)
            {
                Md5Info info = set.infos[i];
                if (dic.ContainsKey(info.path)) continue;
                var name = Path.GetFileName(info.path);
                dic.Add(name, info);
            }
            return dic;
        }

        /// <summary>
        /// 读取压缩文件清单字典
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        public static Md5Dic ReadComped(string path)
        {
            var set = ReadCompdSet(path);
            return AssetMf.Read(set);
        }


        public static Md5Set ReadCompdSet(string path)
        {
            var name = Path.GetFileName(path);
            var destPath = AssetPathUtil.GetTempPath(name);
            var decomp = DecompFty.Create();
            decomp.Src = path;
            decomp.Dest = destPath;
            if (decomp.Execute())
            {
                path = destPath;
            }
            else
            {
                return null;
            }

            return AssetMf.ReadSet(path);
        }

        /// <summary>
        /// 转换成XML
        /// </summary>
        /// <param name="src">源路径</param>
        /// <param name="dest">目标路径</param>
        public static void ToXML(string src, string dest, bool isComp)
        {
            if (src == dest) return;
            Md5Set set = null;
            if (isComp)
            {
                var temp = AssetPathUtil.Temp + Path.GetFileName(src);
                set = AssetMf.ReadSetComped(src, temp);
            }
            else
            {
                set = AssetMf.ReadSet(src);
            }
            if (set == null) return;
            var dir = Path.GetDirectoryName(dest);
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
            XmlTool.Serializer<Md5Set>(dest, set);
        }

        #endregion
    }
}