/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.3.12 20:09:25
 ============================================================================*/

using System;
using System.IO;
using System.Net;
using Loong.Game;
using UnityEngine;

namespace Loong
{
    /// <summary>
    /// 通用Ftp类型
    /// </summary>
    public class FTP : FtpBase
    {
        #region 字段
        private byte[] buf = new byte[1024 * 16];
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 委托事件

        #endregion

        #region 私有方法

        /// <summary>
        /// 上传文件
        /// </summary>
        /// <param name="src"></param>
        /// <param name="dest"></param>
        /// <returns></returns>
        private bool UploadFile(string src, string dest)
        {
            int bufLen = buf.Length;
            FileStream fs = null;
            try
            {
                dest = FtpUtil.GetURL(dest, false);
                fs = new FileStream(src, FileMode.Open, FileAccess.Read, FileShare.Read, bufLen);
                var req = FtpUtil.Create(dest, UserName, Password);
                req.Method = WebRequestMethods.Ftp.UploadFile;
                req.ContentLength = fs.Length;
                float total = fs.Length;
                long size = 0;
                using (var upStream = req.GetRequestStream())
                {
                    int contentLen = 0;
                    while ((contentLen = fs.Read(buf, 0, bufLen)) > 0)
                    {
                        size += contentLen;
                        upStream.Write(buf, 0, contentLen);
                        SetPro(size / total);
                    }
                }
                return true;
            }
            catch (Exception e)
            {
                iTrace.Error("Loong", "upload:{0},to:{1},err:{2}", src, dest, e.Message);
            }
            finally
            {
                if (fs != null) fs.Dispose();
            }
            return false;
        }

        /// <summary>
        /// 下载文件
        /// </summary>
        /// <param name="src"></param>
        /// <param name="dest"></param>
        /// <returns></returns>
        private bool DownloadFile(string src, string dest)
        {
            if (File.Exists(dest)) File.Delete(dest);
            FileTool.CheckDir(dest);
            FileStream fs = null;
            int bufLen = buf.Length;
            try
            {
                fs = new FileStream(dest, FileMode.Create, FileAccess.ReadWrite, FileShare.ReadWrite, bufLen);
                var req = FtpUtil.Create(dest, null, null);
                req.Method = WebRequestMethods.Ftp.DownloadFile;
                using (var resp = (FtpWebResponse)req.GetResponse())
                {
                    using (Stream downStream = resp.GetResponseStream())
                    {
                        int size = 0;
                        int readCnt = 0;
                        float total = resp.ContentLength;
                        while ((readCnt = downStream.Read(buf, 0, bufLen)) > 0)
                        {
                            size += readCnt;
                            fs.Write(buf, 0, readCnt);
                            SetPro(size / total);
                        }
                    }
                }
                return true;
            }
            catch (Exception e)
            {
                iTrace.Error("Loong", "download:{0},to:{1},err:{2}", src, dest, e.Message);
            }
            return false;
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public override bool Upload()
        {
            bool suc = true;
            if (File.Exists(LocalPath))
            {
                if (FtpUtil.MakeDirByFile(RemotePath, UserName, Password))
                {
                    suc = UploadFile(LocalPath, RemotePath);
                }
                else
                {
                    suc = false;
                }
            }
            else if (Directory.Exists(LocalPath))
            {
                string rDir = FtpUtil.GetURL(RemotePath);
                if (FtpUtil.MakeDir(LocalPath, rDir, UserName, Password))
                {
                    string[] files = Directory.GetFiles(LocalPath, "*", SearchOption.AllDirectories);
                    int length = files.Length;
                    int localLen = LocalPath.Length;
                    if (!FileTool.IsLastSplash(LocalPath)) localLen += 1;
                    for (int i = 0; i < length; i++)
                    {
                        string file = files[i];
                        string relative = file.Substring(localLen);
                        relative = relative.Replace('\\', '/');
                        string dest = rDir + relative;
                        suc = UploadFile(file, dest);
#if UNITY_EDITOR
                        iTrace.Warning("Loong", "upload file:{0}, {1}", suc ? "suc" : "fail", dest);
#endif
                        if (!suc) break;
                    }
                }
                else
                {
                    suc = false;
                    iTrace.Error("Loong", "make dir:{0} failure", rDir);
                }
            }
            else
            {
                iTrace.Error("Loong", "{0} not exist", LocalPath);
                suc = false;
            }
            Complete(suc);
            return suc;
        }

        public override bool Download()
        {
            bool suc = true;

            return suc;
        }
        #endregion
    }
}