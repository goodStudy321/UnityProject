/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2014.3.12 21:31:52
 ============================================================================*/

using System;
using System.IO;
using System.Net;
using Loong.Game;
using System.Collections;
using System.Collections.Generic;

namespace Loong
{
    using FtpMethod = WebRequestMethods.Ftp;
    /// <summary>
    /// Ftp工具类
    /// </summary>
    public static class FtpUtil
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
        private static bool Call(string method, string url, string user, string pass)
        {
            bool suc = true;
            var req = Create(url, user, pass);
            req.Method = method;
            FtpWebResponse resp = null;
            try
            {
                resp = (FtpWebResponse)req.GetResponse();
            }
            catch (Exception e)
            {
                suc = false;
                iTrace.Error("Loong", "{0} err:{1}, url:{2}", method, e.Message, url);
            }
            finally
            {
                if (resp != null) resp.Close();
            }
            return suc;
        }

        /// <summary>
        /// 获取路径中的文件夹路径
        /// </summary>
        /// <param name="path">目录路径</param>
        /// <returns></returns>
        public static string[] GetFolders(string path)
        {
            char c = '/';
            int beg = path.IndexOf(c, 6);
            if (beg < 1) return null;
            string relative = path.Substring(beg + 1);
            int last = relative.Length - 1;
            if (relative.LastIndexOf(c) == last)
            {
                relative = relative.Substring(0, last);
            }
            string[] arr = relative.Split(c);
            return arr;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 创建请求
        /// </summary>
        /// <param name="url">地址</param>
        /// <param name="user">用户名</param>
        /// <param name="pass">密码</param>
        /// <param name="passive">默认:打开被动模式</param>
        /// <returns></returns>
        public static FtpWebRequest Create(string url, string user, string pass, bool passive = true)
        {
            if (string.IsNullOrEmpty(url)) return null;
            var req = (FtpWebRequest)FtpWebRequest.Create(url);
            req.UsePassive = passive;
            req.KeepAlive = true;
            req.UseBinary = true;
            NetworkCredential credential = null;
            if ((!string.IsNullOrEmpty(pass)) && (!string.IsNullOrEmpty(user)))
            {
                credential = new NetworkCredential(user, pass);
            }
            if (credential != null)
            {
                req.Credentials = credential;
            }
            return req;
        }

        /// <summary>
        /// 获取有效URL
        /// </summary>
        /// <param name="url"></param>
        /// <returns></returns>
        public static string GetURL(string url, bool isDir = true)
        {
            string pre = "ftp://";
            url = url.Replace("\\", "/");
            if (isDir)
            {
                char lastC = url[url.Length - 1];
                if (lastC != '/') url = url + "/";
            }
            if (!url.StartsWith(pre))
            {
                url = string.Format("{0}{1}", pre, url);
            }
            return url;
        }

        /// <summary>
        /// 获取远程路径的目录
        /// </summary>
        /// <param name="url"></param>
        /// <returns></returns>
        public static string GetDir(string url)
        {
            url = GetURL(url, false);
            int lastIdx = url.LastIndexOf('/');
            if (lastIdx < 1) return null;
            string dir = url.Substring(0, lastIdx);
            return dir;
        }

        /// <summary>
        /// 获取真正的URL前缀
        /// </summary>
        /// <param name="url"></param>
        /// <returns></returns>
        public static string GetPreURL(string url)
        {
            int beg = url.IndexOf('/', 6);
            if (beg < 1) return url;
            string real = url.Substring(0, beg);
            return real;
        }

        /// <summary>
        /// 获取详细列表,若返回空:一定发生错误
        /// </summary>
        /// <param name="op">0:文件夹,1:文件,2:所有</param>
        /// <param name="url"></param>
        /// <param name="user">用户名</param>
        /// <param name="pass">密码</param>
        /// <param name="passive">被动模式,默认为true</param>
        /// <param name="recursive">递归</param>
        /// <param name="parent">父文件夹</param>
        /// <param name="set">文件夹/文件列表</param>
        /// <returns></returns>
        public static HashSet<string> GetDetails(int op, string url, string user, string pass, bool passive = true, bool recursive = false, string parent = null, HashSet<string> set = null)
        {
            if (string.IsNullOrEmpty(url)) return null;
            url = GetURL(url);
            var req = Create(url, user, pass, passive);
            req.Method = WebRequestMethods.Ftp.ListDirectoryDetails;
            bool isFolder = true;
            WebResponse resp = null;
            Stream stream = null;
            try
            {
                resp = req.GetResponse();
                stream = resp.GetResponseStream();
                if (set == null) set = new HashSet<string>();
                using (var reader = new StreamReader(stream))
                {
                    string detail = null;
                    while (((detail = reader.ReadLine()) != null))
                    {
                        isFolder = detail.StartsWith("dr");

                        int lastEmptyIdx = detail.LastIndexOf(" ");
                        char ht = char.Parse("\t");
                        int lastHtIdx = detail.LastIndexOf(ht);

                        int lastIdx = Math.Max(lastHtIdx, lastEmptyIdx);
                        string path = detail.Substring(lastIdx + 1);
                        string rPath = string.IsNullOrEmpty(parent) ? path : string.Format("{0}/{1}", parent, path);
                        if ((op == 1) && !isFolder)
                        {
                            set.Add(rPath);
                        }
                        else if ((op == 0) && isFolder)
                        {
                            set.Add(rPath);
                        }
                        else if (op == 2)
                        {
                            set.Add(rPath);
                        }
                        if (recursive && isFolder)
                        {
                            string newURL = string.Format("{0}{1}/", url, path);
                            GetDetails(op, newURL, user, pass, passive, true, rPath, set);
                        }
                    }
                }
            }
            catch (Exception e)
            {
                iTrace.Error("Loong", "GetDetail,err:{0}, URL:{1}", e.Message, url);
            }
            finally
            {
                if (stream != null) stream.Close();
                if (resp != null) resp.Close();
            }
            return set;
        }


        /// <summary>
        /// 获取文件夹列表
        /// </summary>
        /// <param name="url"></param>
        /// <param name="user">用户名</param>
        /// <param name="pass">密码</param>
        /// <param name="passive">被动模式,默认为true</param>
        /// <param name="recursive">递归</param>
        /// <param name="parent">父文件夹</param>
        /// <returns></returns>
        public static HashSet<string> GetDirs(string url, string user, string pass, bool passive = true, bool recursive = false, string parent = null)
        {
            url = GetURL(url);
            var set = GetDetails(0, url, user, pass, passive, recursive, parent, null);
            return set;
        }

        /// <summary>
        /// 获取文件夹列表
        /// </summary>
        /// <param name="url">URL地址</param>
        /// <param name="user">用户名</param>
        /// <param name="pass">密码</param>
        /// <param name="passive">被动模式,默认为true</param>
        /// <param name="recursive">递归</param>
        /// <param name="parent">父文件夹</param>
        /// <returns></returns>
        public static HashSet<string> GetFiles(string url, string user, string pass, bool passive = true, bool recursive = false, string parent = null)
        {
            url = GetURL(url);
            var set = GetDetails(1, url, user, pass, passive, recursive, parent, null);
            return set;
        }

        /// <summary>
        /// 创建目录,如果目录已经存在则跳过
        /// </summary>
        /// <param name="url"></param>
        /// <param name="user"></param>
        /// <param name="pass"></param>
        public static bool MakeDir(string url, string user, string pass)
        {
            if (string.IsNullOrEmpty(url)) return false;
            url = GetURL(url);
            string realURL = GetPreURL(url);
            string[] folders = GetFolders(url);
            if (folders == null) return false;
            int length = folders.Length;
            int last = length - 1;
            bool needChk = true;
            for (int i = 0; i < length; i++)
            {
                var folder = folders[i];
                if (needChk)
                {
                    var set = GetDetails(0, realURL, user, pass, true, false);

                    if (set == null) return false;
                    if (!set.Contains(folder))
                    {
                        needChk = false;
                        var newURL = realURL + "/" + folder;
                        realURL = newURL;
                        if (!CallMakeDir(realURL, user, pass)) return false;
                    }
                    else
                    {
                        realURL = realURL + "/" + folder;
                    }
                }
                else
                {
                    var newURL = realURL + "/" + folder;
                    realURL = newURL;
                    if (!CallMakeDir(realURL, user, pass)) return false;
                }
                if (i == last) break;
            }
            return true;
        }

        /// <summary>
        /// 创建本地目录的所有子目录
        /// </summary>
        /// <param name="localDir">本地目录</param>
        /// <param name="url">远程目录</param>
        /// <param name="user"></param>
        /// <param name="pass"></param>
        /// <returns></returns>
        public static bool MakeDir(string localDir, string url, string user, string pass)
        {
            url = GetURL(url);
            string[] dirs = Directory.GetDirectories(localDir, "*", SearchOption.AllDirectories);

            int length = dirs.Length;
            int localLen = localDir.Length;
            char last = localDir[localLen - 1];
            if ((last != '/') && (last != '\\'))
            {
                localLen += 1;
            }
            for (int i = 0; i < length; i++)
            {
                var old = dirs[i];
                string dir = old.Substring(localLen);
                dirs[i] = dir.Replace('\\', '/');
            }

            if (DirExist(url, user, pass))
            {
                var set = GetDirs(url, user, pass, true, true);
                if (set == null) return false;
                for (int i = 0; i < length; i++)
                {
                    string dir = dirs[i];
                    if (set.Contains(dir)) continue;
                    string fullDir = url + dir;
                    if (CallMakeDir(fullDir, user, pass)) continue;
                    return false;
                }
            }
            else
            {
                if (!MakeDir(url, user, pass)) return false;
                for (int i = 0; i < length; i++)
                {
                    string dir = dirs[i];
                    string fullDir = url + dir;
                    if (CallMakeDir(fullDir, user, pass)) continue;
                    return false;
                }
            }
            return true;
        }

        /// <summary>
        /// 获取远程路径的目录,如果不存在则创建
        /// </summary>
        /// <param name="url"></param>
        /// <param name="user"></param>
        /// <param name="pass"></param>
        /// <returns></returns>
        public static bool MakeDirByFile(string url, string user, string pass)
        {
            string dir = GetDir(url);
            return MakeDir(dir, user, pass);
        }

        /// <summary>
        /// 直接创建目录
        /// </summary>
        /// <param name="url">远程目录</param>
        /// <param name="user"></param>
        /// <param name="pass"></param>
        /// <returns></returns>
        public static bool CallMakeDir(string url, string user, string pass)
        {
            var suc = Call(FtpMethod.MakeDirectory, url, user, pass);
            return suc;
        }


        /// <summary>
        /// 判断目录是否存在
        /// </summary>
        /// <param name="url">远程目录</param>
        /// <returns></returns>
        public static bool DirExist(string url, string user, string pass)
        {
            if (string.IsNullOrEmpty(url)) return false;
            url = GetURL(url);
            string real = GetPreURL(url);
            string[] folders = GetFolders(url);
            if (folders == null) return false;
            string realURL = real;
            HashSet<string> set = null;
            int length = folders.Length;
            int last = length - 1;
            for (int i = 0; i < length; i++)
            {
                string folder = folders[i];
                if (set != null) set.Clear();
                set = GetDirs(realURL, user, pass);
                if (set == null) return false;
                if (!set.Contains(folder)) return false;
                realURL = realURL + "/" + folder;
                if (i == last) break;
            }
            return true;
        }

        /// <summary>
        /// 删除目录,需要FTP Server实现RMD命令
        /// </summary>
        /// <param name="url">远程目录</param>
        /// <param name="user"></param>
        /// <param name="pass"></param>
        /// <returns></returns>
        public static bool DelDir(string url, string user, string pass)
        {
            if (!DirExist(url, user, pass)) return false;
            bool suc = DirectDelDir(url, user, pass);
            return suc;
        }

        /// <summary>
        /// 直接删除目录,需要FTP Server实现RMD命令
        /// </summary>
        /// <param name="url">远程目录</param>
        /// <param name="user"></param>
        /// <param name="pass"></param>
        /// <returns></returns>
        public static bool DirectDelDir(string url, string user, string pass)
        {
            bool suc = Call(FtpMethod.RemoveDirectory, url, user, pass);
            return suc;
        }

        /// <summary>
        /// 删除文件
        /// </summary>
        /// <param name="url">远程文件</param>
        /// <param name="user"></param>
        /// <param name="pass"></param>
        /// <returns></returns>
        public static bool DelFile(string url, string user, string pass)
        {
            if (!FileExist(url, user, pass)) return false;
            bool suc = DirectDelFile(url, user, pass);
            return suc;
        }

        /// <summary>
        /// 直接删除文件
        /// </summary>
        /// <param name="url"></param>
        /// <param name="user"></param>
        /// <param name="pass"></param>
        /// <returns></returns>
        public static bool DirectDelFile(string url, string user, string pass)
        {
            bool suc = Call(FtpMethod.DeleteFile, url, user, pass);
            return suc;
        }

        /// <summary>
        /// 文件是否存在
        /// </summary>
        /// <param name="url">远程文件</param>
        /// <param name="user"></param>
        /// <param name="pass"></param>
        /// <returns></returns>
        public static bool FileExist(string url, string user, string pass)
        {
            if (string.IsNullOrEmpty(url)) return false;
            url = GetURL(url, false);
            int lastIdx = url.LastIndexOf('/');
            string dirName = url.Substring(0, lastIdx);
            if (!DirExist(dirName, user, pass)) return false;
            string fileName = Path.GetFileName(url);
            var set = GetDetails(1, dirName, user, pass);
            if (set == null) return false;
            if (set.Contains(fileName)) return true;
            return false;
        }


        #endregion
    }
}