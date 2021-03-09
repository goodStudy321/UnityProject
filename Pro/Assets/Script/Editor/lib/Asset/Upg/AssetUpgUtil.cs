/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014/11/14 11:35:15
 * 1,启用压缩时,生成的清单文件中的大小(Sz)是压缩文件的大小
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
    using FileTool = Loong.Game.FileTool;
    using StrDic = Dictionary<string, string>;
    using Md5Dic = Dictionary<string, Md5Info>;
    using PackDic = Dictionary<string, eAssetInfo>;
    using NameDic = Dictionary<string, List<string>>;
    /// <summary>
    /// 资源升级工具
    /// </summary>
    public static class AssetUpgUtil
    {
        #region 字段

        private static AssetUpgView data = null;

        private static ElapsedTime et = new ElapsedTime();

        /// <summary>
        /// 菜单优先级
        /// </summary>
        public const int Pri = MenuTool.AssetPri + 13;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "资源更新工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "资源更新工具/";

        /// <summary>
        /// 收集后事件
        /// </summary>
        public static event Action<UpgInfo> upgrade = null;

        /// <summary>
        /// 资源版本号文件名称
        /// </summary>
        public const string VerFileName = "AssetVer.txt";

        /// <summary>
        /// 清单文件名称
        /// </summary>
        public const string ManifestFileName = "Manifest.xml";

        /// <summary>
        /// 升级信息文件名称
        /// </summary>
        public const string UpgInfoFileName = "UpgradeInfo.xml";
        /// <summary>
        /// 过滤后缀
        /// </summary>
        public static readonly HashSet<string> filters = new HashSet<string>() { Suffix.Manifest };

        #endregion

        #region 属性
        /// <summary>
        /// 更新数据
        /// </summary>
        public static AssetUpgView Data
        {
            get
            {
                if (data == null)
                {
                    data = AssetDataUtil.Get<AssetUpgView>();
                }
                return data;
            }
        }

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        /// <summary>
        /// 创建压缩实例
        /// </summary>
        /// <returns></returns>
        private static CompBase CreateComp()
        {
            return CompFty.Create(Data.CompressType);
        }

        /// <summary>
        /// 获取分包资源的详细字典,k:资源名(小写),v:eAssetInfo
        /// </summary>
        /// <returns></returns>
        private static PackDic GetPackDic()
        {
            var detail = AssetPackUtil.ReadDetail();
            if (detail == null) return null;
            var dic = detail.GetDic();
            return dic;
        }


        public static bool IsNecByName(string name)
        {
            //if (name == CSHotfixUtil.fileName) return true;
            if (name == "lua.bytes") return true;
            if (name == "Android") return true;
            if (name == "iOS") return true;

            var sfx = Path.GetExtension(name);
            if (sfx == ".tbl") return true;
            if (sfx == ".bin") return true;
            if (sfx == ".act") return true;
            return false;
        }

        /// <summary>
        /// 通过配置资源信息设置运行时资源信息
        /// </summary>
        /// <param name="info"></param>
        /// <param name="ei"></param>
        private static void SetInfo(PackDic dic, NameDic nDic, Md5Info info, string fn)
        {
            if (dic == null) return;
            if (IsNecByName(fn)) return;
            eAssetInfo ei = null;
            List<string> lst = null;
            if (nDic.ContainsKey(fn))
            {
                lst = nDic[fn];
            }
            if (lst != null)
            {
                int len = lst.Count;
                for (int i = 0; i < len; i++)
                {
                    var nm = lst[i];
                    if (dic.ContainsKey(nm))
                    {
                        ei = dic[nm];
                        break;
                    }
                }
            }
            if (ei == null)
            {
                info.Lv = (ushort)AssetPackUtil.MaxLv();
                info.St = (short)AssetPackUtil.MaxSort();
            }
            else
            {
                info.Lv = (ushort)ei.Lv;
                info.St = (short)ei.Sort;
            }
        }

        /// <summary>
        /// 获取指定目录的所有文件的MD5值
        /// </summary>
        /// <param name="dir">目录</param>
        /// <param name="ver">当前版本号</param>
        /// <param name="lastDic">上一个版本的MD5信息</param>
        /// <param name="filters">过滤模式</param>
        /// <param name="filters">过滤文件集合</param>
        /// <returns></returns>
        private static Md5Dic GetMd5Dic(string dir, int ver, Md5Dic lastDic, AssetUpgMode mode = AssetUpgMode.None, HashSet<string> filters = null)
        {
            if (!Directory.Exists(dir)) return null;
            if (mode == AssetUpgMode.Assign)
            {
                return GetByAssign(dir, ver, lastDic, filters);
            }
            return GetByFilter(dir, ver, lastDic, filters);
        }

        /// <summary>
        /// 指定文件
        /// </summary>
        /// <returns></returns>
        private static Md5Dic GetByAssign(string dir, int ver, Md5Dic lastDic, HashSet<string> filters)
        {
            if (lastDic == null || filters == null || filters.Count < 1)
            {
                return GetByFilter(dir, ver, lastDic, null);
            }
            var packDic = GetPackDic();
            var abNameDic = ABNameUtil.GetDic();
            var dic = new Md5Dic();
            var lem = lastDic.GetEnumerator();
            while (lem.MoveNext())
            {
                var it = lem.Current;
                dic.Add(it.Key, it.Value);
            }
            var fem = filters.GetEnumerator();
            while (fem.MoveNext())
            {
                var key = fem.Current;
                if (string.IsNullOrEmpty(key)) continue;
                var fullPath = Path.Combine(dir, key);
                if (File.Exists(fullPath))
                {
                    var info = GetNewInfo(key, fullPath, ver, lastDic);
                    if (dic.ContainsKey(key))
                    {
                        dic[key] = info;
                    }
                    else
                    {
                        dic.Add(key, info);
                    }
                    if (packDic == null) continue;
                    SetInfo(packDic, abNameDic, info, fullPath);
                }
                else
                {
                    Debug.LogErrorFormat("Loong, {0} not exist", fullPath);
                }
            }
            return dic;
        }

        /// <summary>
        /// 过滤文件
        /// </summary>
        /// <returns></returns>
        private static Md5Dic GetByFilter(string dir, int ver, Md5Dic lastDic, HashSet<string> filters)
        {
            var files = Directory.GetFiles(dir, "*", SearchOption.AllDirectories);
            if (files == null || files.Length == 0) return null;
            var dic = new Md5Dic();
            var dirLen = dir.Length;
            var packDic = GetPackDic();
            var abNameDic = ABNameUtil.GetDic();
            float length = files.Length;
            for (int i = 0; i < length; i++)
            {
                var filePath = files[i];
                ProgressBarUtil.Show("获取MD5", filePath, i / length);
                var fileName = Path.GetFileName(filePath);
                if (fileName == ".DS_Store") continue;
                if (fileName == ManifestFileName) continue;
                var sfx = Path.GetExtension(fileName);
                if (sfx == Suffix.Meta) continue;
                if (sfx == Suffix.Manifest) continue;

                var oldkey = filePath.Substring(dirLen);
                var newkey = oldkey.Replace(@"\", "/");
                if (dic.ContainsKey(newkey)) continue;
                Md5Info info = null;
                if (filters == null)
                {
                    info = GetNewInfo(newkey, filePath, ver, lastDic);
                }
                else if (filters.Contains(newkey))
                {
                    if (lastDic != null && lastDic.ContainsKey(newkey))
                    {
                        info = lastDic[newkey];
                    }
                    else
                    {
                        continue;
                    }
                }
                else
                {
                    info = GetNewInfo(newkey, filePath, ver, lastDic);
                }
                dic.Add(newkey, info);
                if (packDic == null) continue;
                SetInfo(packDic, abNameDic, info, fileName);
            }
            ProgressBarUtil.Clear();
            return dic;
        }

        /// <summary>
        /// 获取新信息
        /// </summary>
        /// <param name="key">键值</param>
        /// <param name="filePath">完整路径</param>
        /// <param name="ver">版本号</param>
        /// <param name="lastDic">上一个版本的字典</param>
        /// <returns></returns>
        private static Md5Info GetNewInfo(string key, string filePath, int ver, Md5Dic lastDic)
        {
            var md5 = Md5Crypto.GenFile(filePath);
            Md5Info info = null;
            bool isNew = false;
            if (lastDic == null)
            {
                isNew = true;
            }
            else
            {
                if (lastDic.ContainsKey(key))
                {
                    var lastInfo = lastDic[key];
                    if (lastInfo.MD5.Equals(md5))
                    {
                        info = lastInfo;
                    }
                    else
                    {
                        isNew = true;
                    }
                }
                else
                {
                    isNew = true;
                }
            }
            if (isNew)
            {
                info = new Md5Info(key, md5);
                var fi = new FileInfo(filePath);
                info.Sz = (int)fi.Length;
                info.Ver = ver;
            }
            return info;
        }


        /// <summary>
        /// 将文件MD5信息列表写入文件
        /// </summary>
        /// <param name="dic">MD5字典</param>
        /// <param name="destPath">文件路径</param>
        private static void WriteMd5Set(Md5Dic dic, string destPath)
        {
            if (dic == null || dic.Count == 0) return;
            FileTool.CheckDir(destPath);
            var infos = new List<Md5Info>();
            var em = dic.GetEnumerator();
            while (em.MoveNext())
            {
                var it = em.Current;
                infos.Add(it.Value);
            }
            //infos.Sort(CompareByVer);
            infos.Sort();
            var upgSet = new Md5Set(infos);
            upgSet.Save(destPath);
        }

        /// <summary>
        /// 通过版本号进行排序
        /// </summary>
        /// <param name="lhs"></param>
        /// <param name="rhs"></param>
        /// <returns></returns>
        private static int CompareByVer(Md5Info lhs, Md5Info rhs)
        {
            if (lhs == null) return 1;
            if (rhs == null) return 1;
            if (lhs.Ver < rhs.Ver) return 1;
            if (lhs.Ver > rhs.Ver) return -1;
            return 0;
        }

        /// <summary>
        /// 从文件读取MD5信息并将其转换为字典
        /// </summary>
        /// <param name="srcPath">源文件</param>
        /// <param name="isComp">true:文件是压缩的</param>
        /// <returns></returns>
        private static Md5Dic ReadMd5(string srcPath, bool isComp)
        {
            if (!File.Exists(srcPath))
            {
                UIEditTip.Error("读取MD5信息时,路径:{0},不存在", srcPath);
                return null;
            }
            if (isComp)
            {
                var name = Path.GetFileName(srcPath);
                var tempPath = AssetPathUtil.Temp + name;
                return AssetMf.ReadComped(srcPath, tempPath);
            }
            else
            {
                return AssetMf.Read(srcPath);
            }
        }

        /// <summary>
        /// 获取升级信息
        /// </summary>
        /// <param name="oldDic">旧的MD5字典</param>
        /// <param name="newDic">新的MD5字典</param>
        /// <returns></returns>
        private static UpgInfo GetUpgInfo(Md5Dic oldDic, Md5Dic newDic)
        {
            var deleted = new List<Md5Info>();
            var changed = new List<Md5Info>();
            var incresed = new List<Md5Info>();
            var nem = newDic.GetEnumerator();
            while (nem.MoveNext())
            {
                var it = nem.Current;
                var key = it.Key;
                var val = it.Value;
                if (oldDic.ContainsKey(key))
                {
                    if (oldDic[key].MD5.Equals(val.MD5)) continue;
                    changed.Add(val);
                }
                else
                {
                    incresed.Add(val);
                }
            }

            var oem = oldDic.GetEnumerator();
            while (oem.MoveNext())
            {
                var it = oem.Current;
                if (newDic.ContainsKey(it.Key)) continue;
                deleted.Add(it.Value);
            }
            var upgradeInfo = new UpgInfo(deleted, changed, incresed);
            return upgradeInfo;
        }

        /// <summary>
        /// 解析详细文件MD5信息
        /// </summary>
        private static void HandleInfo(UpgInfo info, string srcDir, string destDir)
        {

            if (Directory.Exists(destDir)) Directory.CreateDirectory(destDir);
            if (info.deleted.Count != 0) UIEditTip.Warning("有删除的文件奥");
            if (info.changed.Count != 0) Copy(info.changed, srcDir, destDir);
            if (info.incresed.Count != 0) Copy(info.incresed, srcDir, destDir);
            if (upgrade != null) upgrade(info);
        }


        private static void Copy(List<Md5Info> infos, string srcDir, string destDir)
        {
            if (infos == null || infos.Count == 0) return;
            float length = infos.Count;
            for (int i = 0; i < length; i++)
            {
                Md5Info info = infos[i];
                string file = info.path;
                ProgressBarUtil.Show("", "复制文件", i / length);
                string srcFile = Path.Combine(srcDir, file);
                if (!File.Exists(srcFile)) continue;
                string destFile = Path.Combine(destDir, file);
                FileTool.CheckDir(destFile);
                File.Copy(srcFile, destFile, true);
            }
            ProgressBarUtil.Clear();
        }

        private static void SetCompSize(Md5Dic lastCompDic, Md5Dic curDic)
        {
            var em = lastCompDic.GetEnumerator();
            while (em.MoveNext())
            {
                var it = em.Current;
                var k = it.Key;
                if (!curDic.ContainsKey(k)) continue;
                var last = it.Value;
                var cur = curDic[k];
                if (last.MD5 != cur.MD5) continue;
                if (last.Ver != cur.Ver) continue;
                cur.Sz = last.Sz;
            }
        }

        #endregion
        #region 保护方法

        #endregion

        #region 公开方法
        #region 删除操作
        /// <summary>
        /// 删除指定平台当前版本号的升级信息
        /// </summary>
        public static void Delete(BuildTarget target)
        {
            string folder = EditUtil.GetPlatform(target);
            #region 检查是否存在高版本
            int highVer = Data.version + 1;
            string highFolder = Data.GetUpgDir(folder, highVer);
            if (Directory.Exists(highFolder))
            {
                UIEditTip.Warning("Loong,先删除高版本:{0},才能删除低版本:{1}", highVer, Data.version); return;
            }
            #endregion
            Delete(folder, Data.version);
        }

        /// <summary>
        /// 删除指定平台当前版本号的升级信息
        /// </summary>
        /// <param name="target"></param>
        public static void DeleteWithDialog(BuildTarget target)
        {
            if (EditorUtility.DisplayDialog("", "确定删除", "确定", "取消"))
            {
                Delete(target);
            }
        }

        /// <summary>
        /// 删除指定平台指定版本号的资源更新信息
        /// </summary>
        /// <param name="target">平台</param>
        /// <param name="ver">版本号</param>
        /// <returns></returns>
        public static bool Delete(BuildTarget target, int ver)
        {
            string folder = EditUtil.GetPlatform(target);
            return Delete(folder, ver);
        }

        /// <summary>
        /// 删除指定平台指定版本号的资源更新信息
        /// </summary>
        /// <param name="target"></param>
        /// <param name="ver"></param>
        public static void DeleteWithDialog(BuildTarget target, int ver)
        {
            if (EditorUtility.DisplayDialog("", "确定删除", "确定", "取消"))
            {
                Delete(target, ver);
            }
        }

        /// <summary>
        /// 删除指定平台文件夹指定版本号的资源更新信息
        /// </summary>
        /// <param name="folder">平台文件夹</param>
        /// <param name="ver">版本号</param>
        /// <returns></returns>
        public static bool Delete(string folder, int ver)
        {
            var dir = Data.GetUpgDir(folder, ver);
            if (Directory.Exists(dir))
            {
                Directory.Delete(dir, true);
                UIEditTip.Log("Loong,删除{0}平台,版本号为:{1}的升级信息成功", folder, ver);

                var compDir = Data.GetCompDir(folder, ver);
                if (Directory.Exists(compDir)) Directory.Delete(compDir, true);
                return true;
            }
            else
            {
                UIEditTip.Warning("指定版本号的升级目录:{0},不存在,无需删除", dir);
                return false;
            }
        }

        /// <summary>
        /// 删除指定平台文件夹指定版本号和之上版本号的资源更新信息
        /// </summary>
        /// <param name="folder"></param>
        /// <param name="ver"></param>
        public static void DeleteUp(string folder, int ver)
        {
            while (Delete(folder, ver)) ver++;
        }

        /// <summary>
        /// 删除指定平台指定版本号和之上版本号的资源更新信息
        /// </summary>
        /// <param name="target"></param>
        /// <param name="ver"></param>
        public static void DeleteUp(BuildTarget target, int ver)
        {
            string folder = EditUtil.GetPlatform(target);
            DeleteUp(folder, ver);
        }

        /// <summary>
        /// 删除指定平台指定版本号和之上版本号的资源更新信息
        /// </summary>
        /// <param name="target"></param>
        /// <param name="ver"></param>
        public static void DeleteUpWithDialog(BuildTarget target, int ver)
        {
            if (EditorUtility.DisplayDialog("", "确定删除", "确定", "取消"))
            {
                DeleteUp(target, ver);
            }
        }
        #endregion

        #region 版本号
        /// <summary>
        /// 保存版本号到指定目录
        /// </summary>
        /// <param name="dir">目录</param>
        /// <param name="ver">版本号</param>
        public static void SaveVer(string dir, int ver)
        {
            string verFilePath = Path.Combine(dir, VerFileName);
            string verStr = ver.ToString();
            FileTool.Save(verFilePath, verStr);
        }

        /// <summary>
        /// 保存内部资源版本号,每次重新发包时执行,版本号置0
        /// </summary>
        public static void SaveInternalVer()
        {
            string streamingPath = Application.streamingAssetsPath;
            SaveVer(streamingPath, 0);
        }

        /// <summary>
        /// 保存更新版本号
        /// </summary>
        /// <param name="folder">文件夹</param>
        /// <param name="ver">版本号</param>
        public static void SaveAssetVer(string folder, int ver)
        {
            string upgDir = Data.GetUpgDir(folder, ver);
            SaveVer(upgDir, ver);

        }
        #endregion

        /// <summary>
        /// 压缩资源
        /// </summary>
        public static void Compress(string srcDir, string compDir, int ver)
        {
            string md5Path = Path.Combine(srcDir, ManifestFileName);
            if (File.Exists(md5Path))
            {
                var dic = AssetMf.Read(md5Path);
                Compress(dic, srcDir, compDir, ver);
            }
            else
            {
                UIEditTip.Error("清单文件:{0}不存在", md5Path);
            }
        }

        /// <summary>
        /// 压缩资源
        /// </summary>
        /// <param name="dic">源文件字典</param>
        /// <param name="srcDir">源文件目录</param>
        /// <param name="compDir">要锁目录</param>
        public static void Compress(Md5Dic dic, string srcDir, string compDir, int ver)
        {
            srcDir = DirUtil.GetFull(srcDir);
            if (!Directory.Exists(srcDir))
            {
                iTrace.Warning("Loong", string.Format("compress dir:{0} not exist!", srcDir));
                return;
            }
            if (ver > 0)
            {
                var lastVer = ver - 1;
                var plat = EditUtil.GetPlatform();
                var lastCompMd5Path = Data.GetCompMd5Path(plat, lastVer);
                var lastCompDic = ReadMd5(lastCompMd5Path, true);
                SetCompSize(lastCompDic, dic);
            }

            var comp = CreateComp();
            if (comp == null) return;
            string[] files = Directory.GetFiles(srcDir, "*.*", SearchOption.AllDirectories);
            if (files == null || files.Length < 1) return;
            if (!Directory.Exists(compDir)) Directory.CreateDirectory(compDir);
            var dirLen = srcDir.Length;
            float length = files.Length;
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < length; i++)
            {
                string src = files[i];
                string name = Path.GetFileName(src);
                if (name == ManifestFileName)
                {
                    continue;
                }
                else if (IsFilterFile(name))
                {
                    var filterFile = Path.Combine(compDir, name);
                    FileTool.Copy(src, filterFile);
                    continue;
                }
                string msg = "压缩:" + src;
                ProgressBarUtil.Show("", msg, i / length);
                string rPath = src.Substring(dirLen);
                rPath = rPath.Replace("\\", "/");
                sb.Remove(0, sb.Length);
                sb.Append(compDir).Append("/").Append(rPath);
                string dest = sb.ToString();
                FileTool.CheckDir(dest);
                comp.Src = src;
                comp.Dest = dest;
                if (!comp.Execute())
                {
                    iTrace.Error("Loong", string.Format("压缩:{0},失败", src));
                    break;
                }
                if (dic == null) continue;
                if (!dic.ContainsKey(rPath)) continue;
                var fi = new FileInfo(dest);
                var info = dic[rPath];
                info.Sz = (int)fi.Length;
            }

            var destMf = Path.Combine(compDir, ManifestFileName);
            if (dic == null)
            {
                var srcMf = Path.Combine(srcDir, ManifestFileName);
                if (File.Exists(srcMf)) File.Copy(srcMf, destMf, true);
            }
            else
            {
                WriteMd5Set(dic, destMf);
            }


            GC.Collect();
            ProgressBarUtil.Clear();
            EditorUtility.UnloadUnusedAssetsImmediate();
            UIEditTip.Warning("Loong,压缩完毕");
        }

        /// <summary>
        /// true:过滤文件
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public static bool IsFilterFile(string name)
        {
            if (name == VerFileName) return true;
            if (name == UpgInfoFileName) return true;
            if (name == ManifestFileName) return true;
            return false;
        }

        /// <summary>
        /// 收集指定平台指定版本号的资源的资源
        /// </summary>
        /// <param name="target"></param>
        /// <param name="ver"></param>
        /// <param name="filters">过滤模式</param>
        /// <param name="filters">过滤文件集合</param>
        public static void Collect(BuildTarget target, int ver, AssetUpgMode mode = AssetUpgMode.None, HashSet<string> filters = null)
        {
            et.Beg();
            #region 检查是否需要收集更新信息
            var srcDir = ABTool.Data.Output;
            srcDir = DirUtil.GetFull(srcDir);
            if (!Directory.Exists(srcDir))
            {
                UIEditTip.Error("资源文件夹:{0},不存在", srcDir);
                return;
            }

            var plat = EditUtil.GetPlatform(target);
            var newMd5Path = Data.GetMd5Path(plat, ver);
            if (File.Exists(newMd5Path))
            {
                UIEditTip.Error("版本号为:{0}的升级信息已经存在", ver);
                return;
            }
            #endregion
            Md5Dic curDic = null;
            var destDir = Data.GetUpgDir(plat, ver);
            if (ver == 0)
            {
                var upgDir = Data.GetUpgDir(plat, 0);
                curDic = GetMd5Dic(srcDir, ver, null);
                var srcMfPath = Data.GetSrcMd5Path();
                WriteMd5Set(curDic, srcMfPath);
                SaveAssetVer(plat, 0);
                EditDirUtil.Copy(srcDir, upgDir, filters);
            }
            else
            {
                var lastMd5Path = Data.GetMd5Path(plat, ver - 1);
                if (!File.Exists(lastMd5Path))
                {
                    UIEditTip.Error("无上一个版本MD5文件:{0},无法进行MD5比对", lastMd5Path);
                    return;
                }
                var lastDic = ReadMd5(lastMd5Path, false);
                curDic = GetMd5Dic(srcDir, ver, lastDic, mode, filters);
                var upgInfo = GetUpgInfo(lastDic, curDic);
                if (!upgInfo.Check())
                {
                    UIEditTip.Warning("没有发现删除,修改,新增内容"); return;
                }
                WriteMd5Set(curDic, newMd5Path);
                SaveAssetVer(plat, ver);
                var upgInfoPath = Data.GetUpgInfoPath(plat, ver);
                XmlTool.Serializer<UpgInfo>(upgInfoPath, upgInfo);
                HandleInfo(upgInfo, srcDir, destDir);
            }
            string destMfPath = null;
            var comp = CreateComp();
            if (Data.UseCompress)
            {
                //判断是否需要自动压缩0版本资源
                //if (ver < 1 && !data.AutoCompressZero) return;
                var compDir = Data.GetCompDir(plat, ver);
                Compress(curDic, destDir, compDir, ver);
                var srcMfPath = Data.GetSrcMd5Path();
                destMfPath = Path.Combine(compDir, ManifestFileName);
                FileTool.Copy(destMfPath, srcMfPath);

                //压缩清单
                comp.Src = srcMfPath;
                comp.Dest = destMfPath;
                comp.Execute();
            }
            else
            {
                destMfPath = Path.Combine(srcDir, ManifestFileName);
                FileTool.Copy(newMd5Path, destMfPath);
            }

            UIEditTip.Log("资源目录:{0},生成升级版本:{1},清单:{2}", srcDir, ver, newMd5Path);
            et.End("Asset Upg Collect and Compress");
        }



        /// <summary>
        /// 收集指定平台的资源
        /// </summary>
        public static void Collect(BuildTarget target)
        {
            Collect(target, Data.version);
        }

        /// <summary>
        /// 搜集当前平台信息
        /// </summary>
        /// <param name="ver"></param>
        public static void Collect(int ver)
        {
            Collect(EditorUserBuildSettings.activeBuildTarget, ver);
        }


        /// <summary>
        /// 收集工程设置平台的更新数据
        /// </summary>
        [MenuItem(menu + "收集/工程设置", false, Pri + 1)]
        [MenuItem(AMenu + "收集/工程设置", false, Pri + 1)]
        public static void CollectSetting()
        {
            Collect(EditorUserBuildSettings.activeBuildTarget);
        }

        /// <summary>
        /// 收集安卓平台的更新数据
        /// </summary>
        [MenuItem(menu + "收集/Android", false, Pri + 2)]
        [MenuItem(AMenu + "收集/Android", false, Pri + 2)]
        public static void CollectAndroid()
        {
            Collect(BuildTarget.Android);
        }

        /// <summary>
        /// 收集IOS平台的更新数据
        /// </summary>
        [MenuItem(menu + "收集/iOS", false, Pri + 3)]
        [MenuItem(AMenu + "收集/iOS", false, Pri + 3)]
        public static void CollectIos()
        {
            Collect(BuildTarget.iOS);
        }


        #endregion
    }
}