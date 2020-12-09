using System;
using System.IO;
using System.Text;
using System.Threading;
using System.Collections.Generic;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Hello.Game
{
    public static class FileTool
    {
        /// <summary>
        ///  读取文件的内容/并返回字符串
        /// </summary>
        /// <param name="path">文件路径</param>
        /// <returns></returns>
        public static string Load(string path)
        {
            if (!File.Exists(path)) return null;
            using (StreamReader reader = new StreamReader(path, Encoding.UTF8))
            {
                return reader.ReadToEnd();
            }
        }

        /// <summary>
        /// 读取文件的内容/并返回直接数组
        /// </summary>
        /// <param name="path">文件路径</param>
        /// <returns></returns>
        public static byte[] LoadBytes(string path)
        {
            if (!File.Exists(path)) return null;
            byte[] bytes = null;
            using (FileStream fs = new FileStream(path, FileMode.Open))
            {
                bytes = new byte[fs.Length];
                fs.Read(bytes, 0, bytes.Length);
            }
            return bytes;
        }

        /// <summary>
        /// 向文件中写入字符串
        /// </summary>
        /// <param name="path">路径</param>
        /// <param name="str">字符</param>
        /// <param name="append">true:追加</param>
        public static void Save(string path, string str, bool append = false)
        {
            CheckDir(path);
            using (StreamWriter writer = new StreamWriter(path, append, Encoding.UTF8))
            {
                writer.Write(str);
            }
        }

        /// <summary>
        /// 向文件中写入字符串
        /// 安全保存,如果发生异常,继续保存直到成功为止
        /// </summary>
        /// <param name="path"></param>
        /// <param name="str"></param>
        /// <param name="append"></param>
        public static void SafeSave(string path, string str, bool append = false)
        {
            CheckDir(path);
            bool suc = true;
            StreamWriter writer = null;
            try
            {
                writer = new StreamWriter(path, append, Encoding.UTF8);
                writer.Write(str);
            }
            catch (Exception)
            {
                suc = false;
            }
            if (writer != null)
            {
                writer.Dispose();
            }
            if (suc) return;
            Thread.Sleep(20);
            SafeSave(path, str, append);
        }

        /// <summary>
        /// 向文件中写入字符串
        /// </summary>
        /// <param name="path">路径</param>
        /// <param name="str">字符</param>
        /// <param name="encoding">编码</param>
        /// <param name="append">true:追加</param>
        public static void Save(string path, string str, Encoding encoding, bool append = false)
        {
            CheckDir(path);
            using (StreamWriter writer = new StreamWriter(path, append, encoding))
            {
                writer.Write(str);
            }
        }


        /// <summary>
        /// 向文件中写入字节数组/默认UTF8编码
        /// </summary>
        /// <param name="path">路径</param>
        /// <param name="bytes">字节数组</param>
        public static void SaveBytes(string path, byte[] bytes)
        {
            SaveBytes(path, bytes, Encoding.UTF8);
        }

        public static void SafeSaveBytes(string path, byte[] bytes)
        {
            SafeSaveBytes(path, bytes, Encoding.UTF8);
        }

        /// <summary>
        /// 向文件中写入字节数组
        /// </summary>
        /// <param name="path">路径</param>
        /// <param name="bytes">字节数组</param>
        /// <param name="encoding">编码</param>
        public static void SaveBytes(string path, byte[] bytes, Encoding encoding)
        {
            if (bytes == null) return;
            if (string.IsNullOrEmpty(path)) return;
            CheckDir(path);
            using (var stream = new FileStream(path, FileMode.Create))
            {
                using (var writer = new BinaryWriter(stream, encoding))
                {
                    writer.Write(bytes);
                }
            }
        }

        /// <summary>
        /// 向文件中写入字节数组
        /// 安全保存,如果发生异常,继续保存直到成功为止
        /// </summary>
        /// <param name="path"></param>
        /// <param name="bytes"></param>
        /// <param name="encoding"></param>
        public static void SafeSaveBytes(string path, byte[] bytes, Encoding encoding)
        {
            if (bytes == null) return;
            if (string.IsNullOrEmpty(path)) return;
            CheckDir(path);
            bool suc = true;
            FileStream fs = null;
            BinaryWriter writer = null;
            try
            {
                fs = new FileStream(path, FileMode.Create);
                using (writer = new BinaryWriter(fs, encoding))
                {
                    writer.Write(bytes);
                }
            }
            catch (Exception)
            {
                suc = false;
            }
            if (fs != null) fs.Dispose();
            if (suc) return;
            Thread.Sleep(20);
            SafeSaveBytes(path, bytes, encoding);
        }

        public static void SaveSafeBytesDefaultEncoding(string path, byte[] bytes)
        {
            CheckDir(path);
            bool suc = true;
            FileStream fs = null;
            try
            {
                fs = new FileStream(path, FileMode.Create);
                fs.Write(bytes, 0, bytes.Length);
            }
            catch (Exception)
            {
                suc = false;
            }
            if (fs != null)
            {
                fs.Dispose();
            }
            if (suc) return;
            Thread.Sleep(20);
            SaveSafeBytesDefaultEncoding(path, bytes);
        }

        /// <summary>
        ///  删除文件
        /// </summary>
        /// <param name="path">文件路径</param>
        public static void Delete(string path)
        {
            if (File.Exists(path)) File.Delete(path);
        }

        /// <summary>
        /// 删除工程内文件
        /// </summary>
        /// <param name="path">文件路径</param>
        public static void DeleteProjectFile(string path)
        {
            if (!File.Exists(path)) return;
            File.Delete(path);
            string metaPath = string.Format("{0}.meta", path);
            Delete(metaPath);
        }

        /// <summary>
        /// 判断一个文件路径的目录是否存在,如果不存在创建它并返回false,反之返回true
        /// </summary>
        public static bool CheckDir(string filePath)
        {
            string dir = Path.GetDirectoryName(filePath);
            if (!Directory.Exists(dir))
            {
                Directory.CreateDirectory(dir);
                return false;
            }
            return true;
        }

        /// <summary>
        /// 拷贝文件
        /// </summary>
        /// <param name="srcPath">源文件</param>
        /// <param name="destPath">目标文件</param>
        /// <param name="overwrite">true:允许覆盖</param>
        public static void Copy(string srcPath, string destPath, bool overwrite = true)
        {
            if (File.Exists(srcPath)) File.Copy(srcPath, destPath, overwrite);
        }


        public static void SafeCopy(string src, string dest)
        {
            if (!File.Exists(src)) return;
            CheckDir(dest);
            bool suc = true;
            try
            {
                File.Copy(src, dest, true);
            }
            catch (Exception)
            {
                suc = false;
            }
            if (suc) return;
            Thread.Sleep(20);
            SafeCopy(src, dest);
        }

        /// <summary>
        /// 将指定目录的文件列表拷贝到目标目录
        /// </summary>
        /// <param name="files"></param>
        /// <param name="srcDir"></param>
        /// <param name="destDir"></param>
        public static void Copy(List<string> files, string srcDir, string destDir)
        {
            if (files == null || files.Count == 0) return;
            float length = files.Count;
            for (int i = 0; i < length; i++)
            {
                string file = files[i];
#if UNITY_EDITOR
                EditorUtility.DisplayProgressBar("", "复制文件", i / length);
#endif
                string srcFile = Path.Combine(srcDir, file);
                if (!File.Exists(srcFile)) continue;
                string destFile = Path.Combine(destDir, file);
                CheckDir(destFile);
                File.Copy(srcFile, destFile, true);
            }
#if UNITY_EDITOR
            EditorUtility.ClearProgressBar();
#endif
        }

        /// <summary>
        /// 安全删除
        /// </summary>
        /// <param name="path"></param>
        public static void SafeDelete(string path)
        {
            if (File.Exists(path))
            {
                try
                {
                    File.Delete(path);
                }
                catch (System.Exception)
                {
                }
            }
        }


        public static FileStream SafeCreate(string path, int sleep = 10, int bufSize = 1024 * 4)
        {
            FileStream fs = null;
            try
            {
                fs = new FileStream(path, FileMode.Create, FileAccess.ReadWrite, FileShare.None, bufSize);
            }
            catch (Exception)
            {
                if (fs != null)
                {
                    fs.Dispose();
                    fs = null;
                }
            }
            if (fs == null)
            {
                Thread.Sleep(sleep);
                sleep += 5;
                if (sleep > 30) sleep = 30;
                fs = SafeCreate(path, sleep, bufSize);
            }
            return fs;
        }

        public static string GetFullPath(string path)
        {
            if (string.IsNullOrEmpty(path)) return "";
            var full = Path.GetFullPath(path);
            full = full.Replace('\\', '/');
            return GetSlashPath(full);
        }


        public static string GetSlashPath(string path)
        {
            var last = path.Length - 1;
            var last_c = path[last];
            if (last_c != '/') path = path + "/";
            return path;
        }

        /// <summary>
        /// 判断路径是否已斜杠结尾
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        public static bool IsLastSplash(string path)
        {
            var last = path.Length - 1;
            var last_c = path[last];
            if (last_c == '/') return true;
            if (last_c == '\\') return true;
            return false;
        }
    }
}

