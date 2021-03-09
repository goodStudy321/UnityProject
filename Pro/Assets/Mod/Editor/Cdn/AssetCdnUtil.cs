/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/13 15:58:47
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
    using Md5Dic = Dictionary<string, Md5Info>;
    /// <summary>
    /// 资源CDN工具
    /// </summary>
    public static class AssetCdnUtil
    {
        #region 字段
        private static AssetCdnView data = null;


        /// <summary>
        /// 菜单优先级
        /// </summary>
        public const int Pri = AssetUtil.Pri + 40;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = AssetUtil.menu + "CDN工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = AssetUtil.AMenu + "CDN工具/";

        /// <summary>
        /// 渠道列表
        /// </summary>
        public static readonly string[] Channels = new string[] { "蜃龙", "君海", "爱奇艺", "神起" };
        #endregion

        #region 属性
        /// <summary>
        /// 校验数据
        /// </summary>
        public static AssetCdnView Data
        {
            get
            {
                if (data == null)
                {
                    data = AssetDataUtil.Get<AssetCdnView>();
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
        private static void UploadPro(float val)
        {
            ProgressBarUtil.Show("", "上传中···", val);
        }

        private static void DownloadPro(float val)
        {
            ProgressBarUtil.Show("", "下载中···", val);
        }

        private static void UnzipPro(float val)
        {
            ProgressBarUtil.Show("", "解压中···", val);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法


        /// <summary>
        /// 上传本地文件夹内的资源到远程目录
        /// </summary>
        /// <param name="remote">远程目录</param>
        /// <param name="local">本地目录</param>
        /// <returns></returns>
        public static bool Upload(string remote, string local)
        {
            iTrace.Log("Loong", "upload {0} to {1}", local, remote);

            if (Directory.Exists(local))
            {
                ProgressBarUtil.Max = 10;
                var ftp = new FTP();
                ftp.UserName = Data.FtpUserName;
                ftp.Password = Data.FtpPassword;
                ftp.LocalPath = local;
                ftp.RemotePath = remote;
                ftp.progress += UploadPro;
                bool suc = ftp.Upload();
                if (suc)
                {
                    iTrace.Warning("Loong", "upload:{0}, to:{1},suc", ftp.LocalPath, ftp.RemotePath);
                }
                else
                {
                    iTrace.Error("Loong", "upload:{0}, to:{1},fail", ftp.LocalPath, ftp.RemotePath);
                }
                ProgressBarUtil.Clear();
                return suc;
            }
            iTrace.Error("Loong", "upload localDir: {0} not exist", local);
            return false;
        }

        /// <summary>
        /// 获取解压后路径
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public static string GetLocalPath(string name)
        {
            string path = Path.Combine(Data.Dir, name);
            return path;
        }

        /// <summary>
        /// 获取下载文件路径
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public static string GetCompPath(string name)
        {
            string dir = Path.Combine(Data.Dir, "Zip");
            string fullPath = Path.Combine(dir, name);
            return fullPath;
        }

        /// <summary>
        /// 校验清单文件
        /// </summary>
        /// <param name="ip"></param>
        /// <param name="localDir"></param>
        /// <returns></returns>
        public static bool CheckMf(string ip, string localDir)
        {
            if (Directory.Exists(Data.Dir)) Directory.Delete(Data.Dir, true);
            string mfName = AssetMf.Name;
            string localMfPath = Path.Combine(localDir, mfName);
            if (!File.Exists(localMfPath))
            {
                iTrace.Error("Loong", "{0} not exist", localMfPath);
                return false;
            }
            string remoteMfPath = Path.Combine(ip, mfName);
            DownloadBase dl = new Download();
            string localPath = GetLocalPath(mfName);
            dl.Src = remoteMfPath;
            dl.Dest = localPath;
            if (dl.Execute())
            {
                var sMd5 = Md5Crypto.GenFile(localPath);
                var lMd5 = Md5Crypto.GenFile(localMfPath);
                if (lMd5 == sMd5)
                {
                    iTrace.Log("Loong", "manifest:{0} verify suc", remoteMfPath);
                    return true;
                }
                iTrace.Error("Loong", "manifest verify fail, server md5:{0} ,local md5:{1}", sMd5, lMd5);
            }
            iTrace.Error("Loong", "download manifest:{0} fail", remoteMfPath);

            return false;
        }

        /// <summary>
        /// 校验远程目录的文件和本地目录的文件
        /// </summary>
        /// <param name="url">远程目录</param>
        /// <param name="localDir">本地目录</param>
        public static bool Verify(string url, string localDir)
        {
            iTrace.Log("Loong", "beg verify,ip:{0},localDir:{1}", url, localDir);
            if (!Directory.Exists(localDir))
            {
                iTrace.Error("Loong", "localDir:{0} not exist", localDir);
                return false;
            }

            if (!CheckMf(url, localDir)) return false;
            string lastDir = Path.GetFileName(localDir);
            UpgInfo info = null;
            bool suc = true;
            if (lastDir == "0")
            {
                string md5Path = Path.Combine(localDir, AssetUpgUtil.ManifestFileName);
                var set = new Md5Set();
                set.Read(md5Path);
                suc = Verify(url, set.infos);
            }
            else
            {
                string upgInfoPath = Path.Combine(localDir, AssetUpgUtil.UpgInfoFileName);
                info = Loong.Game.XmlTool.Deserializer<UpgInfo>(upgInfoPath);
                if (info == null)
                {
                    iTrace.Error("Loong", "read upgradeInfo:{0} fail", upgInfoPath);
                    suc = false;
                }
                else
                {
                    suc = Verify(url, info);
                }
            }
            string des = suc ? "suc" : "fail";
            var msg = string.Format("Verify {0},localDir:{1}, remote:{2}", des, localDir, url);
            if (suc)
            {
                iTrace.Warning("Loong", msg);
            }
            else
            {
                iTrace.Error("Loong", msg);
            }
            return suc;
        }

        /// <summary>
        /// 校验
        /// </summary>
        /// <param name="url">远程路径</param>
        /// <param name="info">升级信息</param>
        public static bool Verify(string url, UpgInfo info)
        {
            if (info == null) return false;
            var fixes = info.GetFixes();
            return Verify(url, fixes);
        }

        /// <summary>
        /// 校验
        /// </summary>
        /// <param name="url"></param>
        /// <param name="localDir"></param>
        /// <param name="lst">升级列表</param>
        /// <returns>校验失败列表</returns>
        public static bool Verify(string url, List<Md5Info> lst)
        {
            if (lst == null) return false;
            if (lst.Count < 1) return true;
            float length = lst.Count;
            var decomp = DecompFty.Create();
            var dl = new Download();
            bool suc = true;
            for (int i = 0; i < length; i++)
            {
                var info = lst[i];
                string path = info.path;
                string compPath = GetCompPath(path);
                dl.Dest = compPath;
                var src = Path.Combine(url, path);
                dl.Src = src;
                FileTool.CheckDir(dl.Dest);
                float pro = i / length;
                ProgressBarUtil.Show("下载中", src, pro);
                if (!dl.Execute())
                {
                    iTrace.Error("Loong", "download:{0} fail", dl.Src);
                    suc = false; break;
                }
                string localPath = GetLocalPath(path);
                string localDir = Path.GetDirectoryName(localPath);
                decomp.SrcStream = File.OpenRead(compPath);
                decomp.Dest = localDir;
                Directory.CreateDirectory(localDir);
                ProgressBarUtil.Show("解压中", src, pro);
                if (!decomp.Execute())
                {
                    iTrace.Error("Loong", "decomp:{0} fail", dl.Src);
                    suc = false; break;
                }
                ProgressBarUtil.Show("校验中", src, pro);
                var sMd5 = Md5Crypto.GenFile(localPath);
                var lMd5 = info.MD5;
                if (sMd5 == lMd5)
                {
                    continue;
                }
                iTrace.Error("Loong", "verify {0},md5:{1},local md5:{2} fail", src, sMd5, lMd5);
                suc = false; break;
            }

            ProgressBarUtil.Clear();

            return suc;
        }

        /// <summary>
        /// 获取资源URL
        /// </summary>
        /// <param name="url">远程路径</param>
        /// <param name="proName">项目名</param>
        /// <param name="id">渠道ID</param>
        /// <param name="debug">调试</param>
        /// <param name="plat">平台名</param>
        /// <returns></returns>
        public static string GetAssetUrl(string url, string proName, int id, bool debug, string plat)
        {
            var sb = new StringBuilder();
            sb.Append(url);
            var lastC = url[url.Length - 1];
            if ((lastC != '/') && (lastC != '\\')) sb.Append("/");
            sb.Append(proName);
            if (!string.IsNullOrEmpty(proName))
            {
                lastC = proName[proName.Length - 1];
                if ((lastC != '/') && (lastC != '\\')) sb.Append("/");
            }
            sb.Append(id).Append("/");
            string release = debug ? "Debug" : "Release";
            sb.Append(release).Append("/");
            sb.Append(plat).Append("/Assets/");
            return sb.ToString();
        }

        public static string GetAssetUrl(string url, string proName, int id, bool debug, string plat, int ver)
        {
            var assetUrl = GetAssetUrl(url, proName, id, debug, plat);
            return string.Format("{0}{1}/", assetUrl, ver);
        }


        #endregion
    }
}