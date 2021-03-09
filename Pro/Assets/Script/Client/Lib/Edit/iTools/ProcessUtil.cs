/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2013/6/23 10:34:01
 ============================================================================*/

#if UNITY_EDITOR
using System;
using System.IO;
using System.Text;
using System.Diagnostics;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 编辑器进程工具
    /// </summary>
    public static class ProcessUtil
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 执行进程
        /// </summary>
        /// <param name="path">文件路径</param>
        /// <param name="args">参数</param>
        /// <param name="tip">提示</param>
        public static Process Execute(string path, string args = null, string tip = "", bool wairForExit = true)
        {
            if (string.IsNullOrEmpty(path))
            {
                UIEditTip.Error("{0}文件路径为空,无法启动", tip);
                return null;
            }
            path = Path.GetFullPath(path);
            if (File.Exists(path))
            {
                Process process = new Process();
                process.StartInfo.FileName = path;
                if (!string.IsNullOrEmpty(args)) process.StartInfo.Arguments = args;
                process.Start();
                if (wairForExit) process.WaitForExit();
                process.Close();
                return process;
            }
            else
            {
                UIEditTip.Error("{0}文件路径:{1},不存在", tip, path);
            }
            return null;
        }

        /// <summary>
        /// 打开目录
        /// </summary>
        /// <param name="dir">目录</param>
        /// <param name="tip">提示</param>
        public static void Start(string dir, string tip = "")
        {
            string fullDir = Path.GetFullPath(dir);
            if (string.IsNullOrEmpty(fullDir))
            {
                UIEditTip.Error("{0}目录为空,无法打开", tip);
            }
            else if (Directory.Exists(fullDir))
            {
                Process.Start(fullDir);
            }
            else
            {
                UIEditTip.Error("{0}目录:{1},不存在,无法打开", tip, fullDir);
            }
        }

        /// <summary>
        /// 执行进程;
        /// 发生错误时,对标准错误流中的内容进行输出
        /// 正常执行时,对标准输出流中的内容进行输出,但是有些进程并不一定在错误流中输出,可能会在此流中显示
        /// </summary>
        /// <param name="fileName"></param>
        /// <param name="args"></param>
        /// <param name="tip"></param>
        public static bool Start(string fileName, string args, string tip, bool checkErr = true)
        {
            var suc = true;
            Process process = null;
            try
            {
                if (string.IsNullOrEmpty(tip)) tip = fileName;
                process = new Process();
                var start = process.StartInfo;
                start.FileName = fileName;
                start.Arguments = args;
                start.UseShellExecute = false;
                start.RedirectStandardError = true;
                start.RedirectStandardOutput = true;
                start.StandardErrorEncoding = Encoding.Default;
                start.StandardOutputEncoding = Encoding.Default;
                process.Start();
                if (checkErr)
                {
                    string err = null;
                    using (var reader = process.StandardError)
                    {
                        err = reader.ReadToEnd();
                    }
                    if (!string.IsNullOrEmpty(err))
                    {
                        iTrace.Error("Loong", "{0}, err:{1}", tip, err);
                        return false;
                    }
                }

                using (var reader = process.StandardOutput)
                {
                    string line = null;
                    while ((line = reader.ReadLine()) != null)
                    {
                        iTrace.Log("Loong", "{0} {1}", tip, line);
                    }
                }
            }
            catch (Exception e)
            {
                suc = false;
                iTrace.Error("Loong", "{0} err:{1}", tip, e.Message);
            }
            finally
            {
                if (process != null) process.Close();
            }

            return suc;
        }
        #endregion
    }
}
#endif