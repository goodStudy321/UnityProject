#if UNITY_EDITOR
using System;
using System.IO;
using System.Text;
using System.Diagnostics;
using System.Collections;
using System.Collections.Generic;

namespace Hello.Game
{
    public static class ProcessUtil
    {
        public static Process Execute(string path,string args = null,string tip = "",bool wairForExit = true)
        {
            if (string.IsNullOrEmpty(path))
            {
                UIEditTip.Error("{0}文件路径为空，无法启动", tip);
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

        public static void Start(string dir,string tip = "")
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
                UIEditTip.Error("{0}目录:{1},不存在，无法打开", tip, fullDir);
            }
        }

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
                        iTrace.Error("Hello", "{0}, err:{1}", tip, err);
                        return false;
                    }
                }

                using (var reader = process.StandardOutput)
                {
                    string line = null;
                    while ((line = reader.ReadLine()) != null)
                    {
                        iTrace.Log("Hello", "{0} {1}", tip, line);
                    }
                }
            }
            catch (Exception e)
            {
                suc = false;
                iTrace.Error("Hello", "{0} err:{1}", tip, e.Message);
            }
            finally
            {
                if (process != null) process.Close();
            }

            return suc;
        }
    }
}


#endif
