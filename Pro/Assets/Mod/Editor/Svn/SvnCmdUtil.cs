//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/8/1 17:42:50
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using System.Text;
using System.Diagnostics;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    using iTrace = Loong.Game.iTrace;

    /// <summary>
    /// SvnUtil
    /// </summary>
    public static class SvnCmdUtil
    {
        #region 字段

        public const char K_Add = 'A';

        public const char K_Del = 'D';

        public const char K_Miss = '!';

        public const char K_Unver = '?';

        public const char K_Modify = 'M';

        public const string Name = "svn";

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

        public static string GetPath(string status)
        {
            var beg = status.LastIndexOf(" ") + 1;
            var path = status.Substring(beg);
            path = path.Replace('\\', '/');
            return path;
        }

        public static SvnStatusInfo Status(string dir)
        {
            if (Directory.Exists(dir))
            {
                var process = new Process();
                var start = process.StartInfo;
                start.FileName = Name;
                start.Arguments = string.Format("status -v {0}", dir);
                start.RedirectStandardOutput = true;
                start.StandardOutputEncoding = Encoding.Default;
                start.UseShellExecute = false;

                process.Start();

                var info = new SvnStatusInfo();
                using (var reader = process.StandardOutput)
                {
                    string line = null;
                    while ((line = reader.ReadLine()) != null)
                    {
                        var ch = line[0];
                        if (ch == K_Add)
                        {
                            info.adds.Add(GetPath(line));
                        }
                        else if (ch == K_Unver)
                        {
                            info.unvers.Add(GetPath(line));
                        }
                        else if (ch == K_Miss)
                        {
                            info.misses.Add(GetPath(line));
                        }
                        else if (ch == K_Del)
                        {
                            info.deletes.Add(GetPath(line));
                        }
                        else if (ch == K_Modify)
                        {
                            info.modifies.Add(GetPath(line));
                        }
                    }
                }

                process.Close();

                return info;
            }
            iTrace.Error("Loong", "{0} not exist!", dir);
            return null;
        }

        /// <summary>
        /// 执行命令
        /// </summary>
        /// <param name="cmd">命令</param>
        /// <param name="paths">路径列表</param>
        /// <returns></returns>
        public static bool Exe(string cmd, List<string> paths)
        {
            if (paths == null || paths.Count < 1) return true;
            int length = paths.Count;
            var last = length - 1;
            var sb = new StringBuilder();
            sb.Append(cmd).Append(" ");
            for (int i = 0; i < length; i++)
            {
                var path = paths[i];
                sb.Append("\"");
                sb.Append(path);
                sb.Append("\"");
                if (i < last) sb.Append(" ");
            }
            return Exe(sb.ToString());
        }

        /// <summary>
        /// 执行命令
        /// </summary>
        /// <param name="arg">参数</param>
        /// <returns></returns>
        public static bool Exe(string arg)
        {
            var suc = true;
            Process process = null;
            try
            {

                process = new Process();
                var start = process.StartInfo;
                start.FileName = Name;
                start.Arguments = arg;
                start.UseShellExecute = false;
                start.RedirectStandardError = true;
                start.RedirectStandardOutput = true;
                start.StandardErrorEncoding = Encoding.Default;
                start.StandardOutputEncoding = Encoding.Default;
                process.Start();
                string err = null;
                using (var reader = process.StandardError)
                {
                    err = reader.ReadToEnd();
                }
                if (!string.IsNullOrEmpty(err))
                {
                    iTrace.Error("Loong", "Svn, err:{0}", err);
                    return false;
                }

                using (var reader = process.StandardOutput)
                {
                    string line = null;
                    while ((line = reader.ReadLine()) != null)
                    {
                        iTrace.Log("Loong", "Svn {0}", line);
                    }
                }
            }
            catch (Exception e)
            {
                suc = false;
                iTrace.Error("Loong", "svn exe err:{0}", e.Message);
            }
            finally
            {
                if (process != null) process.Close();
            }

            return suc;
        }

        /// <summary>
        /// 添加文件
        /// </summary>
        /// <param name="paths">true:文件列表</param>
        /// <returns>true:成功</returns>
        public static bool Add(List<string> paths)
        {
            return Exe("add -q", paths);
        }

        /// <summary>
        /// 删除文件
        /// </summary>
        /// <param name="paths">true:文件列表</param>
        /// <returns>true:成功</returns>
        public static bool Del(List<string> paths)
        {
            return Exe("delete -q", paths);
        }

        /// <summary>
        /// 提交
        /// </summary>
        /// <param name="dir">目录</param>
        /// <param name="fmt">日志</param>
        /// <returns></returns>
        public static bool Commit(string dir, string fmt, params object[] args)
        {
            if (Directory.Exists(dir))
            {

                var cleanup = string.Format("cleanup {0}", dir);
                if (!Exe(cleanup)) return false;
                var log = string.Format(fmt, args);
                var info = Status(dir);
                if (string.IsNullOrEmpty(log)) log = DateTime.Now.ToString();
                if (info == null) return false;
                if (!info.CanCommit()) return false;
                if (!Add(info.unvers)) return false;
                if (!Del(info.misses)) return false;

                if (!Exe(cleanup)) return false;
                var arg = string.Format("commit {0} -q -m {1}", dir, log);
                return Exe(arg);
            }

            iTrace.Error("Loong", "Commit dir:{0} not exist", dir);
            return false;
        }
        #endregion
    }
}